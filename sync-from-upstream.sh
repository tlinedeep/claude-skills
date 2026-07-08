#!/bin/bash
# 从所有上游仓库同步全部技能
# 使用: ./sync-from-upstream.sh [--push]

set -e

GLOBAL_SKILLS="$HOME/.claude/skills"
cd "$GLOBAL_SKILLS"

# ============================================================
# 上游仓库配置 (仓库名 → 分支 → 技能列表)
# ============================================================
UPSTREAMS=(
    "upstream:main:algorithmic-art,brand-guidelines,canvas-design,claude-api,doc-coauthoring,docx,frontend-design,internal-comms,mcp-builder,pdf,pptx,skill-creator,slack-gif-creator,theme-factory,web-artifacts-builder,webapp-testing,xlsx"
    "superpowers:main:brainstorming,dispatching-parallel-agents,executing-plans,finishing-a-development-branch,receiving-code-review,requesting-code-review,subagent-driven-development,systematic-debugging,test-driven-development,using-git-worktrees,using-superpowers,verification-before-completion,writing-plans,writing-skills"
    "ppt-master:main:ppt-master"
    "karpathy:main:karpathy-guidelines"
)

TOTAL_UPDATED=0
TOTAL_SKILLS=0

echo "══════════════════════════════════════════"
echo "🔄 从所有上游同步 Skills..."
echo ""

for entry in "${UPSTREAMS[@]}"; do
    IFS=':' read -r remote branch skills <<< "$entry"
    IFS=',' read -ra SKILL_LIST <<< "$skills"

    echo "--- 上游: $remote ($branch) ---"

    # 拉取最新
    git fetch "$remote" "$branch" --depth=1 --quiet 2>&1 || {
        echo "   ⚠️  拉取 $remote 失败，跳过"
        continue
    }

    for skill in "${SKILL_LIST[@]}"; do
        # 检查上游是否存在这个技能
        if ! git ls-tree -d "$remote/$branch" "skills/$skill/" &>/dev/null 2>&1; then
            continue
        fi

        TOTAL_SKILLS=$((TOTAL_SKILLS + 1))

        # 统计变更
        diff_count=$(git diff --name-only "$remote/$branch" -- "skills/$skill/" 2>/dev/null | wc -l)
        if [ "$diff_count" -eq 0 ]; then
            continue
        fi

        echo "   📦 $skill ($diff_count 个文件变更)"

        # 删除上游已移除的文件
        while IFS= read -r local_file; do
            upstream_path="skills/$local_file"
            if ! git ls-tree -r "$remote/$branch" --name-only "skills/$skill/" 2>/dev/null | grep -qxF "$upstream_path"; then
                [ -f "$local_file" ] && rm "$local_file" 2>/dev/null
            fi
        done < <(find "$skill" -type f 2>/dev/null)

        # 从上游提取所有文件 (用 archive 模式，大量文件时效率高)
        mkdir -p "$skill"
        git archive "$remote/$branch" "skills/$skill/" 2>/dev/null | tar xf - --strip-components=1 -C "$skill/" 2>/dev/null

        TOTAL_UPDATED=$((TOTAL_UPDATED + 1))
    done
done

echo ""
echo "══════════════════════════════════════════"

if [ "$TOTAL_UPDATED" -eq 0 ]; then
    echo "✅ 全部 $TOTAL_SKILLS 个技能已是最新"
    exit 0
fi

echo "📝 提交变更..."
git add -A
if git diff --cached --quiet; then
    echo "✅ 无变更需要提交"
else
    git commit -m "Sync skills from upstreams [$(date +%Y-%m-%d)]"
    echo "✅ 提交完成"

    if [ "$1" = "--push" ]; then
        echo "📤 推送到远程..."
        git push origin master
        echo "✅ 推送完成"
    else
        echo "💡 提示: 使用 --push 参数自动推送到 GitHub"
    fi
fi

echo ""
echo "🎉 同步完成！($TOTAL_UPDATED/$TOTAL_SKILLS 个技能已更新)"
