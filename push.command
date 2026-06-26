#!/bin/bash
# Double-click this file in Finder to push Celadune to GitHub

cd "$(dirname "$0")"

# Remove any stale git lock files
rm -f .git/index.lock .git/HEAD.lock .git/refs/remotes/origin/main.lock .git/packed-refs.lock

# Stage everything, commit, and push
git add -A

# Only commit if there's something new
if git diff --cached --quiet; then
  echo "Nothing new to push — already up to date."
else
  git commit -m "Update Celadune $(date '+%Y-%m-%d %H:%M')"
  git push origin main --force
  echo ""
  echo "✅ Pushed! Live site updates in ~1 min:"
  echo "   https://dannyccash-web.github.io/celadune/"
fi

echo ""
echo "Press any key to close..."
read -n 1
