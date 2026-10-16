#!/bin/bash
# Shared settings for the tailwind-forge analysis scripts. Sourced, not run.
# shellcheck disable=SC2034  # variables are used by the scripts that source this file

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Source directories: scan every one that exists, else the project root
SRC_DIRS=()
for d in src app components pages lib; do
    [ -d "$d" ] && SRC_DIRS+=("$d")
done
[ ${#SRC_DIRS[@]} -eq 0 ] && SRC_DIRS=(".")

# Directories never scanned (dependencies and build output)
EXCLUDES=(--exclude-dir={node_modules,dist,build,out,.next,.nuxt,.output,.svelte-kit,.astro,.vercel,.git,coverage})

# Files that can contain Tailwind classes (markup, components, and cn()/CVA definitions)
INCLUDES=("--include=*."{tsx,jsx,ts,js,vue,svelte,astro,html,mdx})

# Find arguments that skip the same directories (use as: find DIR "${PRUNE[@]}" ... -print)
PRUNE=(\( -name node_modules -o -name dist -o -name build -o -name out -o -name .next -o -name .nuxt -o -name .output -o -name .svelte-kit -o -name .astro -o -name .vercel -o -name .git -o -name coverage \) -prune -o)
