#!/bin/bash
# Analyze dark mode implementation and coverage

set -e

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

echo "=== Tailwind CSS Dark Mode Analysis ==="
echo ""

echo "Analyzing directories: ${SRC_DIRS[*]}"
echo ""

# Check dark mode configuration
echo "=== Configuration Check ==="
echo ""

# Check for @custom-variant in CSS
DARK_VARIANT=$(grep -rl --include="*.css" "${EXCLUDES[@]}" "@custom-variant dark" . 2>/dev/null | head -1)
if [ -n "$DARK_VARIANT" ]; then
    echo -e "${GREEN}Dark mode variant configured in: $DARK_VARIANT${NC}"
    grep "@custom-variant dark" "$DARK_VARIANT" 2>/dev/null
elif ls tailwind.config.* >/dev/null 2>&1 && grep -qE "darkMode" tailwind.config.* 2>/dev/null; then
    echo "v3 config sets the dark mode strategy:"
    grep -hE "darkMode" tailwind.config.* 2>/dev/null | head -1
else
    echo "No @custom-variant dark found: dark: follows prefers-color-scheme (v4 default)"
    echo "  For a manual toggle add: @custom-variant dark (&:where(.dark, .dark *));"
fi

# Detect token-swap dark mode: a .dark / [data-theme] / prefers-color-scheme: dark block
# that declares custom properties. @custom-variant lines are ignored (they also contain ".dark").
has_dark_token_block() {
    awk '
        /@custom-variant/ { next }
        !inblk && (/prefers-color-scheme: *dark/ || /(^|[ ,:])(\.dark|\[data-theme[^]]*\])[^,;]*\{/) { inblk = 1; depth = 0 }
        inblk {
            if ($0 ~ /^[ \t]*--[a-zA-Z]/ || $0 ~ /\{[ \t]*--[a-zA-Z]/) { found = 1; exit }
            opens = gsub(/\{/, "{"); closes = gsub(/\}/, "}")
            depth += opens - closes
            if ((opens || closes) && depth <= 0) inblk = 0
        }
        END { exit !found }
    ' "$1"
}
TOKEN_SWAP=""
while IFS= read -r css_file; do
    if has_dark_token_block "$css_file"; then
        TOKEN_SWAP="$css_file"
        break
    fi
done < <(grep -rlE --include="*.css" "${EXCLUDES[@]}" "prefers-color-scheme: *dark|\.dark|data-theme" . 2>/dev/null)
if [ -n "$TOKEN_SWAP" ]; then
    echo -e "${GREEN}Token-swap dark mode detected in: $TOKEN_SWAP${NC}"
    echo "  Colors switch through CSS variables, so few dark: classes are expected"
fi

DARK_USAGE=$(grep -roE "dark:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
if [ "$DARK_USAGE" -eq 0 ] && [ -z "$DARK_VARIANT" ] && [ -z "$TOKEN_SWAP" ]; then
    echo ""
    echo "No dark mode detected (no dark: classes, no dark variant, no token overrides)."
    echo "  Do not add dark: variants unless dark mode is a requirement."
    exit 0
fi

echo ""

# Check for dark class on html element (in layout files)
echo "=== HTML Dark Class Implementation ==="
LAYOUT_FILES=$( { find "${SRC_DIRS[@]}" "${PRUNE[@]}" \( -name "layout.tsx" -o -name "layout.jsx" -o -name "root.tsx" -o -name "root.jsx" -o -name "_app.tsx" -o -name "_app.jsx" -o -name "_document.tsx" -o -name "_document.jsx" -o -name "app.vue" -o -name "app.html" -o -name "Layout.astro" -o -name "+layout.svelte" -o -name "index.html" \) -print 2>/dev/null; ls index.html 2>/dev/null; } | sort -u)
if [ -n "$LAYOUT_FILES" ]; then
    while IFS= read -r file; do
        if grep -q "dark" "$file" 2>/dev/null; then
            echo -e "${GREEN}Dark mode class handling found in: $file${NC}"
        fi
    done <<< "$LAYOUT_FILES"
fi

echo ""

# Check for theme toggle implementation
echo "=== Theme Toggle Implementation ==="
THEME_TOGGLE=$(grep -r "dark\|theme\|color-scheme" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | grep -E "toggle|switch|setTheme|setDark" | head -5)
if [ -n "$THEME_TOGGLE" ]; then
    echo -e "${GREEN}Theme toggle logic found:${NC}"
    echo "$THEME_TOGGLE"
else
    echo -e "${YELLOW}No theme toggle implementation detected${NC}"
fi

echo ""

# Check for next-themes or similar
NEXT_THEMES=$(grep -r "next-themes\|ThemeProvider" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | head -3)
if [ -n "$NEXT_THEMES" ]; then
    echo -e "${GREEN}Using theme library (next-themes or similar)${NC}"
fi

echo ""

# Analyze dark mode class coverage
echo "=== Dark Mode Class Coverage ==="
echo ""

# Count elements with background colors
BG_CLASSES=$(grep -roE "bg-[a-zA-Z]+-[0-9]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
DARK_BG_CLASSES=$(grep -roE "dark:bg-[a-zA-Z]+-[0-9]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
BG_CLASSES=$((BG_CLASSES - DARK_BG_CLASSES))

echo "Background colors: $BG_CLASSES"
echo "Dark background colors: $DARK_BG_CLASSES"

if [ "$BG_CLASSES" -gt 0 ]; then
    COVERAGE=$((DARK_BG_CLASSES * 100 / BG_CLASSES))
    echo "Dark mode background coverage: ${COVERAGE}%"
fi

echo ""

# Count text colors
TEXT_CLASSES=$(grep -roE "text-[a-zA-Z]+-[0-9]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
DARK_TEXT_CLASSES=$(grep -roE "dark:text-[a-zA-Z]+-[0-9]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
TEXT_CLASSES=$((TEXT_CLASSES - DARK_TEXT_CLASSES))

echo "Text colors: $TEXT_CLASSES"
echo "Dark text colors: $DARK_TEXT_CLASSES"

if [ "$TEXT_CLASSES" -gt 0 ]; then
    COVERAGE=$((DARK_TEXT_CLASSES * 100 / TEXT_CLASSES))
    echo "Dark mode text coverage: ${COVERAGE}%"
fi

echo ""

# Count border colors
BORDER_CLASSES=$(grep -roE "border-[a-zA-Z]+-[0-9]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
DARK_BORDER_CLASSES=$(grep -roE "dark:border-[a-zA-Z]+-[0-9]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
BORDER_CLASSES=$((BORDER_CLASSES - DARK_BORDER_CLASSES))

echo "Border colors: $BORDER_CLASSES"
echo "Dark border colors: $DARK_BORDER_CLASSES"

if [ "$BORDER_CLASSES" -gt 0 ]; then
    COVERAGE=$((DARK_BORDER_CLASSES * 100 / BORDER_CLASSES))
    echo "Dark mode border coverage: ${COVERAGE}%"
fi

echo ""

# Find elements that might need dark mode
echo "=== Potential Missing Dark Mode ==="
echo ""

# Find bg-white without dark variant
BG_WHITE_MISSING=$(grep -rn "bg-white" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | grep -v "dark:bg" | head -5)
if [ -n "$BG_WHITE_MISSING" ]; then
    echo -e "${YELLOW}bg-white without dark variant:${NC}"
    echo "$BG_WHITE_MISSING" | while IFS= read -r line; do
        echo "  $line"
    done
fi

# Find text-gray-900 without dark variant
TEXT_DARK_MISSING=$(grep -rn "text-gray-900\|text-black" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | grep -v "dark:text" | head -5)
if [ -n "$TEXT_DARK_MISSING" ]; then
    echo ""
    echo -e "${YELLOW}Dark text without dark variant:${NC}"
    echo "$TEXT_DARK_MISSING" | while IFS= read -r line; do
        echo "  $line"
    done
fi

echo ""

# Summary
echo "=== Summary ==="
echo ""

TOTAL_DARK_CLASSES=$((DARK_BG_CLASSES + DARK_TEXT_CLASSES + DARK_BORDER_CLASSES))
TOTAL_COLOR_CLASSES=$((BG_CLASSES + TEXT_CLASSES + BORDER_CLASSES))

if [ "$TOTAL_COLOR_CLASSES" -gt 0 ]; then
    OVERALL_COVERAGE=$((TOTAL_DARK_CLASSES * 100 / TOTAL_COLOR_CLASSES))

    if [ "$OVERALL_COVERAGE" -gt 80 ]; then
        echo -e "${GREEN}Excellent dark mode coverage: ${OVERALL_COVERAGE}%${NC}"
    elif [ "$OVERALL_COVERAGE" -gt 50 ]; then
        echo -e "${YELLOW}Good dark mode coverage: ${OVERALL_COVERAGE}%${NC}"
        echo "  Consider adding dark variants to more elements"
    elif [ -n "$TOKEN_SWAP" ]; then
        echo "dark: class coverage: ${OVERALL_COVERAGE}% (expected to be low with token-swap dark mode)"
        echo "  Check that hard-coded palette classes (bg-white, text-gray-900) use tokens instead"
    else
        echo -e "${RED}Low dark mode coverage: ${OVERALL_COVERAGE}%${NC}"
        echo "  Many elements may look broken in dark mode"
    fi
else
    echo "No color classes found to analyze"
fi

echo ""
echo "Done!"
