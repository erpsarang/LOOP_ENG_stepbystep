# CSV amount CLI 인수인계

## 프로젝트 목적

이 프로젝트는 CSV 파일의 `amount` 컬럼에서 유효한 숫자를 합산하는 작은 Node.js CLI입니다. 빈 값과 숫자가 아닌 값은 합계에서 제외하고 오류 행으로 집계합니다. 사람이 읽는 출력과 자동화용 JSON 출력을 지원하며 외부 npm 패키지는 사용하지 않습니다.

## 주요 파일 구조

- `app.js`: CSV 파싱, 금액 집계, 결과 포맷과 CLI 진입점
- `input.csv`: 사용자가 바로 실행해볼 수 있는 기본 예제
- `test.js`: 함수, 파일 처리와 CLI 로직의 회귀 테스트
- `verify.js`: 테스트와 대표 CLI 시나리오를 실행하는 품질 게이트
- `package.json`: 프로젝트 메타데이터와 `start`, `test`, `verify` 스크립트
- `fixtures/`: 자동 검증용 고정 CSV, 기대값 모듈과 설명
- `README.md`: 사용자 사용법과 프로젝트 개요
- `LOOP_PLAN.md`: 각 개선 LOOP의 작은 TODO와 완료 상태
- `LOOP_LOG.md`: 각 LOOP의 변경, 실패·수정, 실행 결과 기록

## 실행 방법

요구 환경은 Node.js 14.14 이상입니다. 외부 의존성이 없어 `npm install`은 필요하지 않습니다.

```powershell
node app.js input.csv
node app.js input.csv --json
node app.js input.csv --summary
node app.js --help
```

파일 경로를 생략하면 `input.csv`를 사용합니다. 존재하지 않는 파일이나 처리할 수 없는 CSV는 오류 메시지와 종료 코드 `1`을 반환합니다.

## 테스트 방법

```powershell
npm test
```

테스트는 파싱, 공백·소수·음수, BOM, 경고, JSON, 인자 처리, 파일 누락과 컬럼 누락을 검증합니다.

## 품질 게이트 실행 방법

변경 완료나 인수인계 전에는 다음 한 명령을 실행합니다.

```powershell
npm run verify
```

품질 게이트는 테스트, 정상 fixture 일반 출력, 잘못된 금액 fixture의 JSON·summary 출력, 누락 파일, `amount` 컬럼 누락, 도움말을 확인합니다. 모든 항목이 통과해야 종료 코드 `0`을 반환합니다. 누락 파일과 컬럼 누락의 코드 `1`은 예상 결과로 판정합니다.

## fixture 데이터

- `fixtures/valid.csv`: 공백이 있는 정수, 소수, 음수. 기대 합계 `1500.5`, 오류 `0`건
- `fixtures/invalid-amount.csv`: 숫자가 아닌 값과 빈 값. 기대 합계 `30.5`, 오류·경고 `2`건
- `fixtures/missing-amount-column.csv`: `amount` 컬럼 없음. 기대 종료 코드 `1`
- `fixtures/expectations.js`: 테스트와 품질 게이트가 공유하는 기계용 기대값의 단일 기준
- `fixtures/README.md`: 각 fixture의 사람이 읽는 상세 설명

fixture를 변경할 때는 CSV, `expectations.js`, `fixtures/README.md`를 함께 검토합니다.

## LOOP 문서의 역할

`LOOP_PLAN.md`는 작업을 검증 가능한 작은 TODO로 나누고 완료 상태를 보여줍니다. `LOOP_LOG.md`는 실제 변경과 명령 결과, 실패 원인, 수정과 재시도 횟수를 보존합니다. 새 LOOP에서도 계획을 먼저 추가하고, 작업 후 품질 게이트 결과를 로그에 기록하는 흐름을 유지합니다.

## 주요 LOOP 요약

- 초기 LOOP: Node 실행 확인, 잘못된 금액 경고, 합계·오류 수 출력, 함수 분리와 CLI 파일 인자 추가
- 출력·입력 견고성 LOOP: JSON 출력, 공백·소수·음수, UTF-8 BOM과 친절한 오류 처리 보강
- 자율 LOOP 및 감사: TODO 기반 반복, 실제 행 번호 유지, CLI 도움말·인자 검증, 문서와 테스트 감사
- 품질 게이트 LOOP: `npm run verify`로 대표 명령과 기대 종료 코드를 자동 검증
- fixture LOOP: 사용자 예제와 고정 검증 데이터 분리, 기대값 문서화와 `expectations.js` 단일화
- 릴리스 점검 LOOP: 무설치 실행, 패키지 메타데이터, 구조와 오류 처리 문서 검토

## 남은 리스크

- 파일 전체를 메모리에 읽으므로 매우 큰 CSV에는 적합하지 않습니다.
- JavaScript `Number`를 사용하므로 매우 큰 금액이나 정밀한 통화 계산에는 오차 가능성이 있습니다.
- 자체 CSV 파서는 현재 요구에는 충분하지만 모든 CSV 변형을 완전히 지원하는 범용 파서는 아닙니다.
- Windows에서 검증했으며 다른 운영체제에서는 별도의 실제 실행 확인이 필요합니다.
- 자식 프로세스를 제한하는 샌드박스에서는 품질 게이트 실행 권한이 필요할 수 있습니다.

## 다음 개선 후보

- 대용량 파일을 위한 스트리밍 처리
- 금액 정밀도를 보장하는 정수 최소 단위 또는 decimal 처리
- Windows와 Linux를 포함한 CI 구성
- 테스트 케이스 이름과 구획을 명시하는 테스트 러너 도입
- fixture 문서와 기대값의 자동 일치 검사

이 후보들은 현재 범위에 포함되지 않습니다. 새 작업에서는 기존 CLI 계약과 `npm run verify` 통과를 우선 보존해야 합니다.
