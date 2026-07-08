#!/bin/bash
# 从上游 anthropics/skills 同步更新本地公共技能
# 使用方式: ./sync-from-upstream.sh [--push]
#   --push  自动推送到你的 GitHub 远程

set -e

GLOBAL_SKILLS="$HOME/.claude/skills"
UPSTREAM_REPO="https://github.com/anthropics/skills.git"

# 上游中的公共技能列表（按需增删）
UPSTREAM_SKILLS=(
    algorithmic-art
    brand-guidelines
    canvas-design
    claude-api
    doc-coauthoring
    docx
    frontend-design
    internal-comms
    mcp-builder
    pdf
    pptx
    skill-creator
    slack-gif-creator
    theme-factory
    web-artifacts-builder
    webapp-testing
    xlsx
)

cd "$GLOBAL_SKILLS"

echo "══════════════════════════════════════════"
echo "🔄 从上游同步 Skills..."
echo "   仓库: $UPSTREAM_REPO"
echo ""

# 确保 upstream 远程存在
if ! git remote get-url upstream &>/dev/null; then
    echo "📡 添加上游远程..."
    git remote add upstream "$UPSTREAM_REPO"
fi

# 获取最新内容
echo "📥 拉取上游更新..."
git fetch upstream --quiet
echo ""

# 比较变更
CHANGED=0
for skill in "${UPSTREAM_SKILLS[@]}"; do
    # 检查上游是否存在这个技能
    if ! git ls-tree -d upstream/main skills/$skill/ &>/dev/null; then
        continue
    fi

    # 统计变更文件数
    diff_count=$(git diff --name-only upstream/main -- skills/$skill/ 2>/dev/null | wc -l)
    if [ "$diff_count" -eq 0 ]; then
        continue
    fi
    CHANGED=$((CHANGED + 1))
    echo "📦 $skill ($diff_count 个文件变更)"

    # 同步文件：先删除本地该技能目录中已不存在的文件
    while IFS= read -r local_file; do
        upstream_path="skills/$local_file"
        if ! git ls-tree -r upstream/main --name-only skills/$skill/ | grep -qxF "$upstream_path"; then
            if [ -f "$local_file" ]; then
                rm "$local_file"
                echo "   🗑️  删除: $local_file"
            fi
        fi
    done < <(find "$skill" -type f 2>/dev/null)

    # 从上游提取文件
    while IFS= read -r f; do
        local_path="${f#skills/}"  # 去掉 skills/ 前缀
        mkdir -p "$(dirname "$local_path")" 2>/dev/null
        git show upstream/main:"$f" > "$local_path"
    done < <(git ls-tree -r upstream/main --name-only skills/$skill/)
done

if [ "$CHANGED" -eq 0 ]; then
    echo "✅ 所有技能已是最新，无需更新"
    exit 0
fi

echo ""
echo "══════════════════════════════════════════"
echo "📝 提交变更..."

git add -A
if git diff --cached --quiet; then
    echo "✅ 无变更需要提交"
else
    git commit -m "Sync skills from upstream anthropics/skills [$(date +%Y-%m-%d)]"
    echo "✅ 提交完成"

    # 如果带了 --push 参数，推送到 origin
    if [ "$1" = "--push" ]; then
        echo ""
        echo "📤 推送到远程..."
        git push origin master
        echo "✅ 推送完成"
    else
        echo ""
        echo "💡 提示: 使用 --push 参数自动推送到 GitHub"
        echo "    ./sync-from-upstream.sh --push"
    fi
fi

echo ""
echo "🎉 同步完成！"
