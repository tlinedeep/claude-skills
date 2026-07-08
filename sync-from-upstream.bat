@echo off
REM 从所有上游仓库同步全部技能
REM 配合 Windows 计划任务使用
REM 请以管理员身份运行

set GLOBAL_SKILLS=%USERPROFILE%\.claude\skills
cd /d "%GLOBAL_SKILLS%"

echo [%date% %time%] 正在检查所有上游更新...

REM 拉取所有上游
git fetch upstream main --depth=1 --quiet
git fetch superpowers main --depth=1 --quiet
git fetch ppt-master main --depth=1 --quiet
git fetch karpathy main --depth=1 --quiet

REM 推送到 origin
git push origin master

echo [%date% %time%] 同步完成！
