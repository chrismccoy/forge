#!/bin/bash
# Analyze Tailwind CSS accessibility patterns

set -e

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

echo "=== Tailwind CSS Accessibility Analysis ==="
echo ""

echo "Analyzing directories: ${SRC_DIRS[*]}"
echo ""

# Check focus states
echo "=== Focus State Analysis ==="
echo ""

# Count focus classes
FOCUS_VISIBLE=$(grep -roE "focus-visible:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
FOCUS_REGULAR=$(grep -roE "focus:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
FOCUS_WITHIN=$(grep -roE "focus-within:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)

echo "focus-visible: classes: $FOCUS_VISIBLE"
echo "focus: classes: $FOCUS_REGULAR"
echo "focus-within: classes: $FOCUS_WITHIN"

if [ "$FOCUS_VISIBLE" -eq 0 ] && [ "$FOCUS_REGULAR" -eq 0 ]; then
    echo -e "${RED}No focus styles found${NC}"
    echo "  Interactive elements need a visible focus indicator (focus-visible:outline-2 focus-visible:outline-offset-2)"
elif [ "$FOCUS_VISIBLE" -gt "$FOCUS_REGULAR" ]; then
    echo -e "${GREEN}Good! Using focus-visible for better keyboard navigation${NC}"
else
    echo -e "${YELLOW}Consider using focus-visible: instead of focus: for keyboard-only focus styles${NC}"
fi

echo ""

# Focus outlines survive forced-colors mode; rings (box-shadow) do not
FOCUS_OUTLINE=$(grep -roE "focus(-visible)?:outline-[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
FOCUS_RING=$(grep -roE "focus(-visible)?:ring(-[a-zA-Z0-9_-]+)?" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
echo "Focus outline utilities: $FOCUS_OUTLINE"
echo "Focus ring utilities: $FOCUS_RING"
if [ "$FOCUS_RING" -gt 0 ] && [ "$FOCUS_OUTLINE" -eq 0 ]; then
    echo -e "${YELLOW}Focus uses rings only: box-shadow rings disappear in forced-colors mode${NC}"
    echo "  Add an outline (outline-hidden keeps one in forced-colors mode) or use focus-visible:outline-*"
fi

# Check outline usage
OUTLINE_NONE=$(grep -rn "outline-none" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
# Strip the outline-none token itself (focus:outline-none contains "focus"), then look for a real indicator
OUTLINE_NONE_WITH_RING=$(grep -rh "outline-none" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | sed -E 's/([a-z-]+:)*outline-none//g' | grep -cE "(focus|focus-visible):(ring|outline|border|shadow)" || true)

echo ""
echo "outline-none usage: $OUTLINE_NONE"
if [ "$OUTLINE_NONE" -gt 0 ]; then
    if [ "$OUTLINE_NONE_WITH_RING" -lt "$OUTLINE_NONE" ]; then
        echo -e "${RED}Warning: Found outline-none without replacement focus indicator${NC}"
        echo "  Always provide an alternative focus state (ring, border, etc.)"
    else
        echo -e "${GREEN}outline-none paired with focus indicators${NC}"
    fi
    echo -e "${YELLOW}Note: in v4 outline-none sets outline-style: none, which hides focus in forced-colors mode${NC}"
    echo "  Prefer outline-hidden + ring, or focus-visible:outline-2 focus-visible:outline-offset-2"
fi

echo ""

# Check reduced motion
echo "=== Reduced Motion Analysis ==="
echo ""

MOTION_SAFE=$(grep -roE "motion-safe:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
MOTION_REDUCE=$(grep -roE "motion-reduce:[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)

echo "motion-safe: classes: $MOTION_SAFE"
echo "motion-reduce: classes: $MOTION_REDUCE"

# Count animations/transitions
ANIMATE_CLASSES=$(grep -roE "animate-[a-zA-Z0-9_-]+" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
TRANSITION_CLASSES=$(grep -roE "(^|[\"'[:space:]:])transition(-[a-z]+)?([\"'[:space:]]|$)" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)

echo ""
echo "Animation classes: $ANIMATE_CLASSES"
echo "Transition classes: $TRANSITION_CLASSES"

TOTAL_MOTION=$((ANIMATE_CLASSES + TRANSITION_CLASSES))
MOTION_RESPECT=$((MOTION_SAFE + MOTION_REDUCE))

if [ "$TOTAL_MOTION" -eq 0 ]; then
    echo -e "${GREEN}No animation or transition classes found${NC}"
elif [ "$MOTION_RESPECT" -eq 0 ]; then
    echo -e "${YELLOW}Motion found but no motion-safe: or motion-reduce: variants${NC}"
    echo "  Wrap non-essential animations in motion-safe: or add motion-reduce: fallbacks"
elif [ "$ANIMATE_CLASSES" -gt "$MOTION_RESPECT" ]; then
    echo -e "${YELLOW}$ANIMATE_CLASSES animation classes but only $MOTION_RESPECT motion-safe:/motion-reduce: variants${NC}"
    echo "  Check that looping or large animations respect reduced motion"
else
    echo -e "${GREEN}Motion preferences being respected${NC}"
fi

echo ""

# Check screen reader utilities
echo "=== Screen Reader Utilities ==="
echo ""

SR_ONLY=$(grep -roE "(^|[\"'[:space:]:])sr-only" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
NOT_SR_ONLY=$(grep -roE "not-sr-only" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)

echo "sr-only classes: $SR_ONLY"
echo "not-sr-only classes: $NOT_SR_ONLY"

if [ "$SR_ONLY" -gt 0 ]; then
    echo -e "${GREEN}Good! Using sr-only for screen reader text${NC}"
fi

echo ""

# Check for ARIA attributes
echo "=== ARIA Usage ==="
echo ""

ARIA_ATTRS=$(grep -roE "aria-[a-zA-Z]+=" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
ROLE_ATTRS=$(grep -roE "role=" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)

echo "ARIA attributes: $ARIA_ATTRS"
echo "Role attributes: $ROLE_ATTRS"

echo ""

# Check interactive elements
echo "=== Interactive Element Analysis ==="
echo "(Heuristic: only checks the line containing the opening tag; multi-line JSX is undercounted)"
echo ""

# Buttons without focus states
BUTTONS=$(grep -rn "<button" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
BUTTONS_WITH_FOCUS=$(grep -n "<button" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" -r 2>/dev/null | grep -E "focus" | wc -l)

echo "Total buttons: $BUTTONS"
echo "Buttons with focus styles: $BUTTONS_WITH_FOCUS"

if [ "$BUTTONS" -gt 0 ]; then
    BUTTON_COVERAGE=$((BUTTONS_WITH_FOCUS * 100 / BUTTONS))
    if [ "$BUTTON_COVERAGE" -lt 80 ]; then
        echo -e "${YELLOW}Only ${BUTTON_COVERAGE}% of buttons have focus styles${NC}"
    else
        echo -e "${GREEN}Good focus state coverage on buttons${NC}"
    fi
fi

echo ""

# Links
LINKS=$(grep -rn "<a " "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | wc -l)
LINKS_WITH_FOCUS=$(grep -n "<a " "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" -r 2>/dev/null | grep -E "focus" | wc -l)

echo "Total links: $LINKS"
echo "Links with focus styles: $LINKS_WITH_FOCUS"

echo ""

# Check for touch target sizes
echo "=== Touch Target Analysis ==="
echo ""

SMALL_BUTTONS=$(grep -rnE "(^|[\"'[:space:]])(p|py|px)-(0|0\.5|1|1\.5|2)([\"'[:space:]]|$)" "${SRC_DIRS[@]}" "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | grep -iE "button|click" | wc -l)

if [ "$SMALL_BUTTONS" -gt 0 ]; then
    echo -e "${YELLOW}Found $SMALL_BUTTONS potentially small touch targets${NC}"
    echo "  WCAG 2.2 AA minimum is 24x24px (min-h-6 min-w-6); 44x44px recommended (min-h-11 min-w-11)"
else
    echo -e "${GREEN}No obviously small touch targets detected${NC}"
fi

echo ""

# Summary
echo "=== Accessibility Summary ==="
echo ""

SCORE=0
MAX_SCORE=5

[ "$FOCUS_VISIBLE" -gt 0 ] && SCORE=$((SCORE + 1))
[ "$MOTION_RESPECT" -gt 0 ] && SCORE=$((SCORE + 1))
[ "$SR_ONLY" -gt 0 ] && SCORE=$((SCORE + 1))
[ "$ARIA_ATTRS" -gt 0 ] && SCORE=$((SCORE + 1))
[ "$FOCUS_OUTLINE" -gt 0 ] && SCORE=$((SCORE + 1))

echo "Accessibility Score: $SCORE/$MAX_SCORE"

if [ "$SCORE" -eq 5 ]; then
    echo -e "${GREEN}Excellent! Following accessibility best practices${NC}"
elif [ "$SCORE" -ge 3 ]; then
    echo -e "${YELLOW}Good foundation, but room for improvement${NC}"
else
    echo -e "${RED}Consider improving accessibility coverage${NC}"
fi

echo ""
echo "Done!"
