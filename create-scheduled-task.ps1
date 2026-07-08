# 创建 Sync-Skills-Upstream 计划任务
# 每周一上午 9:00 自动从上游同步技能

$TaskName = "Sync-Skills-Upstream"
$Action = New-ScheduledTaskAction -Execute "C:\Program Files\Git\bin\bash.exe" -Argument '-c "cd /c/Users/Administrator/.claude/skills && bash sync-from-upstream.sh --push"'
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:00"
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Force

Write-Host "✅ 计划任务 '$TaskName' 已创建！"
Write-Host "   触发器: 每周一 09:00"
Write-Host "   操作: 自动同步上游 skills 并推送到 GitHub"
