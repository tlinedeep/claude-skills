@echo off
REM 创建计划任务：每周一自动同步 Skills 上游更新
REM 请以管理员身份运行此脚本
REM 从同目录的 Sync-Skills-Upstream.xml 导入配置

schtasks /create /tn "Sync-Skills-Upstream" /xml "%~dp0Sync-Skills-Upstream.xml" /f

if %errorlevel% equ 0 (
    echo [OK] 计划任务 'Sync-Skills-Upstream' 已创建
    echo      触发器: 每周一 09:00
    echo      操作: 自动同步上游 skills ^& 推送到 GitHub
) else (
    echo [!!] 创建失败，请以管理员身份运行此脚本
    echo      右键点击 install-task.bat → 以管理员身份运行
)

pause
