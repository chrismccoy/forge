#!/bin/bash
# Analyze Tailwind CSS class usage patterns in the project

set -e

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

echo "=== Tailwind CSS Class Analysis ==="
echo ""

echo "Analyzing directories: ${SRC_DIRS[*]}"
echo ""

# File extensions to search

echo "=== Class Usage Statistics ==="
echo ""

# Count total class attributes
TOTAL_CLASS_ATTRS=$(grep -rE "class(Name)?=" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
echo "Total class attributes found: $TOTAL_CLASS_ATTRS"

# Count responsive classes (anchored so 2xl:, max-md:, and @md: are not counted)
SM_CLASSES=$(grep -roE "(^|[\"'[:space:]])sm:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
MD_CLASSES=$(grep -roE "(^|[\"'[:space:]])md:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
LG_CLASSES=$(grep -roE "(^|[\"'[:space:]])lg:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
XL_CLASSES=$(grep -roE "(^|[\"'[:space:]])xl:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)

echo ""
echo "=== Responsive Class Usage ==="
echo "sm: prefixed classes: $SM_CLASSES"
echo "md: prefixed classes: $MD_CLASSES"
echo "lg: prefixed classes: $LG_CLASSES"
echo "xl: prefixed classes: $XL_CLASSES"

# Count dark mode classes
DARK_CLASSES=$(grep -roE "dark:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
echo ""
echo "=== Dark Mode Usage ==="
echo "dark: prefixed classes: $DARK_CLASSES"

# Check for hover/focus states
HOVER_CLASSES=$(grep -roE "hover:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
FOCUS_CLASSES=$(grep -roE "focus:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
echo ""
echo "=== State Variant Usage ==="
echo "hover: prefixed classes: $HOVER_CLASSES"
echo "focus: prefixed classes: $FOCUS_CLASSES"

# Check for potential issues
echo ""
echo "=== Potential Issues ==="
echo ""

# Check for dynamic class names (potential purging issues)
# Flag partial class names built at runtime, e.g. `bg-${color}-500` (Tailwind cannot see these).
# Whole-class interpolation such as `${base} ${className}` is safe and not flagged.
DYNAMIC_CLASSES=$(grep -rnE '[a-z0-9:]-\$\{' "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | head -10 || true)

if [ -n "$DYNAMIC_CLASSES" ]; then
    echo -e "${YELLOW}Partial class names built at runtime (Tailwind will not generate these):${NC}"
    echo "  Map values to complete class strings instead, e.g. { red: \"bg-red-500\" }"
    echo "$DYNAMIC_CLASSES"
    echo ""
else
    echo -e "${GREEN}No dynamic class name patterns detected${NC}"
fi

# Check for very long class strings (might need extraction)
echo ""
echo "=== Long Class Strings ==="
LONG_CLASSES=$(grep -roE 'class(Name)?="[^"]{200,}"' "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | head -5 || true)

if [ -n "$LONG_CLASSES" ]; then
    echo -e "${YELLOW}Very long class strings found (consider component extraction):${NC}"
    echo "$LONG_CLASSES" | while IFS= read -r line; do
        printf '  %.100s...\n' "$line"
    done
else
    echo -e "${GREEN}No excessively long class strings found${NC}"
fi

# Most used utility patterns
echo ""
echo "=== Most Used Class Patterns ==="
grep -rhoE "[a-z]+(-[a-z0-9]+)+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | \
    sort | uniq -c | sort -rn | head -15 || echo "Could not analyze patterns"

# Check for clsx/cn usage
echo ""
echo "=== Utility Library Usage ==="
CLSX_USAGE=$(grep -r "clsx\|cn(" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
TWMERGE_USAGE=$(grep -r "twMerge\|tailwind-merge" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)

echo "clsx/cn usage: $CLSX_USAGE instances"
echo "tailwind-merge usage: $TWMERGE_USAGE instances"

if [ "$CLSX_USAGE" -gt 0 ] && [ "$TWMERGE_USAGE" -eq 0 ]; then
    echo "  cn()/clsx without tailwind-merge: conflicting classes passed through className are not resolved"
fi

echo ""
echo "Done!"
