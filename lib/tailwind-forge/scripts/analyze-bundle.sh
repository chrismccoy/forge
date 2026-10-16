#!/bin/bash
# Analyze Tailwind CSS bundle size and optimization opportunities

set -e

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

echo "=== Tailwind CSS Bundle Analysis ==="
echo ""

# Find CSS output files
find_css_files() {
    local dirs=("dist" "build" ".next/static/css" "out" ".output/public" ".svelte-kit/output" "public")
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -name "*.css" 2>/dev/null
        fi
    done
}

# Format a byte count: bytes under 1 KB, otherwise KB with one decimal
fmt_size() {
    if [ "$1" -lt 1024 ]; then
        echo "${1} B"
    else
        awk -v b="$1" 'BEGIN { printf "%.1f KB", b / 1024 }'
    fi
}

ALL_CSS=()
while IFS= read -r file; do
    ALL_CSS+=("$file")
done < <(find_css_files)

# Prefer files with the Tailwind banner so unrelated CSS (for example in public/) is skipped
CSS_FILES=()
for file in "${ALL_CSS[@]}"; do
    if head -c 200 "$file" 2>/dev/null | grep -q "tailwindcss"; then
        CSS_FILES+=("$file")
    fi
done
[ ${#CSS_FILES[@]} -eq 0 ] && CSS_FILES=("${ALL_CSS[@]}")

if [ ${#CSS_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}No compiled CSS files found in common output directories${NC}"
    echo "Run your build command first: npm run build"
    echo ""
    echo "Checking for development CSS..."

    # Try to find any CSS with Tailwind classes
    DEV_CSS=$(find . "${PRUNE[@]}" -name "*.css" -type f -print 2>/dev/null | head -5)
    if [ -n "$DEV_CSS" ]; then
        echo "Found CSS files:"
        echo "$DEV_CSS"
    fi
    exit 0
fi

echo "=== CSS File Sizes ==="
echo ""

for file in "${CSS_FILES[@]}"; do
    if [ -f "$file" ]; then
        SIZE=$(fmt_size "$(wc -c < "$file")")
        LINES=$(wc -l < "$file")
        echo -e "${GREEN}$file${NC}"
        echo "  Raw size: $SIZE"
        echo "  Lines: $LINES"

        # Calculate gzipped size
        GZIP_SIZE=$(gzip -c "$file" 2>/dev/null | wc -c)
        echo "  Gzipped: $(fmt_size "$GZIP_SIZE")"

        # Calculate brotli size if available
        if command -v brotli &> /dev/null; then
            BROTLI_SIZE=$(brotli -c "$file" 2>/dev/null | wc -c)
            echo "  Brotli: $(fmt_size "$BROTLI_SIZE")"
        fi

        echo ""
    fi
done

# Analyze selectors in CSS
echo "=== Selector Analysis ==="
echo ""

for file in "${CSS_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "File: $file"

        # Count unique selectors
        SELECTOR_COUNT=$(grep -oE '\.[a-zA-Z_-]([a-zA-Z0-9_-]|\\.)*' "$file" 2>/dev/null | sort -u | wc -l)
        echo "  Unique class selectors: $SELECTOR_COUNT"

        # Count media queries
        MEDIA_QUERIES=$(grep -c "@media" "$file" 2>/dev/null || true)
        echo "  Media queries: $MEDIA_QUERIES"

        # Count keyframes
        KEYFRAMES=$(grep -c "@keyframes" "$file" 2>/dev/null || true)
        echo "  Keyframe animations: $KEYFRAMES"

        # Count CSS variables
        CSS_VARS=$(grep -oE -e '--[a-zA-Z0-9_-]+' "$file" 2>/dev/null | sort -u | wc -l)
        echo "  CSS custom properties: $CSS_VARS"

        echo ""
    fi
done

# Size recommendations
echo "=== Size Recommendations ==="
echo ""

TOTAL_GZIP=0
for file in "${CSS_FILES[@]}"; do
    if [ -f "$file" ]; then
        GZIP_SIZE=$(gzip -c "$file" 2>/dev/null | wc -c)
        TOTAL_GZIP=$((TOTAL_GZIP + GZIP_SIZE))
    fi
done

TOTAL_GZIP_KB=$((TOTAL_GZIP / 1024))

if [ "$TOTAL_GZIP_KB" -lt 15 ]; then
    echo -e "${GREEN}Excellent! Total gzipped CSS is under 15KB ($(fmt_size "$TOTAL_GZIP"))${NC}"
elif [ "$TOTAL_GZIP_KB" -lt 30 ]; then
    echo -e "${GREEN}Good! Total gzipped CSS is under 30KB ($(fmt_size "$TOTAL_GZIP"))${NC}"
elif [ "$TOTAL_GZIP_KB" -lt 50 ]; then
    echo -e "${YELLOW}Acceptable. Total gzipped CSS is under 50KB ($(fmt_size "$TOTAL_GZIP"))${NC}"
    echo "  Check for dynamic class patterns and over-broad @source paths"
else
    echo -e "${RED}Large bundle! Total gzipped CSS is $(fmt_size "$TOTAL_GZIP")${NC}"
    echo "  Recommendations:"
    echo "  - Check for dynamic class name patterns"
    echo "  - Review @source paths for over-broad patterns"
    echo "  - Remove unused plugins"
fi

echo ""

# Check for common optimization opportunities
echo "=== Optimization Opportunities ==="
echo ""

# Check for transition-all usage
TRANSITION_ALL=$(grep -r "transition-all" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
if [ "$TRANSITION_ALL" -gt 5 ]; then
    echo -e "${YELLOW}Found $TRANSITION_ALL uses of transition-all${NC}"
    echo "  Consider using specific transition classes (transition-colors, transition-transform)"
fi

# Check for theme customization
if ls tailwind.config.* >/dev/null 2>&1; then
    if grep -rq --include="*.css" "${EXCLUDES[@]}" "@config" . 2>/dev/null; then
        echo "JS config loaded through @config (supported in v4)"
        echo "  Consider moving theme values into @theme over time"
    else
        echo -e "${YELLOW}Found tailwind.config file without @config (v3 setup)${NC}"
        echo "  Consider migrating to v4 CSS-first configuration"
    fi
fi

# Check for @theme usage
THEME_USAGE=$(grep -rl --include="*.css" "${EXCLUDES[@]}" "@theme" . 2>/dev/null | wc -l)
if [ "$THEME_USAGE" -gt 0 ]; then
    echo -e "${GREEN}Using v4 @theme directive ($THEME_USAGE files)${NC}"
fi

echo ""
echo "Done!"
