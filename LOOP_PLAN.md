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
