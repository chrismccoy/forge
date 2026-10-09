<?php
/**
 * Dump the outward-facing surface of a plugin tree as sorted lines.
 * Usage: php surface.php <plugin-root> > out.txt
 * Lines: "<kind>\t<value>". Kinds: call:<fn> (first string args), i18n (text, context,
 * plural, domain), wp_error (error code), literal (every string literal).
 * Skips vendor/, tests/, build/, node_modules/ and .git/. Needs PHP 8.0 or later.
 */

if (!isset($argv[1]) || !is_dir($argv[1])) {
    fwrite(STDERR, "Usage: php surface.php <plugin-root> > out.txt\n");
    exit(1);
}
$root = rtrim($argv[1], '/');
$watch = [
    'get_option', 'update_option', 'add_option', 'delete_option', 'register_setting',
    'get_post_meta', 'update_post_meta', 'add_post_meta', 'delete_post_meta',
    'get_transient', 'set_transient', 'delete_transient',
    'register_rest_route', 'add_action', 'add_filter', 'do_action', 'apply_filters',
    'wp_localize_script', 'wp_add_inline_script', 'wp_enqueue_script', 'wp_register_script',
    'wp_enqueue_style', 'wp_register_style', 'add_menu_page', 'add_submenu_page',
    'add_settings_section', 'add_settings_field', 'settings_fields', 'wp_nonce_field',
    'check_admin_referer', 'wp_verify_nonce', 'wp_create_nonce', 'current_user_can',
    'register_post_type', 'register_taxonomy', 'wp_insert_term', 'wp_set_object_terms',
];
$i18n = ['__', '_e', '_x', '_ex', '_n', '_nx', 'esc_html__', 'esc_html_e', 'esc_attr__', 'esc_attr_e', 'esc_html_x', 'esc_attr_x'];

$out = [];
$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS));
foreach ($it as $f) {
    $rel = substr($f->getPathname(), strlen($root) + 1);
    if ($f->getExtension() !== 'php' || preg_match('#^(vendor|tests|node_modules|build|\.git)/#', $rel)) {
        continue;
    }
    $toks = array_values(array_filter(
        token_get_all(file_get_contents($f->getPathname())),
        fn($t) => !is_array($t) || !in_array($t[0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)
    ));
    $n = count($toks);
    for ($i = 0; $i < $n; $i++) {
        $t = $toks[$i];
        if (is_array($t) && $t[0] === T_CONSTANT_ENCAPSED_STRING) {
            $out[] = "literal\t" . stripslashes(substr($t[1], 1, -1));
        }
        // new WP_Error('code'
        if (is_array($t) && $t[0] === T_NEW) {
            $c = $toks[$i + 1] ?? null;
            if (is_array($c) && in_array(ltrim($c[1], '\\'), ['WP_Error'], true)
                && ($toks[$i + 2] ?? null) === '(' && is_array($toks[$i + 3] ?? null)
                && $toks[$i + 3][0] === T_CONSTANT_ENCAPSED_STRING) {
                $out[] = "wp_error\t" . substr($toks[$i + 3][1], 1, -1);
            }
        }
        if (!is_array($t) || !in_array($t[0], [T_STRING, T_NAME_FULLY_QUALIFIED], true)) {
            continue;
        }
        $name = ltrim($t[1], '\\');
        $prev = $toks[$i - 1] ?? null;
        if (is_array($prev) && in_array($prev[0], [T_OBJECT_OPERATOR, T_DOUBLE_COLON, T_FUNCTION, T_NULLSAFE_OBJECT_OPERATOR], true)) {
            continue;
        }
        if (($toks[$i + 1] ?? null) !== '(') {
            continue;
        }
        // Collect top-level string-literal args (null for non-literal).
        $args = [];
        $cur = [];
        $depth = 0;
        for ($j = $i + 2; $j < $n; $j++) {
            $x = $toks[$j];
            if (in_array($x, ['(', '[', '{'], true) || (is_array($x) && in_array($x[0], [T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES], true))) {
                $depth++;
            } elseif (in_array($x, [')', ']', '}'], true)) {
                if ($depth === 0) {
                    $args[] = $cur;
                    break;
                }
                $depth--;
            } elseif ($x === ',' && $depth === 0) {
                $args[] = $cur;
                $cur = [];
                continue;
            }
            $cur[] = $x;
        }
        $lit = fn($a) => (count($a) === 1 && is_array($a[0]) && $a[0][0] === T_CONSTANT_ENCAPSED_STRING)
            ? stripslashes(substr($a[0][1], 1, -1)) : '<expr>';
        if (in_array($name, $i18n, true)) {
            // Context and plural positions per function; the domain is always the last argument.
            $ctxAt = ['_x' => 1, '_ex' => 1, 'esc_html_x' => 1, 'esc_attr_x' => 1, '_nx' => 3][$name] ?? null;
            $plAt = ['_n' => 1, '_nx' => 1][$name] ?? null;
            $out[] = "i18n\t" . $lit($args[0] ?? [])
                . ($ctxAt !== null ? "\t[context=" . $lit($args[$ctxAt] ?? []) . ']' : '')
                . ($plAt !== null ? "\t[plural=" . $lit($args[$plAt] ?? []) . ']' : '')
                . "\t[domain=" . $lit(end($args) ?: []) . ']';
        } elseif (in_array($name, $watch, true)) {
            $vals = array_map($lit, array_slice($args, 0, $name === 'register_rest_route' || $name === 'register_setting' ? 2 : 1));
            $out[] = "call:$name\t" . implode("\t", $vals);
        }
    }
}
sort($out);
echo implode("\n", array_unique($out)), "\n";
