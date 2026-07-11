const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const {
  parseCsv,
  summarizeAmounts,
  formatResult,
  formatJsonResult,
  formatSummaryResult,
  escapeCsvValue,
  formatCsvResult,
  sumAmount,
  runCli,
  executeCli,
  parseCliArgs,
  executeArgs,
} = require('./app');
const FIXTURES = require('./fixtures/expectations');

const fixturePath = (fixture) => path.resolve(__dirname, fixture.path);
const validFixturePath = fixturePath(FIXTURES.valid);
const invalidAmountFixturePath = fixturePath(FIXTURES.invalidAmount);
const missingAmountColumnFixturePath = fixturePath(FIXTURES.missingAmountColumn);

function captureOutput() {
  const messages = { logs: [], warnings: [], errors: [] };
  return {
    messages,
    output: {
      log: (message) => messages.logs.push(message),
      warn: (message) => messages.warnings.push(message),
      error: (message) => messages.errors.push(message),
    },
  };
}

assert.deepStrictEqual(parseCsv('item,amount\r\n"A, large",10\r\n'), [
  ['item', 'amount'],
  ['A, large', '10'],
]);
assert.throws(() => parseCsv('item,amount\n"A,10\n'), /따옴표가 닫히지 않았습니다/);
assert.deepStrictEqual(parseCsv('\uFEFFitem,amount\nA,10\n'), [
  ['item', 'amount'],
  ['A', '10'],
]);

assert.deepStrictEqual(
  summarizeAmounts([['item', 'amount'], ['A', '10'], ['B', '20.5']]),
  { total: 30.5, errorCount: 0 },
);
assert.throws(() => summarizeAmounts([['item', 'price'], ['A', '10']]), /amount 컬럼/);

const warnings = [];
assert.deepStrictEqual(
  summarizeAmounts(
    [['item', 'amount'], ['A', '10'], ['B', 'abc'], ['C', ''], ['D', '20']],
    (message) => warnings.push(message),
  ),
  { total: 30, errorCount: 2 },
);
assert.deepStrictEqual(warnings, [
  '경고: 3행의 amount 값이 올바른 숫자가 아닙니다: abc',
  '경고: 4행의 amount 값이 올바른 숫자가 아닙니다: (빈 값)',
]);

const blankLineWarnings = [];
assert.deepStrictEqual(
  sumAmount('item,amount\nA,10\n\nB,invalid\n', (message) => blankLineWarnings.push(message)),
  { total: 10, errorCount: 1 },
);
assert.deepStrictEqual(blankLineWarnings, [
  '경고: 4행의 amount 값이 올바른 숫자가 아닙니다: invalid',
]);

assert.strictEqual(
  formatResult({ total: 30, errorCount: 2 }),
  'amount 합계: 30, 오류 행 수: 2',
);
assert.strictEqual(
  formatJsonResult({ total: 10, errorCount: 0 }, []),
  '{\n  "total": 10,\n  "errorCount": 0\n}',
);
assert.strictEqual(
  formatSummaryResult({ total: 30.5, errorCount: 2 }, ['경고 1', '경고 2']),
  'CSV 처리 요약\n- 합계: 30.5\n- 오류 행 수: 2\n- 경고 수: 2',
);
assert.strictEqual(escapeCsvValue('plain'), 'plain');
assert.strictEqual(escapeCsvValue('comma,value'), '"comma,value"');
assert.strictEqual(escapeCsvValue('quote"value'), '"quote""value"');
assert.strictEqual(escapeCsvValue('line\nbreak'), '"line\nbreak"');
assert.strictEqual(
  formatCsvResult({ total: 30.5, errorCount: 2 }, ['경고 1', '경고 2']),
  'total,errorCount,warningCount\n30.5,2,2',
);
assert.deepStrictEqual(parseCliArgs(['input.csv', '--json']), {
  filePath: 'input.csv', json: true, summary: false, csv: false, help: false,
});
assert.deepStrictEqual(parseCliArgs(['--json', 'input.csv']), {
  filePath: 'input.csv', json: true, summary: false, csv: false, help: false,
});
assert.deepStrictEqual(parseCliArgs(['input.csv', '--summary']), {
  filePath: 'input.csv', json: false, summary: true, csv: false, help: false,
});
assert.deepStrictEqual(parseCliArgs(['input.csv', '--summary', '--csv']), {
  filePath: 'input.csv', json: false, summary: true, csv: true, help: false,
});
assert.deepStrictEqual(parseCliArgs([]), {
  filePath: 'input.csv', json: false, summary: false, csv: false, help: false,
});
assert.throws(() => parseCliArgs(['first.csv', 'second.csv']), /하나만 지정/);
assert.throws(() => parseCliArgs(['--json', '--summary']), /함께 사용할 수 없습니다/);
assert.throws(() => parseCliArgs(['--json', '--csv']), /함께 사용할 수 없습니다/);
assert.throws(() => sumAmount('  \n\r\n'), /CSV 파일이 비어 있습니다/);

const helpCapture = captureOutput();
assert.strictEqual(executeArgs(['--help'], helpCapture.output), 0);
assert.match(helpCapture.messages.logs[0], /사용법:/);

const invalidOptionCapture = captureOutput();
assert.strictEqual(executeArgs(['--unknown'], invalidOptionCapture.output), 1);
assert.deepStrictEqual(invalidOptionCapture.messages.errors, ['오류: 알 수 없는 옵션입니다: --unknown']);

assert.deepStrictEqual(sumAmount('item,amount\n"A, large",10\nB,-3\n'), { total: 7, errorCount: 0 });
assert.deepStrictEqual(sumAmount('item,amount\nA, 1000 \n'), { total: 1000, errorCount: 0 });
assert.deepStrictEqual(sumAmount('item,amount\nA,1000.5\n'), { total: 1000.5, errorCount: 0 });
assert.deepStrictEqual(sumAmount('item,amount\nA,-500\n'), { total: -500, errorCount: 0 });
assert.deepStrictEqual(sumAmount('\uFEFFitem,amount\nA,1000\n'), { total: 1000, errorCount: 0 });

const invalidFixtureCapture = captureOutput();
runCli(invalidAmountFixturePath, invalidFixtureCapture.output);
assert.deepStrictEqual(invalidFixtureCapture.messages.logs, [
  `amount 합계: ${FIXTURES.invalidAmount.total}, 오류 행 수: ${FIXTURES.invalidAmount.errorCount}`,
]);
assert.strictEqual(invalidFixtureCapture.messages.warnings.length, FIXTURES.invalidAmount.warningCount);
assert.match(invalidFixtureCapture.messages.warnings[0], /경고: 3행/);
assert.match(invalidFixtureCapture.messages.warnings[1], /경고: 4행/);

const jsonCapture = captureOutput();
runCli(invalidAmountFixturePath, jsonCapture.output, { json: true });
assert.deepStrictEqual(jsonCapture.messages.warnings, []);
assert.deepStrictEqual(jsonCapture.messages.errors, []);
assert.deepStrictEqual(JSON.parse(jsonCapture.messages.logs[0]), {
  total: FIXTURES.invalidAmount.total,
  errorCount: FIXTURES.invalidAmount.errorCount,
  warnings: [
    '경고: 3행의 amount 값이 올바른 숫자가 아닙니다: abc',
    '경고: 4행의 amount 값이 올바른 숫자가 아닙니다: (빈 값)',
  ],
});

const summaryCapture = captureOutput();
runCli(invalidAmountFixturePath, summaryCapture.output, { summary: true });
assert.deepStrictEqual(summaryCapture.messages.logs, [
  `CSV 처리 요약\n- 합계: ${FIXTURES.invalidAmount.total}\n- 오류 행 수: ${FIXTURES.invalidAmount.errorCount}\n- 경고 수: ${FIXTURES.invalidAmount.warningCount}`,
]);
assert.deepStrictEqual(summaryCapture.messages.warnings, []);
assert.deepStrictEqual(summaryCapture.messages.errors, []);

const csvCapture = captureOutput();
runCli(invalidAmountFixturePath, csvCapture.output, { summary: true, csv: true });
assert.deepStrictEqual(csvCapture.messages.logs, [
  `total,errorCount,warningCount\n${FIXTURES.invalidAmount.total},${FIXTURES.invalidAmount.errorCount},${FIXTURES.invalidAmount.warningCount}`,
]);
assert.deepStrictEqual(csvCapture.messages.warnings, []);
assert.deepStrictEqual(csvCapture.messages.errors, []);

const tempDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'csv-amount-test-'));
try {
  const otherCapture = captureOutput();
  runCli(validFixturePath, otherCapture.output);
  assert.deepStrictEqual(otherCapture.messages.logs, [
    `amount 합계: ${FIXTURES.valid.total}, 오류 행 수: ${FIXTURES.valid.errorCount}`,
  ]);
  assert.deepStrictEqual(otherCapture.messages.warnings, []);

  const otherJsonCapture = captureOutput();
  runCli(validFixturePath, otherJsonCapture.output, { json: true });
  assert.deepStrictEqual(JSON.parse(otherJsonCapture.messages.logs[0]), {
    total: FIXTURES.valid.total,
    errorCount: FIXTURES.valid.errorCount,
  });
  assert.deepStrictEqual(otherJsonCapture.messages.warnings, []);

  const bomCsvPath = path.join(tempDirectory, 'bom.csv');
  fs.writeFileSync(bomCsvPath, '\uFEFFitem,amount\nA, 1000.5 \nB,-500\n', 'utf8');
  const bomCapture = captureOutput();
  assert.strictEqual(executeArgs([bomCsvPath, '--json'], bomCapture.output), 0);
  assert.deepStrictEqual(JSON.parse(bomCapture.messages.logs[0]), { total: 500.5, errorCount: 0 });

  const missingPath = path.join(tempDirectory, 'missing.csv');
  const missingCapture = captureOutput();
  assert.strictEqual(executeCli(missingPath, missingCapture.output, { json: true }), 1);
  assert.strictEqual(missingCapture.messages.errors.length, 1);
  assert.match(missingCapture.messages.errors[0], /오류: CSV 파일을 찾을 수 없습니다:/);
  assert.match(missingCapture.messages.errors[0], /missing\.csv/);

  const noAmountCapture = captureOutput();
  assert.strictEqual(
    executeCli(missingAmountColumnFixturePath, noAmountCapture.output),
    FIXTURES.missingAmountColumn.expectedStatus,
  );
  assert.deepStrictEqual(noAmountCapture.messages.errors, [
    `오류: ${FIXTURES.missingAmountColumn.errorMessage}`,
  ]);
} finally {
  fs.rmSync(tempDirectory, { recursive: true, force: true });
}

console.log('모든 테스트 통과');
