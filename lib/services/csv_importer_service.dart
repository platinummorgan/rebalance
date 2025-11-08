import 'package:csv/csv.dart';
import '../data/models.dart';

/// Service for importing Accounts, Liabilities, and Income from CSV files
class CsvImporterService {
  /// Parse CSV content and determine data type
  static Future<CsvImportResult> parseCSV(String csvContent) async {
    try {
      final List<List<dynamic>> rows =
          const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty) {
        return CsvImportResult.error('CSV file is empty');
      }

      // First row should be headers
      final headers =
          rows[0].map((e) => e.toString().toLowerCase().trim()).toList();

      // Determine type based on headers
      if (_isAccountCSV(headers)) {
        return _parseAccounts(headers, rows.skip(1).toList());
      } else if (_isLiabilityCSV(headers)) {
        return _parseLiabilities(headers, rows.skip(1).toList());
      } else if (_isIncomeCSV(headers)) {
        return _parseIncome(headers, rows.skip(1).toList());
      } else {
        return CsvImportResult.error(
          'Unable to determine CSV type. Expected headers for Accounts, Liabilities, or Income.\n\n'
          'Found headers: ${headers.join(", ")}',
        );
      }
    } catch (e) {
      return CsvImportResult.error('Error parsing CSV: $e');
    }
  }

  // ==================== TYPE DETECTION ====================

  static bool _isAccountCSV(List<String> headers) {
    return headers.contains('name') &&
        headers.contains('balance') &&
        (headers.contains('kind') || headers.contains('type'));
  }

  static bool _isLiabilityCSV(List<String> headers) {
    return headers.contains('name') &&
        headers.contains('balance') &&
        headers.contains('apr');
  }

  static bool _isIncomeCSV(List<String> headers) {
    return headers.contains('name') &&
        (headers.contains('gross') ||
            headers.contains('grossamount') ||
            headers.contains('gross_amount')) &&
        (headers.contains('frequency'));
  }

  // ==================== ACCOUNT PARSING ====================

  static CsvImportResult _parseAccounts(
    List<String> headers,
    List<List<dynamic>> rows,
  ) {
    final List<Account> accounts = [];
    final List<String> errors = [];

    for (int i = 0; i < rows.length; i++) {
      try {
        final row = rows[i];
        if (row.isEmpty ||
            row.every((cell) => cell.toString().trim().isEmpty)) {
          continue; // Skip empty rows
        }

        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          data[headers[j]] = row[j];
        }

        final account = _createAccount(data);
        accounts.add(account);
      } catch (e) {
        errors.add('Row ${i + 2}: $e');
      }
    }

    if (accounts.isEmpty && errors.isNotEmpty) {
      return CsvImportResult.error(
        'No valid accounts found:\n${errors.join('\n')}',
      );
    }

    return CsvImportResult.success(
      type: 'accounts',
      accounts: accounts,
      errors: errors,
    );
  }

  static Account _createAccount(Map<String, dynamic> data) {
    final String name = _getString(
      data,
      ['name', 'account_name', 'accountname'],
      required: true,
    );
    final double balance =
        _getDouble(data, ['balance', 'amount'], required: true);
    final String kind =
        _getString(data, ['kind', 'type', 'account_type'], required: true);

    // Asset allocation percentages (default to 0 if not provided)
    final double pctCash =
        _getDouble(data, ['cash', 'pct_cash', 'pctcash'], defaultValue: 0.0);
    final double pctBonds =
        _getDouble(data, ['bonds', 'pct_bonds', 'pctbonds'], defaultValue: 0.0);
    final double pctUsEq = _getDouble(
      data,
      ['us_equity', 'pct_us_eq', 'pctuseq', 'us_eq'],
      defaultValue: 0.0,
    );
    final double pctIntlEq = _getDouble(
      data,
      ['intl_equity', 'pct_intl_eq', 'pctintleq', 'intl_eq'],
      defaultValue: 0.0,
    );
    final double pctRealEstate = _getDouble(
      data,
      ['real_estate', 'pct_real_estate', 'pctrealestate'],
      defaultValue: 0.0,
    );
    final double pctAlt = _getDouble(
      data,
      ['alternatives', 'pct_alt', 'pctalt', 'alt'],
      defaultValue: 0.0,
    );

    // If no allocations provided, use defaults based on account type
    bool hasAllocations =
        pctCash + pctBonds + pctUsEq + pctIntlEq + pctRealEstate + pctAlt >
            0.001;

    Map<String, double> allocations = {};
    if (!hasAllocations) {
      final defaults = Account.defaultAllocations[kind] ??
          Account.defaultAllocations['other']!;
      allocations = defaults;
    } else {
      allocations = {
        'cash': pctCash,
        'bonds': pctBonds,
        'usEq': pctUsEq,
        'intlEq': pctIntlEq,
        'realEstate': pctRealEstate,
        'alt': pctAlt,
      };
    }

    final bool isLocked = _getBool(
      data,
      ['locked', 'is_locked', 'islocked'],
      defaultValue: false,
    );
    final double employerStockPct = _getDouble(
      data,
      ['employer_stock', 'employer_stock_pct'],
      defaultValue: 0.0,
    );

    return Account(
      id: '${DateTime.now().millisecondsSinceEpoch}_${name.replaceAll(' ', '_')}',
      name: name,
      kind: _normalizeAccountKind(kind),
      balance: balance,
      pctCash: allocations['cash']!,
      pctBonds: allocations['bonds']!,
      pctUsEq: allocations['usEq']!,
      pctIntlEq: allocations['intlEq']!,
      pctRealEstate: allocations['realEstate']!,
      pctAlt: allocations['alt']!,
      updatedAt: DateTime.now(),
      isLocked: isLocked,
      employerStockPct: employerStockPct,
    );
  }

  static String _normalizeAccountKind(String kind) {
    final normalized = kind.toLowerCase().trim().replaceAll(' ', '_');

    // Map common variations to standard kinds
    final Map<String, String> kindMap = {
      'checking': 'cash',
      'savings': 'savings',
      'brokerage': 'brokerage',
      'investment': 'brokerage',
      'retirement': 'retirement',
      '401k': 'retirement',
      '401(k)': 'retirement',
      'ira': 'retirement',
      'roth': 'retirement',
      'roth_ira': 'retirement',
      'real_estate': 'realEstateEquity',
      'realestate': 'realEstateEquity',
      'hsa': 'hsa',
      '529': '_529',
      'crypto': 'crypto',
      'cryptocurrency': 'crypto',
      'other': 'other',
    };

    return kindMap[normalized] ?? 'other';
  }

  // ==================== LIABILITY PARSING ====================

  static CsvImportResult _parseLiabilities(
    List<String> headers,
    List<List<dynamic>> rows,
  ) {
    final List<Liability> liabilities = [];
    final List<String> errors = [];

    for (int i = 0; i < rows.length; i++) {
      try {
        final row = rows[i];
        if (row.isEmpty ||
            row.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }

        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          data[headers[j]] = row[j];
        }

        final liability = _createLiability(data);
        liabilities.add(liability);
      } catch (e) {
        errors.add('Row ${i + 2}: $e');
      }
    }

    if (liabilities.isEmpty && errors.isNotEmpty) {
      return CsvImportResult.error(
        'No valid liabilities found:\n${errors.join('\n')}',
      );
    }

    return CsvImportResult.success(
      type: 'liabilities',
      liabilities: liabilities,
      errors: errors,
    );
  }

  static Liability _createLiability(Map<String, dynamic> data) {
    final String name =
        _getString(data, ['name', 'liability_name'], required: true);
    final double balance =
        _getDouble(data, ['balance', 'amount'], required: true);
    final double apr =
        _getDouble(data, ['apr', 'interest_rate', 'rate'], required: true);
    final double minPayment = _getDouble(
      data,
      ['min_payment', 'minimum_payment', 'payment'],
      required: true,
    );
    final String kind =
        _getString(data, ['kind', 'type'], defaultValue: 'other');

    final double creditLimit =
        _getDouble(data, ['credit_limit', 'limit'], required: false);

    return Liability(
      id: '${DateTime.now().millisecondsSinceEpoch}_${name.replaceAll(' ', '_')}',
      name: name,
      kind: _normalizeLiabilityKind(kind),
      balance: balance,
      apr: apr,
      minPayment: minPayment,
      updatedAt: DateTime.now(),
      creditLimit: creditLimit,
    );
  }

  static String _normalizeLiabilityKind(String kind) {
    final normalized = kind.toLowerCase().trim().replaceAll(' ', '_');

    final Map<String, String> kindMap = {
      'mortgage': 'mortgage',
      'home_loan': 'mortgage',
      'credit_card': 'creditCard',
      'creditcard': 'creditCard',
      'card': 'creditCard',
      'student_loan': 'studentLoan',
      'studentloan': 'studentLoan',
      'student': 'studentLoan',
      'personal_loan': 'personalLoan',
      'personalloan': 'personalLoan',
      'personal': 'personalLoan',
      'car_loan': 'personalLoan',
      'auto_loan': 'personalLoan',
      'other': 'other',
    };

    return kindMap[normalized] ?? 'other';
  }

  // ==================== INCOME PARSING ====================

  static CsvImportResult _parseIncome(
    List<String> headers,
    List<List<dynamic>> rows,
  ) {
    final List<Income> incomes = [];
    final List<String> errors = [];

    for (int i = 0; i < rows.length; i++) {
      try {
        final row = rows[i];
        if (row.isEmpty ||
            row.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }

        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          data[headers[j]] = row[j];
        }

        final income = _createIncome(data);
        incomes.add(income);
      } catch (e) {
        errors.add('Row ${i + 2}: $e');
      }
    }

    if (incomes.isEmpty && errors.isNotEmpty) {
      return CsvImportResult.error(
        'No valid income found:\n${errors.join('\n')}',
      );
    }

    return CsvImportResult.success(
      type: 'income',
      incomes: incomes,
      errors: errors,
    );
  }

  static Income _createIncome(Map<String, dynamic> data) {
    final String name =
        _getString(data, ['name', 'income_name'], required: true);
    final double grossAmount = _getDouble(
      data,
      ['gross', 'grossamount', 'gross_amount', 'amount'],
      required: true,
    );
    final String frequency =
        _getString(data, ['frequency', 'period'], required: true);
    final String kind =
        _getString(data, ['kind', 'type'], defaultValue: 'other');

    // Optional tax fields
    final double federalTax = _getDouble(
      data,
      ['federal_tax', 'federaltax', 'federal'],
      required: false,
    );
    final double stateTax =
        _getDouble(data, ['state_tax', 'statetax', 'state'], required: false);
    final double socialSecurity = _getDouble(
      data,
      ['social_security', 'socialsecurity', 'ss', 'fica'],
      required: false,
    );
    final double medicare = _getDouble(data, ['medicare'], required: false);
    final double retirement401k = _getDouble(
      data,
      ['401k', 'retirement', '401k_contribution'],
      required: false,
    );
    final double healthInsurance = _getDouble(
      data,
      ['health_insurance', 'healthinsurance', 'health'],
      required: false,
    );
    final double otherDeductions = _getDouble(
      data,
      ['other_deductions', 'otherdeductions', 'deductions'],
      required: false,
    );

    return Income(
      id: '${DateTime.now().millisecondsSinceEpoch}_${name.replaceAll(' ', '_')}',
      name: name,
      kind: _normalizeIncomeKind(kind),
      grossAmount: grossAmount,
      frequency: _normalizeFrequency(frequency),
      updatedAt: DateTime.now(),
      federalTax: federalTax,
      stateTax: stateTax,
      socialSecurityTax: socialSecurity,
      medicareTax: medicare,
      retirement401k: retirement401k,
      healthInsurance: healthInsurance,
      otherDeductions: otherDeductions,
    );
  }

  static String _normalizeIncomeKind(String kind) {
    final normalized = kind.toLowerCase().trim().replaceAll(' ', '_');

    final Map<String, String> kindMap = {
      'salary': 'Salary',
      'wage': 'Hourly Wage',
      'hourly': 'Hourly Wage',
      'bonus': 'Bonus',
      'commission': 'Commission',
      'freelance': 'Freelance',
      'contract': 'Freelance',
      'rental': 'Rental Income',
      'rent': 'Rental Income',
      'investment': 'Investment Income',
      'dividends': 'Investment Income',
      'interest': 'Investment Income',
      'pension': 'Pension',
      'retirement': 'Pension',
      'social_security': 'Social Security',
      'ss': 'Social Security',
      'other': 'Other',
    };

    return kindMap[normalized] ?? 'Other';
  }

  static String _normalizeFrequency(String frequency) {
    final normalized = frequency.toLowerCase().trim().replaceAll(' ', '_');

    final Map<String, String> freqMap = {
      'hourly': 'Hourly',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'biweekly': 'Bi-Weekly',
      'bi-weekly': 'Bi-Weekly',
      'bi_weekly': 'Bi-Weekly',
      'semimonthly': 'Semi-Monthly',
      'semi-monthly': 'Semi-Monthly',
      'semi_monthly': 'Semi-Monthly',
      'monthly': 'Monthly',
      'quarterly': 'Quarterly',
      'annual': 'Annually',
      'annually': 'Annually',
      'yearly': 'Annually',
    };

    return freqMap[normalized] ?? 'Monthly';
  }

  // ==================== HELPER METHODS ====================

  static String _getString(
    Map<String, dynamic> data,
    List<String> keys, {
    bool required = false,
    String defaultValue = '',
  }) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        return data[key].toString().trim();
      }
    }

    if (required) {
      throw Exception('Required field not found: ${keys.join(" or ")}');
    }

    return defaultValue;
  }

  static double _getDouble(
    Map<String, dynamic> data,
    List<String> keys, {
    bool required = false,
    double defaultValue = 0.0,
  }) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        final value = data[key];
        if (value is num) {
          return value.toDouble();
        }

        // Try parsing string
        try {
          final str =
              value.toString().trim().replaceAll(',', '').replaceAll('%', '');
          return double.parse(str);
        } catch (e) {
          // Continue to next key
        }
      }
    }

    if (required) {
      throw Exception('Required numeric field not found: ${keys.join(" or ")}');
    }

    return defaultValue;
  }

  static bool _getBool(
    Map<String, dynamic> data,
    List<String> keys, {
    bool defaultValue = false,
  }) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        final value = data[key];
        if (value is bool) return value;

        final str = value.toString().toLowerCase().trim();
        if (str == 'true' || str == '1' || str == 'yes' || str == 'y') {
          return true;
        }
        if (str == 'false' || str == '0' || str == 'no' || str == 'n') {
          return false;
        }
      }
    }

    return defaultValue;
  }
}

// ==================== RESULT CLASSES ====================

class CsvImportResult {
  final bool success;
  final String? errorMessage;
  final String? type; // 'accounts', 'liabilities', 'income'
  final List<Account>? accounts;
  final List<Liability>? liabilities;
  final List<Income>? incomes;
  final List<String>? errors;

  CsvImportResult({
    required this.success,
    this.errorMessage,
    this.type,
    this.accounts,
    this.liabilities,
    this.incomes,
    this.errors,
  });

  factory CsvImportResult.success({
    required String type,
    List<Account>? accounts,
    List<Liability>? liabilities,
    List<Income>? incomes,
    List<String>? errors,
  }) {
    return CsvImportResult(
      success: true,
      type: type,
      accounts: accounts,
      liabilities: liabilities,
      incomes: incomes,
      errors: errors,
    );
  }

  factory CsvImportResult.error(String message) {
    return CsvImportResult(
      success: false,
      errorMessage: message,
    );
  }

  int get itemCount {
    if (accounts != null) return accounts!.length;
    if (liabilities != null) return liabilities!.length;
    if (incomes != null) return incomes!.length;
    return 0;
  }

  String get typeDisplay {
    switch (type) {
      case 'accounts':
        return 'Accounts';
      case 'liabilities':
        return 'Liabilities';
      case 'income':
        return 'Income';
      default:
        return 'Items';
    }
  }
}
