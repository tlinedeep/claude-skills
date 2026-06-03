#!/bin/bash
# Sync skills from project (.agents/skills) to global (.claude/skills)
# Usage: ./sync-skills.sh [project_path]

set -e

GLOBAL_SKILLS="$HOME/.claude/skills"
PROJECT_SKILLS="${1:-$HOME/cc1/.agents/skills}"

if [ ! -d "$PROJECT_SKILLS" ]; then
    echo "❌ Project skills directory not found: $PROJECT_SKILLS"
    exit 1
fi

echo "📁 Source: $PROJECT_SKILLS"
echo "📁 Target: $GLOBAL_SKILLS"
echo ""

# Copy all skills from project to global
cd "$PROJECT_SKILLS"
for skill in */; do
    skill_name="${skill%/}"
    echo "🔄 Syncing: $skill_name"
    # Use robocopy on Windows (mirrors directory, /MIR = mirror, /E = copy subdirs, /NJH = no job header, /NJS = no job summary, /NFL = no file list, /NDL = no dir list
    robocopy "$PROJECT_SKILLS/$skill_name" "$GLOBAL_SKILLS/$skill_name" /MIR /E /NJH /NJS /NFL /NDL /NP 2>/dev/null || true
done

# Git commit in global
cd "$GLOBAL_SKILLS"
git add -A
if git diff --cached --quiet; then
    echo ""
    echo "✅ No changes to commit"
else
    git commit -m "Sync skills from project: $(date +%Y-%m-%d_%H:%M:%S)"
    echo ""
    echo "✅ Changes committed"
fi

echo ""
echo "🎉 Sync complete!"
