#!/usr/bin/env bash
# A dev's own build: "compiles" the app from src/ into build/.
set -euo pipefail
mkdir -p build
version=$(tr -d '[:space:]' < src/version.txt)
greeting=$(cat src/greeting.txt)
printf '#!/usr/bin/env bash\necho "%s (v%s)"\n' "$greeting" "$version" > build/app
chmod +x build/app
printf '%s\n' "$version" > build/version.txt
echo "built build/app v$version"
