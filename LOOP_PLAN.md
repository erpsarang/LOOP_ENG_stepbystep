# Autonomous LOOP Plan

- [x] TODO 1: `--help`를 추가하고 알 수 없는 옵션 및 여러 입력 파일을 친절하게 거부한다.
- [x] TODO 2: 빈 행이 있어도 경고에 실제 CSV 행 번호를 표시한다.
- [x] TODO 3: CLI 인자와 CSV 경계 조건 테스트를 보강한다.
- [x] TODO 4: README를 최종 CLI 동작과 지원 범위에 맞게 정리한다.

각 TODO 완료 조건: `npm test`, `node app.js input.csv`, `node app.js input.csv --json`이 모두 종료 코드 0으로 통과해야 한다.

## 9번째 LOOP — 품질 게이트 자동화

- [x] TODO 5: 다섯 검증 명령과 기대 종료 코드를 판정하는 `verify.js`를 추가한다.
- [x] TODO 6: `package.json`과 README에 `npm run verify`를 연결하고 설명한다.
- [x] TODO 7: `npm run verify`를 실제 실행하고 결과를 로그에 기록한다.

## 10번째 LOOP — 회귀 방지용 테스트 데이터 분리

- [x] TODO 8: 유효 데이터, 잘못된 금액, 누락 컬럼 fixture를 추가한다.
- [x] TODO 9: `test.js`와 `verify.js`의 고정 기대값을 fixture에 연결한다.
- [x] TODO 10: 예제와 fixture의 차이를 문서화하고 품질 게이트 결과를 기록한다.

## 11번째 LOOP — 품질 게이트 신뢰성 강화

- [x] TODO 11: 각 fixture의 목적과 기대 결과를 `fixtures/README.md`에 문서화한다.
- [x] TODO 12: `verify.js`의 fixture 경로와 기대값을 한곳에 모으고 결과에 사용 fixture를 표시한다.
- [x] TODO 13: 테스트·검증 기대값의 일치 여부를 확인하고 품질 게이트 결과를 기록한다.

## 12번째 LOOP — fixture 기대값 중복 제거

- [x] TODO 14: fixture 경로, 목적과 기대 결과를 `fixtures/expectations.js`에 정의한다.
- [x] TODO 15: `test.js`와 `verify.js`가 공통 기대값 모듈을 사용하도록 변경한다.
- [x] TODO 16: fixture 문서 일치성을 확인하고 품질 게이트 결과를 기록한다.

## 13번째 LOOP — 릴리스 점검

- [x] TODO 17: 패키지 메타데이터와 실행 환경 요구사항을 점검한다.
- [x] TODO 18: README의 무설치 실행, 프로젝트 구조, 오류 및 품질 게이트 설명을 보완한다.
- [x] TODO 19: 코드·fixture·문서 일치성을 확인하고 품질 게이트 결과를 기록한다.

## 14번째 LOOP — 최종 인수인계 문서 작성

- [x] TODO 20: 프로젝트 운영과 구조를 설명하는 `HANDOFF.md`를 작성한다.
- [x] TODO 21: 주요 LOOP 이력, 리스크와 다음 개선 후보를 인수인계 문서에 정리한다.
- [x] TODO 22: README에서 인수인계 문서를 연결하고 품질 게이트 결과를 기록한다.

## 15번째 LOOP — 버전 관리 스냅샷

- [x] TODO 23: Git 저장소·CLI·사용자 설정을 확인하고 `.gitignore`를 준비한다.
- [x] TODO 24: 품질 게이트 통과 상태에서 Git 기준점 커밋 가능 여부를 판단한다.
- [x] TODO 25: 커밋 또는 차단 사유와 최종 작업 트리 상태를 기록한다.

## 16번째 LOOP — summary 출력 옵션

- [x] TODO 26: `--summary` 인자와 사람이 읽기 좋은 요약 포맷을 추가한다.
- [x] TODO 27: summary 단위 테스트와 품질 게이트 검증을 추가한다.
- [x] TODO 28: README 사용법과 LOOP 실행 결과를 기록한다.

## 18번째 LOOP — 실험 브랜치 변경사항 커밋

- [x] TODO 29: 실험 브랜치와 작업 트리 상태를 확인하고 품질 게이트를 실행한다.
- [x] TODO 30: summary 기능 변경을 `feat: add summary output option`으로 커밋한다.
- [x] TODO 31: 커밋 결과를 LOOP 문서에 기록하고 별도 문서 커밋으로 남긴다.

## 20번째 LOOP — 검증된 실험 브랜치 master 병합

- [x] TODO 32: 실험 브랜치와 master를 각각 clean 상태에서 검증한다.
- [x] TODO 33: `experiment/summary-option`을 `--no-ff` merge commit으로 master에 병합한다.
- [x] TODO 34: 병합 후 품질 게이트와 그래프를 확인하고 결과를 기록한다.

## 21번째 LOOP — 병합 완료된 실험 브랜치 정리 판단

- [x] TODO 35: 현재 브랜치, 작업 트리와 master 병합 브랜치 목록을 확인한다.
- [x] TODO 36: 커밋 그래프와 품질 게이트로 `experiment/summary-option`의 병합 완료 상태를 검증한다.
- [x] TODO 37: 브랜치 정리 판단과 실제 삭제 전 사용자 확인 필요 여부를 기록한다.

## 22번째 LOOP — 병합 완료된 로컬 브랜치 안전 삭제

- [x] TODO 38: `master`와 clean 작업 트리를 확인하고 `npm run verify`를 실행한다.
- [x] TODO 39: `experiment/summary-option`의 master 병합 상태를 확인하고 `git branch -d experiment/summary-option`으로 안전하게 삭제한다.
- [x] TODO 40: 로컬 브랜치 부재와 GitHub 미푸시 상태를 확인하고 결과를 기록한다.

## 23번째 LOOP — GitHub push 전 최종 로컬 감사

- [x] TODO 41: 프로젝트 경로, `master` 브랜치와 clean 작업 트리를 확인한다.
- [x] TODO 42: 품질 게이트, 삭제 브랜치 부재, 최근 커밋 이력과 로컬 브랜치 목록을 감사한다.
- [x] TODO 43: 원격 저장소 설정과 GitHub 미푸시 상태를 확인하고 향후 push 준비 상태를 기록한다.

## 24번째 LOOP — GitHub push 전 remote 연결 준비

- [x] TODO 44: `master`, clean 작업 트리와 품질 게이트 통과 상태를 확인한다.
- [x] TODO 45: 기존 remote 부재를 확인하고 지정된 GitHub 저장소를 `origin`으로 추가한다.
- [x] TODO 46: 최종 origin URL과 미푸시 상태를 확인하고 다음 LOOP의 push 가능 여부를 기록한다.

## 25번째 LOOP — GitHub 최초 push

- [x] TODO 47: `master`, clean 작업 트리, 품질 게이트와 origin URL을 확인한다.
- [x] TODO 48: 원격 저장소에 기존 브랜치가 없음을 확인하고 force push 금지 상태에서 최초 push를 준비한다.
- [x] TODO 49: `git push -u origin master`를 실행하고 원격 master 및 upstream 설정을 확인한다.
- [x] TODO 50: push 완료 결과를 문서 커밋으로 기록하고 일반 `git push`로 원격에 반영한다.

## 26번째 LOOP — GitHub 최초 push 이후 원격 동기화 감사

- [x] TODO 51: `master`, clean 작업 트리, 품질 게이트, origin URL과 upstream 설정을 확인한다.
- [x] TODO 52: 문서 수정 전 HEAD, `origin/master`, 원격 master 해시가 일치하는지 감사한다.
- [x] TODO 53: 동기화 감사 결과를 문서 커밋으로 기록하고 일반 push로 원격에 반영한다.

## 27번째 LOOP — 최근 커밋 요약 및 프로젝트 체크포인트 문서화

- [x] TODO 54: `master`, clean 작업 트리, 품질 게이트와 `origin/master` upstream 상태를 확인한다.
- [x] TODO 55: 최근 15개 커밋을 검토해 프로젝트 생성부터 원격 동기화 감사까지 완료 범위를 요약한다.
- [x] TODO 56: 안정 체크포인트와 다음 후보 작업을 기록하고 일반 push로 GitHub에 반영한다.

## 28번째 LOOP — 다음 실험 기능 선정 및 브랜치 준비

- [x] TODO 57: clean `master`, 품질 게이트, remote/upstream과 대상 브랜치 부재를 확인한다.
- [x] TODO 58: 후보를 검토해 CSV 출력 기능을 작고 독립적이며 검증 가능한 다음 실험으로 선정한다.
- [x] TODO 59: `master`에서 `experiment/csv-output`을 생성하고 소스 변경 없이 준비 결과를 기록한다.

## 29번째 LOOP — CSV 출력 기능 설계 및 수용 기준 정의

- [x] TODO 60: 실험 브랜치의 clean 상태, 품질 게이트와 upstream을 확인하고 CLI·테스트·검증 구조를 조사한다.
- [x] TODO 61: `--csv` 출력 스키마, 다른 출력 모드와의 충돌 규칙, 이스케이프 및 빈 입력 동작을 설계한다.
- [x] TODO 62: 회귀 방지와 fixture 기반 검증을 포함한 수용 기준 및 다음 LOOP 구현 범위를 기록한다.

## 30번째 LOOP — CSV 출력 기능 구현

- [x] TODO 63: clean 실험 브랜치와 구현 전 7개 품질 게이트 통과 상태를 확인한다.
- [x] TODO 64: `--csv`, CSV 필드 이스케이프, 헤더와 단일 요약 행 출력을 구현한다.
- [x] TODO 65: 기본·JSON·summary 회귀 테스트와 `--summary --csv` 조합 검증을 보강한다.
- [x] TODO 66: README·HANDOFF·LOOP 문서를 갱신하고 구현 후 8개 품질 게이트를 통과한다.

## 31-FIX LOOP — `--json --csv` 조합 오류 수정

- [x] TODO 67: clean 실험 브랜치에서 `--json --csv` 종료 코드 1 충돌을 재현하고 원인을 확인한다.
- [x] TODO 68: 인자 충돌 검사를 최소 수정해 `--csv`가 JSON과 함께 지정돼도 우선 출력되게 한다.
- [x] TODO 69: JSON·summary 단독 회귀와 CSV 단독·두 조합의 테스트 및 품질 게이트를 보강한다.
- [x] TODO 70: 사용 문서와 LOOP 결과를 갱신하고 9개 품질 게이트 및 직접 실행을 통과한다.

## 32번째 LOOP — CSV 수용 기준 재감사

- [x] TODO 71: clean 실험 브랜치, upstream과 9개 품질 게이트 통과 상태를 확인한다.
- [x] TODO 72: master 대비 7개 파일과 4개 커밋의 변경 범위를 검토한다.
- [x] TODO 73: 기본·summary·JSON·CSV 및 두 CSV 조합을 직접 실행해 출력 우선순위와 회귀를 확인한다.
- [x] TODO 74: 최종 수용 기준과 문서 반영을 감사하고 master 병합 검토 가능 여부를 기록한다.

## 33번째 LOOP — master 병합 전 최종 판단

- [x] TODO 75: origin fetch 후 실험 브랜치·upstream과 master·origin/master 동기화를 확인한다.
- [x] TODO 76: 9개 품질 게이트와 여섯 핵심 CLI 조합을 검증한다.
- [x] TODO 77: master 대비 7개 파일·5개 커밋 범위와 merge-base를 점검한다.
- [x] TODO 78: CSV 수용 기준과 병합 가능 판단을 기록하고 아직 병합하지 않는다.

## 34번째 LOOP — CSV 실험 브랜치 master 병합

- [x] TODO 79: master가 `origin/master`와 동일하고 병합 전 기존 7개 품질 게이트가 통과함을 확인한다.
- [x] TODO 80: `experiment/csv-output`을 `--no-ff` merge commit으로 충돌 없이 병합한다.
- [x] TODO 81: 병합 후 9개 품질 게이트와 CSV 단독·두 조합을 검증한다.
- [x] TODO 82: 병합 결과를 문서 커밋으로 기록하고 master push는 LOOP 35까지 보류한다.

## 35번째 LOOP — 병합 후 품질 게이트 및 master push

- [x] TODO 83: clean master에서 병합 결과의 9개 품질 게이트를 최종 검증한다.
- [x] TODO 84: `origin/master..master`의 예상 8개 커밋을 검토하고 일반 push한다.
- [x] TODO 85: push 후 HEAD, `origin/master`, 원격 master 해시 일치를 확인한다.
- [x] TODO 86: push 결과를 문서 커밋으로 기록하고 일반 push로 최종 반영한다.

## 36번째 LOOP — 병합 후 원격 동기화 감사 및 브랜치 정리 판단

- [x] TODO 87: clean master에서 9개 품질 게이트와 master 세 해시 일치를 확인한다.
- [x] TODO 88: `experiment/csv-output`의 master 병합 완료 상태를 확인한다.
- [x] TODO 89: 로컬·원격 실험 브랜치가 모두 존재함을 확인하고 삭제 권고 여부를 판단한다.
- [x] TODO 90: 최종 감사 결과를 기록하되 실험 브랜치는 실제 삭제하지 않는다.

## 37번째 LOOP — 병합 완료된 CSV 실험 브랜치 안전 정리

- [x] TODO 91: clean master, 9개 품질 게이트와 master 세 해시 일치를 확인한다.
- [x] TODO 92: `experiment/csv-output`의 master 병합과 로컬·원격 존재를 재확인한다.
- [x] TODO 93: 로컬 브랜치를 `git branch -d`로, 원격 브랜치를 delete push로 안전 삭제한다.
- [x] TODO 94: 로컬·원격 브랜치 부재와 강제 삭제·force push 미사용을 기록한다.

## 38번째 LOOP — 전체 실습 회고 및 LOOP 엔지니어링 패턴 문서화

- [x] TODO 95: clean master, 9개 품질 게이트, 원격 동기화와 단일 브랜치 상태를 확인한다.
- [x] TODO 96: 최근 30개 커밋과 전체 LOOP 계획·로그에서 반복 가능한 흐름을 추출한다.
- [x] TODO 97: 수동·자율 LOOP, 승인 경계, 브랜치·검증·중단·금지 규칙을 새 패턴 문서에 정리한다.
- [x] TODO 98: 다음 실험에 복사 가능한 표준 자율 LOOP 프롬프트 골격을 작성한다.

## 39번째 LOOP — 다음 실험 후보 검토 및 선정

- [x] TODO 99: clean master, 9개 품질 게이트와 master 세 해시 동기화를 확인한다.
- [x] TODO 100: 로컬·원격 브랜치가 master 하나인지 확인하고 후보별 가치와 위험을 비교한다.
- [x] TODO 101: 명시적으로 남은 리스크인 다른 OS 검증을 다음 실험으로 선정한다.
- [x] TODO 102: 다음 LOOP의 실험 브랜치 준비를 권고하되 이번 LOOP에서는 생성하지 않는다.

## 40번째 LOOP — GitHub Actions 교차 운영체제 검증

- 목표: GitHub Actions에서 동일한 `npm run verify`를 Windows, Ubuntu, macOS에서 실행한다.
- 실험 범위: `.github/workflows/cross-platform-verify.yml`과 LOOP 문서에 한정하며, 확인된 OS 문제가 없으면 애플리케이션 소스와 테스트를 변경하지 않는다.
- 예상 위험: Windows `ComSpec` 분기, Unix의 npm 직접 실행, 경로·대소문자·줄바꿈·인코딩·임시 디렉터리 차이, GitHub-hosted runner 아키텍처별 Node 배포물 가용성.
- 품질 게이트: 변경 전후 로컬 `npm run verify` 9개 PASS와 원격 matrix의 Windows·Ubuntu·macOS 전체 PASS.
- 완료 조건: 예상 파일만 변경, 로컬 검증 통과, 실험 브랜치 일반 push, 원격 workflow 실행 확인과 OS별 결과 보고.
- [x] TODO 103: 동기화된 clean master와 기준 9개 품질 게이트를 확인하고 실험 브랜치를 생성한다.
- [x] TODO 104: 검증 스크립트의 셸·경로·대소문자·줄바꿈·인코딩·임시 경로·Node 버전 위험을 조사한다.
- [x] TODO 105: 세 OS와 동일한 Node.js 22.17.0 matrix에서 `npm run verify`를 실행하는 workflow를 작성한다.
- [x] TODO 106: 로컬 검증, 커밋·push와 GitHub Actions OS별 결과 확인을 완료한다.
- master 병합: 이번 LOOP에서는 수행하지 않는다.

## 41번째 LOOP — 교차 운영체제 검증 workflow master 병합

- 목표: 성공한 `experiment/cross-platform-verify`를 master에 `--no-ff`로 병합하고 검증 후 일반 push한다.
- [x] TODO 107: 최신 실험 커밋의 Windows·Ubuntu·macOS Actions와 quality gate PASS를 재확인한다.
- [x] TODO 108: 실험 브랜치와 master에서 병합 전 로컬 9개 품질 게이트를 통과한다.
- [x] TODO 109: 실험 브랜치를 충돌 없이 `--no-ff` merge commit으로 master에 병합한다.
- [x] TODO 110: 병합 후 master의 9개 품질 게이트를 통과하고 결과를 문서화한다.
- [x] TODO 111: LOOP 41 문서 커밋과 master 일반 push 후 원격 동기화를 확인한다.
- 실험 브랜치 삭제: 이번 LOOP에서는 수행하지 않는다.

## 42번째 LOOP — Autonomous LOOP Runner v1 구축

- 목표: 사람의 중간 확인 없이 최대 10회 또는 120분 동안 제한된 코드 품질 개선을 반복하는 Windows PowerShell Runner를 구축한다.
- 실행 범위: 전용 `autonomy/*` 브랜치의 로컬 작업만 허용하며 master 병합·push, 모든 원격 push, 브랜치 삭제를 금지한다.
- 품질 게이트: 각 반복은 분석 → 테스트 → 구현 → `npm run verify` → 독립 `codex review` → 필요 시 수정·재검증 → 로컬 commit → 기록 순서를 따른다.
- 종료 조건: 최대 반복 수, 전체 시간, 연속 실패, 연속 무진전 중 먼저 충족되는 조건으로 종료하고 최종 보고서를 보존한다.
- [x] TODO 112: 동기화된 clean master와 9개 품질 게이트를 확인하고 로컬 전용 `autonomy/loop-runner-v1` 브랜치를 생성한다.
- [x] TODO 113: `AGENTS.md` 공통 안전 규약과 `AUTONOMOUS_GOAL.md` 장기 품질 목표·허용 범위를 정의한다.
- [x] TODO 114: `workspace-write`, `approval_policy=never`의 `codex exec`·`codex review` 단계와 종료 상태 머신을 PowerShell Runner로 구현한다.
- [x] TODO 115: 반복별 로그, JSONL 기록, 최종 JSON·Markdown 보고서를 `.autonomous-loop/runs`에 보존하고 Git에서 제외한다.
- [x] TODO 116: 무진전 종료와 연속 실패 종료의 두 smoke test, 구문 검사, 독립 review와 로컬 9개 품질 게이트를 통과한다.
- master 병합·원격 push·브랜치 삭제: 이번 LOOP에서는 수행하지 않는다.

## 43번째 LOOP — 실패 실행 복구 및 Autonomous LOOP Runner v1.1

- 목표: 실패 실행의 안전한 변경은 완성하고, 향후 반복 실패가 작업 트리를 오염시키지 않도록 체크포인트 복구와 과제 skip을 구현한다.
- [x] TODO 117: 실패 보고서와 iteration 로그, `test.js:183`, 작업 트리 diff를 분석한다.
- [x] TODO 118: CSV 우선순위 변경을 최소 완성하고 `npm test`와 9개 `npm run verify`를 통과한다.
- [x] TODO 119: 실행·반복 체크포인트, 실패 시 HEAD·index·worktree·untracked 복구와 실패 과제 skip을 구현한다.
- [x] TODO 120: 복구 성공 실패를 분리하고, 복구 불가능한 연속 실패에만 중단 한도를 적용한다.
- [x] TODO 121: Node.js v22.17.0 사전 점검과 실패·복구·skip 정보를 포함한 최종 보고서를 구현한다.
- [x] TODO 122: PowerShell 구문, 두 Runner smoke test, 9개 verify와 반복 독립 review를 통과한다.
- master 병합·원격 push·브랜치 삭제: 이번 LOOP에서는 수행하지 않는다.

## 44번째 LOOP — Autonomous LOOP Runner Node 사전 점검 현실화

- 목표: 로컬 Autonomous LOOP Runner의 Node 사전 점검을 현실적으로 조정해 Node.js 22.x 또는 24.x LTS에서 시작 가능하게 만들고, GitHub Actions의 22.17.0 고정은 유지한다.
- 실행 범위: `scripts/run-autonomous-loop.ps1`과 LOOP 문서에 한정한다. master 병합, 원격 push, 브랜치 삭제, workflow 변경은 이번 LOOP에서 수행하지 않는다.
- 예상 위험: Node 버전 판정이 너무 느슨해지거나 너무 엄격해져 Runner 시작이 막히는 문제, 실패 시 보고서 메시지의 모호성, smoke test 또는 `npm run verify` 회귀.
- 품질 게이트: 수정 후 `npm run verify` 9개 PASS, Runner smoke test 2종 PASS, current Node v24.18.0에서 Runner preflight 통과, 다른 버전은 명확한 오류와 보고서를 남기고 중단.
- 완료 조건: 허용 Node 범위와 실패 메시지가 코드에 반영되고, 검증과 smoke test가 모두 통과하며, 문서가 현재 정책을 설명한다.
- [x] TODO 123: 현재 브랜치, clean 상태, HEAD와 master의 분리, 현재 Node 버전과 기존 runner 정책을 확인한다.
- [x] TODO 124: Node preflight를 22.x 또는 24.x LTS 허용으로 조정하고, GitHub Actions의 22.17.0 고정은 유지한다.
- [x] TODO 125: `npm run verify`와 두 Runner smoke test를 다시 실행해 수정이 회귀를 만들지 확인한다.
- [x] TODO 126: LOOP 44 결과와 새 Node 정책을 LOOP 문서에 기록하고, master 병합·원격 push 없이 마무리한다.

## 45번째 LOOP — Autonomous Runner Node 정책 문서 정합성

- 목표: Runner가 허용하는 Node.js 22.x 또는 24.x LTS 정책과 `AGENTS.md`의 자율 실행 규칙을 일치시킨다.
- 발견한 충돌: Runner는 LOOP 44부터 Node.js 22.x 또는 24.x를 허용하지만 `AGENTS.md`는 정확히 `v22.17.0`만 허용해 현재 로컬 Node.js v24.18.0과 모순됐다.
- 실행 범위: `AGENTS.md`와 LOOP 문서만 최소 수정하며 Runner 동작, GitHub Actions의 22.17.0 고정, 과거 LOOP 기록은 변경하지 않는다.
- 품질 게이트: `npm run verify` 9개 PASS와 `ProgressThenNoProgress`, `ConsecutiveFailures` Runner smoke test PASS.
- [x] TODO 127: 지정 문서와 Runner 구현을 확인해 현재 정책과 오래된 제한의 범위를 판별한다.
- [x] TODO 128: `AGENTS.md`의 Node 규칙을 Node.js 22.x 또는 24.x LTS 허용으로 최소 수정한다.
- [x] TODO 129: `npm run verify`와 두 Runner smoke test를 실행해 회귀가 없음을 확인한다.
- [x] TODO 130: 실제 변경 파일과 검증 결과를 LOOP 문서에 기록하고 관련 파일만 로컬 커밋한다.

## 46번째 LOOP — Autonomous Runner GoalPath 프롬프트 적용

- 목표: `-GoalPath`로 선택한 목표 파일을 analysis, test, implementation, correction 단계의 모든 Codex 프롬프트에 적용한다.
- 실행 범위: `scripts/run-autonomous-loop.ps1`, `AGENTS.md`, LOOP 문서만 최소 수정하며 Runner의 권한, 허용 파일 목록, Git 정책, 반복·시간·복구 정책은 유지한다.
- 품질 게이트: PowerShell 구문 검사, 하드코딩된 목표 파일 참조 감사, `ProgressThenNoProgress`, `ConsecutiveFailures` Smoke Test와 `npm run verify` PASS.
- [x] TODO 131: clean autonomy 브랜치, Node.js 24 LTS와 기존 `GoalPath` 해석 및 프롬프트 하드코딩 원인을 확인한다.
- [x] TODO 132: 네 단계 프롬프트가 Runner가 해석한 목표 경로를 사용하도록 수정하고 기본값을 유지한다.
- [x] TODO 133: `AGENTS.md`의 목표 파일 읽기·편집 금지 규칙을 사용자 지정 `GoalPath`와 일치시킨다.
- [x] TODO 134: 구문·정적 감사, 두 Smoke Test와 `npm run verify`를 통과하고 관련 파일만 로컬 커밋한다.

## 47번째 LOOP — quoted CSV escaped double quote 회귀 테스트

- 목표: 따옴표로 감싼 CSV 필드 내부의 escaped double quote(`""`) 처리에 직접적인 회귀 테스트를 추가한다.
- 실행 범위: 자율 Runner `run-20260712-090836`의 iteration 1로 `test.js`만 수정하며 프로덕션 코드와 공개 CLI 동작은 변경하지 않는다.
- [x] TODO 135: 기존 parser 테스트에 escaped double quote 분기의 직접 검증이 없음을 확인한다.
- [x] TODO 136: `"A ""quoted"" item",10`이 `A "quoted" item`과 amount `10`으로 파싱되는지 검증한다.
- [x] TODO 137: `npm run verify` 9개, `git diff --check`와 독립 리뷰를 통과하고 정상 로컬 커밋한다.

## 48번째 LOOP — quoted CSV 내부 CRLF 회귀 테스트

- 목표: 따옴표로 감싼 CSV 필드 내부의 CRLF 줄바꿈 보존과 후속 amount 합계 처리를 회귀 테스트로 보호한다.
- 실행 범위: 자율 Runner `run-20260712-090836`의 iteration 2로 `test.js`만 수정하며 fixture와 프로덕션 코드는 변경하지 않는다.
- [x] TODO 138: quoted field 내부 CRLF 보존과 `sumAmount` 동작에 직접적인 테스트가 없음을 확인한다.
- [x] TODO 139: embedded CRLF가 포함된 레코드의 파싱 결과와 total `10`, errorCount `0`을 검증한다.
- [x] TODO 140: `npm run verify` 9개, `git diff --check`와 독립 리뷰를 통과하고 정상 로컬 커밋한다.
