"""Tests for codebase_analyzer.py.

Each test builds a tiny project in a temp dir that mirrors a pattern seen in a
real codebase, runs analyze_project, and checks the extracted routes/APIs/models.

Run: python3 -m unittest discover -s scripts/tests
"""

import json
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from codebase_analyzer import analyze_project  # noqa: E402


_TEMP_DIRS = []  # keep fixture dirs alive until the process exits


def make_project(files):
    """Write {relative_path: content} into a fresh temp dir and return its Path."""
    tmp = tempfile.TemporaryDirectory()
    _TEMP_DIRS.append(tmp)
    root = Path(tmp.name)
    for rel, content in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(textwrap.dedent(content).lstrip("\n"))
    return root


def pkg(*deps):
    return json.dumps({"name": "fixture", "dependencies": {d: "1.0.0" for d in deps}})


def endpoints(analysis):
    return {(r["method"], r["path"]) for r in analysis["routes"]["backend_endpoints"]}


def pages(analysis):
    return {r["path"] for r in analysis["routes"]["frontend_pages"]}


def api_calls(analysis):
    return {(a["method"], a["path"]) for a in analysis["apis"]["endpoints"]}


class ExpressRoutes(unittest.TestCase):
    def test_router_calls_become_endpoints_with_their_own_method(self):
        root = make_project({
            "package.json": pkg("express"),
            "routes/prompts.js": """
                const router = express.Router();
                router.get("/prompts", ctrl.index);
                router.post("/prompts/:id/rating/:value", ctrl.rate);
                router.get("/prompts/:id/edit", ctrl.editForm);
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {
            ("GET", "/prompts"),
            ("POST", "/prompts/:id/rating/:value"),
            ("GET", "/prompts/:id/edit"),
        })

    def test_esm_mount_prefix_is_applied(self):
        root = make_project({
            "package.json": pkg("express"),
            "server.js": """
                import uploadRouter from './routes/upload.routes.js';
                app.use('/upload', uploadLimiter, uploadRouter);
            """,
            "routes/upload.routes.js": """
                router.post('/catbox', upload.single('file'), handler);
                router.post('/litterbox', handler);
                export default router;
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {
            ("POST", "/upload/catbox"),
            ("POST", "/upload/litterbox"),
        })

    def test_nested_require_mounts_compose_prefixes(self):
        root = make_project({
            "package.json": pkg("express"),
            "server.js": """
                const buildRouter = require("./routes");
                app.use("/", buildRouter(deps));
            """,
            "routes/index.js": """
                module.exports = (deps) => {
                  const router = express.Router();
                  router.use(require("./health")(deps));
                  router.use("/api", require("./api")(deps));
                  return router;
                };
            """,
            "routes/health.js": """
                router.get("/health", (req, res) => res.json({ ok: true }));
            """,
            "routes/api.js": """
                router.post("/generate", limiter, generate.generate);
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {
            ("GET", "/health"),
            ("POST", "/api/generate"),
        })

    def test_template_literal_prefix_constant_is_resolved(self):
        root = make_project({
            "package.json": pkg("express"),
            "config/urls.js": 'const SHARE_PREFIX = "/s";\n',
            "routes/share.js": """
                router.get(`${SHARE_PREFIX}/:token`, guard, ctrl.view);
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {("GET", "/s/:token")})

    def test_server_rendered_get_route_is_a_page(self):
        root = make_project({
            "package.json": pkg("express", "ejs"),
            "server.js": """
                app.get('/', (_req, res) => {
                  res.render('index', { title: 'Upload' });
                });
            """,
            "views/index.ejs": "<h1><%= title %></h1>\n",
        })
        analysis = analyze_project(root)
        self.assertIn("/", pages(analysis))
        page = next(p for p in analysis["routes"]["frontend_pages"] if p["path"] == "/")
        self.assertEqual(page.get("view"), "index")
        self.assertEqual(analysis["summary"]["stack_type"], "fullstack")

    def test_route_definitions_are_not_reported_as_api_calls(self):
        root = make_project({
            "package.json": pkg("express"),
            "routes/categories.js": """
                router.get("/categories", ctrl.index);
                router.post("/categories/:id/delete", ctrl.remove);
            """,
        })
        self.assertEqual(api_calls(analyze_project(root)), set())

    def test_unresolved_dynamic_segment_gets_its_own_slash(self):
        root = make_project({
            "package.json": pkg("express"),
            "config/urls.js": 'const FAVOURITES_PREFIX = "/f";\n',
            "routes/fav.js": """
                for (const path of ["/:token", "/:token/page/:page"]) {
                  router.get(`${FAVOURITES_PREFIX}${path}`, handler);
                }
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {("GET", "/f/:path")})

    def test_unresolved_download_routes_are_endpoints_not_pages(self):
        root = make_project({
            "package.json": pkg("express", "ejs"),
            "views/share.ejs": "<h1>share</h1>\n",
            "routes/share.js": """
                router.get("/c/:token", ctrl.view);
                router.get("/c/:token/download", ctrl.downloadAll);
                router.get("/c/:token/i/:id/file", ctrl.file);
                router.get("/prompts/export", ctrl.exportAll);
            """,
        })
        analysis = analyze_project(root)
        self.assertEqual(pages(analysis), {"/c/:token"})
        self.assertEqual(endpoints(analysis), {
            ("GET", "/c/:token/download"),
            ("GET", "/c/:token/i/:id/file"),
            ("GET", "/prompts/export"),
        })

    def test_trailing_slash_variants_are_one_endpoint(self):
        root = make_project({
            "package.json": pkg("express"),
            "routes/a.js": 'router.get("/prompts/", a);\n',
            "routes/b.js": 'router.get("/prompts", b);\n',
        })
        self.assertEqual(endpoints(analyze_project(root)), {("GET", "/prompts")})


class NestRoutes(unittest.TestCase):
    def test_controller_prefix_applies_and_is_not_its_own_route(self):
        root = make_project({
            "package.json": pkg("@nestjs/core"),
            "src/users/users.controller.ts": """
                @Controller('users')
                export class UsersController {
                  @Get()
                  findAll() {}

                  @Post(':id/roles')
                  addRole() {}
                }
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {
            ("GET", "/users"),
            ("POST", "/users/:id/roles"),
        })


class TestAndCommentNoise(unittest.TestCase):
    def test_test_and_spec_files_are_ignored(self):
        root = make_project({
            "package.json": pkg("express"),
            "tests/api.test.js": 'await fetch("/api/generate", { method: "POST" });\n',
            "e2e/auth.spec.js": 'await page.goto("/health"); request.get("/health");\n',
            "src/thing.test.js": 'router.get("/fake", x);\n',
        })
        analysis = analyze_project(root)
        self.assertEqual(api_calls(analysis), set())
        self.assertEqual(endpoints(analysis), set())

    def test_commented_out_routes_are_ignored(self):
        root = make_project({
            "package.json": pkg("express"),
            "routes/x.js": """
                // router.get("/old", legacy);
                /* router.post("/older", legacy); */
                router.get("/live", handler); // keep me, see http://example.com
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {("GET", "/live")})


class ClientApiCalls(unittest.TestCase):
    def test_template_literal_paths_and_wrapper_methods(self):
        root = make_project({
            "package.json": pkg("react"),
            "src/agent.js": """
                const Auth = {
                  login: (email, password) =>
                    requests.post('/users/login', { user: { email, password } }),
                  current: () => requests.get('/user'),
                };
                const Articles = {
                  get: slug => requests.get(`/articles/${slug}`),
                  del: slug => requests.del(`/articles/${slug}`),
                  byTag: (tag, page) => requests.get(`/articles?tag=${encode(tag)}&${limit(10, page)}`),
                };
            """,
        })
        self.assertEqual(api_calls(analyze_project(root)), {
            ("POST", "/users/login"),
            ("GET", "/user"),
            ("GET", "/articles/:slug"),
            ("DELETE", "/articles/:slug"),
            ("GET", "/articles"),
        })

    def test_concatenated_paths_keep_their_tail(self):
        root = make_project({
            "package.json": pkg("express"),
            "public/js/favorite.js": """
                fetch("/generations/" + button.getAttribute("data-gen-id") + "/favorite", { method: "POST" });
                api.post("/prompts/" + id + "/pin", { pinned: true });
            """,
        })
        self.assertEqual(api_calls(analyze_project(root)), {
            ("POST", "/generations/:id/favorite"),
            ("POST", "/prompts/:id/pin"),
        })

    def test_fetch_method_comes_from_options(self):
        root = make_project({
            "package.json": pkg("react"),
            "src/api.js": """
                fetch('/api/items', { method: "POST", body });
                fetch(`/api/items/${id}`);
            """,
        })
        self.assertEqual(api_calls(analyze_project(root)), {
            ("POST", "/api/items"),
            ("GET", "/api/items/:id"),
        })

    def test_xhr_open_with_template_literal(self):
        root = make_project({
            "package.json": pkg("express"),
            "public/js/uploader.js": """
                const xhr = new XMLHttpRequest();
                xhr.open('POST', `/upload/${this.mode}`);
            """,
        })
        self.assertEqual(api_calls(analyze_project(root)), {("POST", "/upload/:mode")})


class ReactRoutes(unittest.TestCase):
    def test_route_elements_in_any_component_are_pages_not_apis(self):
        root = make_project({
            "package.json": pkg("react", "react-router-dom"),
            "src/components/App.js": """
                <Switch>
                  <Route exact path="/" component={Home}/>
                  <Route path="/login" component={Login} />
                  <Route path="/editor/:slug" component={Editor} />
                </Switch>
            """,
        })
        analysis = analyze_project(root)
        self.assertEqual(pages(analysis), {"/", "/login", "/editor/:slug"})
        self.assertEqual(api_calls(analysis), set())

    def test_backend_models_dir_is_not_state_management(self):
        root = make_project({
            "package.json": pkg("express"),
            "models/prompt.js": "module.exports = {};\n",
        })
        self.assertFalse(analyze_project(root)["summary"]["has_state_management"])

    def test_redux_dependency_counts_as_state_management(self):
        root = make_project({"package.json": pkg("react", "redux", "react-redux")})
        self.assertTrue(analyze_project(root)["summary"]["has_state_management"])


class DjangoRoutes(unittest.TestCase):
    def test_include_prefix_is_joined_and_regex_cleaned(self):
        root = make_project({
            "manage.py": "",
            "conduit/urls.py": '''
                """
                Examples:
                    url(r'^blog/', include('blog.urls'))
                """
                urlpatterns = [
                    url(r'^admin/', admin.site.urls),
                    url(r'^api/', include('conduit.apps.articles.urls', namespace='articles')),
                ]
            ''',
            "conduit/apps/articles/urls.py": """
                urlpatterns = [
                    url(r'^articles/(?P<article_slug>[-\\w]+)/comments/?$', CommentsListCreateAPIView.as_view()),
                    url(r'^tags/?$', TagListAPIView.as_view()),
                ]
            """,
            "conduit/apps/articles/views.py": """
                class CommentsListCreateAPIView(generics.ListCreateAPIView):
                    pass

                class TagListAPIView(generics.ListAPIView):
                    pass
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {
            ("GET", "/api/articles/:article_slug/comments"),
            ("POST", "/api/articles/:article_slug/comments"),
            ("GET", "/api/tags"),
        })

    def test_api_view_methods_come_from_handler_defs(self):
        root = make_project({
            "manage.py": "",
            "app/urls.py": "urlpatterns = [path('users/login/', LoginAPIView.as_view())]\n",
            "app/views.py": """
                class LoginAPIView(APIView):
                    def post(self, request):
                        return Response()
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {("POST", "/users/login")})

    def test_router_viewset_expands_to_collection_and_item_endpoints(self):
        root = make_project({
            "manage.py": "",
            "urls.py": "urlpatterns = [url(r'^api/', include('articles.urls'))]\n",
            "articles/urls.py": """
                router = DefaultRouter(trailing_slash=False)
                router.register(r'articles', ArticleViewSet)
                urlpatterns = [url(r'^', include(router.urls))]
            """,
            "articles/views.py": """
                class ArticleViewSet(mixins.CreateModelMixin,
                                     mixins.ListModelMixin,
                                     mixins.RetrieveModelMixin,
                                     viewsets.GenericViewSet):
                    lookup_field = 'slug'

                    def update(self, request, slug):
                        pass
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {
            ("GET", "/api/articles"),
            ("POST", "/api/articles"),
            ("GET", "/api/articles/:slug"),
            ("PUT", "/api/articles/:slug"),  # update() only; no partial_update, so no PATCH
        })

    def test_models_inheriting_from_abstract_base_are_found(self):
        root = make_project({
            "manage.py": "",
            "core/models.py": """
                class TimestampedModel(models.Model):
                    created_at = models.DateTimeField(auto_now_add=True)

                    class Meta:
                        abstract = True
            """,
            "articles/models.py": """
                class Article(TimestampedModel):
                    title = models.CharField(max_length=255)

                class User(AbstractBaseUser, PermissionsMixin, TimestampedModel):
                    email = models.EmailField(unique=True)
            """,
        })
        models = {m["name"]: m for m in analyze_project(root)["models"]["definitions"]}
        self.assertEqual(set(models), {"TimestampedModel", "Article", "User"})
        self.assertTrue(models["TimestampedModel"].get("abstract"))
        self.assertEqual([f["name"] for f in models["Article"]["fields"]], ["title"])


class FileSystemRouting(unittest.TestCase):
    def test_next_app_router_pages_and_route_handlers(self):
        root = make_project({
            "package.json": pkg("next", "react"),
            "app/page.tsx": "export default function Home() {}\n",
            "app/layout.tsx": "export default function Layout() {}\n",
            "app/users/page.tsx": "export default function Users() {}\n",
            "app/users/[id]/page.tsx": "export default function User() {}\n",
            "app/(marketing)/about/page.tsx": "export default function About() {}\n",
            "app/_components/Button.tsx": "export default function Button() {}\n",
            "app/api/users/route.ts": """
                export async function GET() {}
                export async function POST(req) {}
            """,
        })
        analysis = analyze_project(root)
        self.assertEqual(pages(analysis), {"/", "/users", "/users/:id", "/about"})
        self.assertEqual(endpoints(analysis), {("GET", "/api/users"), ("POST", "/api/users")})
        self.assertEqual(analysis["summary"]["stack_type"], "fullstack")

    def test_next_pages_router_skips_special_files_and_reads_api_methods(self):
        root = make_project({
            "package.json": pkg("next", "react"),
            "pages/_app.tsx": "export default function App() {}\n",
            "pages/_document.tsx": "export default function Doc() {}\n",
            "pages/index.tsx": "export default function Home() {}\n",
            "pages/users/[id].tsx": "export default function User() {}\n",
            "pages/api/users.ts": """
                export default function handler(req, res) {
                  if (req.method === 'POST') { return create(req, res); }
                  return list(req, res);
                }
            """,
        })
        analysis = analyze_project(root)
        self.assertEqual(pages(analysis), {"/", "/users/:id"})
        self.assertEqual(endpoints(analysis), {("POST", "/api/users"), ("ANY", "/api/users")})

    def test_sveltekit_page_and_server_files(self):
        root = make_project({
            "package.json": pkg("@sveltejs/kit", "svelte"),
            "src/routes/+page.svelte": "<h1>Home</h1>\n",
            "src/routes/+layout.svelte": "<slot />\n",
            "src/routes/(app)/users/[id]/+page.svelte": "<h1>User</h1>\n",
            "src/routes/users/[id]/+page.server.ts": "export async function load() {}\n",
            "src/routes/api/users/+server.ts": "export const GET = async () => {};\n",
        })
        analysis = analyze_project(root)
        self.assertEqual(pages(analysis), {"/", "/users/:id"})
        self.assertEqual(endpoints(analysis), {("GET", "/api/users")})

    def test_remix_flat_routes(self):
        root = make_project({
            "package.json": pkg("@remix-run/react", "react"),
            "app/root.tsx": "export default function App() {}\n",
            "app/routes/_index.tsx": "export default function Index() {}\n",
            "app/routes/users._index.tsx": "export default function Users() {}\n",
            "app/routes/users.$id.tsx": "export default function User() {}\n",
            "app/routes/_auth.login.tsx": "export default function Login() {}\n",
            "app/routes/settings.profile/route.tsx": "export default function Profile() {}\n",
            "app/routes/api.users.ts": "export async function loader() {}\nexport async function action() {}\n",
        })
        analysis = analyze_project(root)
        self.assertEqual(pages(analysis), {"/", "/users", "/users/:id", "/login", "/settings/profile"})
        self.assertEqual(endpoints(analysis), {("GET", "/api/users"), ("POST", "/api/users")})

    def test_nuxt_pages_and_server_api(self):
        root = make_project({
            "package.json": pkg("nuxt", "vue"),
            "pages/index.vue": "<template><h1>Home</h1></template>\n",
            "pages/users/[id].vue": "<template><h1>User</h1></template>\n",
            "server/api/users.get.ts": "export default defineEventHandler(() => [])\n",
            "server/api/users/[id].ts": "export default defineEventHandler(() => ({}))\n",
        })
        analysis = analyze_project(root)
        self.assertEqual(pages(analysis), {"/", "/users/:id"})
        self.assertEqual(endpoints(analysis), {("GET", "/api/users"), ("ANY", "/api/users/:id")})

    def test_page_folders_named_like_build_dirs_are_kept(self):
        root = make_project({
            "package.json": pkg("next", "react"),
            "app/media/page.tsx": "export default function Media() {}\n",
            "app/build/page.tsx": "export default function Build() {}\n",
            "app/test/page.tsx": "export default function TestCenter() {}\n",
            "app/users/page.test.tsx": "it('renders', () => {});\n",
        })
        self.assertEqual(pages(analyze_project(root)), {"/media", "/build", "/test"})

    def test_astro_pages_and_endpoints(self):
        root = make_project({
            "package.json": pkg("astro"),
            "src/pages/index.astro": "<h1>Home</h1>\n",
            "src/pages/blog/[slug].md": "# Post\n",
            "src/pages/api/feed.ts": "export async function GET() {}\n",
        })
        analysis = analyze_project(root)
        self.assertEqual(pages(analysis), {"/", "/blog/:slug"})
        self.assertEqual(endpoints(analysis), {("GET", "/api/feed")})


class NestPrefixes(unittest.TestCase):
    def test_object_form_controller_and_global_prefix(self):
        root = make_project({
            "package.json": pkg("@nestjs/core"),
            "src/main.ts": "app.setGlobalPrefix('api');\n",
            "src/users.controller.ts": """
                @Controller({ path: 'users', version: '1' })
                export class UsersController {
                  @Get(':id')
                  findOne() {}
                }
            """,
        })
        self.assertEqual(endpoints(analyze_project(root)), {("GET", "/api/users/:id")})


class MockDetection(unittest.TestCase):
    def test_unrelated_promise_resolve_does_not_mark_real_calls_mock(self):
        root = make_project({
            "package.json": pkg("react", "axios"),
            "src/api.js": """
                export const getUsers = () => axios.get('/api/users');

                export function delay(ms) {
                  return new Promise((r) => setTimeout(r, ms)).then(() => Promise.resolve());
                }
            """,
        })
        api = analyze_project(root)["apis"]["endpoints"][0]
        self.assertTrue(api["integrated"])
        self.assertFalse(api["mock_detected"])

    def test_project_inside_a_mocks_folder_is_not_all_mock(self):
        outer = make_project({
            "mocks/app/package.json": pkg("react"),
            "mocks/app/src/api.js": "fetch('/api/users');\n",
            "mocks/app/src/__mocks__/api.js": "fetch('/api/fake');\n",
        })
        apis = {a["path"]: a for a in analyze_project(outer / "mocks" / "app")["apis"]["endpoints"]}
        self.assertFalse(apis["/api/users"]["mock_detected"])
        self.assertTrue(apis["/api/fake"]["mock_detected"])

    def test_same_endpoint_in_mock_handler_and_real_service_is_merged_as_integrated(self):
        root = make_project({
            "package.json": pkg("react", "axios", "msw"),
            "src/mocks/handlers.ts": "export const handlers = [http.get('/api/users', () => [])];\n",
            "src/services/user.ts": "export const listUsers = () => axios.get('/api/users');\n",
        })
        apis = analyze_project(root)["apis"]["endpoints"]
        self.assertEqual(len(apis), 1)
        self.assertTrue(apis[0]["integrated"])
        self.assertFalse(apis[0]["mock_detected"])
        self.assertEqual(apis[0]["source"], "src/services/user.ts")
        self.assertEqual(apis[0]["sources"], ["src/mocks/handlers.ts", "src/services/user.ts"])

    def test_call_next_to_mock_data_is_mock(self):
        root = make_project({
            "package.json": pkg("react", "axios"),
            "src/api.js": """
                export const getUsers = () => axios.get('/api/users');

















                const mockStats = { users: 10 };
                export const getStats = () => USE_MOCK ? mockStats : axios.get('/api/stats');
            """,
        })
        apis = {a["path"]: a for a in analyze_project(root)["apis"]["endpoints"]}
        self.assertFalse(apis["/api/users"]["mock_detected"])
        self.assertTrue(apis["/api/stats"]["mock_detected"])


class OutputHygiene(unittest.TestCase):
    def test_sources_are_relative_to_project_root(self):
        root = make_project({
            "package.json": pkg("express"),
            "routes/a.js": 'router.get("/a", h);\n',
        })
        analysis = analyze_project(root)
        self.assertEqual(analysis["routes"]["backend_endpoints"][0]["source"], "routes/a.js")
        self.assertEqual(analysis["structure"]["route_dirs"], ["routes"])

    def test_html_comments_in_components_are_ignored(self):
        root = make_project({
            "package.json": pkg("vue"),
            "src/App.vue": """
                <template>
                  <!-- <button @click="fetch('/api/old')">old</button> -->
                </template>
                <script>
                fetch('/api/live');
                </script>
            """,
        })
        self.assertEqual(api_calls(analyze_project(root)), {("GET", "/api/live")})

    def test_egg_info_directories_are_ignored(self):
        root = make_project({
            "manage.py": "",
            "mypkg.egg-info/urls.py": "urlpatterns = [path('ghost/', GhostView.as_view())]\n",
            "app/urls.py": "urlpatterns = [path('real/', RealView.as_view())]\n",
        })
        self.assertEqual({p for _, p in endpoints(analyze_project(root))}, {"/real"})

    def test_python_framework_from_pipfile_alone(self):
        root = make_project({"Pipfile": '[packages]\nflask = "*"\n'})
        self.assertEqual(analyze_project(root)["project"]["framework"], "flask")


class Cli(unittest.TestCase):
    def run_cli(self, *args):
        script = Path(__file__).resolve().parent.parent / "codebase_analyzer.py"
        return subprocess.run([sys.executable, "-I", str(script), *args],
                              capture_output=True, text=True)

    def test_writes_utf8_under_a_non_utf8_locale(self):
        root = make_project({
            "package.json": pkg("react"),
            "src/status.ts": "export const STATUS_MAP = { active: '启用' };\n",
        })
        out = root / "analysis.json"
        env = {**os.environ, "LC_ALL": "C", "LANG": "C", "PYTHONUTF8": "0", "PYTHONCOERCECLOCALE": "0"}
        script = Path(__file__).resolve().parent.parent / "codebase_analyzer.py"
        result = subprocess.run([sys.executable, "-I", "-X", "utf8=0", str(script), str(root), "-o", str(out)],
                                capture_output=True, text=True, env=env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("启用", out.read_text(encoding="utf-8"))

    def test_missing_directory_fails_cleanly_in_markdown_mode(self):
        result = self.run_cli("/nonexistent/project", "-f", "markdown")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Not a directory", result.stderr)
        self.assertNotIn("Traceback", result.stderr)



if __name__ == "__main__":
    unittest.main()
