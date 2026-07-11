# CSV amount 합계 CLI

외부 npm 패키지 없이 Node.js 표준 모듈만 사용해 CSV 파일의 유효한 `amount` 값 합계와 오류 행 수를 계산합니다.

프로젝트 운영, 검증 체계와 개선 이력은 [HANDOFF.md](HANDOFF.md)에서 확인할 수 있습니다.

## 요구 사항과 준비

- Node.js 14.14 이상
- 첫 행에 `amount` 헤더가 있는 CSV 파일

외부 패키지를 사용하지 않으므로 `npm install`은 필요하지 않습니다. 프로젝트 파일을 받은 뒤 Node.js가 설치된 터미널에서 바로 실행할 수 있습니다.

## 지원하는 입력 형식

- `amount` 앞뒤 공백: ` 1000 `
- 정수와 소수: `1000`, `1000.5`
- 음수: `-500`
- UTF-8 및 UTF-8 BOM 파일

`amount` 컬럼이 없으면 `오류: amount 컬럼을 찾을 수 없습니다.`를 출력하고 종료 코드 `1`로 끝납니다.

## 실행

기본 예제 파일인 `input.csv`를 계산합니다.

```powershell
node app.js
```

파일 경로를 명시하거나 npm 스크립트를 사용할 수도 있습니다.

```powershell
node app.js input.csv
npm start
```

도움말은 다음 명령으로 확인합니다.

```powershell
node app.js --help
```

입력 CSV는 한 번에 하나만 지정할 수 있습니다. 알 수 없는 옵션이나 여러 파일 경로를 전달하면 오류 메시지와 함께 종료 코드 `1`로 끝납니다.

`amount` 값이 비어 있거나 숫자가 아니면 해당 행을 합계에서 제외하고 실제 CSV 행 번호가 포함된 경고를 출력합니다. 빈 행은 계산에서 무시하며, 실행 결과에는 정상 합계와 오류 행 수가 함께 표시됩니다.

```text
경고: 5행의 amount 값이 올바른 숫자가 아닙니다: unknown
경고: 6행의 amount 값이 올바른 숫자가 아닙니다: (빈 값)
amount 합계: 18000, 오류 행 수: 2
```

다른 CSV 파일을 계산하려면 경로를 인자로 전달합니다.

```powershell
node app.js path/to/data.csv
```

## JSON 출력

`--json` 옵션을 사용하면 자동화 도구에서 처리하기 쉬운 JSON 형식으로 출력합니다.

```powershell
node app.js input.csv --json
```

잘못된 데이터의 경고는 별도 출력과 섞이지 않고 `warnings` 배열에 포함됩니다. 경고가 없으면 이 배열은 생략됩니다.

```json
{
  "total": 18000,
  "errorCount": 2,
  "warnings": [
    "경고: 5행의 amount 값이 올바른 숫자가 아닙니다: unknown",
    "경고: 6행의 amount 값이 올바른 숫자가 아닙니다: (빈 값)"
  ]
}
```

## 요약 출력

`--summary` 옵션은 개별 경고 메시지 대신 경고 수를 포함한 사람이 읽기 좋은 요약을 출력합니다.

```powershell
node app.js fixtures/invalid-amount.csv --summary
```

```text
CSV 처리 요약
- 합계: 30.5
- 오류 행 수: 2
- 경고 수: 2
```

`--json`과 `--summary`는 출력 형식 옵션이므로 함께 사용할 수 없습니다.

## CSV 요약 출력

`--csv` 옵션은 합계, 오류 행 수와 경고 수를 헤더와 단일 데이터 행으로 출력합니다. `--summary`와 함께 지정해도 CSV 출력이 우선됩니다.

```powershell
node app.js fixtures/invalid-amount.csv --csv
node app.js fixtures/invalid-amount.csv --summary --csv
```

```csv
total,errorCount,warningCount
30.5,2,2
```

CSV 필드에 콤마, 큰따옴표 또는 줄바꿈이 포함되면 필드를 큰따옴표로 감싸고 내부 큰따옴표를 두 번 써서 안전하게 출력합니다. `--json`과 `--csv`는 함께 사용할 수 없습니다.

지정한 파일이 없으면 친절한 오류를 출력하고 종료 코드 `1`로 끝납니다.

```text
오류: CSV 파일을 찾을 수 없습니다: missing.csv
```

대표적인 오류 처리는 다음과 같습니다.

| 상황 | 처리 |
| --- | --- |
| 파일 없음 | 오류 메시지 출력 후 종료 코드 `1` |
| `amount` 컬럼 없음 | 오류 메시지 출력 후 종료 코드 `1` |
| 닫히지 않은 CSV 따옴표 | 오류 메시지 출력 후 종료 코드 `1` |
| 빈 값 또는 숫자가 아닌 `amount` | 해당 행을 제외하고 경고 및 오류 행 수에 포함 |
| 알 수 없는 옵션 또는 여러 파일 경로 | 오류 메시지 출력 후 종료 코드 `1` |

## 테스트

```powershell
npm test
```

`node test.js`로도 같은 테스트를 실행할 수 있습니다. 테스트 범위에는 다음 항목이 포함됩니다.

- 기본 파일과 별도 CSV 경로
- 일반 출력과 JSON·summary·CSV 출력
- 존재하지 않는 파일과 `amount` 컬럼 누락
- 공백, 소수, 음수, BOM, 빈 CSV와 빈 행
- 도움말, 옵션 순서, 잘못된 옵션과 복수 파일 인자

## 전체 품질 검증

배포나 변경 완료 전에 전체 품질 게이트를 한 명령으로 실행할 수 있습니다.

```powershell
npm run verify
```

이 명령은 테스트, 일반 출력, JSON 파싱, summary 출력, CSV 출력과 summary 조합, 누락 파일, `amount` 컬럼 누락, 도움말을 검증합니다. 예상된 오류의 종료 코드 `1`도 정확히 판정합니다. 각 항목의 성공 또는 실패와 최종 집계를 출력하며 하나라도 실패하면 종료 코드 `1`로 끝납니다.

## 예제와 테스트 데이터

- `input.csv`: 사용자가 CLI를 바로 실행해보는 예제 파일입니다. 기본 경로로 계속 사용됩니다.
- `fixtures/`: 테스트와 품질 검증이 사용하는 고정 CSV 데이터입니다.
  - `valid.csv`: 공백, 소수, 음수를 포함한 유효 금액 데이터
  - `invalid-amount.csv`: 숫자가 아닌 값과 빈 금액을 포함한 데이터
  - `missing-amount-column.csv`: `amount` 컬럼이 없는 데이터

자동 검증의 기대값은 fixture를 기준으로 하므로 사용자가 `input.csv`의 예제 내용을 바꾸더라도 테스트 결과에 직접 영향을 주지 않습니다.
각 파일의 상세 목적과 기대 결과는 `fixtures/README.md`에 정리되어 있습니다.

## 프로젝트 구조

- `app.js`: CSV 처리 함수와 CLI 진입점
- `input.csv`: 사용자가 실행해보는 기본 예제
- `test.js`: 함수 및 파일 처리 회귀 테스트
- `verify.js`: 전체 품질 게이트 실행기
- `package.json`: 프로젝트 정보와 `start`, `test`, `verify` 스크립트
- `fixtures/`: 고정 테스트 데이터, 기대값 모듈, fixture 설명
- `LOOP_PLAN.md`, `LOOP_LOG.md`: 개선 계획과 실행 이력

주요 코드 함수는 다음과 같습니다.

- `parseCsv(text)`: CSV 문자열을 행과 필드 배열로 변환합니다.
- `summarizeAmounts(rows)`: 유효한 `amount`를 합산하고 오류 행 수를 집계합니다.
- `formatResult(summary)`: 계산 결과를 CLI 출력 문자열로 만듭니다.
- `formatJsonResult(summary, warnings)`: 계산 결과와 경고를 JSON 문자열로 만듭니다.
- `formatCsvResult(summary, warnings)`: 계산 결과와 경고 수를 CSV 헤더와 단일 행으로 만듭니다.
- `sumAmount(csvText)`: 위 파싱과 집계 함수를 조합해 기존 호출 방식을 유지합니다.
- `executeArgs(args)`: CLI 인자를 검증하고 도움말 또는 파일 처리를 실행합니다.

숫자가 아닌 값과 빈 값은 경고 후 합계에서 제외합니다. `amount` 컬럼 누락과 잘못 닫힌 따옴표처럼 파일을 처리할 수 없는 경우에는 오류로 종료합니다. 따옴표로 감싼 필드와 필드 안의 쉼표도 지원합니다.
