const FIXTURES = {
  valid: {
    path: 'fixtures/valid.csv',
    purpose: '지원되는 정상 amount 형식 검증',
    total: 1500.5,
    errorCount: 0,
    warningCount: 0,
    expectedStatus: 0,
  },
  invalidAmount: {
    path: 'fixtures/invalid-amount.csv',
    purpose: '잘못된 amount를 제외하고 경고하는 동작 검증',
    total: 30.5,
    errorCount: 2,
    warningCount: 2,
    expectedStatus: 0,
  },
  missingAmountColumn: {
    path: 'fixtures/missing-amount-column.csv',
    purpose: '필수 amount 컬럼 누락 오류 검증',
    total: null,
    errorCount: null,
    warningCount: 0,
    expectedStatus: 1,
    errorMessage: 'amount 컬럼을 찾을 수 없습니다.',
  },
};

module.exports = FIXTURES;
