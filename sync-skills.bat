@echo off
REM Sync skills from project (.agents/skills) to global (.claude/skills)
REM Usage: sync-skills.bat [project_path]

set GLOBAL_SKILLS=%USERPROFILE%\.claude\skills
set PROJECT_SKILLS=%1
if "%PROJECT_SKILLS%"=="" set PROJECT_SKILLS=%USERPROFILE%\cc1\.agents\skills

if not exist "%PROJECT_SKILLS%" (
    echo ❌ Project skills directory not found: %PROJECT_SKILLS%
    exit /b 1
)

echo 📁 Source: %PROJECT_SKILLS%
echo 📁 Target: %GLOBAL_SKILLS%
echo.

REM Copy all skills
for /d %%i in ("%PROJECT_SKILLS%\*") do (
    echo 🔄 Syncing: %%~nxi
    xcopy "%%i" "%GLOBAL_SKILLS%\%%~nxi\" /E /I /Y /Q >nul
)

REM Git commit
cd /d "%GLOBAL_SKILLS%"
git add -A
git diff --cached --quiet >nul 2>&1
if %errorlevel%==0 (
    echo.
    echo ✅ No changes to commit
) else (
    git commit -m "Sync skills from project: %date% %time%"
    echo.
    echo ✅ Changes committed
)

echo.
echo 🎉 Sync complete!
