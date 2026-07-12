\# RUNNER CHECKLIST



\## 실행하지 말 것

\- 5h limit가 10% 이하면 자율 Runner를 실행하지 않는다.

\- 이때는 로컬 확인만 수행한다: `git status`, `node -v`, `npm run verify`



\## 실행 전 확인

\- 현재 브랜치가 `autonomy/...` 인지 확인

\- 작업 트리가 clean인지 확인

\- `node -v` 확인

\- `npm run verify` PASS 확인



\## 실행

\- 리셋 직후 아래 순서로 실행한다.



```powershell

git branch --show-current

git status --short

node -v

npm run verify

.\\scripts\\run-autonomous-loop.ps1

모델과 reasoning 수준을 명시하려면 다음과 같이 실행한다.

```powershell
pwsh -NoProfile -File .\scripts\run-autonomous-loop.ps1 `
  -Model gpt-5.6-terra `
  -ReasoningEffort medium `
  -MaxIterations 10 `
  -MaxMinutes 120 `
  -MaxConsecutiveFailures 3 `
  -MaxNoProgress 2 `
  -GoalPath .\AUTONOMOUS_GOAL.md
```

