const fs = require('fs');
const path = require('path');
const rowsWithQuotedFields = new WeakSet();

function parseCsv(text) {
  const normalizedText = text.startsWith('\uFEFF') ? text.slice(1) : text;
  const rows = [];
  let row = [];
  let field = '';
  let fieldStarted = false;
  let rowHasQuotedField = false;
  let quoted = false;
  let quotedFieldClosed = false;

  for (let i = 0; i < normalizedText.length; i += 1) {
    const char = normalizedText[i];

    if (quoted) {
      if (char === '"' && normalizedText[i + 1] === '"') {
        field += '"';
        i += 1;
      } else if (char === '"') {
        quoted = false;
        quotedFieldClosed = true;
      } else {
        field += char;
      }
    } else if (quotedFieldClosed && char !== ',' && char !== '\n' && char !== '\r') {
      throw new Error('CSV의 따옴표 형식이 올바르지 않습니다.');
    } else if (char === '"') {
      fieldStarted = true;
      rowHasQuotedField = true;
      quoted = true;
    } else if (char === ',') {
      row.push(field);
      field = '';
      fieldStarted = false;
      quotedFieldClosed = false;
    } else if (char === '\n' || char === '\r') {
      row.push(field);
      if (rowHasQuotedField) rowsWithQuotedFields.add(row);
      rows.push(row);
      row = [];
      field = '';
      fieldStarted = false;
      rowHasQuotedField = false;
      quotedFieldClosed = false;
      if (char === '\r' && normalizedText[i + 1] === '\n') {
        i += 1;
      }
    } else {
      field += char;
      fieldStarted = true;
    }
  }

  if (quoted) {
    throw new Error('CSV의 따옴표가 닫히지 않았습니다.');
  }

  if (fieldStarted || row.length > 0) {
    row.push(field);
    if (rowHasQuotedField) rowsWithQuotedFields.add(row);
    rows.push(row);
  }

  return rows;
}

function summarizeAmounts(rows, warn = () => {}) {
  const nonEmptyRows = rows
    .map((row, index) => ({ row, rowNumber: index + 1 }))
    .filter(({ row }) => (
      rowsWithQuotedFields.has(row) || row.some((field) => field.trim() !== '')
    ));

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

function formatSummaryResult(summary, warnings) {
  return [
    'CSV 처리 요약',
    `- 합계: ${summary.total}`,
    `- 오류 행 수: ${summary.errorCount}`,
    `- 경고 수: ${warnings.length}`,
  ].join('\n');
}

function escapeCsvValue(value) {
  const text = String(value);
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function formatCsvResult(summary, warnings) {
  const headers = ['total', 'errorCount', 'warningCount'];
  const values = [summary.total, summary.errorCount, warnings.length];
  return [headers, values]
    .map((row) => row.map(escapeCsvValue).join(','))
    .join('\n');
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
    if (options.json || options.summary || options.csv) {
      warnings.push(message);
    } else {
      output.warn(message);
    }
  });
  if (options.csv) {
    output.log(formatCsvResult(result, warnings));
  } else if (options.json) {
    output.log(formatJsonResult(result, warnings));
  } else if (options.summary) {
    output.log(formatSummaryResult(result, warnings));
  } else {
    output.log(formatResult(result));
  }
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
  const knownOptions = ['--json', '--summary', '--csv', '--help', '-h'];
  const unknownOption = args.find((arg) => arg.startsWith('-') && !knownOptions.includes(arg));
  if (unknownOption) {
    throw new Error(`알 수 없는 옵션입니다: ${unknownOption}`);
  }

  const filePaths = args.filter((arg) => !arg.startsWith('-'));
  if (filePaths.length > 1) {
    throw new Error('CSV 파일은 하나만 지정할 수 있습니다.');
  }

  if (args.includes('--json') && args.includes('--summary') && !args.includes('--csv')) {
    throw new Error('--json과 --summary는 함께 사용할 수 없습니다.');
  }

  return {
    filePath: filePaths[0] || 'input.csv',
    json: args.includes('--json'),
    summary: args.includes('--summary'),
    csv: args.includes('--csv'),
    help: args.includes('--help') || args.includes('-h'),
  };
}

function formatHelp() {
  return [
    '사용법: node app.js [CSV 파일] [--json | --summary | --csv]',
    '',
    '옵션:',
    '  --json      결과를 JSON으로 출력합니다.',
    '  --summary   결과를 사람이 읽기 좋은 요약으로 출력합니다.',
    '  --csv       결과를 CSV 요약으로 출력합니다. 다른 출력 옵션보다 우선합니다.',
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
  formatSummaryResult,
  escapeCsvValue,
  formatCsvResult,
  sumAmount,
  runCli,
  executeCli,
  parseCliArgs,
  formatHelp,
  executeArgs,
};
