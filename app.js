const fs = require('fs');
const path = require('path');

function parseCsv(text) {
  const normalizedText = text.startsWith('\uFEFF') ? text.slice(1) : text;
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;

  for (let i = 0; i < normalizedText.length; i += 1) {
    const char = normalizedText[i];

    if (quoted) {
      if (char === '"' && normalizedText[i + 1] === '"') {
        field += '"';
        i += 1;
      } else if (char === '"') {
        quoted = false;
      } else {
        field += char;
      }
    } else if (char === '"') {
      quoted = true;
    } else if (char === ',') {
      row.push(field);
      field = '';
    } else if (char === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else if (char !== '\r') {
      field += char;
    }
  }

  if (quoted) {
    throw new Error('CSV의 따옴표가 닫히지 않았습니다.');
  }

  if (field !== '' || row.length > 0) {
    row.push(field);
    rows.push(row);
  }

  return rows;
}

function summarizeAmounts(rows, warn = () => {}) {
  const nonEmptyRows = rows
    .map((row, index) => ({ row, rowNumber: index + 1 }))
    .filter(({ row }) => row.some((field) => field.trim() !== ''));

  if (nonEmptyRows.length === 0) {
    throw new Error('CSV 파일이 비어 있습니다.');
  }

  const headers = nonEmptyRows[0].row.map((header) => header.trim());
  const amountIndex = headers.indexOf('amount');

  if (amountIndex === -1) {
    throw new Error('amount 컬럼을 찾을 수 없습니다.');
  }

  return nonEmptyRows.slice(1).reduce((result, entry) => {
    const { row, rowNumber } = entry;
    const value = (row[amountIndex] ?? '').trim();
    const amount = Number(value);

    if (value === '' || !Number.isFinite(amount)) {
      warn(`경고: ${rowNumber}행의 amount 값이 올바른 숫자가 아닙니다: ${value || '(빈 값)'}`);
      result.errorCount += 1;
      return result;
    }

    result.total += amount;
    return result;
  }, { total: 0, errorCount: 0 });
}

function formatResult(summary) {
  return `amount 합계: ${summary.total}, 오류 행 수: ${summary.errorCount}`;
}

function formatJsonResult(summary, warnings) {
  const result = { ...summary };
  if (warnings.length > 0) {
    result.warnings = warnings;
  }
  return JSON.stringify(result, null, 2);
}

function sumAmount(csvText, warn = () => {}) {
  return summarizeAmounts(parseCsv(csvText), warn);
}

function runCli(filePath = 'input.csv', output = console, options = {}) {
  const inputPath = path.resolve(filePath);
  let csvText;

  try {
    csvText = fs.readFileSync(inputPath, 'utf8');
  } catch (error) {
    if (error.code === 'ENOENT') {
      throw new Error(`CSV 파일을 찾을 수 없습니다: ${filePath}`);
    }
    throw error;
  }

  const warnings = [];
  const result = sumAmount(csvText, (message) => {
    if (options.json) {
      warnings.push(message);
    } else {
      output.warn(message);
    }
  });
  output.log(options.json ? formatJsonResult(result, warnings) : formatResult(result));
}

function executeCli(filePath, output = console, options = {}) {
  try {
    runCli(filePath, output, options);
    return 0;
  } catch (error) {
    output.error(`오류: ${error.message}`);
    return 1;
  }
}

function parseCliArgs(args) {
  const unknownOption = args.find((arg) => arg.startsWith('-') && !['--json', '--help', '-h'].includes(arg));
  if (unknownOption) {
    throw new Error(`알 수 없는 옵션입니다: ${unknownOption}`);
  }

  const filePaths = args.filter((arg) => !arg.startsWith('-'));
  if (filePaths.length > 1) {
    throw new Error('CSV 파일은 하나만 지정할 수 있습니다.');
  }

  return {
    filePath: filePaths[0] || 'input.csv',
    json: args.includes('--json'),
    help: args.includes('--help') || args.includes('-h'),
  };
}

function formatHelp() {
  return [
    '사용법: node app.js [CSV 파일] [--json]',
    '',
    '옵션:',
    '  --json      결과를 JSON으로 출력합니다.',
    '  -h, --help  도움말을 출력합니다.',
  ].join('\n');
}

function executeArgs(args, output = console) {
  try {
    const options = parseCliArgs(args);
    if (options.help) {
      output.log(formatHelp());
      return 0;
    }
    return executeCli(options.filePath, output, options);
  } catch (error) {
    output.error(`오류: ${error.message}`);
    return 1;
  }
}

if (require.main === module) {
  process.exitCode = executeArgs(process.argv.slice(2));
}

module.exports = {
  parseCsv,
  summarizeAmounts,
  formatResult,
  formatJsonResult,
  sumAmount,
  runCli,
  executeCli,
  parseCliArgs,
  formatHelp,
  executeArgs,
};
