#!/bin/bash
# React Bundle Size Analyzer
# Analyzes your React project's bundle size to identify optimization opportunities
#
# Usage: ./analyze-bundle.sh [project-path] [--build]
#        ./analyze-bundle.sh --build [project-path]
#
# project-path defaults to the current directory. Read-only by default. Only
# with --build (in either position) does it run the project's own `build`
# script (which writes build output as usual).
#
# This script:
# - Checks for bundle analyzer tools
# - Reports commonly large dependencies
# - Suggests code splitting opportunities
# - Optionally (--build) runs the production build

set -uo pipefail

usage() {
    echo "Usage: $0 [project-path] [--build]" >&2
    echo "       $0 --build [project-path]" >&2
}

PROJECT_PATH=""
RUN_BUILD=""
for arg in "$@"; do
    case "$arg" in
        --build) RUN_BUILD="--build" ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "Error: unknown option '$arg'" >&2; usage; exit 1 ;;
        *)
            if [ -n "$PROJECT_PATH" ]; then
                echo "Error: more than one project path given" >&2
                usage
                exit 1
            fi
            PROJECT_PATH="$arg"
            ;;
    esac
done
PROJECT_PATH="${PROJECT_PATH:-.}"

if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: '$PROJECT_PATH' is not a directory" >&2
    exit 1
fi
cd "$PROJECT_PATH" || exit 1

echo "=== React Bundle Size Analysis ==="
echo "Project: $PROJECT_PATH"
echo ""

# This script only inspects package.json and a few top-level paths; it does
# not walk the source tree, so no directory exclude list is needed.

# pkg_has_key NAME: package.json declares "NAME" with a version-like value
# (so a script named "next": "next dev" does not count as a dependency)
pkg_has_key() {
    [ -f package.json ] && grep -qE "\"$1\"[[:space:]]*:[[:space:]]*\"([~^<>=*0-9]|latest|canary|rc|beta|npm:|workspace:|file:|link:|github:|git)" package.json 2>/dev/null
}

# Detect package manager (from lockfile)
if [ -f "pnpm-lock.yaml" ]; then
    PM="pnpm"; PM_ADD_DEV="pnpm add -D"; PM_DLX="pnpm dlx"
elif [ -f "yarn.lock" ]; then
    PM="yarn"; PM_ADD_DEV="yarn add -D"; PM_DLX="yarn dlx"
elif [ -f "bun.lock" ] || [ -f "bun.lockb" ]; then
    PM="bun"; PM_ADD_DEV="bun add -d"; PM_DLX="bunx"
else
    PM="npm"; PM_ADD_DEV="npm install -D"; PM_DLX="npx"
fi

echo "Package manager detected: $PM"
echo ""

# Detect build tool
BUILD_TOOL="unknown"
if [ -f "vite.config.ts" ] || [ -f "vite.config.js" ] || [ -f "vite.config.mts" ] || [ -f "vite.config.mjs" ]; then
    BUILD_TOOL="vite"
elif [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ] || pkg_has_key "next"; then
    BUILD_TOOL="next"
elif [ -f "webpack.config.js" ] || [ -f "webpack.config.ts" ]; then
    BUILD_TOOL="webpack"
fi

echo "Build tool detected: $BUILD_TOOL"

# Next.js App Router: app/ or src/app/ in a Next.js project
NEXT_APP_DIR=""
if [ "$BUILD_TOOL" = "next" ]; then
    if [ -d "app" ]; then
        NEXT_APP_DIR="app"
    elif [ -d "src/app" ]; then
        NEXT_APP_DIR="src/app"
    fi
    if [ -n "$NEXT_APP_DIR" ]; then
        echo "Next.js App Router detected: $NEXT_APP_DIR/"
    fi
fi
echo ""

# Check for bundle analyzer
if ! pkg_has_key "rollup-plugin-visualizer" && ! pkg_has_key "webpack-bundle-analyzer" &&
   ! pkg_has_key "@next/bundle-analyzer" && ! pkg_has_key "source-map-explorer"; then
    echo "Bundle analyzer not found. Consider installing:"
    case "$BUILD_TOOL" in
        vite)    echo "  $PM_ADD_DEV rollup-plugin-visualizer" ;;
        next)    echo "  $PM_ADD_DEV @next/bundle-analyzer" ;;
        webpack) echo "  $PM_ADD_DEV webpack-bundle-analyzer" ;;
        *)       echo "  $PM_ADD_DEV source-map-explorer" ;;
    esac
    echo ""
fi

# Analyze package.json for large dependencies
echo "=== Checking for commonly large dependencies ==="
echo ""

LARGE_DEPS=(
    "moment:Consider date-fns or dayjs (smaller)"
    "lodash:Use lodash-es with tree shaking or individual imports"
    "antd:Use tree shaking or import specific components"
    "@mui/material:Import specific components"
    "chart.js:Consider lighter alternatives for simple charts"
    "three:Consider lazy loading for 3D"
    "pdf-lib:Lazy load PDF functionality"
    "xlsx:Lazy load spreadsheet functionality"
)

FOUND_LARGE=0
for dep_info in "${LARGE_DEPS[@]}"; do
    dep="${dep_info%%:*}"
    suggestion="${dep_info#*:}"
    if pkg_has_key "$dep"; then
        echo "⚠️  Found: $dep"
        echo "   Suggestion: $suggestion"
        echo ""
        FOUND_LARGE=1
    fi
done
if [ "$FOUND_LARGE" -eq 0 ]; then
    echo "  None of the commonly large dependencies found"
    echo ""
fi

# Check for code splitting opportunities
echo "=== Code Splitting Opportunities ==="
echo ""

if [ "$BUILD_TOOL" = "next" ]; then
    echo "Route-based code splitting:"
    echo "  Next.js already splits code per route${NEXT_APP_DIR:+ ($NEXT_APP_DIR/)}; no React.lazy needed for routes."
    echo "  For heavy client-only components, use next/dynamic:"
    echo "    const Chart = dynamic(() => import('./Chart'), { ssr: false });"
    echo "  (ssr: false is only allowed inside Client Components)"
    echo ""
elif [ -d "src/pages" ] || [ -d "src/routes" ] || [ -d "pages" ] || [ -d "routes" ] || [ -d "app" ] || [ -d "src/app" ]; then
    echo "Route-based code splitting:"
    echo "  Routes directory found. If your router doesn't already split per route"
    echo "  (React Router framework mode, Remix, and TanStack Router with autoCodeSplitting do),"
    echo "  lazy load route components:"
    echo ""
    echo "    const Dashboard = lazy(() => import('./pages/Dashboard'));"
    echo ""
fi

echo "Heavy component patterns to check:"
echo "  - Modal/Dialog components"
echo "  - Admin panels"
echo "  - Rich text editors"
echo "  - Chart/Graph components"
echo "  - PDF viewers"
echo ""
if [ "$BUILD_TOOL" = "next" ]; then
    echo "Consider loading these with next/dynamic (or React.lazy + Suspense in Client Components)"
else
    echo "Consider lazy loading these with React.lazy() and Suspense"
fi
echo ""

# Run build only if explicitly requested
if [ "$RUN_BUILD" = "--build" ]; then
    echo "=== Running Production Build ==="
    "$PM" run build
    if [ "$BUILD_TOOL" = "vite" ] && [ -d "dist/assets" ]; then
        echo ""
        echo "=== Bundle Sizes (dist/assets) ==="
        find dist/assets -maxdepth 1 -type f -name '*.js' -exec ls -lh {} + 2>/dev/null | awk '{print $NF, $5}'
    fi
    echo ""
fi

echo "=== Recommendations ==="
echo "1. Split heavy, rarely used components with dynamic import()"
echo "2. Enable tree shaking (use ES modules)"
echo "3. Check for unused dependencies: $PM_DLX knip (or depcheck)"
echo "4. Consider lighter alternatives for large libraries"
echo "5. Use production builds of React (automatic in modern tooling)"
if [ "$RUN_BUILD" != "--build" ]; then
    echo ""
    echo "Re-run with --build to run the project's build script (writes build output)."
fi
echo ""
