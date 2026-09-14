#!/bin/bash
# 从所有上游仓库同步全部技能
# 使用: ./sync-from-upstream.sh [--push]

set -e

GLOBAL_SKILLS="$HOME/.claude/skills"
# 无人值守(计划任务)场景下 $HOME 可能异常, 回退到绝对路径
cd "$GLOBAL_SKILLS" 2>/dev/null || cd "/c/Users/Administrator/.claude/skills" 2>/dev/null || { echo "❌ 无法定位 skills 目录"; exit 1; }

# ============================================================
# 上游仓库配置 (仓库名 → 分支 → 技能列表)
# ============================================================
UPSTREAMS=(
    "upstream:main:algorithmic-art,brand-guidelines,canvas-design,claude-api,doc-coauthoring,docx,frontend-design,internal-comms,mcp-builder,pdf,pptx,skill-creator,slack-gif-creator,theme-factory,web-artifacts-builder,webapp-testing,xlsx"
    "superpowers:main:brainstorming,dispatching-parallel-agents,executing-plans,finishing-a-development-branch,receiving-code-review,requesting-code-review,subagent-driven-development,systematic-debugging,test-driven-development,using-git-worktrees,using-superpowers,verification-before-completion,writing-plans,writing-skills"
    "ppt-master:main:ppt-master"
    "karpathy:main:karpathy-guidelines"
    "text-to-cad:main:cad,cad-viewer,step-parts,dxf,urdf,srdf,sdf,sendcutsend,dfam-check,gcode,bambu-labs"
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

        # 统计变更 (对比上游 skills/<skill>/ 与本地 HEAD 的 <skill>/, 两者路径前缀不同不能直接 diff 工作区)
        # 本地还没有这个技能时 HEAD:$skill 不存在, git diff 会报错并返回 0, 会被误判成"无变更"而跳过, 所以单独判断
        if git cat-file -e "HEAD:$skill" 2>/dev/null; then
            diff_count=$(git diff --name-only "$remote/$branch:skills/$skill/" "HEAD:$skill/" 2>/dev/null | wc -l)
            if [ "$diff_count" -eq 0 ]; then
                continue
            fi
            echo "   📦 $skill ($diff_count 个文件变更)"
        else
            echo "   📦 $skill (新增技能)"
        fi

        # 删除上游已移除的文件 (一次性列出两边文件清单求差集, 避免对每个文件启动子进程)
        upstream_list=$(mktemp)
        local_list=$(mktemp)
        git ls-tree -r "$remote/$branch" --name-only "skills/$skill/" 2>/dev/null | sed 's|^skills/||' | sort -u > "$upstream_list"
        find "$skill" -type f 2>/dev/null | sed 's|^\./||' | sort -u > "$local_list"
        comm -23 "$local_list" "$upstream_list" | tr '\n' '\0' | xargs -0 -r rm -f
        rm -f "$upstream_list" "$local_list"

        # 从上游提取所有文件 (用 archive 模式，大量文件时效率高)
        # git archive 输出的是仓库相对路径 skills/<skill>/<file>, 需 --strip-components=2 才能落在 <skill>/ 顶层
        mkdir -p "$skill"
        git archive "$remote/$branch" "skills/$skill/" 2>/dev/null | tar xf - --strip-components=2 -C "$skill/" 2>/dev/null

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
