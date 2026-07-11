# Autonomous LOOP Log

실행 날짜: 2026-07-11

최종 상태: 모든 TODO 완료, 모든 필수 검증 통과.

## TODO 1 완료 — CLI 도움말과 인자 검증

- 변경: `--help`/`-h`, 알 수 없는 옵션 거부, 복수 CSV 경로 거부, 인자 실행 진입점 추가.
- `npm test`: 성공, 종료 코드 0, `모든 테스트 통과`.
- `node app.js input.csv`: 성공, 종료 코드 0, 합계 18000/오류 2.
- `node app.js input.csv --json`: 성공, 종료 코드 0, JSON 합계 18000/오류 2/경고 2건.
- 재시도: 0회.

## TODO 2 완료 — 실제 CSV 행 번호 유지

- 변경: 비어 있지 않은 행에 원본 행 번호를 함께 보관해 빈 행 뒤 경고도 실제 위치를 표시.
- `npm test`: 성공, 종료 코드 0, `모든 테스트 통과`.
- `node app.js input.csv`: 성공, 종료 코드 0, 기존 일반 출력 유지.
- `node app.js input.csv --json`: 성공, 종료 코드 0, 기존 JSON 출력 유지.
- 재시도: 0회.

## TODO 3 완료 — 경계 조건 회귀 테스트

- 변경: 옵션 순서, 기본 인자, 복수 파일, 빈 CSV, BOM+공백+소수+음수의 CLI 통합 테스트 추가.
- `npm test`: 성공, 종료 코드 0, `모든 테스트 통과`.
- `node app.js input.csv`: 성공, 종료 코드 0, 기존 일반 출력 유지.
- `node app.js input.csv --json`: 성공, 종료 코드 0, 기존 JSON 출력 유지.
- 재시도: 0회.

## TODO 4 완료 — README 최종 정리

- 변경: 도움말, 인자 제한, 실제 행 번호, 지원 형식과 전체 테스트 범위 문서화.
- `npm test`: 성공, 종료 코드 0, `모든 테스트 통과`.
- `node app.js input.csv`: 성공, 종료 코드 0, 합계 18000/오류 2.
- `node app.js input.csv --json`: 성공, 종료 코드 0, 유효한 단일 JSON과 경고 2건.
- 재시도: 0회.

## 8번째 LOOP — 자율 LOOP 감사

- 감사 범위: `LOOP_PLAN.md`, `LOOP_LOG.md`, `app.js`, `test.js`, `README.md`, `package.json`, `input.csv`.
- 계획/기록 대조: 완료된 4개 TODO와 실제 구현 및 테스트가 일치함.
- README 대조: 기본 실행, 파일 인자, JSON, 도움말, 누락 파일, 지원 입력 형식이 실제 CLI와 일치함.
- 테스트 평가: 파싱, 집계, 출력 포맷, CLI 인자, 파일 오류, BOM, 숫자 형식과 빈 행 등 주요 요구사항을 검증함.
- 코드 평가: 함수 책임이 분리되어 있고 감사 범위에서 제거할 명백한 중복이나 필수 수정 사항 없음.
- 코드/기능 변경: 없음. 감사 결과 불일치나 회귀가 발견되지 않아 불필요한 변경을 피함.
- `npm test`: 성공, 종료 코드 0, `모든 테스트 통과`.
- `node app.js input.csv`: 성공, 종료 코드 0, 합계 18000/오류 2/경고 2건.
- `node app.js input.csv --json`: 성공, 종료 코드 0, 합계 18000/오류 2/JSON 경고 2건.
- `node app.js missing.csv`: 기대한 실패, 종료 코드 1, `오류: CSV 파일을 찾을 수 없습니다: missing.csv`.
- `node app.js --help`: 성공, 종료 코드 0, 사용법과 옵션 출력.

## 9번째 LOOP — 품질 게이트 자동화

- 중단 상태 복구: 이전 시도에는 `LOOP_PLAN.md`의 미완료 TODO만 있었고 `verify.js`, npm 스크립트, README, 로그 변경은 없었음. 기존 계획을 재사용함.
- 변경: `verify.js`에서 테스트, 일반 출력, JSON 출력, 누락 파일, 도움말의 명령과 기대 종료 코드를 순차 검증.
- JSON 검증: stdout에 `JSON.parse`를 적용하고 `total`, `errorCount`, `warnings` 구조를 확인.
- 연결: `package.json`에 `verify` 스크립트를 추가하고 README에 `npm run verify` 사용법을 문서화.
- 1차 실행 실패: 샌드박스의 자식 프로세스 제한으로 Node 명령이 `EPERM`; Windows의 `npm.cmd` 직접 실행은 `EINVAL`.
- 수정: Windows에서 `npm test`를 `ComSpec /c`로 실행하도록 변경. 샌드박스 제한은 승인된 실제 실행 환경에서 재검증.
- 2차 `npm run verify`: 성공, 종료 코드 0.
  - `npm test`: PASS, 종료 코드 0.
  - `node app.js input.csv`: PASS, 종료 코드 0.
  - `node app.js input.csv --json`: PASS, 종료 코드 0, JSON 파싱 성공.
  - `node app.js missing.csv`: PASS, 기대 종료 코드 1.
  - `node app.js --help`: PASS, 종료 코드 0.
- 재시도: 1회(허용 최대 3회 이내).

## 10번째 LOOP — 회귀 방지용 테스트 데이터 분리

- 변경: `fixtures/valid.csv`, `fixtures/invalid-amount.csv`, `fixtures/missing-amount-column.csv` 추가.
- 테스트 전환: 파일 처리 테스트는 fixture를 사용하며 `input.csv` 참조는 기본 CLI 인자 계약 확인에만 남김.
- 검증 전환: 일반 출력은 `valid.csv`의 합계 1500.5/오류 0, JSON 출력은 `invalid-amount.csv`의 합계 30.5/오류 2/경고 2건을 검증.
- 문서화: `input.csv`는 사용자 예제, `fixtures/`는 고정 자동 검증 데이터임을 README에 명시.
- `npm run verify`: 성공, 종료 코드 0.
  - `npm test`: PASS, 종료 코드 0.
  - `node app.js fixtures/valid.csv`: PASS, 종료 코드 0.
  - `node app.js fixtures/invalid-amount.csv --json`: PASS, 종료 코드 0, JSON 파싱 성공.
  - `node app.js missing.csv`: PASS, 기대 종료 코드 1.
  - `node app.js --help`: PASS, 종료 코드 0.
- 재시도: 0회.

## 11번째 LOOP — 품질 게이트 신뢰성 강화

- 문서화: `fixtures/README.md`에 세 fixture의 목적, 기대 합계, 오류/경고 수, 종료 코드와 오류 메시지를 기록.
- 기대값 중앙화: `verify.js` 상단의 `FIXTURES` 객체에 fixture 경로와 기대값을 모음.
- 출력 개선: fixture 기반 PASS/FAIL 결과에 `[fixture: 경로]`를 표시.
- 검증 강화: `missing-amount-column.csv`를 품질 게이트에서 직접 실행해 종료 코드 1과 오류 메시지를 확인.
- 일치성 대조: fixture 문서, `test.js`, `verify.js`의 합계 1500.5/30.5, 오류 0/2, 누락 컬럼 오류가 일치함.
- `npm run verify`: 성공, 종료 코드 0.
  - 단위 및 통합 테스트: PASS.
  - `fixtures/valid.csv` 일반 출력: PASS, 종료 코드 0.
  - `fixtures/invalid-amount.csv` JSON 출력: PASS, 종료 코드 0, JSON 파싱 성공.
  - 존재하지 않는 파일: PASS, 기대 종료 코드 1.
  - `fixtures/missing-amount-column.csv`: PASS, 기대 종료 코드 1.
  - CLI 도움말: PASS, 종료 코드 0.
- 재시도: 0회.

## 12번째 LOOP — fixture 기대값 중복 제거

- 단일 기준 추가: `fixtures/expectations.js`에 세 fixture의 경로, 목적, 합계, 오류/경고 수, 기대 종료 코드와 누락 컬럼 오류 메시지를 정의.
- 테스트 전환: `test.js`가 공통 모듈의 경로와 기대 결과를 사용하도록 변경.
- 검증 전환: `verify.js` 내부 `FIXTURES` 중복을 제거하고 공통 모듈을 import하도록 변경.
- 문서 일치: `fixtures/README.md`의 합계 1500.5/30.5, 오류 0/2, 누락 컬럼 코드 1이 공통 모듈과 일치함을 확인.
- 실행 전 점검 수정: 자동 치환으로 종료 코드 참조 대상이 의미상 뒤바뀐 부분을 발견해 각 fixture에 맞게 수정. 실행 실패는 발생하지 않음.
- `npm run verify`: 성공, 종료 코드 0, 6개 검증 모두 PASS.
- 재시도: 0회.

## 13번째 LOOP — 릴리스 점검

- 패키지 점검: 이름 `csv-amount-cli`, 버전 `1.0.0`, `start`/`test`/`verify` 스크립트가 목적에 맞고 JSON 파싱에 성공.
- 메타데이터 보완: 설명과 Node.js `>=14.14` 엔진 요구사항을 `package.json`에 추가.
- 무설치 실행: 외부 의존성이 없어 `npm install` 없이 실행 가능함을 README에 명시.
- 사용법 점검: `node app.js input.csv`, JSON 옵션, `npm test`, `npm run verify`가 README에 모두 포함됨.
- 문서 보완: 프로젝트 파일 구조, 대표 오류 처리 표, 현재 6개 품질 게이트 범위를 추가.
- 코드 점검: `app.js`, `test.js`, `verify.js`에서 `debugger`, `console.debug`, TODO/FIXME 또는 임시 코드 흔적 없음.
- fixture 점검: `fixtures/README.md`와 `fixtures/expectations.js`의 목적, 합계 1500.5/30.5, 오류 0/2, 종료 코드 0/1이 일치.
- CLI 기능 변경: 없음.
- `npm run verify`: 성공, 종료 코드 0, 6개 검증 모두 PASS.
- 재시도: 0회.

## 14번째 LOOP — 최종 인수인계 문서 작성

- 신규 문서: `HANDOFF.md`에 프로젝트 목적, 파일 구조, 실행·테스트·품질 게이트 방법을 정리.
- 검증 데이터: 세 fixture의 목적과 기대 결과, `expectations.js` 단일 기준의 관리 방법을 설명.
- LOOP 인수인계: `LOOP_PLAN.md`와 `LOOP_LOG.md` 역할, 초기 기능부터 릴리스 점검까지 주요 LOOP를 요약.
- 향후 판단: 대용량 처리, 숫자 정밀도, CSV 범용성, 타 운영체제 검증 등 남은 리스크와 개선 후보를 기록.
- 연결: README 상단에 `HANDOFF.md` 참조 링크를 추가.
- 코드 변경: 없음. `app.js`, `test.js`, `verify.js` 유지.
- `npm run verify`: 성공, 종료 코드 0, 6개 검증 모두 PASS.
- 재시도: 0회.

## 15번째 LOOP — 버전 관리 스냅샷

- 저장소 점검: `.git` 디렉터리는 존재하지만 `HEAD`와 `config`가 없어 유효한 Git 저장소로 초기화되지 않은 상태.
- Git CLI 점검: PATH, 일반 설치 경로, 사용자 LocalAppData, Scoop, WinGet 링크, Chocolatey 경로에서 실행 파일을 찾지 못함.
- 사용자 설정: 로컬 및 전역 설정에서 Git `user.name`, `user.email` 모두 확인되지 않음.
- `.gitignore` 추가: `node_modules/`, `npm-debug.log*`, `.env`, `.DS_Store`. LOOP 문서, HANDOFF와 fixtures는 제외하지 않음.
- `npm run verify`: 성공, 종료 코드 0, 6개 검증 모두 PASS.
- 실패 1: `git init` 실행 시 `git` 명령을 찾을 수 없어 종료 코드 1.
- 실패 2: `git status` 실행 시 같은 원인으로 종료 코드 1. 동일 원인 반복을 확인해 추가 재시도 중단(최대 3회 이내).
- 커밋: 생성하지 않음. Git CLI 부재로 저장소 초기화와 status가 불가능하고 사용자 이름·이메일 설정도 없음.
- 최종 Git 상태: Git 명령 기반 작업 트리 상태는 확인 불가. 기준점 커밋은 생성되지 않았으며 프로젝트 파일과 `.gitignore`는 워크스페이스에 보존됨.
- 후속 조치: Git 설치 후 `git init`, 사용자 설정 확인, `git status`, 전체 파일 추가, `chore: release csv amount cli loop lab baseline` 커밋 순서로 진행 필요.

### Git 설치 후 재개

- Git 설치 확인: `git version 2.55.0.windows.2`.
- 저장소 상태: `git status` 성공, `master` 브랜치의 유효한 저장소이며 아직 커밋 없음.
- 복구 판단: `.git` 재초기화나 삭제가 필요하지 않아 기존 저장소를 그대로 사용.
- Git 사용자 설정: `user.name`, `user.email` 모두 설정됨(값은 로그에 기록하지 않음).
- `npm run verify`: 성공, 종료 코드 0, 6개 검증 모두 PASS.
- 스냅샷 범위: `.gitignore`, LOOP 문서, HANDOFF, fixtures와 전체 CLI 프로젝트 파일.
- 커밋 메시지: `chore: release csv amount cli loop lab baseline`.
- 커밋 결과: 첫 기준점 커밋 생성 성공. 이 결과를 로그에 포함하기 위해 동일 메시지로 amend하여 단일 커밋으로 유지.

## 16번째 LOOP — summary 출력 옵션

- 브랜치 확인: `experiment/summary-option`, 시작 시 작업 트리 clean. `master`에서 직접 작업하지 않음.
- CLI 변경: `--summary` 옵션과 `formatSummaryResult` 추가. 합계, 오류 행 수, 경고 수를 사람이 읽는 형식으로 출력.
- 출력 분리: summary 모드에서는 개별 경고를 stderr에 섞지 않고 경고 수로 집계.
- 인자 검증: `--json`과 `--summary` 동시 사용을 오류로 처리.
- 테스트: summary 포맷, 인자 파싱, 옵션 충돌, fixture 출력과 경고 비혼합을 검증.
- 품질 게이트: `fixtures/invalid-amount.csv --summary` 실제 CLI 검증 추가.
- 문서: README와 HANDOFF에 summary 사용법 및 품질 게이트 범위를 반영.
- `npm run verify`: 성공, 종료 코드 0, 7개 검증 모두 PASS.
- 재시도: 0회.

## 18번째 LOOP — 실험 브랜치 변경사항 커밋

- 브랜치: `experiment/summary-option` 확인. `master`에서 작업하지 않음.
- 커밋 전 상태: summary 관련 7개 파일이 수정되고 스테이징되지 않은 상태.
- 커밋 전 `npm run verify`: 성공, 종료 코드 0, 7개 검증 모두 PASS.
- 기능 커밋: `dc9f671 feat: add summary output option` 생성 성공.
- 문서 기록: 이번 실행 결과와 완료 TODO를 별도 문서 커밋으로 기록.
- 재시도: 0회.

## 19번째 LOOP — 실험 브랜치 병합 판단

- 현재 브랜치: `experiment/summary-option`, 시작 시 작업 트리 clean.
- 커밋 그래프: 실험 브랜치는 master 기준점 `3b9332a` 위에 기능 커밋 `dc9f671`과 문서 커밋 `a3a3935`가 직선으로 이어짐.
- master 대비 범위: 7개 파일, summary 포맷·인자 처리·테스트·품질 게이트·사용 문서와 LOOP 기록에 한정.
- 기존 동작: 일반 출력과 JSON 분기는 유지되고 도움말만 새 옵션을 반영. 기존 품질 게이트 항목 모두 PASS.
- 테스트 충분성: 포맷, summary 인자, JSON 충돌, fixture 결과, 경고 비혼합과 실제 CLI 출력을 검증.
- 문서 일관성: README, HANDOFF, LOOP_PLAN, LOOP_LOG가 구현과 품질 게이트 7개 항목을 일관되게 설명.
- 범위 평가: 하나의 출력 옵션과 직접 관련된 테스트·문서만 추가되어 과도한 기능 확장 없음.
- `npm run verify`: 성공, 종료 코드 0, 7개 검증 모두 PASS.
- 병합 판단: **merge recommended**.
- 병합 실행: 하지 않음. master 브랜치는 수정하지 않음.

## 20번째 LOOP — 검증된 실험 브랜치 master 병합

- 병합 전 실험 브랜치: `experiment/summary-option`, 작업 트리 clean, `npm run verify` 7개 검증 PASS.
- master 전환: 성공, 병합 전 작업 트리 clean.
- 병합 전 master 검증: 기존 6개 품질 게이트 PASS.
- 병합: `git merge --no-ff experiment/summary-option -m "merge: summary option"` 성공, 충돌 없음.
- 병합 커밋: `34dc644 merge: summary option`.
- 병합 후 검증: `npm run verify` 성공, 종료 코드 0, summary 포함 7개 검증 모두 PASS.
- 그래프 확인: master merge commit의 두 부모 아래에 기준점과 실험 브랜치의 기능·문서 커밋이 보존됨.
- 병합 직후 상태: master 작업 트리 clean.
- 재시도 및 충돌 해결: 0회.

## 21번째 LOOP — 병합 완료된 실험 브랜치 정리 판단

- 현재 브랜치: `master`.
- 시작 상태: 작업 트리 clean.
- 병합 확인: `git branch --merged master`에 `experiment/summary-option`이 포함됨.
- 로그 확인: merge commit `34dc644 merge: summary option`과 실험 브랜치의 기능·문서 커밋이 `git log --oneline --graph --decorate --all -10`에서 추적 가능함.
- `npm run verify`: 성공, 종료 코드 0, 7개 검증 모두 PASS.
- 검증 재시도: 최초 샌드박스 실행은 자식 프로세스 생성이 `EPERM`으로 차단되어 실패했고, 권한을 허용한 재실행에서 정상 통과함.
- 브랜치 정리 판단: **delete recommended**.
- 판단 근거: 변경사항은 master에 병합 완료되었고 Git 로그에 이력이 보존되어 브랜치 자체를 학습 기록으로 유지할 추가 가치가 크지 않음.
- 삭제 실행: 하지 않음. 실제 삭제 전 사용자 확인이 필요함.

## 22번째 LOOP — 병합 완료된 로컬 브랜치 안전 삭제

- 목적: master에 병합 완료된 로컬 `experiment/summary-option` 브랜치를 안전하게 삭제함.
- 사전 상태: 현재 경로 `C:\Users\sangyeul\CODEX\codex-loop-lab`, 현재 브랜치 `master`, 작업 트리 clean.
- master 검증: `npm run verify` 성공, 종료 코드 0, 7개 검증 모두 PASS.
- 병합 확인: `git branch --merged master` 결과에 `experiment/summary-option`이 포함됨.
- 삭제 명령: `git branch -d experiment/summary-option`.
- 삭제 결과: 성공. 브랜치의 마지막 커밋은 `7865434`였으며, 로컬 브랜치 목록에서 더 이상 존재하지 않음을 확인함.
- 강제 삭제: `git branch -D`는 사용하지 않음.
- GitHub push: 수행하지 않음. 이번 LOOP는 로컬 Git 정리와 문서 기록에 한정함.

## 23번째 LOOP — GitHub push 전 최종 로컬 감사

- 목적: GitHub push 전 최종 로컬 감사.
- 프로젝트 경로: `C:\Users\sangyeul\CODEX\codex-loop-lab` 확인.
- 현재 브랜치: `master`.
- 작업 트리 상태: 문서 수정 전 clean.
- `npm run verify`: 성공, 종료 코드 0, 7개 검증 모두 PASS.
- 삭제 브랜치 확인: `git branch --list experiment/summary-option` 결과가 비어 있어 해당 브랜치가 로컬에 더 이상 없음을 확인함.
- 최근 커밋 이력: 기준점 커밋 위에 summary 기능 및 문서 커밋, no-ff 병합 커밋, LOOP 20~22 결과 문서 커밋이 순서대로 보존되어 있음을 검토함. 감사 시작 시 HEAD는 `44ba0f3 docs: record loop 22 branch cleanup`.
- 로컬 브랜치: `master`만 존재함.
- remote 설정: `git remote -v` 결과가 비어 있어 설정된 원격 저장소가 없음.
- GitHub push: 의도적으로 수행하지 않음.
- 결론: 모든 로컬 점검을 통과해 향후 push를 위한 로컬 준비가 완료됨. 실제 push 전 원격 저장소 설정이 필요함.

## 24번째 LOOP — GitHub push 전 remote 연결 준비

- 목적: GitHub push 전 remote 연결 준비.
- 현재 브랜치: `master`.
- 작업 트리 상태: 문서 수정 전 clean.
- `npm run verify`: 성공, 종료 코드 0, 7개 검증 모두 PASS.
- 기존 remote 확인: `git remote -v` 결과가 비어 있었고 `origin`이 설정되지 않은 상태였음.
- origin 추가: `git remote add origin https://github.com/erpsarang/LOOP_ENG_stepbystep` 실행 성공.
- 최종 remote URL: fetch와 push 모두 `https://github.com/erpsarang/LOOP_ENG_stepbystep`으로 확인됨.
- GitHub push: 의도적으로 수행하지 않음.
- 결론: remote 연결 준비가 완료되어 다음 LOOP에서 인증과 저장소 접근 권한을 확인한 뒤 push 가능함.

## 25번째 LOOP — GitHub 최초 push

### Push 전 점검

- 목적: GitHub 최초 push.
- 현재 브랜치: `master`.
- 작업 트리 상태: 문서 수정 전 clean.
- `npm run verify`: 성공, 종료 코드 0, 7개 검증 모두 PASS.
- origin remote URL: fetch와 push 모두 `https://github.com/erpsarang/LOOP_ENG_stepbystep`으로 확인됨.
- 원격 브랜치 확인: `git ls-remote --heads origin` 결과가 비어 있어 기존 원격 브랜치나 커밋을 가리키는 head가 없음을 확인함.
- force push 금지: `--force`, `-f`, `--force-with-lease`를 사용하지 않음.
- 최초 push 예정 명령: `git push -u origin master`.

### Push 완료 결과

- 최초 push: `git push -u origin master` 성공, 로컬 `master`가 새 원격 브랜치 `master`로 반영됨.
- upstream 설정: 로컬 `master`가 `origin/master`를 추적하도록 설정됨.
- 원격 master 확인: `git ls-remote --heads origin master`에서 `refs/heads/master`가 최초 push 커밋 `886062c`를 가리킴을 확인함.
- force push: 사용하지 않음. 최초 push와 최종 문서 반영 모두 일반 push만 사용함.
- 최종 결론: 로컬 `master`가 GitHub `origin/master`에 반영됨.

## 26번째 LOOP — GitHub 최초 push 이후 원격 동기화 감사

- 목적: GitHub 최초 push 이후 원격 동기화 감사.
- 현재 브랜치: `master`.
- 작업 트리 상태: 문서 수정 전 clean, `master...origin/master` 동기화 표시.
- `npm run verify`: 성공, 종료 코드 0, 7개 검증 모두 PASS.
- origin remote URL: fetch와 push 모두 `https://github.com/erpsarang/LOOP_ENG_stepbystep`.
- upstream 추적 상태: 로컬 `master`가 `origin/master`를 추적함.
- 문서 수정 전 HEAD 해시: `c62e47649a1485e6074105d0cc40131a9f210f64`.
- 문서 수정 전 `origin/master` 해시: `c62e47649a1485e6074105d0cc40131a9f210f64`.
- 문서 수정 전 원격 master 해시: `c62e47649a1485e6074105d0cc40131a9f210f64`.
- 해시 비교: 세 해시가 모두 일치함.
- force push: 사용하지 않음. LOOP 26 문서 커밋은 일반 `git push`로만 반영함.
- 결론: 감사 시점의 로컬 `master`, 로컬 추적 ref와 GitHub 원격 `master`가 정상 동기화됨.

## 27번째 LOOP — 최근 커밋 요약 및 프로젝트 체크포인트 문서화

- 목적: 최근 커밋 요약 및 프로젝트 체크포인트 문서화.
- 현재 브랜치: `master`.
- 작업 트리 상태: 문서 수정 전 clean, `master...origin/master` 동기화 상태.
- `npm run verify`: 성공, 종료 코드 0, 7개 검증 모두 PASS.
- upstream 상태: 로컬 `master`가 `origin/master`를 추적하며, 감사 시작 시 둘 다 `a7a1129`를 가리킴.
- 최근 커밋 요약: `3b9332a`에서 기본 CSV amount CLI 프로젝트와 검증 체계의 기준점을 만들고, `dc9f671`에서 실험 브랜치의 `--summary` 기능을 구현했으며, `34dc644`에서 no-ff 병합함. 이후 병합 결과 기록, 브랜치 정리 판단과 안전 삭제, GitHub remote 설정, 최초 push, 원격 동기화 감사를 문서 커밋으로 순차 보존함.
- 기록 방식: `LOOP_PLAN.md`의 완료 TODO와 `LOOP_LOG.md`의 실행 근거를 함께 갱신하는 LOOP 기록 방식을 확립함.
- 현재 완료된 실습 범위: 기본 프로젝트 생성 및 자동 검증 체계 구축, 실험 브랜치 기능 개발, master no-ff 병합, 병합 후 검증 통과, 병합 브랜치 안전 삭제, GitHub remote 설정, 최초 push, 로컬·추적 ref·원격 master 동기화 감사까지 완료함.
- 다음 후보 작업: 대용량 CSV 스트리밍 처리, 금액 숫자 정밀도 개선, CSV 형식 범용성 확대, 타 운영체제 검증 자동화를 후속 LOOP 후보로 유지함.
- force push: 사용하지 않음. LOOP 27 문서 커밋은 일반 `git push`로만 반영함.
- 결론: 검증된 기능과 전체 Git 이력이 GitHub에 반영된 안정 체크포인트 상태임.

## 28번째 LOOP — 다음 실험 기능 선정 및 브랜치 준비

- 목적: 다음 실험 기능 후보 선정 및 실험 브랜치 준비.
- 기준 브랜치 상태: `master`가 clean 상태였고 `origin/master`와 함께 `6c17e3b`를 가리킴.
- `npm run verify`: 브랜치 생성 전 성공, 종료 코드 0, 7개 검증 모두 PASS.
- remote/upstream 상태: origin은 `https://github.com/erpsarang/LOOP_ENG_stepbystep`이며, 기준 브랜치 `master`가 `origin/master`를 추적함.
- 검토 후보: CSV 출력 기능, 의존성 정리, 소스 구조 정리, 다른 OS 검증, README 보강.
- 선정 후보: CSV 출력 기능.
- 선정 이유: 기존 입력·집계 흐름에 독립적인 출력 형식으로 추가할 수 있어 범위가 작고, fixture 기반 출력 및 옵션 충돌을 명확히 검증할 수 있음.
- 브랜치 사전 확인: `experiment/csv-output`이 로컬과 origin에 모두 존재하지 않음을 확인함.
- 생성 브랜치: `master`에서 `git switch -c experiment/csv-output`으로 `experiment/csv-output` 생성 및 이동 성공.
- 소스 코드: 이번 LOOP에서는 수정하지 않음.
- force push: 사용하지 않음. 브랜치 문서 커밋은 일반 push로만 반영함.
- 결론: 다음 LOOP에서 CSV 출력 기능을 설계하거나 구현할 수 있는 실험 브랜치 준비 완료.

## 29번째 LOOP — CSV 출력 기능 설계 및 수용 기준 정의

- 목적: CSV 출력 기능 설계 및 수용 기준 정의.
- 현재 브랜치: `experiment/csv-output`.
- 작업 트리 상태: 문서 수정 전 clean.
- `npm run verify`: 성공, 종료 코드 0, 기존 7개 검증 모두 PASS.
- upstream 상태: `origin/experiment/csv-output` 추적, 감사 시작 시 로컬과 upstream 모두 `9dd4133`.
- 확인한 주요 파일: `package.json`, `app.js`, `test.js`, `verify.js`, `fixtures/expectations.js`와 세 CSV fixture.
- 명령 구조: `package.json`은 `start`, `test`, `verify` 스크립트를 제공하고, `app.js`의 `executeArgs`가 `parseCliArgs` 결과를 `executeCli`와 `runCli`로 전달함.
- 기존 출력 구조: `runCli`는 공통 집계 결과와 warnings를 만든 뒤 JSON, summary, 기본 출력 순으로 전용 포맷터를 선택함. `--json`과 `--summary`는 상호 배타적이며 구조화·요약 모드에서는 경고를 stderr에 개별 출력하지 않고 결과에 포함하거나 개수로 집계함.
- 테스트·검증 구조: `test.js`가 포맷터, 인자 파싱, 옵션 충돌, fixture 통합 동작을 검증하고, `verify.js`가 `fixtures/expectations.js`의 단일 기대값을 사용해 실제 CLI 명령과 종료 코드를 검사함.

### CSV 출력 설계안

- 추천 옵션: `--format csv`보다 현재 단일 플래그 방식과 일관되고 구현 범위가 작은 `--csv`를 채택함.
- 기존 출력 관계: 옵션이 없을 때의 기본 출력과 `--json`, `--summary` 결과는 변경하지 않고 `--csv`만 별도 출력 분기로 추가함.
- 옵션 충돌: `--csv`는 `--json`, `--summary`와 각각 또는 함께 사용할 수 없으며, 둘 이상의 출력 모드가 지정되면 친절한 오류와 종료 코드 1을 반환함.
- CSV 스키마: 첫 줄 헤더는 `total,errorCount,warningCount`, 둘째 줄은 집계 합계, 오류 행 수, 수집된 경고 수를 같은 순서로 담는 단일 요약 행임.
- 경고 처리: CSV 모드에서는 summary 모드처럼 개별 경고를 stderr에 출력하지 않고 `warningCount`로 집계해 stdout이 유효한 CSV만 포함하도록 함.
- 필드 인코딩: 모든 값을 문자열로 변환하고 콤마, 큰따옴표, CR 또는 LF가 포함된 필드는 큰따옴표로 감싸며 내부 큰따옴표는 두 번 써서 이스케이프함. 그 외 값은 불필요하게 인용하지 않음.
- 줄바꿈: 레코드는 `\n`으로 결합하고 필드 안의 원래 CR/LF는 인용 필드 내부에 보존함.
- 빈 데이터: 기존 `CSV 파일이 비어 있습니다.` 오류와 종료 코드 1을 유지하며, 불완전한 헤더나 데이터 행은 stdout에 출력하지 않음.
- 검증 방법: 포맷터 및 필드 이스케이퍼 단위 테스트, `parseCliArgs`의 `--csv`와 충돌 테스트, 기존 invalid-amount fixture를 이용한 `runCli` 통합 테스트, `verify.js`의 실제 `--csv` 명령 및 CSV 구조·값·빈 stderr 검증을 추가함.
- 다음 LOOP 수정 후보: `app.js`, `test.js`, `verify.js`, `README.md`, `HANDOFF.md`. 기존 fixture 기대값을 재사용하고 새 데이터가 필요할 때만 `fixtures/` 문서와 기대값을 함께 갱신함.

### 수용 기준

- 기존 `npm run verify` 항목과 기본 출력, JSON 출력, summary 출력이 그대로 통과해야 함.
- `--csv` 사용 시 정확한 헤더 `total,errorCount,warningCount`와 단일 데이터 행이 stdout에 출력되어야 함.
- CSV 값에 콤마, 큰따옴표, CR 또는 LF가 포함돼도 필드 경계와 레코드가 깨지지 않도록 인용·이스케이프되어야 함.
- `--csv`와 `--summary` 또는 `--json`을 함께 사용하면 명확한 충돌 오류와 종료 코드 1을 반환해야 함.
- 유효·잘못된 amount fixture를 이용해 합계, 오류 수, 경고 수와 stderr 비혼합을 반복 검증할 수 있어야 함.
- 빈 CSV 입력은 기존 오류 계약을 유지하고 CSV 헤더를 출력하지 않아야 함.
- 이번 LOOP에서는 소스 코드를 수정하지 않았으며 구현은 다음 LOOP에서 수행함.
- force push: 사용하지 않음. 문서 커밋은 일반 `git push`로만 반영함.

## 30번째 LOOP — CSV 출력 기능 구현

- 목적: CSV 출력 기능 구현.
- 현재 브랜치: `experiment/csv-output`.
- 작업 트리 시작 상태: clean, `origin/experiment/csv-output` 추적.
- 구현 전 `npm run verify`: 성공, 종료 코드 0, 기존 7개 검증 모두 PASS.
- 변경한 주요 파일: `app.js`, `test.js`, `verify.js`, `README.md`, `HANDOFF.md`, `LOOP_PLAN.md`, `LOOP_LOG.md`.
- 구현 옵션: `--csv`를 인자 파싱, 도움말과 출력 분기에 추가함.
- CSV 출력: 헤더 `total,errorCount,warningCount`와 합계·오류 수·경고 수의 단일 데이터 행을 stdout에 출력함.
- 이스케이프: `escapeCsvValue`가 콤마, 큰따옴표, CR 또는 LF가 있는 값을 큰따옴표로 감싸고 내부 큰따옴표를 두 번 쓰도록 구현함.
- 기존 출력 보존: 옵션 없는 기본 출력, `--json`, `--summary`의 포맷과 오류 계약을 변경하지 않음.
- summary 관계: LOOP 30 요구사항에 따라 LOOP 29의 상호 배타 초안을 조정해 `--summary --csv` 조합을 허용하고 CSV 출력을 우선함. `--json --csv`는 충돌 오류를 반환함.
- 테스트 보강: CSV 포맷터와 이스케이퍼의 일반 값·콤마·큰따옴표·줄바꿈을 단위 검증하고, fixture 기반 CSV 출력, 경고 수와 stderr 비혼합, `--summary --csv` 인자 조합을 검증함.
- 품질 게이트 보강: `fixtures/invalid-amount.csv --summary --csv` 실제 CLI 검증을 추가해 정확한 헤더, 데이터 행과 빈 stderr를 확인함.
- 구현 후 `npm run verify`: 성공, 종료 코드 0, 8개 검증 모두 PASS.
- 직접 실행: `node app.js --csv`와 `node app.js --summary --csv` 모두 헤더와 `18000,2,2` 데이터 행을 출력하고 종료 코드 0을 반환함.
- 일반 push: 기능 커밋 후 `origin/experiment/csv-output`에 일반 `git push` 예정.
- force push: 사용하지 않음.

## 31-FIX LOOP — `--json --csv` 조합 오류 수정

- 목적: `--json --csv` 조합 오류 수정.
- 현재 브랜치: `experiment/csv-output`.
- 시작 작업 트리 상태: clean, `origin/experiment/csv-output` 추적.
- 발견된 문제: `node app.js input.csv --json --csv`가 `오류: --json과 --csv는 함께 사용할 수 없습니다.`를 출력하고 종료 코드 1을 반환함.
- 원인: `parseCliArgs`에 JSON과 CSV의 동시 사용을 거부하는 전용 조건이 있었음. 실제 `runCli` 출력 분기는 이미 CSV를 JSON보다 먼저 평가하고 있었음.
- 수정 방향: JSON+CSV 충돌 조건만 제거하고 기존 CSV 우선 출력 분기를 재사용해 `--csv` 지정 시 CSV가 우선되도록 함.
- 변경한 주요 파일: `app.js`, `test.js`, `verify.js`, `README.md`, `HANDOFF.md`, `LOOP_PLAN.md`, `LOOP_LOG.md`.
- 테스트 보강: `parseCliArgs`가 `--json --csv`를 허용하는지, `executeArgs`가 종료 코드 0과 정확한 CSV를 반환하는지 검증함. JSON·summary 단독과 CSV 단독·summary 조합의 기존 검증도 유지함.
- 품질 게이트 보강: invalid-amount fixture의 `--json --csv` 실제 실행에서 헤더 `total,errorCount,warningCount`, 데이터 행 `30.5,2,2`, 빈 stderr와 종료 코드 0을 확인하는 항목을 추가함.
- `npm run verify`: 성공, 종료 코드 0, 9개 검증 모두 PASS.
- 직접 실행: 기본, `--summary`, `--json`, `--csv`, `--summary --csv`, `--json --csv`가 모두 종료 코드 0. 두 CSV 조합은 헤더와 `18000,2,2`를 출력함.
- 수용 기준: CSV 단독, summary+CSV, JSON+CSV, CSV 헤더·단일 행, 기본·summary·JSON 회귀와 전체 품질 게이트를 모두 충족함.
- master 병합: 아직 수행하지 않음.
- force push: 사용하지 않음. 수정 커밋은 일반 `git push`로만 반영함.
- 결론: 다음 LOOP에서 CSV 수용 기준을 재감사하거나 master 병합을 검토할 수 있음.

## 32번째 LOOP — CSV 수용 기준 재감사

- 목적: LOOP 31-FIX 이후 CSV 수용 기준 재감사.
- 현재 브랜치: `experiment/csv-output`.
- 작업 트리 상태: 문서 수정 전 clean.
- `npm run verify`: 성공, 종료 코드 0, 9개 검증 모두 PASS.
- upstream 상태: `origin/experiment/csv-output` 추적, 감사 시작 시 로컬과 upstream 모두 `2ecf17f`.
- master 대비 변경 파일 요약: `app.js`, `test.js`, `verify.js`, `README.md`, `HANDOFF.md`, `LOOP_PLAN.md`, `LOOP_LOG.md`의 7개 파일, 237 insertions 및 14 deletions. 기능·테스트·사용 문서·LOOP 기록에 한정되어 불필요한 대규모 리팩터링 없음.
- master 대비 커밋 목록: `9dd4133 docs: record loop 28 next experiment branch`, `ca0ab9c docs: record loop 29 csv design`, `0a2a42e feat: add csv output option`, `2ecf17f fix: allow csv output with json option`.
- 코드·테스트 확인: `app.js`에 `escapeCsvValue`, `formatCsvResult`와 CSV 우선 출력 분기가 있고, `test.js`와 `verify.js`에 이스케이프·헤더·단일 행·summary/JSON 조합 검증이 있음.
- README/HANDOFF: `--csv`, `--summary --csv`, `--json --csv` 사용법, CSV 우선 규칙과 품질 게이트 범위가 모두 반영됨.
- 직접 실행 fixture: `fixtures/valid.csv`.
- 기본 실행: 종료 코드 0, 기존 `amount 합계: 1500.5, 오류 행 수: 0` 유지.
- `--summary`: 종료 코드 0, 기존 합계·오류·경고 수 요약 유지.
- `--json`: 종료 코드 0, 기존 JSON 합계 1500.5와 오류 수 0 유지.
- `--csv`: 종료 코드 0, 첫 줄 `total,errorCount,warningCount`, 둘째 줄 `1500.5,0,0`의 단일 요약 행 출력.
- `--summary --csv`: 종료 코드 0, summary 대신 CSV 헤더와 단일 행이 우선 출력됨.
- `--json --csv`: 종료 코드 0, JSON 대신 CSV 헤더와 단일 행이 우선 출력됨.

### 최종 수용 기준

- PASS: `npm run verify` 통과.
- PASS: 기본·summary·JSON 단독 출력 회귀 없음.
- PASS: CSV 헤더와 단일 요약 데이터 행 정확성.
- PASS: summary+CSV 및 JSON+CSV 조합에서 에러 없이 CSV 우선.
- PASS: 콤마, 큰따옴표와 줄바꿈을 처리하는 CSV escaping 구현 및 단위 테스트 존재.
- PASS: README와 HANDOFF 사용법 반영.
- PASS: master 대비 변경이 관련 7개 파일과 목적별 4개 커밋에 한정됨.
- 소스 코드: 이번 LOOP에서는 수정하지 않음.
- master 병합: 이번 LOOP에서는 수행하지 않음.
- force push: 사용하지 않음. 감사 문서 커밋은 일반 `git push`로만 반영함.
- 결론: 최종 수용 기준을 모두 충족해 다음 LOOP에서 master 병합 검토 가능.

## 33번째 LOOP — master 병합 전 최종 판단

- 목적: master 병합 전 최종 판단.
- 현재 브랜치: `experiment/csv-output`.
- 작업 트리 상태: 시작 시 clean.
- 원격 갱신: `git fetch origin` 성공.
- upstream 상태: 로컬 실험 브랜치와 `origin/experiment/csv-output`이 `dade61e`로 일치함.
- `npm run verify`: 성공, 종료 코드 0, 9개 검증 모두 PASS.
- master/origin 상태: 로컬 `master`와 `origin/master`가 `6c17e3b`로 일치하며 diverge 없음.
- master 대비 변경 파일: `app.js`, `test.js`, `verify.js`, `README.md`, `HANDOFF.md`, `LOOP_PLAN.md`, `LOOP_LOG.md`의 관련 7개 파일, 277 insertions 및 14 deletions.
- master 대비 커밋: `9dd4133`, `ca0ab9c`, `0a2a42e`, `2ecf17f`, `dade61e`의 브랜치 준비·설계·기능·수정·재감사 5개 커밋.
- merge-base: `6c17e3b`이며 현재 master와 동일해 master 이후 실험 브랜치만 전진한 상태임. 병합 충돌 가능성이 낮고 범위가 명확함.
- 직접 실행: `fixtures/valid.csv`의 기본, summary, JSON, CSV, summary+CSV, JSON+CSV가 모두 종료 코드 0과 기대 출력을 반환함.
- CSV 수용 기준: 기존 출력 회귀 없음, CSV 헤더·단일 행, 두 조합의 CSV 우선, escaping·테스트·문서 반영을 모두 충족함.
- 병합 가능 판단: **merge recommended**.
- master 병합: 아직 수행하지 않음.
- force push: 사용하지 않음. 판단 문서 커밋은 일반 `git push`로만 반영함.

## 34번째 LOOP — CSV 실험 브랜치 master 병합

- 목적: CSV 실험 브랜치 master 병합.
- 병합 대상: `experiment/csv-output`.
- 병합 방식: `git merge --no-ff experiment/csv-output -m "merge: csv output experiment"`.
- 병합 전 상태: `master`와 `origin/master`가 `6c17e3b`로 일치하고 작업 트리 clean.
- 병합 전 `npm run verify`: 성공, 종료 코드 0, master의 기존 7개 검증 모두 PASS.
- 병합 결과: 충돌 없이 성공, 두 부모를 가진 merge commit `67abe98 merge: csv output experiment` 생성.
- 병합 후 `npm run verify`: 성공, 종료 코드 0, CSV 조합을 포함한 9개 검증 모두 PASS.
- 직접 실행: `fixtures/valid.csv`의 `--csv`, `--summary --csv`, `--json --csv`가 모두 종료 코드 0이며 헤더와 `1500.5,0,0`을 출력함.
- master push: 아직 수행하지 않음. LOOP 35 최종 품질 게이트 이후 일반 push 예정.
- force push: 사용하지 않음.
