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

  [ValidateSet('ProgressThenNoProgress', 'ConsecutiveFailures')]
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

function Test-TimeLimit {
  param([datetime]$StartedAt, [int]$Minutes)
  return ((Get-Date) - $StartedAt).TotalMinutes -ge $Minutes
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
    "- Started: $($StartedAt.ToString('o'))",
    "- Finished: $($finishedAt.ToString('o'))"
  )
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
    @('failure', 'failure', 'progress')
  }

  for ($index = 0; $index -lt $outcomes.Count; $index += 1) {
    $iteration = $index + 1
    $outcome = $outcomes[$index]
    if ($outcome -eq 'progress') {
      $successes += 1
      $failures = 0
      $noProgress = 0
    } elseif ($outcome -eq 'failure') {
      $failures += 1
      $noProgress = 0
    } else {
      $noProgress += 1
      $failures = 0
    }
    $record = [ordered]@{ iteration = $iteration; outcome = $outcome; at = (Get-Date).ToString('o') }
    $records.Add($record)
    $record | ConvertTo-Json | Add-Content -LiteralPath (Join-Path $Directory 'run.jsonl') -Encoding utf8

    if ($failures -ge $FailureLimit) { $reason = 'consecutive_failure_limit'; break }
    if ($noProgress -ge $NoProgressLimit) { $reason = 'no_progress_limit'; break }
  }

  $expected = if ($Scenario -eq 'ProgressThenNoProgress') { 'no_progress_limit' } else { 'consecutive_failure_limit' }
  if ($reason -ne $expected) { throw "Smoke scenario $Scenario ended with $reason instead of $expected" }
  Write-FinalReport -RunDirectory $Directory -RunId $RunId -Branch 'autonomy/smoke' -Reason $reason `
    -StartedAt $startedAt -Iterations $records.Count -SuccessfulCommits $successes -Failures $failures `
    -NoProgress $noProgress -Records $records.ToArray() -Smoke $true
  Write-Host "Smoke scenario $Scenario passed with termination reason: $reason"
}

$repoRoot = (Get-GitOutput -Arguments @('rev-parse', '--show-toplevel')).Trim()
Set-Location -LiteralPath $repoRoot
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
$script:RunDeadline = $startedAt.AddMinutes($MaxMinutes)
$records = [System.Collections.Generic.List[object]]::new()
$consecutiveFailures = 0
$totalFailures = 0
$consecutiveNoProgress = 0
$successfulCommits = 0
$terminationReason = 'max_iterations'
$completedIterations = 0

for ($iteration = 1; $iteration -le $MaxIterations; $iteration += 1) {
  if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { $terminationReason = 'time_limit'; break }
  $iterationDirectory = Join-Path $runDirectory ('iteration-{0:d2}' -f $iteration)
  New-Item -ItemType Directory -Path $iterationDirectory -Force | Out-Null
  $iterationStarted = Get-Date
  $outcome = 'failure'
  $commit = $null
  $errorMessage = $null

  try {
    if ((Get-GitOutput -Arguments @('status', '--porcelain')) -ne '') { throw 'Iteration started with a dirty working tree.' }
    if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { throw 'Time limit reached before analysis.' }

    $analysisPrompt = @"
You are the analysis stage of autonomous quality iteration $iteration.
Read AGENTS.md and AUTONOMOUS_GOAL.md. Inspect the repository and identify exactly one small, valuable,
testable quality improvement. Do not edit any repository file and do not commit. Explain the evidence,
scope, intended test, implementation approach, risks, and stop conditions. If no safe improvement exists,
end with NO_SAFE_IMPROVEMENT.
"@
    $analysisMessage = Join-Path $iterationDirectory 'analysis.md'
    Invoke-NativeLogged -Command 'codex' -Arguments @(
      'exec', '--sandbox', 'workspace-write', '-c', 'approval_policy="never"', '--cd', $repoRoot,
      '--output-last-message', $analysisMessage, $analysisPrompt
    ) -LogPath (Join-Path $iterationDirectory 'analysis.log') | Out-Null
    if ((Get-GitOutput -Arguments @('status', '--porcelain')) -ne '') { throw 'Analysis stage modified repository files.' }
    if ((Get-Content -LiteralPath $analysisMessage -Raw) -match 'NO_SAFE_IMPROVEMENT') {
      $outcome = 'no-progress'
    } else {
      if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { throw 'Time limit reached before test stage.' }
      $testPrompt = @"
You are the test stage of autonomous quality iteration $iteration.
Read AGENTS.md, AUTONOMOUS_GOAL.md, and this analysis file: $analysisMessage
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
Read AGENTS.md, AUTONOMOUS_GOAL.md, and this analysis file: $analysisMessage
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
        $reviewText = $reviewResult.Stdout
        if ($reviewText -match 'REVIEW_CHANGES_REQUESTED') {
          if (Test-TimeLimit -StartedAt $startedAt -Minutes $MaxMinutes) { throw 'Time limit reached before correction.' }
          $correctionPrompt = @"
You are the correction stage of autonomous quality iteration $iteration.
Read AGENTS.md, AUTONOMOUS_GOAL.md, and the independent review at:
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
          if ($finalReview.Stdout -notmatch 'REVIEW_PASS') { throw 'Independent review still requests changes after correction.' }
        } elseif ($reviewText -notmatch 'REVIEW_PASS') {
          throw 'Independent review did not return a recognized marker.'
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
    $consecutiveFailures += 1
    $totalFailures += 1
    $consecutiveNoProgress = 0
    $outcome = 'failure'
  }

  $completedIterations = $iteration
  $record = [ordered]@{
    iteration = $iteration
    startedAt = $iterationStarted.ToString('o')
    finishedAt = (Get-Date).ToString('o')
    outcome = $outcome
    commit = $commit
    error = $errorMessage
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
  -Failures $totalFailures -NoProgress $consecutiveNoProgress -Records $records.ToArray() -Smoke $false

Write-Host "Autonomous LOOP finished: $terminationReason"
Write-Host "Report: $(Join-Path $runDirectory 'final-report.md')"
if ($terminationReason -eq 'consecutive_failure_limit') { exit 2 }
