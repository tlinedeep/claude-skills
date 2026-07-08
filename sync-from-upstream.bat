@echo off
REM 从上游 anthropics/skills 同步更新本地公共技能
REM 配合 Windows 计划任务使用

set GLOBAL_SKILLS=%USERPROFILE%\.claude\skills

cd /d "%GLOBAL_SKILLS%"

REM 确保 upstream 远程存在
git remote get-url upstream >nul 2>&1
if %errorlevel% neq 0 (
    git remote add upstream https://github.com/anthropics/skills.git
)

REM 拉取更新
echo [%date% %time%] 正在检查上游更新...
git fetch upstream --quiet

REM 检查是否有变更
git diff --quiet upstream/main -- skills/ 2>nul
if %errorlevel%==0 (
    echo [%date% %time%] 已是最新，无需更新
    exit /b 0
)

echo [%date% %time%] 发现更新，正在同步...

REM 同步逻辑（简版：直接覆盖上游文件）
set UPSTREAM_SKILLS=algorithmic-art brand-guidelines canvas-design claude-api doc-coauthoring docx frontend-design internal-comms mcp-builder pdf pptx skill-creator slack-gif-creator theme-factory web-artifacts-builder webapp-testing xlsx

for %%s in (%UPSTREAM_SKILLS%) do (
    git ls-tree -r upstream/main --name-only skills/%%s/ 2>nul >nul
    if !errorlevel! equ 0 (
        mkdir %%s 2>nul
        for /f "usebackq delims=" %%f in (`git ls-tree -r upstream/main --name-only skills/%%s/`) do (
            set "local=%%f"
            set "local=!local:skills/=!"
            mkdir "!local!\.." 2>nul
            git show upstream/main:%%f > "!local!" 2>nul
        )
    )
)

git add -A
git commit -m "Auto-sync from upstream anthropics/skills [%date%]"
git push origin master

echo [%date% %time%] 同步完成！
