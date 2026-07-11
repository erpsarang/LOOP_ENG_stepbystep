const { spawnSync } = require('child_process');
const path = require('path');
const FIXTURES = require('./fixtures/expectations');

const projectDirectory = __dirname;
const nodeCommand = process.execPath;
const npmCommand = process.platform === 'win32' ? process.env.ComSpec : 'npm';
const npmTestArgs = process.platform === 'win32' ? ['/d', '/s', '/c', 'npm test'] : ['test'];
const checks = [
  {
    name: '단위 및 통합 테스트',
    displayCommand: 'npm test',
    command: npmCommand,
    args: npmTestArgs,
    expectedStatus: 0,
    validate: ({ stdout }) => stdout.includes('모든 테스트 통과')
      ? null
      : '테스트 성공 메시지를 찾을 수 없습니다.',
  },
  {
    name: '일반 CLI 출력',
    displayCommand: `node app.js ${FIXTURES.valid.path}`,
    fixture: FIXTURES.valid.path,
    command: nodeCommand,
    args: ['app.js', FIXTURES.valid.path],
    expectedStatus: FIXTURES.valid.expectedStatus,
    validate: ({ stdout }) => stdout.includes(
      `amount 합계: ${FIXTURES.valid.total}, 오류 행 수: ${FIXTURES.valid.errorCount}`,
    )
      ? null
      : '예상 합계와 오류 행 수를 찾을 수 없습니다.',
  },
  {
    name: 'JSON CLI 출력',
    displayCommand: `node app.js ${FIXTURES.invalidAmount.path} --json`,
    fixture: FIXTURES.invalidAmount.path,
    command: nodeCommand,
    args: ['app.js', FIXTURES.invalidAmount.path, '--json'],
    expectedStatus: FIXTURES.invalidAmount.expectedStatus,
    validate: ({ stdout }) => {
      try {
        const result = JSON.parse(stdout);
        if (
          result.total !== FIXTURES.invalidAmount.total
          || result.errorCount !== FIXTURES.invalidAmount.errorCount
          || result.warnings?.length !== FIXTURES.invalidAmount.warningCount
        ) {
          return 'JSON 결과의 합계, 오류 행 수 또는 warnings가 예상과 다릅니다.';
        }
        return null;
      } catch (error) {
        return `stdout을 JSON으로 파싱할 수 없습니다: ${error.message}`;
      }
    },
  },
  {
    name: '누락 파일 오류',
    displayCommand: 'node app.js missing.csv',
    command: nodeCommand,
    args: ['app.js', 'missing.csv'],
    expectedStatus: 1,
    validate: ({ stderr }) => stderr.includes('CSV 파일을 찾을 수 없습니다: missing.csv')
      ? null
      : '누락 파일 오류 메시지를 찾을 수 없습니다.',
  },
  {
    name: '요약 CLI 출력',
    displayCommand: `node app.js ${FIXTURES.invalidAmount.path} --summary`,
    fixture: FIXTURES.invalidAmount.path,
    command: nodeCommand,
    args: ['app.js', FIXTURES.invalidAmount.path, '--summary'],
    expectedStatus: FIXTURES.invalidAmount.expectedStatus,
    validate: ({ stdout, stderr }) => {
      const expected = [
        'CSV 처리 요약',
        `- 합계: ${FIXTURES.invalidAmount.total}`,
        `- 오류 행 수: ${FIXTURES.invalidAmount.errorCount}`,
        `- 경고 수: ${FIXTURES.invalidAmount.warningCount}`,
      ].join('\n');
      return stdout.trim() === expected && stderr.trim() === ''
        ? null
        : '요약 출력 또는 stderr가 예상과 다릅니다.';
    },
  },
  {
    name: 'CSV CLI 출력과 summary 조합',
    displayCommand: `node app.js ${FIXTURES.invalidAmount.path} --summary --csv`,
    fixture: FIXTURES.invalidAmount.path,
    command: nodeCommand,
    args: ['app.js', FIXTURES.invalidAmount.path, '--summary', '--csv'],
    expectedStatus: FIXTURES.invalidAmount.expectedStatus,
    validate: ({ stdout, stderr }) => {
      const expected = [
        'total,errorCount,warningCount',
        `${FIXTURES.invalidAmount.total},${FIXTURES.invalidAmount.errorCount},${FIXTURES.invalidAmount.warningCount}`,
      ].join('\n');
      return stdout.trim() === expected && stderr.trim() === ''
        ? null
        : 'CSV 헤더·데이터 행 또는 stderr가 예상과 다릅니다.';
    },
  },
  {
    name: 'CSV CLI 출력과 JSON 조합',
    displayCommand: `node app.js ${FIXTURES.invalidAmount.path} --json --csv`,
    fixture: FIXTURES.invalidAmount.path,
    command: nodeCommand,
    args: ['app.js', FIXTURES.invalidAmount.path, '--json', '--csv'],
    expectedStatus: FIXTURES.invalidAmount.expectedStatus,
    validate: ({ stdout, stderr }) => {
      const expected = [
        'total,errorCount,warningCount',
        `${FIXTURES.invalidAmount.total},${FIXTURES.invalidAmount.errorCount},${FIXTURES.invalidAmount.warningCount}`,
      ].join('\n');
      return stdout.trim() === expected && stderr.trim() === ''
        ? null
        : 'JSON 조합에서 CSV 우선 출력 또는 stderr가 예상과 다릅니다.';
    },
  },
  {
    name: 'amount 컬럼 누락 오류',
    displayCommand: `node app.js ${FIXTURES.missingAmountColumn.path}`,
    fixture: FIXTURES.missingAmountColumn.path,
    command: nodeCommand,
    args: ['app.js', FIXTURES.missingAmountColumn.path],
    expectedStatus: FIXTURES.missingAmountColumn.expectedStatus,
    validate: ({ stderr }) => stderr.includes(FIXTURES.missingAmountColumn.errorMessage)
      ? null
      : 'amount 컬럼 누락 오류 메시지를 찾을 수 없습니다.',
  },
  {
    name: 'CLI 도움말',
    displayCommand: 'node app.js --help',
    command: nodeCommand,
    args: ['app.js', '--help'],
    expectedStatus: 0,
    validate: ({ stdout }) => stdout.includes('사용법: node app.js [CSV 파일] [--json | --summary | --csv]')
      ? null
      : '도움말 사용법을 찾을 수 없습니다.',
  },
];

function runCheck(check) {
  const result = spawnSync(check.command, check.args, {
    cwd: projectDirectory,
    encoding: 'utf8',
    windowsHide: true,
  });

  let failure = null;
  if (result.error) {
    failure = `명령을 실행하지 못했습니다: ${result.error.message}`;
  } else if (result.status !== check.expectedStatus) {
    failure = `종료 코드 ${check.expectedStatus}을(를) 예상했지만 ${result.status}이(가) 반환되었습니다.`;
  } else {
    failure = check.validate(result);
  }

  const fixtureLabel = check.fixture ? ` [fixture: ${check.fixture}]` : '';

  if (failure) {
    console.error(`[FAIL] ${check.name}${fixtureLabel} — ${check.displayCommand}`);
    console.error(`       ${failure}`);
    if (result.stdout && result.stdout.trim()) console.error(`       stdout: ${result.stdout.trim()}`);
    if (result.stderr && result.stderr.trim()) console.error(`       stderr: ${result.stderr.trim()}`);
    return false;
  }

  console.log(`[PASS] ${check.name}${fixtureLabel} — ${check.displayCommand} (종료 코드 ${result.status})`);
  return true;
}

console.log('CSV amount CLI 품질 게이트를 시작합니다.');
const passedCount = checks.filter(runCheck).length;
const failedCount = checks.length - passedCount;

if (failedCount > 0) {
  console.error(`품질 게이트 실패: 성공 ${passedCount}개, 실패 ${failedCount}개`);
  process.exitCode = 1;
} else {
  console.log(`품질 게이트 통과: ${passedCount}개 검증 모두 성공`);
}
