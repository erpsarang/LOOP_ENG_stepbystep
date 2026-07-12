[CmdletBinding()]
param(
  [ValidateRange(1, 10)]
  [int]$MaxIterations = 10,

  [ValidateRange(1, 120)]
  [int]$MaxMinutes = 120,

  [ValidateRange(1, 10)]
  [int]$MaxConsecutiveFailures = 3,

  [ValidateRange(1, 10)]
  [int]$MaxNoProgress = 2,

  [string]$GoalPath = 'AUTONOMOUS_GOAL.md',

  [switch]$SmokeTest,

  [ValidateSet('ProgressThenNoProgress', 'ConsecutiveFailures', 'Encoding')]
  [string]$SmokeScenario = 'ProgressThenNoProgress'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:RunDeadline = $null

function Invoke-NativeLogged {
  param(
    [Parameter(Mandatory)] [string]$Command,
    [Parameter(Mandatory)] [string[]]$Arguments,
    [Parameter(Mandatory)] [string]$LogPath,
    [switch]$AllowFailure
  )

  $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $Command
  $startInfo.WorkingDirectory = (Get-Location).Path
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
  $startInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8
  $startInfo.CreateNoWindow = $true
  foreach ($argument in $Arguments) { $startInfo.ArgumentList.Add($argument) }

  $process = [System.Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  if (-not $process.Start()) { throw "Could not start command: $Command" }
  $stdoutTask = $process.StandardOutput.ReadToEndAsync()
  $stderrTask = $process.StandardError.ReadToEndAsync()
  $remainingMilliseconds = if ($null -ne $script:RunDeadline) {
    [Math]::Max(1, [int](($script:RunDeadline - (Get-Date)).TotalMilliseconds))
  } else {
    [int]::MaxValue
  }
  if (-not $process.WaitForExit($remainingMilliseconds)) {
    $process.Kill($true)
    $process.WaitForExit()
    throw "Command exceeded the autonomous run deadline: $Command"
  }
  $stdout = $stdoutTask.GetAwaiter().GetResult()
  $stderr = $stderrTask.GetAwaiter().GetResult()
  $output = @(($stdout, $stderr) | Where-Object { $_ } | ForEach-Object { $_ -split '\r?\n' } | Where-Object { $_ -ne '' })
  $exitCode = $process.ExitCode
  $process.Dispose()
  $output | Set-Content -LiteralPath $LogPath -Encoding utf8
  if ($output.Count -gt 0) { $output | ForEach-Object { Write-Host $_ } }
  if (-not $AllowFailure -and $exitCode -ne 0) {
    throw "Command failed with exit code ${exitCode}: $Command $($Arguments -join ' ')"
  }
  return [pscustomobject]@{ ExitCode = $exitCode; Output = $output; Stdout = $stdout; Stderr = $stderr }
}

function Assert-AllowedChanges {
  $paths = @(
    & git diff --name-only
    & git diff --cached --name-only
    & git ls-files --others --exclude-standard
  ) | Where-Object { $_ } | Sort-Object -Unique
  if ($LASTEXITCODE -ne 0) { throw 'Could not enumerate changed paths.' }

  $allowed = @(
    '^app\.js$', '^test\.js$', '^verify\.js$', '^README\.md$', '^HANDOFF\.md$',
    '^package\.json$', '^fixtures/'
  )
  foreach ($path in $paths) {
    $normalized = $path.Replace('\', '/')
    if (-not ($allowed | Where-Object { $normalized -match $_ })) {
      throw "Autonomous iteration changed a path outside the goal allowlist: $normalized"
    }
  }
}

function Get-GitOutput {
  param([Parameter(Mandatory)] [string[]]$Arguments)
  $output = @(& git @Arguments 2>&1)
  if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)" }
  return ($output -join "`n").Trim()
}

function Get-WorkingTreeFingerprint {
  $parts = [System.Collections.Generic.List[string]]::new()
  $parts.Add((Get-GitOutput -Arguments @('diff', '--binary')))
  $parts.Add((Get-GitOutput -Arguments @('diff', '--cached', '--binary')))
  $untracked = @(& git ls-files --others --exclude-standard)
  if ($LASTEXITCODE -ne 0) { throw 'Could not fingerprint untracked files.' }
  foreach ($path in ($untracked | Sort-Object)) {
    $parts.Add("$path`t$((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash)")
  }
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($parts -join "`n"))
  return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData($bytes))
}

function Test-TimeLimit {
  param([datetime]$StartedAt, [int]$Minutes)
  return ((Get-Date) - $StartedAt).TotalMinutes -ge $Minutes
}

function Test-SupportedAutonomousNodeVersion {
  param([Parameter(Mandatory)] [string]$NodeVersion)

  if ($NodeVersion -notmatch '^v(?<Major>\d+)\.(?<Minor>\d+)\.(?<Patch>\d+)$') {
    return $false
  }

  return ([int]$Matches.Major -in @(22, 24))
}

function Restore-IterationCheckpoint {
  param(
    [Parameter(Mandatory)] [string]$Checkpoint,
    [Parameter(Mandatory)] [string]$RepositoryRoot,
    [Parameter(Mandatory)] [string]$LogPath
  )

  $messages = [System.Collections.Generic.List[string]]::new()
  try {
    $currentHead = Get-GitOutput -Arguments @('rev-parse', 'HEAD')
    if ($currentHead -ne $Checkpoint) {
      & git merge-base --is-ancestor $Checkpoint $currentHead
      if ($LASTEXITCODE -ne 0) { throw 'Current HEAD is not a descendant of the iteration checkpoint.' }
      & git reset --mixed $Checkpoint 2>&1 | ForEach-Object { $messages.Add([string]$_) }
      if ($LASTEXITCODE -ne 0) { throw "git reset --mixed failed with exit code $LASTEXITCODE" }
      $messages.Add("Moved HEAD from $currentHead back to checkpoint $Checkpoint")
    }
    & git restore --source=$Checkpoint --staged --worktree -- . 2>&1 | ForEach-Object { $messages.Add([string]$_) }
    if ($LASTEXITCODE -ne 0) { throw "git restore failed with exit code $LASTEXITCODE" }

    $untracked = @(& git ls-files --others --exclude-standard)
    if ($LASTEXITCODE -ne 0) { throw 'Could not enumerate untracked files during recovery.' }
    $rootPrefix = $RepositoryRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    foreach ($relativePath in $untracked) {
      if (-not $relativePath) { continue }
      $candidate = [System.IO.Path]::GetFullPath((Join-Path $RepositoryRoot $relativePath))
      if (-not $candidate.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Recovery refused a path outside the repository: $relativePath"
      }
      Remove-Item -LiteralPath $candidate -Force
      $messages.Add("Removed untracked file: $relativePath")
    }

    $remaining = Get-GitOutput -Arguments @('status', '--porcelain')
    if ($remaining -ne '') { throw "Recovery left a dirty working tree: $remaining" }
    if ((Get-GitOutput -Arguments @('rev-parse', 'HEAD')) -ne $Checkpoint) {
      throw 'Recovery did not restore HEAD to the iteration checkpoint.'
    }
    $messages.Add("Restored iteration checkpoint: $Checkpoint")
    $messages | Set-Content -LiteralPath $LogPath -Encoding utf8
    return $true
  } catch {
    $messages.Add("Recovery failed: $($_.Exception.Message)")
    $messages | Set-Content -LiteralPath $LogPath -Encoding utf8
    return $false
  }
}

function Get-ReviewDecision {
  param(
    [Parameter(Mandatory)] [string]$ReviewLog,
    [Parameter(Mandatory)] [string]$DecisionPath,
    [Parameter(Mandatory)] [string]$DecisionLog,
    [Parameter(Mandatory)] [string]$RepositoryRoot
  )

  $prompt = @"
Read AGENTS.md and the independent codex review at: $ReviewLog
Do not edit files. Classify the review outcome only. End with exactly REVIEW_PASS when it contains no
actionable issue, or REVIEW_CHANGES_REQUESTED when it requests any correction.
"@
  $beforeFingerprint = Get-WorkingTreeFingerprint
  Invoke-NativeLogged -Command 'codex' -Arguments @(
    'exec', '--sandbox', 'workspace-write', '-c', 'approval_policy="never"', '--cd', $RepositoryRoot,
    '--output-last-message', $DecisionPath, $prompt
  ) -LogPath $DecisionLog | Out-Null
  if ((Get-WorkingTreeFingerprint) -ne $beforeFingerprint) {
    throw 'Review classifier modified repository files.'
  }
  $decision = Get-Content -LiteralPath $DecisionPath -Raw
  $finalMarker = (($decision -split '\r?\n' | Where-Object { $_.Trim() } | Select-Object -Last 1) -join '').Trim()
  if ($finalMarker -eq 'REVIEW_CHANGES_REQUESTED') { return 'changes-requested' }
  if ($finalMarker -eq 'REVIEW_PASS') { return 'pass' }
  throw 'Review classifier did not return a recognized marker.'
}

function Write-FinalReport {
  param(
    [string]$RunDirectory,
    [string]$RunId,
    [string]$Branch,
    [string]$Reason,
    [datetime]$StartedAt,
    [int]$Iterations,
    [int]$SuccessfulCommits,
    [int]$Failures,
    [int]$NoProgress,
    [string]$StartCheckpoint,
    [string[]]$SkippedTasks,
    [object[]]$Records,
    [bool]$Smoke
  )

  $finishedAt = Get-Date
  $summary = [ordered]@{
    runId = $RunId
    smokeTest = $Smoke
    branch = $Branch
    startedAt = $StartedAt.ToString('o')
    finishedAt = $finishedAt.ToString('o')
    elapsedMinutes = [Math]::Round(($finishedAt - $StartedAt).TotalMinutes, 3)
    terminationReason = $Reason
    iterations = $Iterations
    successfulCommits = $SuccessfulCommits
    failures = $Failures
    consecutiveNoProgress = $NoProgress
    startCheckpoint = $StartCheckpoint
    skippedTasks = $SkippedTasks
    records = $Records
  }
  $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $RunDirectory 'final-report.json') -Encoding utf8

  $lines = @(
    '# Autonomous LOOP Final Report',
    '',
    "- Run: $RunId",
    "- Smoke test: $Smoke",
    "- Branch: $Branch",
    "- Termination: $Reason",
    "- Iterations: $Iterations",
    "- Successful commits: $SuccessfulCommits",
    "- Failures: $Failures",
    "- Consecutive no-progress iterations: $NoProgress",
    "- Start checkpoint: $StartCheckpoint",
    "- Skipped tasks: $($SkippedTasks.Count)",
    "- Started: $($StartedAt.ToString('o'))",
    "- Finished: $($finishedAt.ToString('o'))"
  )
  $failedRecords = @($Records | Where-Object { $_.PSObject.Properties['error'] -and $_.error })
  if ($failedRecords.Count -gt 0) {
    $lines += @('', '## Failures and recovery')
    foreach ($record in $failedRecords) {
      $lines += "- Iteration $($record.iteration): $($record.error) | recovered=$($record.recovered) | skipped=$($record.skippedTask)"
    }
  }
  if ($SkippedTasks.Count -gt 0) {
    $lines += @('', '## Skipped tasks')
    $lines += @($SkippedTasks | ForEach-Object { "- $_" })
  }
  $lines | Set-Content -LiteralPath (Join-Path $RunDirectory 'final-report.md') -Encoding utf8
}

function Invoke-SmokeRun {
  param(
    [string]$Scenario,
    [string]$Directory,
    [string]$RunId,
    [int]$FailureLimit,
    [int]$NoProgressLimit
  )

  $startedAt = Get-Date
  $records = [System.Collections.Generic.List[object]]::new()
  $failures = 0
  $noProgress = 0
  $successes = 0
  $reason = 'max_iterations'
  $outcomes = if ($Scenario -eq 'ProgressThenNoProgress') {
    @('progress', 'no-progress', 'no-progress', 'progress')
  } else {
    @('recovered-failure', 'progress', 'recovery-failure', 'recovery-failure')
  }

  for ($index = 0; $index -lt $outcomes.Count; $index += 1) {
    $iteration = $index + 1
    $outcome = $outcomes[$index]
    if ($outcome -eq 'progress') {
      $successes += 1
      $failures = 0
      $noProgress = 0
    } elseif ($outcome -eq 'recovery-failure') {
      $failures += 1
      $noProgress = 0
    } elseif ($outcome -eq 'recovered-failure') {
      $failures = 0
      $noProgress = 0
    } else {
      $noProgress += 1
      $failures = 0
    }
    $record = [ordered]@{
      iteration = $iteration
      outcome = $outcome
      at = (Get-Date).ToString('o')
      error = if ($outcome -like '*failure') { "simulated $outcome" } else { $null }
      recovered = if ($outcome -eq 'recovered-failure') { $true } elseif ($outcome -eq 'recovery-failure') { $false } else { $null }
      skippedTask = if ($outcome -eq 'recovered-failure') { 'smoke-recovered-task' } else { $null }
    }
    $records.Add($record)
    $record | ConvertTo-Json | Add-Content -LiteralPath (Join-Path $Directory 'run.jsonl') -Encoding utf8

    if ($failures -ge $FailureLimit) { $reason = 'consecutive_failure_limit'; break }
    if ($noProgress -ge $NoProgressLimit) { $reason = 'no_progress_limit'; break }
  }

  $expected = if ($Scenario -eq 'ProgressThenNoProgress') { 'no_progress_limit' } else { 'consecutive_failure_limit' }
  if ($reason -ne $expected) { throw "Smoke scenario $Scenario ended with $reason instead of $expected" }
  Write-FinalReport -RunDirectory $Directory -RunId $RunId -Branch 'autonomy/smoke' -Reason $reason `
    -StartedAt $startedAt -Iterations $records.Count -SuccessfulCommits $successes -Failures $failures `
    -NoProgress $noProgress -StartCheckpoint 'smoke-checkpoint' -SkippedTasks @('smoke-recovered-task') `
    -Records $records.ToArray() -Smoke $true
  Write-Host "Smoke scenario $Scenario passed with termination reason: $reason"
}

function Invoke-EncodingSmokeTest {
  $temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("autonomous-runner-encoding-{0}" -f [System.Guid]::NewGuid())
  $logPath = Join-Path $temporaryDirectory 'encoding.log'
  $stdoutMessage = 'STDOUT 한글 테스트'
  $stderrMessage = 'STDERR 한글 테스트'

  try {
    New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
    $result = Invoke-NativeLogged -Command 'node' -Arguments @(
      '-e', "console.log('$stdoutMessage'); console.error('$stderrMessage');"
    ) -LogPath $logPath
    if ($result.ExitCode -ne 0) { throw "Encoding smoke command failed with exit code $($result.ExitCode)." }
    if (-not $result.Stdout.Contains($stdoutMessage)) { throw 'Encoding smoke stdout did not preserve the expected Korean message.' }
    if (-not $result.Stderr.Contains($stderrMessage)) { throw 'Encoding smoke stderr did not preserve the expected Korean message.' }
    $log = Get-Content -LiteralPath $logPath -Raw -Encoding utf8
    if (-not $log.Contains($stdoutMessage) -or -not $log.Contains($stderrMessage)) {
      throw 'Encoding smoke log did not preserve the expected Korean messages.'
    }
    Write-Host 'Smoke scenario Encoding passed with UTF-8 stdout and stderr.'
  } finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
      if ((Get-Item -LiteralPath $temporaryDirectory -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        throw 'Encoding smoke temporary directory must not be a reparse point.'
      }
      Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
  }
}

$repoRoot = (Get-GitOutput -Arguments @('rev-parse', '--show-toplevel')).Trim()
Set-Location -LiteralPath $repoRoot
if ($SmokeTest -and $SmokeScenario -eq 'Encoding') {
  $script:RunDeadline = (Get-Date).AddMinutes(1)
  Invoke-EncodingSmokeTest
  exit 0
}
$artifactRoot = Join-Path $repoRoot '.autonomous-loop'
if (Test-Path -LiteralPath $artifactRoot) {
  if ((Get-Item -LiteralPath $artifactRoot -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    throw 'Autonomous artifact root must not be a reparse point.'
  }
} else {
  New-Item -ItemType Directory -Path $artifactRoot | Out-Null
}
$resolvedRunRoot = Join-Path $artifactRoot 'runs'
if (Test-Path -LiteralPath $resolvedRunRoot) {
  if ((Get-Item -LiteralPath $resolvedRunRoot -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    throw 'Autonomous run directory must not be a reparse point.'
  }
} else {
  New-Item -ItemType Directory -Path $resolvedRunRoot | Out-Null
}
$runId = if ($SmokeTest) {
  "smoke-$($SmokeScenario.ToLowerInvariant())-$(Get-Date -Format 'yyyyMMdd-HHmmssfff')"
} else {
  "run-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}
$runDirectory = Join-Path $resolvedRunRoot $runId
New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null

if ($SmokeTest) {
  $script:RunDeadline = (Get-Date).AddMinutes(1)
  Invoke-NativeLogged -Command $env:ComSpec -Arguments @('/d', '/s', '/c', 'echo runner-smoke') `
    -LogPath (Join-Path $runDirectory 'native-command.log') | Out-Null
  $failureLimit = if ($SmokeScenario -eq 'ConsecutiveFailures') { 2 } else { $MaxConsecutiveFailures }
  Invoke-SmokeRun -Scenario $SmokeScenario -Directory $runDirectory -RunId $runId `
    -FailureLimit $failureLimit -NoProgressLimit $MaxNoProgress
  exit 0
}

$branch = Get-GitOutput -Arguments @('branch', '--show-current')
if ($branch -notlike 'autonomy/*') { throw "Autonomous runner requires an autonomy/* branch; current branch is '$branch'." }
if ((Get-GitOutput -Arguments @('status', '--porcelain')) -ne '') { throw 'Autonomous runner requires a clean working tree at start.' }

$goalFullPath = Join-Path $repoRoot $GoalPath
if (-not (Test-Path -LiteralPath $goalFullPath -PathType Leaf)) { throw "Goal file not found: $goalFullPath" }
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) { throw 'codex CLI is not available.' }
if (-not $env:ComSpec -or -not (Test-Path -LiteralPath $env:ComSpec)) { throw 'Windows command processor is not available.' }
$startedAt = Get-Date
$startCheckpoint = Get-GitOutput -Arguments @('rev-parse', 'HEAD')
$startCheckpoint | Set-Content -LiteralPath (Join-Path $runDirectory 'start-checkpoint.txt') -Encoding utf8
$requiredNodeVersion = 'v22.x or v24.x'
$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
$actualNodeVersion = if ($nodeCommand) { ((& node --version 2>&1) -join '').Trim() } else { 'not found' }
if (-not $nodeCommand -or $LASTEXITCODE -ne 0 -or -not (Test-SupportedAutonomousNodeVersion -NodeVersion $actualNodeVersion)) {
  $nodeError = "Autonomous runner requires Node.js $requiredNodeVersion LTS locally; current version is '$actualNodeVersion'."
  $record = [ordered]@{ iteration = 0; error = $nodeError; recovered = $null; skippedTask = $null }
  Write-FinalReport -RunDirectory $runDirectory -RunId $runId -Branch $branch -Reason 'node_version_mismatch' `
    -StartedAt $startedAt -Iterations 0 -SuccessfulCommits 0 -Failures 1 -NoProgress 0 `
    -StartCheckpoint $startCheckpoint -SkippedTasks @() -Records @($record) -Smoke $false
  [Console]::Error.WriteLine($nodeError)
  exit 3
}

$script:RunDeadline = $startedAt.AddMinutes($MaxMinutes)
$records = [System.Collections.Generic.List[object]]::new()
$consecutiveFailures = 0
$totalFailures = 0
$consecutiveNoProgress = 0
$successfulCommits = 0
$terminationReason = 'max_iterations'
$completedIterations = 0
$skippedTasks = [System.Collections.Generic.List[string]]::new()

for ($iteration = 1; $iteration -le $MaxIterations; $iteration += 1) {
  if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { $terminationReason = 'time_limit'; break }
  $iterationDirectory = Join-Path $runDirectory ('iteration-{0:d2}' -f $iteration)
  New-Item -ItemType Directory -Path $iterationDirectory -Force | Out-Null
  $iterationStarted = Get-Date
  $outcome = 'failure'
  $commit = $null
  $errorMessage = $null
  $recovered = $null
  $iterationCheckpoint = Get-GitOutput -Arguments @('rev-parse', 'HEAD')
  $iterationCheckpoint | Set-Content -LiteralPath (Join-Path $iterationDirectory 'checkpoint.txt') -Encoding utf8
  $taskSummary = $null

  try {
    if ((Get-GitOutput -Arguments @('status', '--porcelain')) -ne '') { throw 'Iteration started with a dirty working tree.' }
    if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { throw 'Time limit reached before analysis.' }

    $analysisPrompt = @"
You are the analysis stage of autonomous quality iteration $iteration.
Read AGENTS.md and the goal file at: $goalFullPath
Inspect the repository and identify exactly one small, valuable,
testable quality improvement. Do not edit any repository file and do not commit. Explain the evidence,
scope, intended test, implementation approach, risks, and stop conditions. If no safe improvement exists,
end with NO_SAFE_IMPROVEMENT.
The first nonempty line must be `TASK: <specific concise improvement>`.
Do not repeat any previously failed task listed here: $($skippedTasks -join ' | ')
"@
    $analysisMessage = Join-Path $iterationDirectory 'analysis.md'
    Invoke-NativeLogged -Command 'codex' -Arguments @(
      'exec', '--sandbox', 'workspace-write', '-c', 'approval_policy="never"', '--cd', $repoRoot,
      '--output-last-message', $analysisMessage, $analysisPrompt
    ) -LogPath (Join-Path $iterationDirectory 'analysis.log') | Out-Null
    if ((Get-GitOutput -Arguments @('status', '--porcelain')) -ne '') { throw 'Analysis stage modified repository files.' }
    $analysisText = Get-Content -LiteralPath $analysisMessage -Raw
    $taskLine = @($analysisText -split '\r?\n' | Where-Object { $_ -match '^TASK:\s*\S' } | Select-Object -First 1)
    if ($taskLine.Count -gt 0) {
      $taskSummary = ($taskLine[0] -replace '^TASK:\s*', '').Trim()
    } else {
      $taskSummary = (($analysisText -replace '\s+', ' ').Trim())
      if ($taskSummary.Length -gt 500) { $taskSummary = $taskSummary.Substring(0, 500) }
    }
    if ($analysisText -match 'NO_SAFE_IMPROVEMENT') {
      $outcome = 'no-progress'
    } else {
      if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { throw 'Time limit reached before test stage.' }
      $testPrompt = @"
You are the test stage of autonomous quality iteration $iteration.
Read AGENTS.md, the goal file at $goalFullPath, and this analysis file: $analysisMessage
Add only the focused regression or quality test needed for the selected improvement. Do not implement the
production fix, do not weaken existing tests, do not edit runner control files, and do not commit.
"@
      Invoke-NativeLogged -Command 'codex' -Arguments @(
        'exec', '--sandbox', 'workspace-write', '-c', 'approval_policy="never"', '--cd', $repoRoot, $testPrompt
      ) -LogPath (Join-Path $iterationDirectory 'test-agent.log') | Out-Null
      Invoke-NativeLogged -Command $env:ComSpec -Arguments @('/d', '/s', '/c', 'npm test') -LogPath (Join-Path $iterationDirectory 'test-before-implementation.log') -AllowFailure | Out-Null

      if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { throw 'Time limit reached before implementation.' }
      $implementationPrompt = @"
You are the implementation stage of autonomous quality iteration $iteration.
Read AGENTS.md, the goal file at $goalFullPath, and this analysis file: $analysisMessage
Inspect the current uncommitted test changes and implement the smallest production or documentation change
that satisfies the selected improvement. Preserve public behavior, do not weaken tests, do not edit runner
control files, and do not commit.
"@
      Invoke-NativeLogged -Command 'codex' -Arguments @(
        'exec', '--sandbox', 'workspace-write', '-c', 'approval_policy="never"', '--cd', $repoRoot, $implementationPrompt
      ) -LogPath (Join-Path $iterationDirectory 'implementation.log') | Out-Null

      $changed = Get-GitOutput -Arguments @('status', '--porcelain')
      if ($changed -eq '') {
        $outcome = 'no-progress'
      } else {
        Assert-AllowedChanges
        if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { throw 'Time limit reached before verify.' }
        Invoke-NativeLogged -Command $env:ComSpec -Arguments @('/d', '/s', '/c', 'npm run verify') -LogPath (Join-Path $iterationDirectory 'verify-before-review.log') | Out-Null

        $reviewResult = Invoke-NativeLogged -Command 'codex' -Arguments @(
          'review', '-c', 'approval_policy="never"', '-c', 'sandbox_mode="workspace-write"', '--uncommitted'
        ) -LogPath (Join-Path $iterationDirectory 'review.log')
        $reviewDecision = Get-ReviewDecision -ReviewLog (Join-Path $iterationDirectory 'review.log') `
          -DecisionPath (Join-Path $iterationDirectory 'review-decision.md') `
          -DecisionLog (Join-Path $iterationDirectory 'review-decision.log') -RepositoryRoot $repoRoot
        if ($reviewDecision -eq 'changes-requested') {
          if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { throw 'Time limit reached before correction.' }
          $correctionPrompt = @"
You are the correction stage of autonomous quality iteration $iteration.
Read AGENTS.md, the goal file at $goalFullPath, and the independent review at:
$(Join-Path $iterationDirectory 'review.log')
Apply only the concrete review fixes. Do not broaden scope, weaken tests, edit runner control files, or commit.
"@
          Invoke-NativeLogged -Command 'codex' -Arguments @(
            'exec', '--sandbox', 'workspace-write', '-c', 'approval_policy="never"', '--cd', $repoRoot, $correctionPrompt
          ) -LogPath (Join-Path $iterationDirectory 'correction.log') | Out-Null
          Assert-AllowedChanges
          Invoke-NativeLogged -Command $env:ComSpec -Arguments @('/d', '/s', '/c', 'npm run verify') -LogPath (Join-Path $iterationDirectory 'verify-after-correction.log') | Out-Null

          $finalReview = Invoke-NativeLogged -Command 'codex' -Arguments @(
            'review', '-c', 'approval_policy="never"', '-c', 'sandbox_mode="workspace-write"', '--uncommitted'
          ) -LogPath (Join-Path $iterationDirectory 'review-after-correction.log')
          $finalDecision = Get-ReviewDecision -ReviewLog (Join-Path $iterationDirectory 'review-after-correction.log') `
            -DecisionPath (Join-Path $iterationDirectory 'review-after-correction-decision.md') `
            -DecisionLog (Join-Path $iterationDirectory 'review-after-correction-decision.log') -RepositoryRoot $repoRoot
          if ($finalDecision -ne 'pass') { throw 'Independent review still requests changes after correction.' }
        }

        Assert-AllowedChanges
        Invoke-NativeLogged -Command 'git' -Arguments @('diff', '--check') -LogPath (Join-Path $iterationDirectory 'diff-check.log') | Out-Null
        Invoke-NativeLogged -Command $env:ComSpec -Arguments @('/d', '/s', '/c', 'npm run verify') -LogPath (Join-Path $iterationDirectory 'verify-final.log') | Out-Null
        Invoke-NativeLogged -Command 'git' -Arguments @('add', '--all') -LogPath (Join-Path $iterationDirectory 'git-add.log') | Out-Null
        Invoke-NativeLogged -Command 'git' -Arguments @('commit', '-m', "chore: autonomous quality loop $iteration") -LogPath (Join-Path $iterationDirectory 'git-commit.log') | Out-Null
        $commit = Get-GitOutput -Arguments @('rev-parse', '--short', 'HEAD')
        $successfulCommits += 1
        $outcome = 'progress'
      }
    }

    if ($outcome -eq 'progress') {
      $consecutiveFailures = 0
      $consecutiveNoProgress = 0
    } else {
      $consecutiveFailures = 0
      $consecutiveNoProgress += 1
    }
  } catch {
    $errorMessage = $_.Exception.Message
    $errorMessage | Set-Content -LiteralPath (Join-Path $iterationDirectory 'error.txt') -Encoding utf8
    $totalFailures += 1
    $consecutiveNoProgress = 0
    if ($taskSummary) { $skippedTasks.Add($taskSummary) }
    $recovered = Restore-IterationCheckpoint -Checkpoint $iterationCheckpoint -RepositoryRoot $repoRoot `
      -LogPath (Join-Path $iterationDirectory 'recovery.log')
    if ($recovered) {
      $consecutiveFailures = 0
      $outcome = 'recovered-failure'
    } else {
      $consecutiveFailures += 1
      $outcome = 'recovery-failure'
    }
  }

  $completedIterations = $iteration
  $record = [ordered]@{
    iteration = $iteration
    startedAt = $iterationStarted.ToString('o')
    finishedAt = (Get-Date).ToString('o')
    outcome = $outcome
    commit = $commit
    error = $errorMessage
    checkpoint = $iterationCheckpoint
    recovered = $recovered
    skippedTask = $taskSummary
    consecutiveFailures = $consecutiveFailures
    consecutiveNoProgress = $consecutiveNoProgress
  }
  $records.Add($record)
  $record | ConvertTo-Json -Depth 5 | Add-Content -LiteralPath (Join-Path $runDirectory 'run.jsonl') -Encoding utf8

  if ($consecutiveFailures -ge $MaxConsecutiveFailures) { $terminationReason = 'consecutive_failure_limit'; break }
  if ($consecutiveNoProgress -ge $MaxNoProgress) { $terminationReason = 'no_progress_limit'; break }
  if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { $terminationReason = 'time_limit'; break }
}

Write-FinalReport -RunDirectory $runDirectory -RunId $runId -Branch $branch -Reason $terminationReason `
  -StartedAt $startedAt -Iterations $completedIterations -SuccessfulCommits $successfulCommits `
  -Failures $totalFailures -NoProgress $consecutiveNoProgress -StartCheckpoint $startCheckpoint `
  -SkippedTasks $skippedTasks.ToArray() -Records $records.ToArray() -Smoke $false

Write-Host "Autonomous LOOP finished: $terminationReason"
Write-Host "Report: $(Join-Path $runDirectory 'final-report.md')"
if ($terminationReason -eq 'consecutive_failure_limit') { exit 2 }
