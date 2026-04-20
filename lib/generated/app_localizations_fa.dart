// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'ریبالانس';

  @override
  String get netWorth => 'ارزش خالص';

  @override
  String get assets => 'دارایی‌ها';

  @override
  String get liabilities => 'بدهی‌ها';

  @override
  String get cashFlow => 'جریان نقدی';

  @override
  String get healthScore => 'امتیاز سلامت مالی';

  @override
  String get proFeatures => 'ویژگی‌های حرفه‌ای';

  @override
  String get choosePlan => 'طرح خود را انتخاب کنید';

  @override
  String get upgradeToProTitle => 'ارتقا به نسخه حرفه‌ای';

  @override
  String get allProFeatures => 'تمام ویژگی‌های حرفه‌ای';

  @override
  String get cancelAnytime => 'لغو در هر زمان';

  @override
  String get freeTrialDays => '7 روز آزمایش رایگان';

  @override
  String get proMonthly => 'حرفه‌ای ماهانه';

  @override
  String get perMonth => 'در ماه';

  @override
  String get annual => 'سالانه';

  @override
  String get perYear => 'در سال';

  @override
  String get founderLifetime => 'بنیانگذار مادام‌العمر';

  @override
  String get oneTime => 'یک بار';

  @override
  String get bestValue => 'بهترین ارزش';

  @override
  String get limited => 'محدود';

  @override
  String saveMoney(String amount) {
    return 'صرفه‌جویی $amount';
  }

  @override
  String get everythingForever => 'همه چیز برای همیشه';

  @override
  String get firstFounders => '1,000 بنیانگذار اول';

  @override
  String get priceIncreasesAfter => 'قیمت بعداً افزایش می‌یابد';

  @override
  String get retirementCalculator => 'ماشین‌حساب بازنشستگی';

  @override
  String get debtOptimizer => 'بهینه‌ساز بدهی';

  @override
  String get scenarioEngine => 'موتور سناریو';

  @override
  String get taxSmartAllocation => 'تخصیص هوشمند مالیاتی';

  @override
  String get customAlerts => 'هشدارهای سفارشی';

  @override
  String get advancedAnalytics => 'تحلیل‌های پیشرفته';

  @override
  String get unlockWithPro => 'باز کردن با نسخه حرفه‌ای';

  @override
  String get startFreeTrial => 'شروع آزمایش رایگان';

  @override
  String get choosePlanButton => 'انتخاب طرح';

  @override
  String get settings => 'تنظیمات';

  @override
  String get currency => 'ارز';

  @override
  String get darkMode => 'حالت تاریک';

  @override
  String get colorTheme => 'تم رنگی';

  @override
  String get language => 'زبان';

  @override
  String get accounts => 'حساب‌ها';

  @override
  String get addAccount => 'افزودن حساب';

  @override
  String get editAccount => 'ویرایش حساب';

  @override
  String get accountName => 'نام حساب';

  @override
  String get accountType => 'نوع حساب';

  @override
  String get balance => 'موجودی';

  @override
  String get accountDetails => 'جزئیات حساب';

  @override
  String get pleaseEnterAccountName => 'لطفا نام حساب را وارد کنید';

  @override
  String get exampleAccountName => 'مثال: Chase Checking';

  @override
  String get lockedAccount => 'حساب قفل شده';

  @override
  String get cannotBeRebalanced =>
      'نمی‌توان تعادل مجدد کرد (401k، بازنشستگی، محدود)';

  @override
  String get canBeRebalanced => 'می‌تواند در برنامه‌های تعادل مجدد گنجانده شود';

  @override
  String get currentBalance => 'موجودی فعلی';

  @override
  String get pleaseEnterBalance => 'لطفا موجودی را وارد کنید';

  @override
  String get pleaseEnterValidBalance => 'لطفا موجودی معتبر وارد کنید';

  @override
  String get debts => 'بدهی‌ها';

  @override
  String get addDebt => 'افزودن بدهی';

  @override
  String get minimumPayment => 'حداقل پرداخت';

  @override
  String get interestRate => 'نرخ بهره';

  @override
  String get rebalancing => 'متعادل‌سازی مجدد';

  @override
  String get createPlan => 'ایجاد طرح متعادل‌سازی';

  @override
  String get targetAllocation => 'تخصیص هدف';

  @override
  String get dashboard => 'داشبورد';

  @override
  String get reports => 'گزارش‌ها';

  @override
  String get targets => 'اهداف';

  @override
  String get save => 'ذخیره';

  @override
  String get cancel => 'لغو';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'ویرایش';

  @override
  String get add => 'افزودن';

  @override
  String get confirm => 'تأیید';

  @override
  String get loading => 'در حال بارگذاری...';

  @override
  String get error => 'خطا';

  @override
  String errorWithMessage(String message) {
    return 'خطا: $message';
  }

  @override
  String get success => 'موفق';

  @override
  String get recentAccounts => 'حساب‌های اخیر';

  @override
  String get viewAll => 'مشاهده همه';

  @override
  String get noAccountsYet => 'هنوز حسابی وجود ندارد';

  @override
  String get getStarted => 'اولین حساب خود را اضافه کنید';

  @override
  String get totalAssets => 'کل دارایی‌ها';

  @override
  String get totalLiabilities => 'کل بدهی‌ها';

  @override
  String get financialHealth => 'سلامت مالی';

  @override
  String get allocation => 'تخصیص';

  @override
  String get liquidity => 'نقدینگی';

  @override
  String get debtLoad => 'بار بدهی';

  @override
  String get concentration => 'تمرکز';

  @override
  String get excellent => 'عالی';

  @override
  String get good => 'خوب';

  @override
  String get fair => 'متوسط';

  @override
  String get needsWork => 'نیاز به بهبود دارد';

  @override
  String get critical => 'بحرانی';

  @override
  String get poor => 'ضعیف';

  @override
  String get financialHealthScore => 'نمره سلامت مالی';

  @override
  String get howBalancedIsYourPortfolio => 'پرتفوی شما چقدر متعادل است؟';

  @override
  String get wellBalanced => 'به خوبی متعادل';

  @override
  String get excellentHealth => 'سلامت عالی';

  @override
  String get goodHealth => 'سلامت خوب';

  @override
  String get fairHealth => 'سلامت متوسط';

  @override
  String get needsWorkHealth => 'نیاز به بهبود دارد';

  @override
  String get poorHealth => 'سلامت ضعیف';

  @override
  String get weightedBreakdown => 'تفکیک وزنی';

  @override
  String get fixedIncomeBalance => 'تعادل درآمد ثابت';

  @override
  String get liquidityBuffer => 'ذخیره نقدینگی';

  @override
  String get internationalExposure => 'قرارگیری بین‌المللی';

  @override
  String get debtManagement => 'مدیریت بدهی';

  @override
  String get whatMoved => 'چه چیزی تغییر کرد';

  @override
  String get sinceLast30d => 'از 30 روز گذشته:';

  @override
  String get reducedUsEquityPosition => 'موقعیت سهام آمریکا کاهش یافت';

  @override
  String get addedFixedIncomeAllocation => 'تخصیص درآمد ثابت اضافه شد';

  @override
  String get noChangeInCashPosition => 'تغییری در موقعیت نقدی وجود ندارد';

  @override
  String get nextActions => 'اقدامات بعدی';

  @override
  String get openMixAndDials => 'باز کردن ترکیب و صفحه‌ها';

  @override
  String get reviewDetailedAllocationBreakdown => 'بررسی تفصیل تخصیص دقیق';

  @override
  String get addToPlan => 'افزودن به برنامه';

  @override
  String get createRebalancingStrategy => 'ایجاد استراتژی متعادل‌سازی مجدد';

  @override
  String get setTargetAllocation => 'تنظیم تخصیص هدف';

  @override
  String get adjustYourRiskPreferences => 'تنظیم ترجیحات ریسک خود';

  @override
  String get financialHealthTrend => 'روند سلامت مالی';

  @override
  String get keyInsights => 'بینش‌های کلیدی';

  @override
  String get runSimulation => 'اجرای شبیه‌سازی';

  @override
  String get explainGradeBands => 'توضیح محدوده‌های درجه';

  @override
  String get seeHowAddingBondsAffectsScore =>
      'ببینید اضافه کردن 1,500 دلار به اوراق قرضه چگونه بر نمره شما تأثیر می‌گذارد';

  @override
  String get strongUpwardTrend => 'روند صعودی قوی در طی 6 ماه';

  @override
  String get consistentImprovementPattern => 'الگوی بهبود مداوم';

  @override
  String get approachingExcellentHealth => 'نزدیک شدن به سلامت مالی عالی';

  @override
  String get gradualImprovementTrend => 'روند بهبود تدریجی';

  @override
  String get steadyProgressPattern => 'الگوی پیشرفت پایدار';

  @override
  String get decliningTrendNeedsAttention => 'روند نزولی نیاز به توجه دارد';

  @override
  String get highVolatilityInScores => 'نوسان بالا در نمرات';

  @override
  String get considerReviewingStrategy =>
      'بررسی استراتژی مالی را در نظر بگیرید';

  @override
  String get slightDownwardTrend => 'روند نزولی جزئی';

  @override
  String get monitorForContinuedDecline => 'نظارت بر کاهش مداوم';

  @override
  String get stableFinancialHealthScore => 'نمره سلامت مالی پایدار';

  @override
  String get lowVolatilityIndicatesConsistency =>
      'نوسان کم نشان‌دهنده ثبات است';

  @override
  String get overall => 'کلی';

  @override
  String get weakest => 'ضعیف‌ترین';

  @override
  String get healthCalculatedFromComponents => 'سلامت از 5 جزء محاسبه شده است';

  @override
  String get open => 'باز کردن';

  @override
  String get go => 'برو';

  @override
  String get netWorthLabel => 'خالص دارایی';

  @override
  String get assetAllocation => 'تخصیص دارایی';

  @override
  String get cash => 'نقدی';

  @override
  String get bonds => 'اوراق قرضه';

  @override
  String get equities => 'سهام';

  @override
  String get realEstate => 'املاک';

  @override
  String get commodities => 'کالاها';

  @override
  String get crypto => 'رمزارز';

  @override
  String get other => 'سایر';

  @override
  String get totalEquities => 'کل سهام';

  @override
  String get vsTarget => 'در مقابل هدف';

  @override
  String get viewFullAnalysis => 'مشاهده تحلیل کامل';

  @override
  String get reduce => 'کاهش';

  @override
  String get concentrationRisk => 'ریسک تمرکز';

  @override
  String get highRisk => 'ریسک بالا';

  @override
  String get mediumRisk => 'ریسک متوسط';

  @override
  String get lowRisk => 'ریسک پایین';

  @override
  String get spotted => 'مشاهده شد';

  @override
  String get ago => 'پیش';

  @override
  String get updated => 'به‌روزرسانی شد';

  @override
  String get addYourFirstAccount => 'اولین حساب خود را اضافه کنید';

  @override
  String get checkingAccount => 'حساب جاری';

  @override
  String get savingsAccount => 'حساب پس‌انداز';

  @override
  String get brokerageAccount => 'حساب کارگزاری';

  @override
  String get retirementAccount => 'حساب بازنشستگی';

  @override
  String get reduceConcentrationRisk => 'کاهش ریسک تمرکز';

  @override
  String get largestBucket => 'بزرگترین سبد';

  @override
  String get capPerBucket => 'سقف هر سبد';

  @override
  String get targetShift => 'تغییر هدف';

  @override
  String get createRebalancingPlan => 'ایجاد برنامه تعادل مجدد';

  @override
  String get shiftPerMonth => 'تغییر ماهانه';

  @override
  String get spottedAgo => 'مشاهده شد';

  @override
  String get updatedToday => 'امروز به‌روزرسانی شد';

  @override
  String get updatedYesterday => 'دیروز به‌روزرسانی شد';

  @override
  String updatedDaysAgo(Object days) {
    return '$days روز پیش به‌روزرسانی شد';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours ساعت پیش';
  }

  @override
  String daysAgo(Object days) {
    return '$days روز پیش';
  }

  @override
  String monthsAgo(Object months) {
    return '$months ماه پیش';
  }

  @override
  String get incomeSourceName => 'نام منبع درآمد';

  @override
  String get incomeSourceNameHint => 'مثلاً، حقوق شرکت فناوری';

  @override
  String get pleaseEnterName => 'لطفاً نام را وارد کنید';

  @override
  String get incomeType => 'نوع درآمد';

  @override
  String get incomeTypeSalary => 'حقوق';

  @override
  String get incomeTypeHourlyWage => 'دستمزد ساعتی';

  @override
  String get incomeTypeBonus => 'پاداش';

  @override
  String get incomeTypeCommission => 'کمیسیون';

  @override
  String get incomeTypeFreelance => 'فریلنس';

  @override
  String get incomeTypeRentalIncome => 'درآمد اجاره';

  @override
  String get incomeTypeInvestmentIncome => 'درآمد سرمایه‌گذاری';

  @override
  String get incomeTypePension => 'بازنشستگی';

  @override
  String get incomeTypeSocialSecurity => 'تأمین اجتماعی';

  @override
  String get incomeTypeOther => 'سایر';

  @override
  String get grossAmount => 'مبلغ ناخالص';

  @override
  String get pleaseEnterAmount => 'لطفاً مبلغ را وارد کنید';

  @override
  String get pleaseEnterValidNumber => 'لطفاً یک عدد معتبر وارد کنید';

  @override
  String get frequency => 'فرکانس';

  @override
  String get addTaxDeductionBreakdown => 'افزودن جزئیات مالیات و کسورات';

  @override
  String get trackFederalTaxStateTax =>
      'ردیابی مالیات فدرال، مالیات ایالتی و کسورات';

  @override
  String get deductionsPerPaymentPeriod => 'کسورات (در هر دوره پرداخت)';

  @override
  String get federalTax => 'مالیات فدرال';

  @override
  String get stateTax => 'مالیات ایالتی';

  @override
  String get socialSecurityTax => 'مالیات تأمین اجتماعی';

  @override
  String get medicareTax => 'مالیات مراقبت‌های پزشکی';

  @override
  String get retirement401k => 'بازنشستگی (401k، IRA)';

  @override
  String get healthInsurancePremium => 'حق بیمه سلامت';

  @override
  String get otherDeductions => 'سایر کسورات';

  @override
  String get addIncome => 'افزودن درآمد';

  @override
  String get importFromCSV => 'وارد کردن از CSV';

  @override
  String get importDataFromCSV => 'وارد کردن داده‌ها از CSV';

  @override
  String get selectCSVFileDescription =>
      'یک فایل CSV برای وارد کردن حساب‌ها، بدهی‌ها یا داده‌های درآمد انتخاب کنید';

  @override
  String get selectCSVFile => 'انتخاب فایل CSV';

  @override
  String get csvFormatRequirements => 'الزامات قالب CSV';

  @override
  String get accountsLabel => 'حساب‌ها';

  @override
  String get accountsCSVFormat =>
      'name,type,balance,locked,cash,bonds,usEq,intlEq,realEstate,alt';

  @override
  String get liabilitiesLabel => 'بدهی‌ها';

  @override
  String get liabilitiesCSVFormat =>
      'name,type,balance,interestRate,minPayment';

  @override
  String get incomeLabel => 'درآمد';

  @override
  String get incomeCSVFormat => 'name,type,grossAmount,frequency';

  @override
  String get readyToImport => 'آماده برای وارد کردن';

  @override
  String get rowsHadErrors => 'ردیف دارای خطا بود';

  @override
  String get importError => 'خطای وارد کردن';

  @override
  String get unknownError => 'خطای ناشناخته';

  @override
  String get tryAgain => 'دوباره تلاش کنید';

  @override
  String get income => 'درآمد';

  @override
  String get unlockPro => 'باز کردن پرو';

  @override
  String get yourProFeatures => 'ویژگی‌های پرو شما';

  @override
  String get debtPayoffOptimizer => 'بهینه‌ساز پرداخت بدهی';

  @override
  String get debtPayoffDescription =>
      'استراتژی‌های بهمن در مقابل گلوله برفی را با برنامه‌های پرداخت ماهانه مقایسه کنید';

  @override
  String get saveThousands => 'هزاران دلار سود صرفه‌جویی کنید';

  @override
  String get rebalancingAutopilot => 'خلبان خودکار تعادل مجدد';

  @override
  String get rebalancingDescription =>
      'دستورالعمل‌های تجاری خاص با معیارهای ریسک قبل/بعد دریافت کنید';

  @override
  String get reduceRisk => 'ریسک پرتفوی را کاهش دهید';

  @override
  String get whatIfScenarioEngine => 'موتور سناریو چه می‌شود اگر';

  @override
  String get whatIfDescription =>
      'شبیه‌سازی مونت کارلو احتمال موفقیت را با پارامترهای قابل تنظیم نشان می‌دهد';

  @override
  String get seeProbability => 'احتمال موفقیت را ببینید';

  @override
  String get customAlertsWithContext => 'هشدارهای سفارشی با زمینه';

  @override
  String get customAlertsDescription =>
      'آستانه‌های سفارشی با هشدارهای تأثیر دلاری تنظیم کنید';

  @override
  String get knowImpact => 'تأثیر مالی را بدانید';

  @override
  String get taxSmartDescription =>
      'قرارگیری حساب را بهینه کنید و فرصت‌های برداشت ضرر مالیاتی را شناسایی کنید';

  @override
  String get saveTaxes => 'سالانه در مالیات صرفه‌جویی کنید';

  @override
  String get retirementDescription =>
      'شبیه‌سازی مونت کارلو احتمال موفقیت بازنشستگی را پیش‌بینی می‌کند';

  @override
  String get advancedPortfolioAnalytics => 'تحلیل‌های پیشرفته پرتفوی';

  @override
  String get advancedAnalyticsDescription =>
      'شاخص تمرکز HHI، قرار گرفتن در معرض عامل، پیگیری چند پرتفوی';

  @override
  String get planDetails => 'جزئیات طرح';

  @override
  String get proActive => 'پرو فعال';

  @override
  String get rebalancePro => 'تعادل مجدد پرو';

  @override
  String get basedOnYourPortfolio => 'بر اساس پرتفوی شما:';

  @override
  String get saveMoneyReduceRisk =>
      'با برنامه‌ریزی مالی هوشمند پول صرفه‌جویی و ریسک کاهش دهید';

  @override
  String get compareStrategies =>
      'استراتژی‌های بهمن در مقابل گلوله برفی را مقایسه کنید. برنامه‌های پرداخت ماهانه دریافت کنید و کل صرفه‌جویی سود را ببینید.';

  @override
  String get getSpecificTrades =>
      'دستورالعمل‌های تجاری خاص دریافت کنید. معیارهای ریسک قبل/بعد و کاهش نوسان را ببینید.';

  @override
  String get monteCarloSimulation =>
      'شبیه‌سازی مونت کارلو (1000 اجرا) احتمال موفقیت را نشان می‌دهد. مشارکت‌ها، بازده و جدول زمانی را برای بهینه‌سازی برنامه خود تنظیم کنید.';

  @override
  String get customThresholds =>
      'آستانه‌های سفارشی برای تمرکز، جریان، DSCR تنظیم کنید. هر هشدار تأثیر دلاری را نشان می‌دهد.';

  @override
  String get optimizeAccounts =>
      'بهینه کنید کدام حساب کدام دارایی را نگه می‌دارد. فرصت‌های برداشت ضرر مالیاتی را شناسایی کنید. کشش مالیاتی سالانه را کاهش دهید.';

  @override
  String get projectRetirement =>
      'شبیه‌سازی مونت کارلو (1000 اجرا) احتمال موفقیت بازنشستگی را پیش‌بینی می‌کند. پس‌انداز، جدول زمانی و درآمد را برای بهینه‌سازی برنامه خود تنظیم کنید.';

  @override
  String get hhiConcentration =>
      'شاخص تمرکز HHI، تجزیه قرار گرفتن در معرض عامل، پیگیری چند پرتفوی، وزن‌های امتیازدهی سفارشی.';

  @override
  String get privacy100 => '100٪ حریم خصوصی';

  @override
  String get dataOnDevice => 'همه داده‌ها در دستگاه شما باقی می‌مانند';

  @override
  String get encryptedStorage => 'ذخیره‌سازی رمزگذاری شده';

  @override
  String get bankGrade => 'امنیت درجه بانکی';

  @override
  String get saveEst => 'صرفه‌جویی تخمینی ';

  @override
  String get purchaseCancelled => 'خرید لغو شد';

  @override
  String get rebalancingPlan => 'طرح تعادل مجدد';

  @override
  String get rebalancingGuide => 'راهنمای تعادل مجدد';

  @override
  String get addAccountsForRebalancing =>
      'حساب‌هایی با دارایی‌ها برای ساخت طرح تعادل مجدد شخصی خود اضافه کنید';

  @override
  String get rebalancingPlanProDescription =>
      'دستورالعمل‌های تجاری خاص با معیارهای ریسک قبل/بعد دریافت کنید. دقیقاً ببینید چه چیزی را برای رسیدن به تخصیص هدف خود باید بخرید یا بفروشید.';

  @override
  String get yourPersonalizedPlan => 'طرح شخصی شما';

  @override
  String get customizeTrackExecute =>
      'سفارشی‌سازی استراتژی، پیگیری پیشرفت، اجرای معاملات';

  @override
  String get lockedAccountsDetected => 'حساب‌های قفل شده شناسایی شد';

  @override
  String get lockedAccountsMessage =>
      'قفل شده است (مثلاً 401k، بازنشستگی). طرح فقط استفاده می‌کند';

  @override
  String get inUnlockedAccounts => 'در حساب‌های باز شده';

  @override
  String get lockedAccountsTip =>
      'نکته: برای 401k/بازنشستگی، به جای تعادل مجدد دارایی‌های موجود، تخصیص مشارکت خود را به‌روزرسانی کنید.';

  @override
  String get rebalancingStrategy => 'استراتژی تعادل مجدد';

  @override
  String get dollarCostAverageRecommended => 'میانگین هزینه دلاری (توصیه شده)';

  @override
  String get dollarCostDescription =>
      'معاملات را در چند ماه پخش کنید تا ریسک زمان‌بندی را کاهش دهید';

  @override
  String get immediateRebalance => 'تعادل مجدد فوری';

  @override
  String get immediateRebalanceDescription =>
      'اگر اعتماد قوی دارید همه معاملات را اکنون اجرا کنید';

  @override
  String get glidePathDuration => 'مدت مسیر لغزش';

  @override
  String get howManyMonthsToSpread =>
      'می‌خواهید تعادل مجدد را در چند ماه پخش کنید؟';

  @override
  String get fast => 'سریع';

  @override
  String get gradual => 'تدریجی';

  @override
  String get months => 'ماه';

  @override
  String get month => 'ماه';

  @override
  String get executeNow => 'اکنون اجرا کنید';

  @override
  String get totalToRebalanceImmediately => 'مجموع برای تعادل مجدد فوری';

  @override
  String get monthlyTransferAmount => 'مبلغ انتقال ماهانه';

  @override
  String get overMonths => 'در طی';

  @override
  String get total => 'مجموع';

  @override
  String get beforeVsAfter => 'قبل در مقابل بعد';

  @override
  String get current => 'فعلی';

  @override
  String get target => 'هدف';

  @override
  String get executionChecklist => 'لیست بررسی اجرا';

  @override
  String get trackMonthlyProgress =>
      'پیشرفت ماهانه خود را هنگام اجرای معاملات پیگیری کنید';

  @override
  String get transfer => 'انتقال';

  @override
  String get ofMonthsCompleted => 'از';

  @override
  String get monthsCompleted => 'ماه‌های تکمیل شده';

  @override
  String get exportPDF => 'خروجی PDF';

  @override
  String get pdfExportComingSoon => 'خروجی PDF به زودی!';

  @override
  String get whyRebalance => 'چرا تعادل مجدد؟';

  @override
  String get whyRebalanceDescription =>
      'حرکات بازار باعث می‌شود پرتفوی شما از تخصیص هدف منحرف شود و ریسک افزایش یابد. تعادل مجدد پروفایل ریسک/بازده مطلوب شما را بازیابی می‌کند.';

  @override
  String get dollarCostAveragingTitle => 'میانگین هزینه دلاری';

  @override
  String get dollarCostAveragingDescription =>
      'پخش معاملات در طول زمان ریسک زمان‌بندی و تأثیر بازار را کاهش می‌دهد. برای اکثر سرمایه‌گذاران توصیه می‌شود.';

  @override
  String get immediateRebalancingTitle => 'تعادل مجدد فوری';

  @override
  String get immediateRebalancingDescription =>
      'همه معاملات را یکباره اجرا کنید. بهترین اگر اعتماد بازار قوی دارید یا نیاز به تعادل مجدد فوری دارید.';

  @override
  String get youreWellBalanced => 'شما خوب متعادل هستید!';

  @override
  String get noRebalancingNeeded =>
      'پرتفوی شما در محدوده تحمل تخصیص هدف است. در این زمان نیازی به تعادل مجدد نیست.';

  @override
  String get accountType529EducationSavings => '529 پس‌انداز آموزشی';

  @override
  String get accountTypeBrokerage => 'کارگزاری';

  @override
  String get accountTypeBrokerageAccount => 'حساب کارگزاری';

  @override
  String get accountTypeCash => 'نقدی';

  @override
  String get accountTypeCashAccount => 'حساب نقدی';

  @override
  String get accountTypeCD => 'CD';

  @override
  String get accountTypeCertificateOfDeposit => 'گواهی سپرده';

  @override
  String get accountTypeChecking => 'جاری';

  @override
  String get accountTypeCheckingAccount => 'حساب جاری';

  @override
  String get accountTypeCrypto => 'کریپتو';

  @override
  String get accountTypeCryptocurrency => 'ارز دیجیتال';

  @override
  String get accountTypeHealthSavingsAccount => 'حساب پس‌انداز سلامت (HSA)';

  @override
  String get accountTypeHSA => 'HSA';

  @override
  String get accountTypeOther => 'دیگر';

  @override
  String get accountTypeRealEstate => 'املاک';

  @override
  String get accountTypeRealEstateEquity => 'سهام املاک';

  @override
  String get accountTypeRetirement => 'بازنشستگی';

  @override
  String get accountTypeSavings => 'پس‌انداز';

  @override
  String get accountTypeSavingsAccount => 'حساب پس‌انداز';

  @override
  String get liabilityTypeAutoLoan => 'وام خودرو';

  @override
  String get liabilityTypeCreditCard => 'کارت اعتباری';

  @override
  String get liabilityTypeLineOfCredit => 'خط اعتباری';

  @override
  String get liabilityTypeMortgage => 'وام مسکن';

  @override
  String get liabilityTypeOther => 'دیگر';

  @override
  String get liabilityTypePersonalLoan => 'وام شخصی';

  @override
  String get liabilityTypeStudentLoan => 'وام دانشجویی';

  @override
  String get about => 'درباره';

  @override
  String get account => 'حساب';

  @override
  String get accountDeletedSuccessfully => 'حساب با موفقیت حذف شد';

  @override
  String get accountsPlural => 'حساب‌ها';

  @override
  String get addIncomeSource => 'افزودن منبع درآمد';

  @override
  String get addLiability => 'افزودن بدهی';

  @override
  String get addNewAccount => 'افزودن حساب جدید';

  @override
  String get addYourFirstIncomeSource =>
      'اولین منبع درآمد خود را برای پیگیری جریان نقدی اضافه کنید';

  @override
  String get addYourFirstLiability =>
      'اولین بدهی خود را برای پیگیری بدهی‌ها اضافه کنید';

  @override
  String get allocationTargets => 'اهداف تخصیص';

  @override
  String get allocationTargetsDescription =>
      'درصدهای تخصیص دارایی هدف خود را تنظیم کنید';

  @override
  String get allPayments => 'همه پرداخت‌ها';

  @override
  String get alternatives => 'جایگزین‌ها';

  @override
  String get amountCannotBeNegative => 'مبلغ نمی‌تواند منفی باشد';

  @override
  String get annualInterestCost => 'هزینه سود سالانه';

  @override
  String get appInfoAndDisclaimers => 'اطلاعات برنامه و سلب مسئولیت';

  @override
  String get apr => 'APR';

  @override
  String get arabic => 'عربی';

  @override
  String get areYouSureDeleteAccount =>
      'آیا مطمئن هستید که می‌خواهید این حساب را حذف کنید؟';

  @override
  String get areYouSureDeleteIncome =>
      'آیا مطمئن هستید که می‌خواهید این منبع درآمد را حذف کنید؟';

  @override
  String get areYouSureExit => 'آیا مطمئن هستید که می‌خواهید خارج شوید؟';

  @override
  String get assetAllocationDescription =>
      'برای مدیریت ریسک در کلاس‌های دارایی متنوع سازی کنید';

  @override
  String get avgInterestRate => 'نرخ بهره متوسط';

  @override
  String get backToDashboard => 'بازگشت به داشبورد';

  @override
  String get backToSnapshot => 'بازگشت به اسنپ‌شات';

  @override
  String get backupRestoreData => 'پشتیبان‌گیری و بازیابی داده';

  @override
  String get balanced => 'متعادل';

  @override
  String get bengali => 'بنگالی';

  @override
  String get bondsAndFixedIncome => 'اوراق قرضه و درآمد ثابت';

  @override
  String get budgetAndPlanning => 'بودجه و برنامه‌ریزی';

  @override
  String get budgetAndPlanningDescription =>
      'هزینه‌ها را پیگیری کنید و برای اهداف برنامه‌ریزی کنید';

  @override
  String get cap => 'سقف';

  @override
  String get cashAndCashEquivalents => 'نقد و معادل نقد';

  @override
  String get chooseColorScheme => 'طرح رنگ را انتخاب کنید';

  @override
  String get chooseLanguage => 'زبان را انتخاب کنید';

  @override
  String get closeApplication => 'بستن برنامه';

  @override
  String get colorAmber => 'کهربایی';

  @override
  String get colorBlue => 'آبی';

  @override
  String get colorGreen => 'سبز';

  @override
  String get colorIndigo => 'نیلی';

  @override
  String get colorOrange => 'نارنجی';

  @override
  String get colorPink => 'صورتی';

  @override
  String get colorPurple => 'بنفش';

  @override
  String get colorRed => 'قرمز';

  @override
  String get colorTeal => 'فیروزه‌ای';

  @override
  String get componentConcentration => 'تمرکز';

  @override
  String get componentDebtLoad => 'بار بدهی';

  @override
  String get componentFixedIncome => 'درآمد ثابت';

  @override
  String get componentHomeBias => 'تعصب داخلی';

  @override
  String get componentLiquidity => 'نقدینگی';

  @override
  String get controlInternationalExposure =>
      'کنترل قرار گرفتن در معرض بین‌المللی';

  @override
  String get creditLimit => 'حد اعتباری';

  @override
  String get creditLimitCannotBeLessThanBalance =>
      'حد اعتباری نمی‌تواند کمتر از موجودی فعلی باشد';

  @override
  String get creditUtilization => 'استفاده از اعتبار';

  @override
  String get dayOfEachMonth => 'روز هر ماه';

  @override
  String get debt => 'بدهی';

  @override
  String get debtsAndLiabilities => 'بدهی‌ها و تعهدات';

  @override
  String get debtsPlural => 'بدهی‌ها';

  @override
  String get defaultPolicyPenalizeLargeDeviations =>
      'سیاست پیش‌فرض: انحرافات بزرگ از اهداف را جریمه کنید';

  @override
  String get deleteAccount => 'حذف حساب';

  @override
  String get deletedSuccessfully => 'با موفقیت حذف شد';

  @override
  String get deleteIncomeSource => 'حذف منبع درآمد';

  @override
  String get discard => 'لغو';

  @override
  String get displayInCurrency => 'نمایش به ارز';

  @override
  String get editIncome => 'ویرایش درآمد';

  @override
  String get editLiability => 'ویرایش بدهی';

  @override
  String get english => 'انگلیسی';

  @override
  String get enterMinPayment => 'حداقل پرداخت را وارد کنید';

  @override
  String get enterMonthlyEssentials => 'ضروریات ماهانه را وارد کنید';

  @override
  String get enterTargetPercentage => 'درصد هدف را وارد کنید';

  @override
  String get enterValidAmount => 'مبلغ معتبر وارد کنید';

  @override
  String get enterValidNumber => 'عدد معتبر وارد کنید';

  @override
  String get enterValidPayment => 'پرداخت معتبر وارد کنید';

  @override
  String get errorDeletingAccount => 'خطا در حذف حساب';

  @override
  String get errorLoadingAccounts => 'خطا در بارگذاری حساب‌ها';

  @override
  String get errorLoadingLiabilities => 'خطا در بارگذاری بدهی‌ها';

  @override
  String get excludeInternationalExposure =>
      'قرار گرفتن در معرض بین‌المللی را حذف کنید';

  @override
  String get exit => 'خروج';

  @override
  String get exitApp => 'خروج از برنامه';

  @override
  String get filteredFromSnapshot => 'فیلتر شده از اسنپ‌شات';

  @override
  String get financialScore => 'امتیاز مالی';

  @override
  String get frequencyAnnual => 'سالانه';

  @override
  String get frequencyAnnually => 'به صورت سالانه';

  @override
  String get frequencyBiWeekly => 'دو هفته یکبار';

  @override
  String get frequencyBiweekly => 'دو هفته یکبار';

  @override
  String get frequencyDaily => 'روزانه';

  @override
  String get frequencyHourly => 'ساعتی';

  @override
  String get frequencyMonthly => 'ماهانه';

  @override
  String get frequencyQuarterly => 'فصلی';

  @override
  String get frequencySemiMonthly => 'نیم‌ماهانه';

  @override
  String get frequencyWeekly => 'هفتگی';

  @override
  String get goBack => 'بازگشت';

  @override
  String get gotIt => 'متوجه شدم';

  @override
  String get help => 'راهنما';

  @override
  String get helpAllocationTargetsText =>
      'درصدهای هدف را برای هر کلاس دارایی تنظیم کنید. برنامه هنگامی که تخصیص واقعی شما خیلی از این اهداف منحرف شود به شما هشدار می‌دهد.';

  @override
  String get helpAllocationTargetsTitle => 'راهنمای اهداف تخصیص';

  @override
  String get helpMonthlyEssentialsText =>
      'هزینه‌های ضروری ماهانه خود را وارد کنید (اجاره، آب و برق، مواد غذایی و غیره). این به محاسبه هدف صندوق اضطراری شما کمک می‌کند.';

  @override
  String get helpMonthlyEssentialsTitle => 'راهنمای ضروریات ماهانه';

  @override
  String get helpRiskProfileText =>
      'یک پروفایل ریسک انتخاب کنید که با اهداف سرمایه‌گذاری و افق زمانی شما مطابقت داشته باشد. محافظه‌کارانه اوراق قرضه و نقد را ترجیح می‌دهد، رشد سهام را ترجیح می‌دهد، متعادل بین آنهاست.';

  @override
  String get helpRiskProfileTitle => 'راهنمای پروفایل ریسک';

  @override
  String get hindi => 'هندی';

  @override
  String get howWeProtectData => 'چگونه از داده‌های شما محافظت می‌کنیم';

  @override
  String get importAccountsDebtsIncome => 'وارد کردن حساب‌ها، بدهی‌ها و درآمد';

  @override
  String get importAndExport => 'وارد کردن و خروجی';

  @override
  String get importCSV => 'وارد کردن CSV';

  @override
  String get income1099 => 'درآمد 1099';

  @override
  String get incomeBonus => 'پاداش';

  @override
  String get incomeFreelance => 'آزاد';

  @override
  String get incomeInvestment => 'سرمایه‌گذاری';

  @override
  String get incomePension => 'بازنشستگی';

  @override
  String get incomeRental => 'اجاره';

  @override
  String get incomeSalary => 'حقوق';

  @override
  String get incomeSocialSecurity => 'تامین اجتماعی';

  @override
  String get incomeSourceAdded => 'منبع درآمد اضافه شد';

  @override
  String get incomeSourceDeleted => 'منبع درآمد حذف شد';

  @override
  String get incomeSourceUpdated => 'منبع درآمد به‌روزرسانی شد';

  @override
  String get incomeW2 => 'درآمد W-2';

  @override
  String get internationalEquity => 'سهام بین‌المللی';

  @override
  String get intlEquity => 'سهام بین‌المللی';

  @override
  String get justNow => 'همین الان';

  @override
  String get lastPayment => 'آخرین پرداخت';

  @override
  String get legalTermsAndConditions => 'شرایط و ضوابط قانونی';

  @override
  String get lessPunitive => 'کمتر مجازات‌آمیز';

  @override
  String get liabilityDetails => 'جزئیات بدهی';

  @override
  String get liabilityName => 'نام بدهی';

  @override
  String get liabilityNameHint => 'به عنوان مثال، Chase Visa، وام دانشجویی';

  @override
  String get liabilitySavedSuccessfully => 'بدهی با موفقیت ذخیره شد';

  @override
  String get light => 'روشن';

  @override
  String get minPayment => 'حداقل پرداخت';

  @override
  String get monthlyEssentialExpenses => 'هزینه‌های ضروری ماهانه';

  @override
  String get monthlyEssentialsHelper =>
      'هزینه‌های ضروری ماهانه خود را وارد کنید';

  @override
  String get monthlyEssentialsHelperUSD =>
      'به عنوان مثال، 3000 دلار برای اجاره، آب و برق، مواد غذایی';

  @override
  String get monthlyInterest => 'سود ماهانه';

  @override
  String get monthlyPaymentDay => 'روز پرداخت ماهانه';

  @override
  String get monthlyPayments => 'پرداخت‌های ماهانه';

  @override
  String get net => 'خالص';

  @override
  String get netIncome => 'درآمد خالص';

  @override
  String get nextPaymentDueDate => 'تاریخ سررسید پرداخت بعدی';

  @override
  String get noDebtsTracked => 'هنوز بدهی ردیابی نشده است';

  @override
  String get noIncomeSourcesYet => 'هنوز منبع درآمدی وجود ندارد';

  @override
  String get noPaymentsRecordedYet => 'هنوز پرداختی ثبت نشده است';

  @override
  String get offMute => 'خاموش/بی‌صدا';

  @override
  String get optimizePayoffStrategy => 'بهینه‌سازی استراتژی پرداخت';

  @override
  String get paymentHistory => 'تاریخچه پرداخت';

  @override
  String get paymentSchedule => 'برنامه پرداخت';

  @override
  String get paymentsWillAppearHere => 'پرداخت‌ها اینجا نمایش داده می‌شوند';

  @override
  String get percentageMustBeBetween => 'درصد باید بین 0 و 100 باشد';

  @override
  String get persian => 'فارسی';

  @override
  String get french => 'فرانسوی';

  @override
  String get pleaseEnterAPR => 'لطفاً APR را وارد کنید';

  @override
  String get pleaseEnterCurrentBalance => 'لطفاً موجودی فعلی را وارد کنید';

  @override
  String get pleaseEnterLiabilityName => 'لطفاً نام بدهی را وارد کنید';

  @override
  String get pleaseEnterValidAPR => 'لطفاً یک APR معتبر وارد کنید';

  @override
  String get pleaseEnterValidCreditLimit =>
      'لطفاً یک حد اعتباری معتبر وارد کنید';

  @override
  String get privacyPolicy => 'سیاست حریم خصوصی';

  @override
  String get proFeature => 'ویژگی پرو';

  @override
  String get proStatus => 'وضعیت پرو';

  @override
  String get pts => 'امتیاز';

  @override
  String get quickStats => 'آمار سریع';

  @override
  String get realEstateREITs => 'املاک و REITs';

  @override
  String get requestLanguage => 'درخواست زبان';

  @override
  String get retry => 'تلاش مجدد';

  @override
  String get riskBalanced => 'متعادل';

  @override
  String get riskBalancedAllocation => '60% سهام، 35% اوراق قرضه، 5% نقد';

  @override
  String get riskBalancedDescription => 'رشد متوسط با مقداری ثبات';

  @override
  String get riskConservative => 'محافظه‌کارانه';

  @override
  String get riskConservativeAllocation => '30% سهام، 50% اوراق قرضه، 20% نقد';

  @override
  String get riskConservativeDescription => 'اولویت دادن به ثبات و حفظ سرمایه';

  @override
  String get riskGrowth => 'رشد';

  @override
  String get riskGrowthAllocation => '80% سهام، 15% اوراق قرضه، 5% نقد';

  @override
  String get riskGrowthDescription => 'به حداکثر رساندن پتانسیل رشد بلندمدت';

  @override
  String get riskProfile => 'پروفایل ریسک';

  @override
  String get riskProfileDescription =>
      'تحمل ریسک سرمایه‌گذاری خود را انتخاب کنید';

  @override
  String get saveChanges => 'ذخیره تغییرات';

  @override
  String get selectNextPaymentDueDate =>
      'تاریخ سررسید پرداخت بعدی را انتخاب کنید';

  @override
  String get sendFeedback => 'ارسال بازخورد';

  @override
  String get setTargetsAndThresholds => 'تنظیم اهداف و آستانه‌ها';

  @override
  String get settingsSavedSuccessfully => 'تنظیمات با موفقیت ذخیره شد';

  @override
  String get shareThoughtsAndSuggestions =>
      'افکار و پیشنهادات خود را به اشتراک بگذارید';

  @override
  String get showAll => 'نمایش همه';

  @override
  String get source => 'منبع';

  @override
  String get sources => 'منابع';

  @override
  String get stable => 'پایدار';

  @override
  String get standard => 'استاندارد';

  @override
  String get tapToSelectDate => 'برای انتخاب تاریخ ضربه بزنید';

  @override
  String get targetsAndAlerts => 'اهداف و هشدارها';

  @override
  String get targetsAndAlertsHelp => 'راهنمای اهداف و هشدارها';

  @override
  String get taxRate => 'نرخ مالیات';

  @override
  String get termsOfService => 'شرایط خدمات';

  @override
  String get testingAsFreeUser => 'آزمایش به عنوان کاربر رایگان';

  @override
  String get testingAsProUser => 'آزمایش به عنوان کاربر پرو';

  @override
  String get timeframe30d => '30 روز';

  @override
  String get totalAllocation => 'کل تخصیص';

  @override
  String get totalDebt => 'کل بدهی';

  @override
  String get totalMonthlyIncome => 'کل درآمد ماهانه';

  @override
  String get totalPaid => 'کل پرداخت شده';

  @override
  String get totalPayments => 'کل پرداخت‌ها';

  @override
  String get trackCreditCardsAndLoans => 'پیگیری کارت‌های اعتباری و وام‌ها';

  @override
  String get trackYourIncomeSources => 'منابع درآمد خود را پیگیری کنید';

  @override
  String get trackYourNetWorth => 'ارزش خالص خود را پیگیری کنید';

  @override
  String get trend => 'روند';

  @override
  String get unlockAdvancedFeatures => 'باز کردن ویژگی‌های پیشرفته';

  @override
  String get unsavedChanges => 'تغییرات ذخیره نشده';

  @override
  String get unsavedChangesMessage =>
      'شما تغییرات ذخیره نشده دارید. آیا می‌خواهید آنها را لغو کنید؟';

  @override
  String get updateAccount => 'به‌روزرسانی حساب';

  @override
  String get updateLiability => 'به‌روزرسانی بدهی';

  @override
  String get used => 'استفاده شده';

  @override
  String get useDarkTheme => 'استفاده از تم تیره';

  @override
  String get usEquity => 'سهام آمریکا';

  @override
  String get usEquityTarget => 'هدف سهام آمریکا';

  @override
  String get usEquityTargetHelper => 'درصد هدف برای سهام آمریکا';

  @override
  String get view => 'مشاهده';

  @override
  String get viewAllAccounts => 'مشاهده همه حساب‌ها';

  @override
  String get whatTypesOfDebt => 'چه نوع بدهی‌هایی را می‌توانید پیگیری کنید؟';

  @override
  String get why => 'چرا';

  @override
  String cutConcentration(String details) {
    return 'کاهش تمرکز: $details';
  }

  @override
  String errorSavingIncome(String error) {
    return 'خطا در ذخیره درآمد: $error';
  }

  @override
  String deleteIncomeConfirm(String name) {
    return 'آیا مطمئن هستید که می‌خواهید $name را حذف کنید؟';
  }

  @override
  String errorLoadingSettings(String error) {
    return 'خطا در بارگذاری تنظیمات: $error';
  }

  @override
  String failedToSaveSettings(String error) {
    return 'ذخیره تنظیمات انجام نشد: $error';
  }

  @override
  String dayOfMonth(String day) {
    return 'روز ماه: $day';
  }

  @override
  String errorLoadingIncome(String error) {
    return 'خطا در بارگذاری درآمد: $error';
  }

  @override
  String errorDeletingIncome(String error) {
    return 'خطا در حذف درآمد: $error';
  }

  @override
  String get mixAndDials => 'ترکیب و صفحه‌ها';

  @override
  String errorLoadingDataWithError(String error) {
    return 'خطا در بارگذاری داده: $error';
  }

  @override
  String errorLoadingDebtData(String error) {
    return 'خطا در بارگذاری داده‌های بدهی: $error';
  }

  @override
  String get noDataAvailable => 'داده‌ای در دسترس نیست';

  @override
  String get dollarCostAveragingCalculations => 'محاسبات میانگین هزینه دلار';

  @override
  String get primarySecondaryRebalancingTargets =>
      'اهداف تعادل مجدد اولیه/ثانویه';

  @override
  String get timelineWithMonitoringAlerts => 'جدول زمانی با هشدارهای نظارتی';

  @override
  String get adjustTargetAllocation => 'تنظیم تخصیص هدف';

  @override
  String get savePlan => 'ذخیره طرح';

  @override
  String get previewPdf => 'پیش‌نمایش PDF';

  @override
  String get back => 'برگشت';

  @override
  String get aboutMixAndDials => 'درباره ترکیب و صفحه‌ها';

  @override
  String get mixAndDialsDescription =>
      'این صفحه تحلیل مفصلی از پورتفولیو شما ارائه می‌دهد:';

  @override
  String get assetAllocationBreakdown =>
      '• تخصیص دارایی - تفکیک بصری سرمایه‌گذاری‌های شما';

  @override
  String get diversificationDials => '• صفحه‌های تنوع - توزیع ریسک و جغرافیایی';

  @override
  String get rebalancingPlansRecommendations =>
      '• طرح‌های تعادل مجدد - پیشنهادات قابل اجرا';

  @override
  String get rebalancingPlanSavedSuccessfully =>
      'طرح تعادل مجدد با موفقیت ذخیره شد!';

  @override
  String get planSaved => 'طرح ذخیره شد';

  @override
  String get ok => 'تأیید';

  @override
  String get pdfPreview => 'پیش‌نمایش PDF';

  @override
  String get close => 'بستن';

  @override
  String get pdfExportFeatureComingSoon => 'ویژگی صادرات PDF به زودی!';

  @override
  String get downloadPdf => 'دانلود PDF';

  @override
  String get maybeLater => 'شاید بعداً';

  @override
  String errorLoadingAccountsWithError(String error) {
    return 'خطا در بارگذاری حساب‌ها: $error';
  }

  @override
  String get gettingStartedGuide => 'راهنمای شروع';

  @override
  String get previewWithSampleData => 'پیش‌نمایش با داده نمونه';

  @override
  String get archiveAccount => 'بایگانی حساب';

  @override
  String get archived => 'بایگانی شده';

  @override
  String get archive => 'بایگانی';

  @override
  String get loadSampleData => 'بارگذاری داده نمونه';

  @override
  String get sampleDataLoaded => 'داده نمونه بارگذاری شد!';

  @override
  String get load => 'بارگذاری';

  @override
  String get viewAccountsWithUsEquity => 'مشاهده حساب‌ها با سهام آمریکا';

  @override
  String get learnMore => 'بیشتر بدانید';

  @override
  String get riskNudgeSnoozed => 'یادآوری ریسک برای 30 روز به تعویق افتاد';

  @override
  String get riskMarkedAsResolved => 'ریسک به عنوان حل شده علامت‌گذاری شد';

  @override
  String get howWeCalculateThis => 'چگونه این را محاسبه می‌کنیم';

  @override
  String get yourFinancialHealthScoreBasedOn =>
      'امتیاز سلامت مالی شما بر اساس:';

  @override
  String get concentrationRiskPercent => '• ریسک تمرکز (30%)';

  @override
  String get fixedIncomeBalancePercent => '• تعادل درآمد ثابت (25%)';

  @override
  String get liquidityBufferPercent => '• بافر نقدینگی (20%)';

  @override
  String get internationalExposurePercent =>
      '• قرار گرفتن در معرض بین‌المللی (15%)';

  @override
  String get debtManagementPercent => '• مدیریت بدهی (10%)';

  @override
  String get addAccounts => 'افزودن حساب‌ها';

  @override
  String get addMonthlyEssentials => 'افزودن ملزومات ماهانه';

  @override
  String get noTrendDataAvailable => 'داده‌های روند در دسترس نیست';

  @override
  String get exportPdfReport => 'صدور گزارش PDF';

  @override
  String get saveAsSnapshot => 'ذخیره به عنوان اسنپ‌شات';

  @override
  String get viewScoreHistory => 'مشاهده تاریخچه امتیاز';

  @override
  String get compare => 'مقایسه';

  @override
  String get create => 'ایجاد';

  @override
  String get saved => 'ذخیره شد';

  @override
  String failedToCreateSnapshot(String error) {
    return 'ایجاد اسنپ‌شات ناموفق بود: $error';
  }

  @override
  String get snapshotDetail => 'جزئیات اسنپ‌شات';

  @override
  String get snapshotNote => 'یادداشت اسنپ‌شات';

  @override
  String savedToDownloads(String filename) {
    return 'ذخیره شده در Downloads/$filename';
  }

  @override
  String downloadFailed(String error) {
    return 'دانلود ناموفق بود: $error';
  }

  @override
  String isAvailableWithRebalancePro(String feature) {
    return '$feature با Rebalance Pro در دسترس است.';
  }

  @override
  String get startCompare => 'شروع مقایسه';

  @override
  String get selectThisAsStartingPoint =>
      'این را به عنوان نقطه شروع برای مقایسه انتخاب کنید';

  @override
  String get deleteSnapshot => 'اسنپ‌شات حذف شود؟';

  @override
  String failedToDeleteSnapshot(String error) {
    return 'حذف اسنپ‌شات ناموفق بود: $error';
  }

  @override
  String get unlockTaxOptimization => 'باز کردن بهینه‌سازی مالیات';

  @override
  String get estimatedAnnualTaxSavings => 'صرفه‌جویی مالیاتی سالانه تخمینی';

  @override
  String potentialSavings(String amount) {
    return 'صرفه‌جویی بالقوه: $amount / سال';
  }

  @override
  String get yourAssetsAreAlreadyTaxEfficient =>
      'دارایی‌های شما از قبل به صورت کارآمد از نظر مالیاتی قرار دارند. 👍';

  @override
  String get suggestedReallocation => 'تخصیص مجدد پیشنهادی';

  @override
  String get assumptionsAndMethodology => 'فرضیات و روش‌شناسی';

  @override
  String get enableNotifications => 'فعال‌سازی اعلان‌ها';

  @override
  String get getAlertsAboutDrift =>
      'دریافت هشدار درباره انحراف و فرصت‌های تعادل مجدد';

  @override
  String get set => 'تنظیم';

  @override
  String get howItWorks => 'چگونه کار می‌کند';

  @override
  String get averageAnnualReturn => '• میانگین بازدهی سالانه: 7%';

  @override
  String get marketVolatility => '• نوسانات بازار: 15%';

  @override
  String get inflationRate => '• تورم: 3% در سال';

  @override
  String get noDebtsToOptimize => 'بدهی برای بهینه‌سازی وجود ندارد!';

  @override
  String get addLiabilitiesFromTab =>
      'برای استفاده از این ابزار، بدهی‌ها را از تب بدهی‌ها اضافه کنید.';

  @override
  String get currentDebt => 'بدهی فعلی';

  @override
  String liabilityCount(int count, String minPayment) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بدهی',
      one: 'بدهی',
    );
    return '$count $_temp0 • $minPayment/ماه حداقل';
  }

  @override
  String get extraMonthlyPayment => 'پرداخت اضافی ماهانه';

  @override
  String totalMonthlyPayment(String amount) {
    return 'کل پرداخت ماهانه: $amount';
  }

  @override
  String get payoffStrategies => 'استراتژی‌های بازپرداخت';

  @override
  String get strategyRecommendation =>
      'ما گزینه با بهره کل کمتر را توصیه می‌کنیم. شما همچنان می‌توانید دیگری را برای برد‌های انگیزشی انتخاب کنید.';

  @override
  String get avalanche => 'بهمن';

  @override
  String get avalancheRecommended => 'بهمن (توصیه شده)';

  @override
  String get avalancheDescription =>
      'بالاترین نرخ بهره اول – بهره کل را کاهش می‌دهد';

  @override
  String get snowball => 'گلوله برفی';

  @override
  String get snowballRecommended => 'گلوله برفی (توصیه شده)';

  @override
  String get snowballDescription =>
      'کوچکترین مانده اول – برد‌های روانی سریع‌تر';

  @override
  String get unlockDetailedPayoffSchedule => 'باز کردن برنامه بازپرداخت تفصیلی';

  @override
  String get monthByMonthBreakdown =>
      'تفکیک ماه‌به‌ماه پرداخت دریافت کنید که نشان می‌دهد:';

  @override
  String get exactPayoffDate => 'تاریخ دقیق بازپرداخت برای هر بدهی';

  @override
  String get principalVsInterest => 'تفکیک اصل در مقابل بهره';

  @override
  String get remainingBalanceTracking => 'ردیابی مانده باقیمانده';

  @override
  String totalInterestSaved(String amount) {
    return 'کل بهره صرفه‌جویی شده: $amount';
  }

  @override
  String get debtPayoffOrder => 'ترتیب بازپرداخت بدهی';

  @override
  String debtsWillBePaidInOrder(String strategy) {
    return 'بدهی‌ها به این ترتیب پرداخت خواهند شد (استراتژی $strategy):';
  }

  @override
  String get paidOff => 'پرداخت شده';

  @override
  String get payoffTime => 'زمان بازپرداخت';

  @override
  String monthsCount(int count) {
    return '$count ماه';
  }

  @override
  String get totalInterest => 'کل بهره';

  @override
  String saveVsMinimum(String amount) {
    return 'صرفه‌جویی $amount در مقابل حداقل پرداخت‌ها';
  }

  @override
  String get detailedPaymentSchedule => 'برنامه پرداخت تفصیلی';

  @override
  String monthByMonthStrategy(String strategy) {
    return 'تفکیک ماه‌به‌ماه (استراتژی $strategy):';
  }

  @override
  String monthNumber(int number) {
    return 'ماه $number';
  }

  @override
  String principalAndInterest(String principal, String interest) {
    return '$principal اصل • $interest بهره';
  }

  @override
  String remaining(String amount) {
    return 'باقیمانده: $amount';
  }

  @override
  String moreMonths(int count) {
    return '... $count ماه دیگر';
  }

  @override
  String get strategyComparison => 'مقایسه استراتژی';

  @override
  String strategySavingsComparison(
      String strategy, String interestDiff, String monthsInfo) {
    return '$strategy $interestDiff بهره بیشتر صرفه‌جویی می‌کند$monthsInfo در مقابل رویکرد دیگر.';
  }

  @override
  String andFinishesEarlier(int months, String plural) {
    return ' و $months ماه$plural زودتر به پایان می‌رسد';
  }

  @override
  String get unlockDebtPayoffOptimizer => 'باز کردن بهینه‌ساز بازپرداخت بدهی';

  @override
  String get fastestPathToDebtFreedom =>
      'سریع‌ترین مسیر به آزادی از بدهی را پیدا کنید';

  @override
  String get compareAvalancheSnowball =>
      'استراتژی‌های بهمن در مقابل گلوله برفی را مقایسه کنید';

  @override
  String get seeExactPayoffDates =>
      'تاریخ‌های دقیق بازپرداخت برای هر بدهی را ببینید';

  @override
  String get calculateInterestSavings => 'کل صرفه‌جویی بهره را محاسبه کنید';

  @override
  String get getMonthlySchedule => 'برنامه پرداخت ماه‌به‌ماه دریافت کنید';

  @override
  String get best => 'بهترین';

  @override
  String get selected => 'انتخاب شده';

  @override
  String get selectStrategy => 'استراتژی انتخاب کنید';

  @override
  String get typesOfDebtYouCanTrack => 'انواع بدهی که می‌توانید ردیابی کنید';

  @override
  String get creditCardsDescription =>
      '• کارت‌های اعتباری - ردیابی موجودی و استفاده از اعتبار';

  @override
  String get mortgagesDescription => '• رهن - وام‌های مسکن و تأمین مجدد مالی';

  @override
  String get autoLoansDescription =>
      '• وام‌های خودرو - تأمین مالی خودرو و وسیله نقلیه';

  @override
  String get studentLoansDescription => '• وام‌های دانشجویی - بدهی تحصیلی';

  @override
  String get personalLoansDescription => '• وام‌های شخصی - بدهی بدون وثیقه';

  @override
  String get helocDescription => '• HELOC - خطوط اعتباری سهام مسکن';

  @override
  String get businessLoansDescription => '• وام‌های تجاری - بدهی تجاری';

  @override
  String get upgradeForProFeatures =>
      'برای برنامه‌های نامحدود، صادرات PDF و تجزیه و تحلیل پیشرفته به نسخه حرفه‌ای ارتقا دهید.';

  @override
  String get upgradeForPdfExports =>
      'برای صادرات PDF، برنامه‌های نامحدود و تجزیه و تحلیل پیشرفته به نسخه حرفه‌ای ارتقا دهید.';

  @override
  String get pdfExportAvailable => 'صادرات PDF با Rebalance Pro در دسترس است.';

  @override
  String get pdfExportProMessage =>
      'صادرات PDF با Rebalance Pro در دسترس است.\n\nبرای صادرات PDF، برنامه‌های نامحدود و تجزیه و تحلیل پیشرفته به نسخه حرفه‌ای ارتقا دهید.';

  @override
  String get taxOptimizationDescription =>
      'کشش مالیاتی سالانه تخمینی را ببینید و نحوه کاهش آن را با موقعیت بهتر دارایی.';

  @override
  String potentialSavingsPerYear(String amount) {
    return 'صرفه‌جویی بالقوه: $amount / سال';
  }

  @override
  String get assetsAlreadyTaxEfficient =>
      'دارایی‌های شما از قبل به طور کارآمد مالیاتی قرار گرفته‌اند. 👍';

  @override
  String estimatedYearlyImpact(String amount) {
    return 'تأثیر سالانه تخمینی: $amount';
  }

  @override
  String get unlockCustomAlerts => 'باز کردن قفل هشدارهای سفارشی';

  @override
  String get alertSettingsSaved => 'تنظیمات هشدار ذخیره شد';

  @override
  String failedToSave(String error) {
    return 'ذخیره ناموفق بود: $error';
  }

  @override
  String get thresholds => 'آستانه‌ها';

  @override
  String get driftThreshold => 'آستانه انحراف';

  @override
  String get concentrationCap => 'حد تمرکز';

  @override
  String get employerStockCap => 'حد سهام کارفرما';

  @override
  String get notifications => 'اعلان‌ها';

  @override
  String get enableAlertNotifications => 'فعال کردن اعلان‌های هشدار';

  @override
  String get receiveAlertNotificationsDescription =>
      'هشدارهای داخل برنامه را هنگام نقض آستانه‌ها دریافت کنید';

  @override
  String get dollarImpactPreview => 'پیش‌نمایش تأثیر دلار';

  @override
  String get exampleImpact => 'نمونه تأثیر';

  @override
  String get exampleImpactDescription =>
      'هنگامی که یک آستانه نقض می‌شود، هشدارها مبلغ تخمینی دلار مرتبط با قرار گرفتن بیش از حد را نشان می‌دهند تا کاربران تأثیر مالی واقعی را بدانند.';

  @override
  String get scenarioA => 'سناریو A';

  @override
  String get scenarioB => 'سناریو B';

  @override
  String get monthlyContribution => 'کمک ماهانه';

  @override
  String get expectedReturn => 'بازده مورد انتظار';

  @override
  String get volatility => 'نوسان';

  @override
  String get years => 'سال‌ها';

  @override
  String get goalAmount => 'مبلغ هدف';

  @override
  String get resultsA => 'نتایج A';

  @override
  String get resultsB => 'نتایج B';

  @override
  String get successProbability => 'احتمال موفقیت';

  @override
  String get medianEnding => 'پایان میانه';

  @override
  String get tenthPercentile => 'دهک دهم';

  @override
  String get ninetiethPercentile => 'دهک نودم';

  @override
  String get retirementSimulationDescription =>
      'این ماشین حساب 1000 شبیه‌سازی را برای تخمین احتمال موفقیت بازنشستگی شما اجرا می‌کند.';

  @override
  String get yourRetirementPlan => 'طرح بازنشستگی شما';

  @override
  String get currentSavings => 'پس‌انداز فعلی';

  @override
  String get yearsUntilRetirement => 'سال‌ها تا بازنشستگی';

  @override
  String get desiredMonthlyIncome => 'درآمد ماهانه مطلوب';

  @override
  String get yearsInRetirement => 'سال‌های بازنشستگی';

  @override
  String get outcomeDistribution => 'توزیع نتایج';

  @override
  String get outcomeLikelihood => 'احتمال نتایج مختلف';

  @override
  String get fail => 'شکست';

  @override
  String get low => 'پایین';

  @override
  String get med => 'متوسط';

  @override
  String get high => 'بالا';

  @override
  String get recommendations => 'توصیه‌ها';

  @override
  String moveToTaxAdvantaged(Object amount, Object asset) {
    return '$amount از $asset را به حساب مزایای مالیاتی منتقل کنید';
  }

  @override
  String get estimatedAnnualImpact => 'تأثیر سالانه تخمینی';

  @override
  String considerIncreasingContributions(Object amount) {
    return 'برای بهبود شانس خود، افزایش کمک‌های ماهانه به $amount را در نظر بگیرید.';
  }

  @override
  String get excellentOnTrack => 'عالی! برنامه بازنشستگی شما در مسیر درست است.';

  @override
  String incomeExceedsSafeWithdrawal(Object desired, Object safe) {
    return 'درآمد مطلوب شما ($desired) از مبلغ برداشت ایمن \"قانون 4٪\" ($safe) بیشتر است.';
  }

  @override
  String timeIsAdvantage(Object years) {
    return 'با $years سال تا بازنشستگی، زمان بزرگترین مزیت شماست. با کمک‌ها ثابت قدم باشید.';
  }

  @override
  String get planReasonable =>
      'برنامه شما منطقی است. سالانه بررسی کنید و با تغییر وضعیت خود تنظیم کنید.';

  @override
  String get successProbabilityLabel => 'احتمال موفقیت';

  @override
  String grade(Object grade) {
    return 'نمره $grade';
  }

  @override
  String get atRetirement => 'در بازنشستگی';

  @override
  String get medianAfterRetirement => 'میانه پس از بازنشستگی';

  @override
  String get bestCase90th => 'بهترین حالت (دهک 90)';

  @override
  String simulationsYears(Object simulations, Object years) {
    return 'شبیه‌سازی‌ها: $simulations\\nسال‌ها: $years';
  }

  @override
  String get distributionSortedOutcomes => 'توزیع (نتایج مرتب‌شده)';

  @override
  String get thisWeeksSafeToSpend => 'ایمن برای خرج کردن این هفته';

  @override
  String get onTrack => 'در مسیر درست';

  @override
  String daysOfBuffer(int days) {
    return '$days روز ذخیره باقی‌مانده';
  }

  @override
  String youllBeShort(String amount, String day) {
    return '⚠ با این سرعت تا $day به میزان $amount کم خواهید آورد';
  }

  @override
  String incomeAmount(String amount) {
    return 'درآمد $amount';
  }

  @override
  String billsAmount(String amount) {
    return 'قبوض $amount';
  }

  @override
  String get tapToSeeGuardrails => 'برای مشاهده محدودیت‌ها ضربه بزنید';

  @override
  String get moneyHealthScore => 'امتیاز سلامت مالی';

  @override
  String weakestArea(String area) {
    return '$area ضعیف‌ترین نقطه شما در حال حاضر است';
  }

  @override
  String get neverBrokeWeek => 'دیگر هرگز \'هفته بی‌پولی\' نداشته باشید.';

  @override
  String get answerQuestionsGuardrails =>
      'به 3 سؤال سریع پاسخ دهید و ما به شما می‌گوییم این هفته چقدر می‌توانید با اطمینان خرج کنید.';

  @override
  String get setupGuardrails => 'تنظیم محدودیت‌های من (30 ثانیه)';

  @override
  String get updatedNow => 'هم اکنون به‌روزرسانی شد';

  @override
  String get weeklyGuardrails => 'محدودیت‌های هفتگی';

  @override
  String get safeToSpendThisWeek => 'امن برای خرج کردن این هفته';

  @override
  String get overBudgetThisWeek => 'بیش از بودجه این هفته';

  @override
  String alreadyOverThisWeek(String amount) {
    return 'شما قبلاً $amount از بودجه این هفته فراتر رفته‌اید';
  }

  @override
  String goingNegativeByDay(String day) {
    return 'شما در مسیر منفی شدن تا $day هستید';
  }

  @override
  String willBeShortByFriday(String amount) {
    return 'تا جمعه $amount کمبود خواهید داشت';
  }

  @override
  String bufferUntilNext(String day) {
    return 'ذخیره تا $day بعدی';
  }

  @override
  String bufferUntil(String day) {
    return 'ذخیره تا $day';
  }

  @override
  String get warningZoneToast =>
      'شما این هفته در منطقه هشدار هستید. برای دیدن اینکه اگر بیشتر خرج کنید چه اتفاقی می‌افتد، روی کارت ضربه بزنید.';

  @override
  String get monday => 'دوشنبه';

  @override
  String get tuesday => 'سه‌شنبه';

  @override
  String get wednesday => 'چهارشنبه';

  @override
  String get thursday => 'پنج‌شنبه';

  @override
  String get friday => 'جمعه';

  @override
  String get saturday => 'شنبه';

  @override
  String get sunday => 'یکشنبه';

  @override
  String get buffer => 'ذخیره';

  @override
  String bufferUntilDay(String day) {
    return 'اگر مانند هفته گذشته خرج کنید، تا $day ذخیره دارید';
  }

  @override
  String get whatIfYouSpendMore => 'اگر بیشتر خرج کنید چه می‌شود؟';

  @override
  String get additionalSpending => 'هزینه اضافی';

  @override
  String ifYouSpendMore(String amount, String shortage, String date) {
    return 'اگر این هفته +$amount بیشتر خرج کنید ← در $date به میزان $shortage کم خواهید آورد';
  }

  @override
  String stillOnTrack(String buffer) {
    return 'هنوز در مسیر هستید با ذخیره $buffer';
  }

  @override
  String get weeklyIncome => 'درآمد هفتگی';

  @override
  String get weeklyBills => 'قبوض هفتگی';

  @override
  String get bufferDiscretionary => 'ذخیره / اختیاری';

  @override
  String get adjustIncome => 'تنظیم درآمد';

  @override
  String get editBills => 'ویرایش قبوض';

  @override
  String get neverGuessAgain => 'دیگر حدس نزنید';

  @override
  String get autoAlertsProUpsell =>
      'هشدارهای خودکار دریافت کنید وقتی در آستانه تجاوز از مبلغ امن خرج هفتگی خود هستید. قبل از اشتباه بدانید.';

  @override
  String get expenses => 'هزینه‌ها';

  @override
  String get monthlyExpenses => 'هزینه‌های ماهانه';

  @override
  String get noExpensesTracked => 'هیچ هزینه‌ای ثبت نشده';

  @override
  String get trackMonthlyBills =>
      'قبض‌های ماهانه منظم خود مانند اجاره، آب و برق، بیمه و اشتراک‌ها را پیگیری کنید';

  @override
  String get addYourFirstExpense => 'اولین هزینه خود را اضافه کنید';

  @override
  String get addExpense => 'افزودن هزینه';

  @override
  String get editExpense => 'ویرایش هزینه';

  @override
  String get expenseName => 'نام هزینه';

  @override
  String get expenseNameHint => 'به عنوان مثال، قبض برق، اینترنت';

  @override
  String get monthlyAmount => 'مبلغ ماهانه';

  @override
  String get category => 'دسته بندی';

  @override
  String get dueDayOptional => 'روز سررسید (اختیاری)';

  @override
  String get dueDayHint => 'به عنوان مثال، 15 برای 15 ماه';

  @override
  String get mustBeBetween1And31 => 'باید بین 1 تا 31 باشد';

  @override
  String get expenseUpdated => 'هزینه به روز شد';

  @override
  String get expenseAdded => 'هزینه اضافه شد';

  @override
  String get deleteExpenseTitle => 'هزینه حذف شود؟';

  @override
  String get deleteExpenseConfirmation =>
      'آیا مطمئنید که می خواهید این هزینه را حذف کنید؟';

  @override
  String get expenseDeleted => 'هزینه حذف شد';

  @override
  String get expenseCategoryRentMortgage => 'اجاره / رهن';

  @override
  String get expenseCategoryUtilities => 'آب و برق';

  @override
  String get expenseCategoryInsurance => 'بیمه';

  @override
  String get expenseCategorySubscriptions => 'اشتراک ها';

  @override
  String get totalMonthlyExpenses => 'جمع هزینه‌های ماهانه';

  @override
  String get perWeekFull => '/هفته';

  @override
  String get perWeekShort => '/هفته';

  @override
  String dueOnDay(String day) {
    return 'سررسید روز $day';
  }

  @override
  String get profileSetup => 'تنظیم پروفایل';

  @override
  String percentComplete(int percentage) {
    return '$percentage% کامل';
  }

  @override
  String get completeProfileInsights =>
      'پروفایل خود را برای بینش‌های بهتر تکمیل کنید';

  @override
  String get importExportTitle => 'واردات و صادرات';

  @override
  String get backupRestoreSectionTitle => 'پشتیبان گیری و بازیابی';

  @override
  String get exportToCsvTitle => 'صادرات به CSV';

  @override
  String get exportToCsvSubtitle =>
      'رایگان • صادرات مانده حساب برای تجزیه و تحلیل صفحه گسترده';

  @override
  String get createCompleteBackupTitle => 'پشتیبان گیری کامل ایجاد کنید';

  @override
  String get createCompleteBackupSubtitle =>
      'تمام داده ها (حساب ها، بدهی ها، درآمد، تنظیمات) را به یک فایل صادر کنید';

  @override
  String get createEncryptedBackupTitle => 'ایجاد پشتیبان رمزگذاری شده';

  @override
  String get createEncryptedBackupSubtitle =>
      'توصیه می شود • قبل از ذخیره، پشتیبان را با یک عبارت عبور رمزگذاری کنید';

  @override
  String get restoreFromBackupTitle => 'بازیابی از پشتیبان';

  @override
  String get restoreFromBackupSubtitle =>
      'تمام داده ها را از یک فایل پشتیبان بازیابی کنید';

  @override
  String get exportCsvDialogTitle => 'صادرات CSV';

  @override
  String get exportCsvDialogDescription =>
      'فایل CSV شما مستقیماً در پوشه دانلودها ذخیره می شود.';

  @override
  String get exportButtonLabel => 'صادرات';

  @override
  String csvSavedToDownloads(String filename) {
    return 'ذخیره شده در دانلودها:\\n$filename';
  }

  @override
  String exportFailedWithError(String error) {
    return 'صادر نشد: $error';
  }

  @override
  String get encryptedBackupDialogTitle => 'ایجاد پشتیبان رمزگذاری شده';

  @override
  String get backupPassphraseDialogTitle => 'رمز عبور پشتیبان';

  @override
  String get newBackupPassphraseDescription =>
      'از یک عبارت عبور قوی (12+ نویسه با بالا/پایین/رقم/نماد) استفاده کنید. در صورت گم شدن، این نسخه پشتیبان قابل بازیابی نیست.';

  @override
  String get existingBackupPassphraseDescription =>
      'عبارت عبور مورد استفاده در هنگام ایجاد این پشتیبان رمزگذاری شده را وارد کنید.';

  @override
  String get passphraseLabel => 'عبارت عبور';

  @override
  String get confirmPassphraseLabel => 'رمز عبور را تایید کنید';

  @override
  String get passphraseRequiredError => 'عبارت عبور مورد نیاز است.';

  @override
  String get passphrasesDoNotMatchError => 'عبارات عبور مطابقت ندارند.';

  @override
  String get continueLabel => 'ادامه دهید';

  @override
  String get passphraseMinLengthError =>
      'عبارت عبور باید حداقل 12 کاراکتر باشد.';

  @override
  String get passphraseComplexityError =>
      'حداقل از یک حروف بزرگ، کوچک، عدد و نماد استفاده کنید.';

  @override
  String get createBackupFailed => 'پشتیبان‌گیری ایجاد نشد';

  @override
  String backupSavedToDownloads(String filePath) {
    return 'پشتیبان‌گیری در دانلودها ذخیره شد:\\n$filePath';
  }

  @override
  String backupFailedWithError(String error) {
    return 'پشتیبان‌گیری انجام نشد: $error';
  }

  @override
  String get createEncryptedBackupFailed => 'پشتیبان رمزگذاری شده ایجاد نشد';

  @override
  String encryptedBackupSavedToDownloads(String filePath) {
    return 'پشتیبان رمزگذاری شده ذخیره شده در دانلودها:\\n$filePath';
  }

  @override
  String encryptedBackupFailedWithError(String error) {
    return 'پشتیبان‌گیری رمزگذاری شده انجام نشد: $error';
  }

  @override
  String get restoreConfirmTitle => 'بازیابی از پشتیبان گیری؟';

  @override
  String get restoreConfirmWarning =>
      'اخطار: این کار همه داده‌های فعلی شما را با داده‌های فایل پشتیبان جایگزین می‌کند.\\n\\nداده‌های فعلی شما برای همیشه حذف می‌شوند.\\n\\nقبل از ادامه، مطمئن شوید که یک نسخه پشتیبان از داده‌های فعلی خود دارید.';

  @override
  String get restoreButtonLabel => 'بازیابی کنید';

  @override
  String get restoreTooManyPassphraseAttempts =>
      'تعداد زیادی تلاش برای عبارت عبور نادرست. بازیابی لغو شد.';

  @override
  String get restoreSuccessfulTitle => 'بازیابی موفقیت آمیز!';

  @override
  String restoreFailedWithError(String error) {
    return 'بازیابی انجام نشد: $error';
  }

  @override
  String get householdProfilesBetaTitle => 'نمایه‌های خانگی (بتا)';

  @override
  String get householdProfilesDescription =>
      'ایجاد و جابجایی بین پروفایل ها داده های مالی اصلی اکنون در هر نمایه خانوار فعال بارگیری می شود.';

  @override
  String get householdActiveProfileLabel => 'پروفایل فعال';

  @override
  String get householdNoProfilesAvailable => 'هیچ نمایه ای در دسترس نیست';

  @override
  String get householdAddProfileTitle => 'افزودن نمایه خانوار';

  @override
  String get householdRenameProfileTitle => 'تغییر نام نمایه';

  @override
  String get householdDeleteProfileTitle => 'نمایه حذف شود؟';

  @override
  String get householdProfileNameLabel => 'نام پروفایل';

  @override
  String householdDeleteProfileDescription(String name) {
    return 'نمایه \"$name\" حذف شود؟ این تنها زمانی مجاز است که نمایه هیچ گونه سوابق مالی اختصاص داده نشده باشد.';
  }

  @override
  String get householdCreateAtLeastTwoProfiles =>
      'قبل از انتقال داده حداقل دو نمایه ایجاد کنید.';

  @override
  String get householdMoveDataTitle => 'انتقال داده ها بین پروفایل ها';

  @override
  String get householdMoveDataDescription =>
      'با این کار حساب‌ها، بدهی‌ها، درآمدها، هزینه‌ها و اهداف انتخاب شده از یک نمایه به نمایه دیگر اختصاص داده می‌شود.';

  @override
  String get householdMoveFromProfileLabel => 'از نمایه';

  @override
  String get householdMoveToProfileLabel => 'برای پروفایل';

  @override
  String get householdMoveDataTypesLabel => 'انواع داده برای جابجایی';

  @override
  String get householdDataTypeGoals => 'اهداف';

  @override
  String get householdMoveProfilesMustDiffer =>
      'نمایه منبع و هدف باید متفاوت باشد.';

  @override
  String get householdMoveSelectAtLeastOneType =>
      'حداقل یک نوع داده را برای انتقال انتخاب کنید.';

  @override
  String get householdGoalsSectionTitle => 'اهداف خانگی';

  @override
  String get householdGoalNoGoalsForActive =>
      'هنوز هدفی برای نمایه فعال وجود ندارد.';

  @override
  String get householdAddGoalTitle => 'افزودن هدف خانگی';

  @override
  String get householdEditGoalTitle => 'ویرایش هدف خانگی';

  @override
  String get householdGoalNameLabel => 'نام هدف';

  @override
  String get householdGoalTargetAmountLabel => 'مقدار هدف';

  @override
  String get householdGoalCurrentAmountLabel => 'مقدار ذخیره شده فعلی';

  @override
  String get householdGoalSharedToggle =>
      'هدف مشترک (قابل مشاهده برای همه نمایه ها)';

  @override
  String get householdGoalOwnerProfileLabel => 'مشخصات مالک';

  @override
  String get householdGoalNameRequired => 'نام هدف را وارد کنید';

  @override
  String get householdGoalTargetInvalid => 'یک مقدار هدف معتبر وارد کنید.';

  @override
  String get householdGoalCurrentInvalid => 'مقدار جاری معتبر وارد کنید.';

  @override
  String get householdGoalOwnerRequired => 'نمایه مالک را انتخاب کنید.';

  @override
  String get householdGoalScopeShared => 'به اشتراک گذاشته شده است';

  @override
  String get householdGoalScopeProfileUnknown => 'نمایه';

  @override
  String householdGoalScopeProfile(String name) {
    return 'نمایه: $name';
  }

  @override
  String get householdGoalDeleteTitle => 'هدف حذف شود؟';

  @override
  String householdGoalDeleteMessage(String name) {
    return 'هدف \"$name\" حذف شود؟';
  }

  @override
  String householdGoalFailedToAdd(String error) {
    return 'هدف اضافه نشد: $error';
  }

  @override
  String householdGoalFailedToDelete(String error) {
    return 'هدف حذف نشد: $error';
  }

  @override
  String householdGoalFailedToUpdate(String error) {
    return 'هدف به‌روزرسانی نشد: $error';
  }

  @override
  String get householdGoalEditSplitsTitle => 'ویرایش تقسیم های مشارکت';

  @override
  String get householdGoalEditSplitsTooltip => 'ویرایش تقسیم مشارکت';

  @override
  String get householdGoalSplitNeedPositive =>
      'درصد تقسیم بالای صفر را وارد کنید.';

  @override
  String householdGoalFailedToUpdateSplits(String error) {
    return 'تقسیم‌بندی‌ها به‌روزرسانی نشد: $error';
  }

  @override
  String householdGoalProgressSummary(
      String current, String target, String percent) {
    return 'پیشرفت: $current / $target ($percent%)';
  }

  @override
  String householdGoalSplitPreview(String splits) {
    return 'تقسیمات: $splits';
  }

  @override
  String get householdActiveProfileUpdated => 'نمایه فعال به روز شد';

  @override
  String householdFailedToUpdateProfile(String error) {
    return 'نمایه به‌روزرسانی نشد: $error';
  }

  @override
  String householdFailedToAddProfile(String error) {
    return 'نمایه اضافه نشد: $error';
  }

  @override
  String householdFailedToRenameProfile(String error) {
    return 'تغییر نام نمایه ناموفق بود: $error';
  }

  @override
  String householdFailedToDeleteProfile(String error) {
    return 'نمایه حذف نشد: $error';
  }

  @override
  String householdFailedToMoveData(String error) {
    return 'انتقال داده انجام نشد: $error';
  }

  @override
  String householdMovedRecordsSummary(int total, int accounts, int liabilities,
      int incomes, int expenses, int goals) {
    return 'رکوردهای $total منتقل شد (A:$accounts، L:$liabilities، I:$incomes، E:$expenses، G:$goals).';
  }

  @override
  String get householdStatusActive => 'فعال';

  @override
  String get householdStatusInactive => 'غیر فعال';

  @override
  String get householdDeleteTooltipAtLeastOne => 'حداقل یک نمایه مورد نیاز است';

  @override
  String get householdDeleteTooltipMoveDataFirst =>
      'قبل از حذف این نمایه داده ها را جابه جا کنید';

  @override
  String get householdDeleteTooltipDelete => 'حذف کنید';

  @override
  String householdCountsCompact(
      int accounts, int liabilities, int incomes, int expenses, int goals) {
    return 'A:$accounts L:$liabilities I:$incomes E:$expenses G:$goals';
  }

  @override
  String householdProfileOptionLabel(String name, String counts) {
    return '$name ($counts)';
  }

  @override
  String get householdMoveAllToActiveButton =>
      'همه داده ها را به نمایه فعال منتقل کنید';

  @override
  String get householdMoveAllConfirmTitle =>
      'همه داده ها به نمایه فعال منتقل شوند؟';

  @override
  String householdMoveAllConfirmMessage(int totalMovable, String activeName) {
    return 'با این کار رکوردهای $totalMovable از تمام نمایه های دیگر به \"$activeName\" منتقل می شود.';
  }

  @override
  String get householdMoveAllNoData =>
      'هیچ داده ای برای انتقال از نمایه های دیگر وجود ندارد.';

  @override
  String householdMovableFromOtherProfiles(int count) {
    return 'قابل جابجایی از پروفایل های دیگر: $count';
  }

  @override
  String householdFailedToMoveAllData(String error) {
    return 'انتقال همه داده ها انجام نشد: $error';
  }

  @override
  String get householdGoalSplitsFeatureTitle => 'اهداف مشترک خانگی';

  @override
  String get householdGoalSplitsFeatureOutcome =>
      'تقسیم مشارکت ها بر اساس نمایه و پیگیری پیشرفت.';

  @override
  String get householdGoalSplitsFeatureDescription =>
      'اهداف مشترک تعیین کنید، درصد مشارکت را تعیین کنید و همه را در یک راستا نگه دارید.';
}
