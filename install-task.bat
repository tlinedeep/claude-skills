@echo off
REM 创建计划任务：每周一自动同步 Skills 上游更新
REM 请以管理员身份运行此脚本

schtasks /create /tn "Sync-Skills-Upstream" /tr "'C:\Program Files\Git\bin\bash.exe' -c 'cd /c/Users/Administrator/.claude/skills && bash sync-from-upstream.sh --push'" /sc weekly /d MON /st 09:00 /f

if %errorlevel% equ 0 (
    echo [OK] 计划任务 'Sync-Skills-Upstream' 已创建
    echo      触发器: 每周一 09:00
    echo      操作: 自动同步上游 skills ^& 推送到 GitHub
) else (
    echo [!!] 创建失败，请以管理员身份运行此脚本
    echo      右键点击 install-task.bat → 以管理员身份运行
)

pause
