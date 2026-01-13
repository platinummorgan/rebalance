// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ريبالانس';

  @override
  String get netWorth => 'صافي الثروة';

  @override
  String get assets => 'الأصول';

  @override
  String get liabilities => 'الخصوم';

  @override
  String get cashFlow => 'التدفق النقدي';

  @override
  String get healthScore => 'نقاط الصحة المالية';

  @override
  String get proFeatures => 'ميزات برو';

  @override
  String get choosePlan => 'اختر خطتك';

  @override
  String get upgradeToProTitle => 'الترقية إلى برو';

  @override
  String get allProFeatures => 'جميع ميزات برو';

  @override
  String get cancelAnytime => 'إلغاء في أي وقت';

  @override
  String get freeTrialDays => 'تجربة مجانية لمدة 7 أيام';

  @override
  String get proMonthly => 'برو الشهري';

  @override
  String get perMonth => 'شهرياً';

  @override
  String get annual => 'السنوي';

  @override
  String get perYear => 'سنوياً';

  @override
  String get founderLifetime => 'المؤسس مدى الحياة';

  @override
  String get oneTime => 'مرة واحدة';

  @override
  String get bestValue => 'أفضل قيمة';

  @override
  String get limited => 'محدود';

  @override
  String saveMoney(String amount) {
    return 'وفر $amount';
  }

  @override
  String get everythingForever => 'كل شيء للأبد';

  @override
  String get firstFounders => 'أول 1,000 مؤسس';

  @override
  String get priceIncreasesAfter => 'السعر يرتفع بعد ذلك';

  @override
  String get retirementCalculator => 'حاسبة التقاعد';

  @override
  String get debtOptimizer => 'محسن الديون';

  @override
  String get scenarioEngine => 'محرك السيناريوهات';

  @override
  String get taxSmartAllocation => 'التخصيص الضريبي الذكي';

  @override
  String get customAlerts => 'التنبيهات المخصصة';

  @override
  String get advancedAnalytics => 'التحليلات المتقدمة';

  @override
  String get unlockWithPro => 'افتح مع برو';

  @override
  String get startFreeTrial => 'ابدأ التجربة المجانية';

  @override
  String get choosePlanButton => 'اختر الخطة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get currency => 'العملة';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get colorTheme => 'نظام الألوان';

  @override
  String get language => 'اللغة';

  @override
  String get accounts => 'الحسابات';

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String get editAccount => 'تحرير الحساب';

  @override
  String get accountName => 'اسم الحساب';

  @override
  String get accountType => 'نوع الحساب';

  @override
  String get balance => 'الرصيد';

  @override
  String get accountDetails => 'تفاصيل الحساب';

  @override
  String get pleaseEnterAccountName => 'الرجاء إدخال اسم الحساب';

  @override
  String get exampleAccountName => 'مثال، Chase Checking';

  @override
  String get lockedAccount => 'حساب مقفل';

  @override
  String get cannotBeRebalanced => 'لا يمكن إعادة توازنه (401k، معاش، مقيد)';

  @override
  String get canBeRebalanced => 'يمكن تضمينها في خطط إعادة التوازن';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get pleaseEnterBalance => 'الرجاء إدخال رصيد';

  @override
  String get pleaseEnterValidBalance => 'الرجاء إدخال رصيد صحيح';

  @override
  String get debts => 'ديون';

  @override
  String get addDebt => 'إضافة دين';

  @override
  String get minimumPayment => 'الحد الأدنى للدفع';

  @override
  String get interestRate => 'معدل الفائدة';

  @override
  String get rebalancing => 'إعادة التوازن';

  @override
  String get createPlan => 'إنشاء خطة إعادة التوازن';

  @override
  String get targetAllocation => 'التخصيص المستهدف';

  @override
  String get dashboard => 'لوحة القيادة';

  @override
  String get reports => 'التقارير';

  @override
  String get targets => 'الأهداف';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تحرير';

  @override
  String get add => 'إضافة';

  @override
  String get confirm => 'تأكيد';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String errorWithMessage(String message) {
    return 'خطأ: $message';
  }

  @override
  String get success => 'نجح';

  @override
  String get recentAccounts => 'الحسابات الأخيرة';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get noAccountsYet => 'لا توجد حسابات حتى الآن';

  @override
  String get getStarted => 'ابدأ بإضافة حسابك الأول';

  @override
  String get totalAssets => 'إجمالي الأصول';

  @override
  String get totalLiabilities => 'إجمالي الخصوم';

  @override
  String get financialHealth => 'الصحة المالية';

  @override
  String get allocation => 'التخصيص';

  @override
  String get liquidity => 'السيولة';

  @override
  String get debtLoad => 'عبء الديون';

  @override
  String get concentration => 'التركيز';

  @override
  String get excellent => 'ممتاز';

  @override
  String get good => 'جيد';

  @override
  String get fair => 'مقبول';

  @override
  String get needsWork => 'يحتاج إلى تحسين';

  @override
  String get critical => 'حرج';

  @override
  String get poor => 'ضعيف';

  @override
  String get financialHealthScore => 'درجة الصحة المالية';

  @override
  String get howBalancedIsYourPortfolio => 'ما مدى توازن محفظتك؟';

  @override
  String get wellBalanced => 'متوازن بشكل جيد';

  @override
  String get excellentHealth => 'صحة ممتازة';

  @override
  String get goodHealth => 'صحة جيدة';

  @override
  String get fairHealth => 'صحة مقبولة';

  @override
  String get needsWorkHealth => 'يحتاج إلى تحسين';

  @override
  String get poorHealth => 'صحة ضعيفة';

  @override
  String get weightedBreakdown => 'التوزيع الموزون';

  @override
  String get fixedIncomeBalance => 'توازن الدخل الثابت';

  @override
  String get liquidityBuffer => 'احتياطي السيولة';

  @override
  String get internationalExposure => 'التعرض الدولي';

  @override
  String get debtManagement => 'إدارة الديون';

  @override
  String get whatMoved => 'ما الذي تغير';

  @override
  String get sinceLast30d => 'منذ آخر 30 يومًا:';

  @override
  String get reducedUsEquityPosition => 'تم تقليل مركز الأسهم الأمريكية';

  @override
  String get addedFixedIncomeAllocation => 'تمت إضافة توزيع الدخل الثابت';

  @override
  String get noChangeInCashPosition => 'لا يوجد تغيير في المركز النقدي';

  @override
  String get nextActions => 'الإجراءات التالية';

  @override
  String get openMixAndDials => 'فتح المزيج والأقراص';

  @override
  String get reviewDetailedAllocationBreakdown => 'مراجعة تفصيل التوزيع المفصل';

  @override
  String get addToPlan => 'إضافة إلى الخطة';

  @override
  String get createRebalancingStrategy => 'إنشاء استراتيجية إعادة التوازن';

  @override
  String get setTargetAllocation => 'تعيين التوزيع المستهدف';

  @override
  String get adjustYourRiskPreferences => 'ضبط تفضيلات المخاطر الخاصة بك';

  @override
  String get financialHealthTrend => 'اتجاه الصحة المالية';

  @override
  String get keyInsights => 'رؤى رئيسية';

  @override
  String get runSimulation => 'تشغيل المحاكاة';

  @override
  String get explainGradeBands => 'شرح نطاقات الدرجات';

  @override
  String get seeHowAddingBondsAffectsScore =>
      'شاهد كيف تؤثر إضافة 1,500 دولار إلى السندات على نقاطك';

  @override
  String get strongUpwardTrend => 'اتجاه تصاعدي قوي على مدى 6 أشهر';

  @override
  String get consistentImprovementPattern => 'نمط تحسين متسق';

  @override
  String get approachingExcellentHealth => 'الاقتراب من الصحة المالية الممتازة';

  @override
  String get gradualImprovementTrend => 'اتجاه تحسن تدريجي';

  @override
  String get steadyProgressPattern => 'نمط تقدم ثابت';

  @override
  String get decliningTrendNeedsAttention =>
      'الاتجاه المتراجع يحتاج إلى اهتمام';

  @override
  String get highVolatilityInScores => 'تقلب عالي في النقاط';

  @override
  String get considerReviewingStrategy => 'فكر في مراجعة الاستراتيجية المالية';

  @override
  String get slightDownwardTrend => 'اتجاه تنازلي طفيف';

  @override
  String get monitorForContinuedDecline => 'راقب الانخفاض المستمر';

  @override
  String get stableFinancialHealthScore => 'درجة صحة مالية مستقرة';

  @override
  String get lowVolatilityIndicatesConsistency =>
      'التقلب المنخفض يشير إلى الاتساق';

  @override
  String get overall => 'عام';

  @override
  String get weakest => 'الأضعف';

  @override
  String get healthCalculatedFromComponents => 'تم حساب الصحة من 5 مكونات';

  @override
  String get open => 'فتح';

  @override
  String get go => 'انتقال';

  @override
  String get netWorthLabel => 'صافي الثروة';

  @override
  String get assetAllocation => 'توزيع الأصول';

  @override
  String get cash => 'نقد';

  @override
  String get bonds => 'سندات';

  @override
  String get equities => 'أسهم';

  @override
  String get realEstate => 'عقارات';

  @override
  String get commodities => 'سلع';

  @override
  String get crypto => 'عملات رقمية';

  @override
  String get other => 'أخرى';

  @override
  String get totalEquities => 'إجمالي الأسهم';

  @override
  String get vsTarget => 'مقابل الهدف';

  @override
  String get viewFullAnalysis => 'عرض التحليل الكامل';

  @override
  String get reduce => 'تقليل';

  @override
  String get concentrationRisk => 'مخاطر التركيز';

  @override
  String get highRisk => 'مخاطر عالية';

  @override
  String get mediumRisk => 'مخاطر متوسطة';

  @override
  String get lowRisk => 'مخاطر منخفضة';

  @override
  String get spotted => 'تم الرصد';

  @override
  String get ago => 'منذ';

  @override
  String get updated => 'تم التحديث';

  @override
  String get addYourFirstAccount => 'أضف حسابك الأول';

  @override
  String get checkingAccount => 'حساب جاري';

  @override
  String get savingsAccount => 'حساب توفير';

  @override
  String get brokerageAccount => 'حساب وساطة';

  @override
  String get retirementAccount => 'حساب تقاعد';

  @override
  String get reduceConcentrationRisk => 'تقليل مخاطر التركيز';

  @override
  String get largestBucket => 'أكبر مجموعة';

  @override
  String get capPerBucket => 'الحد الأقصى لكل مجموعة';

  @override
  String get targetShift => 'التحول المستهدف';

  @override
  String get createRebalancingPlan => 'إنشاء خطة إعادة التوازن';

  @override
  String get shiftPerMonth => 'التحول شهريا';

  @override
  String get spottedAgo => 'تم الرصد';

  @override
  String get updatedToday => 'تم التحديث اليوم';

  @override
  String get updatedYesterday => 'تم التحديث أمس';

  @override
  String updatedDaysAgo(Object days) {
    return 'تم التحديث منذ $days أيام';
  }

  @override
  String hoursAgo(Object hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String daysAgo(Object days) {
    return 'منذ $days يوم';
  }

  @override
  String monthsAgo(Object months) {
    return 'منذ $months شهر';
  }

  @override
  String get incomeSourceName => 'اسم مصدر الدخل';

  @override
  String get incomeSourceNameHint => 'على سبيل المثال، راتب شركة التكنولوجيا';

  @override
  String get pleaseEnterName => 'يرجى إدخال الاسم';

  @override
  String get incomeType => 'نوع الدخل';

  @override
  String get incomeTypeSalary => 'راتب';

  @override
  String get incomeTypeHourlyWage => 'أجر بالساعة';

  @override
  String get incomeTypeBonus => 'علاوة';

  @override
  String get incomeTypeCommission => 'عمولة';

  @override
  String get incomeTypeFreelance => 'عمل حر';

  @override
  String get incomeTypeRentalIncome => 'دخل الإيجار';

  @override
  String get incomeTypeInvestmentIncome => 'دخل الاستثمار';

  @override
  String get incomeTypePension => 'معاش تقاعدي';

  @override
  String get incomeTypeSocialSecurity => 'الضمان الاجتماعي';

  @override
  String get incomeTypeOther => 'أخرى';

  @override
  String get grossAmount => 'المبلغ الإجمالي';

  @override
  String get pleaseEnterAmount => 'يرجى إدخال المبلغ';

  @override
  String get pleaseEnterValidNumber => 'يرجى إدخال رقم صحيح';

  @override
  String get frequency => 'التكرار';

  @override
  String get addTaxDeductionBreakdown => 'إضافة تفصيل الضرائب والخصومات';

  @override
  String get trackFederalTaxStateTax =>
      'تتبع الضرائب الفيدرالية وضرائب الولاية والخصومات';

  @override
  String get deductionsPerPaymentPeriod => 'الخصومات (لكل فترة دفع)';

  @override
  String get federalTax => 'الضريبة الفيدرالية';

  @override
  String get stateTax => 'ضريبة الولاية';

  @override
  String get socialSecurityTax => 'ضريبة الضمان الاجتماعي';

  @override
  String get medicareTax => 'ضريبة ميديكير';

  @override
  String get retirement401k => 'التقاعد (401k، IRA)';

  @override
  String get healthInsurancePremium => 'قسط التأمين الصحي';

  @override
  String get otherDeductions => 'خصومات أخرى';

  @override
  String get addIncome => 'إضافة دخل';

  @override
  String get importFromCSV => 'استيراد من CSV';

  @override
  String get importDataFromCSV => 'استيراد البيانات من CSV';

  @override
  String get selectCSVFileDescription =>
      'حدد ملف CSV لاستيراد بيانات الحسابات أو الالتزامات أو الدخل';

  @override
  String get selectCSVFile => 'تحديد ملف CSV';

  @override
  String get csvFormatRequirements => 'متطلبات تنسيق CSV';

  @override
  String get accountsLabel => 'حسابات';

  @override
  String get accountsCSVFormat =>
      'name,type,balance,locked,cash,bonds,usEq,intlEq,realEstate,alt';

  @override
  String get liabilitiesLabel => 'التزامات';

  @override
  String get liabilitiesCSVFormat =>
      'name,type,balance,interestRate,minPayment';

  @override
  String get incomeLabel => 'دخل';

  @override
  String get incomeCSVFormat => 'name,type,grossAmount,frequency';

  @override
  String get readyToImport => 'جاهز للاستيراد';

  @override
  String get rowsHadErrors => 'كان للصف أخطاء';

  @override
  String get importError => 'خطأ في الاستيراد';

  @override
  String get unknownError => 'خطأ غير معروف';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get income => 'الدخل';

  @override
  String get unlockPro => 'فتح برو';

  @override
  String get yourProFeatures => 'ميزات برو الخاصة بك';

  @override
  String get debtPayoffOptimizer => 'محسّن سداد الديون';

  @override
  String get debtPayoffDescription =>
      'قارن استراتيجيات الانهيار الجليدي مقابل كرة الثلج مع جداول الدفع الشهرية';

  @override
  String get saveThousands => 'وفر الآلاف في الفوائد';

  @override
  String get rebalancingAutopilot => 'الطيار الآلي لإعادة التوازن';

  @override
  String get rebalancingDescription =>
      'احصل على تعليمات تجارية محددة مع مقاييس المخاطر قبل/بعد';

  @override
  String get reduceRisk => 'قلل مخاطر المحفظة';

  @override
  String get whatIfScenarioEngine => 'محرك سيناريو ماذا لو';

  @override
  String get whatIfDescription =>
      'تُظهر محاكاة مونت كارلو احتمال النجاح مع معاملات قابلة للتعديل';

  @override
  String get seeProbability => 'شاهد احتمال النجاح';

  @override
  String get customAlertsWithContext => 'تنبيهات مخصصة مع السياق';

  @override
  String get customAlertsDescription =>
      'عيّن حدودًا مخصصة مع تنبيهات بالتأثير بالدولار';

  @override
  String get knowImpact => 'اعرف التأثير المالي';

  @override
  String get taxSmartDescription =>
      'حسّن موضع الحساب وحدد فرص حصاد خسارة الضرائب';

  @override
  String get saveTaxes => 'وفر في الضرائب سنويًا';

  @override
  String get retirementDescription =>
      'تتنبأ محاكاة مونت كارلو باحتمال نجاح التقاعد';

  @override
  String get advancedPortfolioAnalytics => 'تحليلات المحفظة المتقدمة';

  @override
  String get advancedAnalyticsDescription =>
      'مؤشر تركيز HHI، تعرض العامل، تتبع متعدد المحافظ';

  @override
  String get planDetails => 'تفاصيل الخطة';

  @override
  String get proActive => 'برو نشط';

  @override
  String get rebalancePro => 'إعادة التوازن برو';

  @override
  String get basedOnYourPortfolio => 'بناءً على محفظتك:';

  @override
  String get saveMoneyReduceRisk =>
      'وفر المال وقلل المخاطر مع التخطيط المالي الذكي';

  @override
  String get compareStrategies =>
      'قارن استراتيجيات الانهيار الجليدي مقابل كرة الثلج. احصل على جداول الدفع الشهرية وشاهد إجمالي وفورات الفوائد.';

  @override
  String get getSpecificTrades =>
      'احصل على تعليمات تجارية محددة. شاهد مقاييس المخاطر قبل/بعد وتقليل التقلب.';

  @override
  String get monteCarloSimulation =>
      'تُظهر محاكاة مونت كارلو (1000 تشغيل) احتمال النجاح. اضبط المساهمات والعوائد والجدول الزمني لتحسين خطتك.';

  @override
  String get customThresholds =>
      'عيّن حدودًا مخصصة للتركيز والتدفق وDSCR. يُظهر كل تنبيه التأثير بالدولار.';

  @override
  String get optimizeAccounts =>
      'حسّن أي حساب يحتفظ بأي أصول. حدد فرص حصاد خسارة الضرائب. قلل السحب الضريبي السنوي.';

  @override
  String get projectRetirement =>
      'تتنبأ محاكاة مونت كارلو (1000 تشغيل) باحتمال نجاح التقاعد. اضبط المدخرات والجدول الزمني والدخل لتحسين خطتك.';

  @override
  String get hhiConcentration =>
      'مؤشر تركيز HHI، تحلل تعرض العامل، تتبع متعدد المحافظ، أوزان التسجيل المخصصة.';

  @override
  String get privacy100 => '100٪ خصوصية';

  @override
  String get dataOnDevice => 'جميع البيانات تبقى على جهازك';

  @override
  String get encryptedStorage => 'تخزين مشفر';

  @override
  String get bankGrade => 'أمان بدرجة مصرفية';

  @override
  String get saveEst => 'التوفير المقدر ';

  @override
  String get purchaseCancelled => 'تم إلغاء الشراء';

  @override
  String get rebalancingPlan => 'خطة إعادة التوازن';

  @override
  String get rebalancingGuide => 'دليل إعادة التوازن';

  @override
  String get addAccountsForRebalancing =>
      'أضف حسابات بها ممتلكات لبناء خطة إعادة التوازن الشخصية الخاصة بك';

  @override
  String get rebalancingPlanProDescription =>
      'احصل على تعليمات تجارية محددة مع مقاييس المخاطر قبل/بعد. انظر بالضبط ما يجب شراؤه أو بيعه للوصول إلى التخصيص المستهدف.';

  @override
  String get yourPersonalizedPlan => 'خطتك الشخصية';

  @override
  String get customizeTrackExecute =>
      'تخصيص الاستراتيجية، تتبع التقدم، تنفيذ الصفقات';

  @override
  String get lockedAccountsDetected => 'تم اكتشاف حسابات مقفلة';

  @override
  String get lockedAccountsMessage =>
      'مقفل (على سبيل المثال، 401k، معاش تقاعدي). تستخدم الخطة فقط';

  @override
  String get inUnlockedAccounts => 'في الحسابات غير المقفلة';

  @override
  String get lockedAccountsTip =>
      'نصيحة: بالنسبة لـ 401k/معاش تقاعدي، قم بتحديث تخصيص مساهمتك بدلاً من إعادة توازن الممتلكات الحالية.';

  @override
  String get rebalancingStrategy => 'استراتيجية إعادة التوازن';

  @override
  String get dollarCostAverageRecommended => 'متوسط التكلفة بالدولار (موصى به)';

  @override
  String get dollarCostDescription =>
      'انشر الصفقات على مدى عدة أشهر لتقليل مخاطر التوقيت';

  @override
  String get immediateRebalance => 'إعادة توازن فورية';

  @override
  String get immediateRebalanceDescription =>
      'نفذ جميع الصفقات الآن إذا كان لديك قناعة قوية';

  @override
  String get glidePathDuration => 'مدة مسار الانزلاق';

  @override
  String get howManyMonthsToSpread => 'كم شهرًا تريد نشر إعادة التوازن؟';

  @override
  String get fast => 'سريع';

  @override
  String get gradual => 'تدريجي';

  @override
  String get months => 'أشهر';

  @override
  String get month => 'شهر';

  @override
  String get executeNow => 'تنفيذ الآن';

  @override
  String get totalToRebalanceImmediately => 'الإجمالي لإعادة التوازن فورًا';

  @override
  String get monthlyTransferAmount => 'مبلغ التحويل الشهري';

  @override
  String get overMonths => 'على مدى';

  @override
  String get total => 'المجموع';

  @override
  String get beforeVsAfter => 'قبل مقابل بعد';

  @override
  String get current => 'الحالي';

  @override
  String get target => 'الهدف';

  @override
  String get executionChecklist => 'قائمة التحقق من التنفيذ';

  @override
  String get trackMonthlyProgress => 'تتبع تقدمك الشهري أثناء تنفيذ الصفقات';

  @override
  String get transfer => 'تحويل';

  @override
  String get ofMonthsCompleted => 'من';

  @override
  String get monthsCompleted => 'الأشهر المكتملة';

  @override
  String get exportPDF => 'تصدير PDF';

  @override
  String get pdfExportComingSoon => 'تصدير PDF قريبًا!';

  @override
  String get whyRebalance => 'لماذا إعادة التوازن؟';

  @override
  String get whyRebalanceDescription =>
      'تتسبب حركات السوق في انحراف محفظتك عن التخصيص المستهدف، مما يزيد من المخاطر. تعيد إعادة التوازن ملف تعريف المخاطر/العائد المرغوب فيه.';

  @override
  String get dollarCostAveragingTitle => 'متوسط التكلفة بالدولار';

  @override
  String get dollarCostAveragingDescription =>
      'نشر الصفقات بمرور الوقت يقلل من مخاطر التوقيت وتأثير السوق. موصى به لمعظم المستثمرين.';

  @override
  String get immediateRebalancingTitle => 'إعادة التوازن الفورية';

  @override
  String get immediateRebalancingDescription =>
      'نفذ جميع الصفقات دفعة واحدة. الأفضل إذا كان لديك قناعة سوقية قوية أو تحتاج إلى إعادة التوازن بشكل عاجل.';

  @override
  String get youreWellBalanced => 'أنت متوازن بشكل جيد!';

  @override
  String get noRebalancingNeeded =>
      'محفظتك ضمن تحمل التخصيص المستهدف. لا حاجة لإعادة التوازن في هذا الوقت.';

  @override
  String get accountType529EducationSavings => '529 مدخرات التعليم';

  @override
  String get accountTypeBrokerage => 'وساطة';

  @override
  String get accountTypeBrokerageAccount => 'حساب وساطة';

  @override
  String get accountTypeCash => 'نقد';

  @override
  String get accountTypeCashAccount => 'حساب نقدي';

  @override
  String get accountTypeCD => 'CD';

  @override
  String get accountTypeCertificateOfDeposit => 'شهادة إيداع';

  @override
  String get accountTypeChecking => 'جاري';

  @override
  String get accountTypeCheckingAccount => 'حساب جاري';

  @override
  String get accountTypeCrypto => 'عملة مشفرة';

  @override
  String get accountTypeCryptocurrency => 'عملة مشفرة';

  @override
  String get accountTypeHealthSavingsAccount => 'حساب التوفير الصحي (HSA)';

  @override
  String get accountTypeHSA => 'HSA';

  @override
  String get accountTypeOther => 'أخرى';

  @override
  String get accountTypeRealEstate => 'عقارات';

  @override
  String get accountTypeRealEstateEquity => 'حقوق الملكية العقارية';

  @override
  String get accountTypeRetirement => 'تقاعد';

  @override
  String get accountTypeSavings => 'توفير';

  @override
  String get accountTypeSavingsAccount => 'حساب توفير';

  @override
  String get liabilityTypeAutoLoan => 'قرض سيارة';

  @override
  String get liabilityTypeCreditCard => 'بطاقة ائتمان';

  @override
  String get liabilityTypeLineOfCredit => 'خط ائتمان';

  @override
  String get liabilityTypeMortgage => 'رهن عقاري';

  @override
  String get liabilityTypeOther => 'أخرى';

  @override
  String get liabilityTypePersonalLoan => 'قرض شخصي';

  @override
  String get liabilityTypeStudentLoan => 'قرض طلابي';

  @override
  String get about => 'حول';

  @override
  String get account => 'حساب';

  @override
  String get accountDeletedSuccessfully => 'تم حذف الحساب بنجاح';

  @override
  String get accountsPlural => 'حسابات';

  @override
  String get addIncomeSource => 'إضافة مصدر دخل';

  @override
  String get addLiability => 'إضافة التزام';

  @override
  String get addNewAccount => 'إضافة حساب جديد';

  @override
  String get addYourFirstIncomeSource =>
      'أضف مصدر دخلك الأول لتتبع التدفق النقدي';

  @override
  String get addYourFirstLiability => 'أضف التزامك الأول لتتبع الديون';

  @override
  String get allocationTargets => 'أهداف التخصيص';

  @override
  String get allocationTargetsDescription =>
      'حدد النسب المستهدفة لتخصيص الأصول';

  @override
  String get allPayments => 'جميع المدفوعات';

  @override
  String get alternatives => 'البدائل';

  @override
  String get amountCannotBeNegative => 'لا يمكن أن يكون المبلغ سالبًا';

  @override
  String get annualInterestCost => 'تكلفة الفائدة السنوية';

  @override
  String get appInfoAndDisclaimers => 'معلومات التطبيق وإخلاء المسؤولية';

  @override
  String get apr => 'APR';

  @override
  String get arabic => 'العربية';

  @override
  String get areYouSureDeleteAccount => 'هل أنت متأكد أنك تريد حذف هذا الحساب؟';

  @override
  String get areYouSureDeleteIncome =>
      'هل أنت متأكد أنك تريد حذف مصدر الدخل هذا؟';

  @override
  String get areYouSureExit => 'هل أنت متأكد أنك تريد الخروج؟';

  @override
  String get assetAllocationDescription =>
      'تنويع عبر فئات الأصول لإدارة المخاطر';

  @override
  String get avgInterestRate => 'متوسط سعر الفائدة';

  @override
  String get backToDashboard => 'العودة إلى لوحة التحكم';

  @override
  String get backToSnapshot => 'العودة إلى اللقطة';

  @override
  String get backupRestoreData => 'نسخ احتياطي واستعادة البيانات';

  @override
  String get balanced => 'متوازن';

  @override
  String get bengali => 'البنغالية';

  @override
  String get bondsAndFixedIncome => 'السندات والدخل الثابت';

  @override
  String get budgetAndPlanning => 'الميزانية والتخطيط';

  @override
  String get budgetAndPlanningDescription => 'تتبع الإنفاق والتخطيط للأهداف';

  @override
  String get cap => 'حد أقصى';

  @override
  String get cashAndCashEquivalents => 'النقد ومعادلات النقد';

  @override
  String get chooseColorScheme => 'اختر نظام الألوان';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get closeApplication => 'إغلاق التطبيق';

  @override
  String get colorAmber => 'كهرماني';

  @override
  String get colorBlue => 'أزرق';

  @override
  String get colorGreen => 'أخضر';

  @override
  String get colorIndigo => 'نيلي';

  @override
  String get colorOrange => 'برتقالي';

  @override
  String get colorPink => 'وردي';

  @override
  String get colorPurple => 'بنفسجي';

  @override
  String get colorRed => 'أحمر';

  @override
  String get colorTeal => 'أزرق مخضر';

  @override
  String get componentConcentration => 'التركيز';

  @override
  String get componentDebtLoad => 'عبء الديون';

  @override
  String get componentFixedIncome => 'الدخل الثابت';

  @override
  String get componentHomeBias => 'التحيز المحلي';

  @override
  String get componentLiquidity => 'السيولة';

  @override
  String get controlInternationalExposure => 'التحكم في التعرض الدولي';

  @override
  String get creditLimit => 'حد الائتمان';

  @override
  String get creditLimitCannotBeLessThanBalance =>
      'لا يمكن أن يكون حد الائتمان أقل من الرصيد الحالي';

  @override
  String get creditUtilization => 'استخدام الائتمان';

  @override
  String get dayOfEachMonth => 'يوم من كل شهر';

  @override
  String get debt => 'دين';

  @override
  String get debtsAndLiabilities => 'الديون والالتزامات';

  @override
  String get debtsPlural => 'ديون';

  @override
  String get defaultPolicyPenalizeLargeDeviations =>
      'السياسة الافتراضية: معاقبة الانحرافات الكبيرة عن الأهداف';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deletedSuccessfully => 'تم الحذف بنجاح';

  @override
  String get deleteIncomeSource => 'حذف مصدر الدخل';

  @override
  String get discard => 'تجاهل';

  @override
  String get displayInCurrency => 'العرض بالعملة';

  @override
  String get editIncome => 'تعديل الدخل';

  @override
  String get editLiability => 'تعديل الالتزام';

  @override
  String get english => 'الإنجليزية';

  @override
  String get enterMinPayment => 'أدخل الحد الأدنى للدفع';

  @override
  String get enterMonthlyEssentials => 'أدخل الأساسيات الشهرية';

  @override
  String get enterTargetPercentage => 'أدخل النسبة المستهدفة';

  @override
  String get enterValidAmount => 'أدخل مبلغًا صالحًا';

  @override
  String get enterValidNumber => 'أدخل رقمًا صالحًا';

  @override
  String get enterValidPayment => 'أدخل دفعة صالحة';

  @override
  String get errorDeletingAccount => 'خطأ في حذف الحساب';

  @override
  String get errorLoadingAccounts => 'خطأ في تحميل الحسابات';

  @override
  String get errorLoadingLiabilities => 'خطأ في تحميل الالتزامات';

  @override
  String get excludeInternationalExposure => 'استبعاد التعرض الدولي';

  @override
  String get exit => 'خروج';

  @override
  String get exitApp => 'الخروج من التطبيق';

  @override
  String get filteredFromSnapshot => 'تمت التصفية من اللقطة';

  @override
  String get financialScore => 'النتيجة المالية';

  @override
  String get frequencyAnnual => 'سنوي';

  @override
  String get frequencyAnnually => 'سنويًا';

  @override
  String get frequencyBiWeekly => 'كل أسبوعين';

  @override
  String get frequencyBiweekly => 'كل أسبوعين';

  @override
  String get frequencyDaily => 'يومي';

  @override
  String get frequencyHourly => 'كل ساعة';

  @override
  String get frequencyMonthly => 'شهري';

  @override
  String get frequencyQuarterly => 'ربع سنوي';

  @override
  String get frequencySemiMonthly => 'نصف شهري';

  @override
  String get frequencyWeekly => 'أسبوعي';

  @override
  String get goBack => 'عودة';

  @override
  String get gotIt => 'فهمت';

  @override
  String get help => 'مساعدة';

  @override
  String get helpAllocationTargetsText =>
      'حدد النسب المستهدفة لكل فئة أصول. سينبهك التطبيق عندما ينحرف تخصيصك الفعلي كثيرًا عن هذه الأهداف.';

  @override
  String get helpAllocationTargetsTitle => 'مساعدة أهداف التخصيص';

  @override
  String get helpMonthlyEssentialsText =>
      'أدخل نفقاتك الأساسية الشهرية (الإيجار، المرافق، البقالة، إلخ). يساعد هذا في حساب هدف صندوق الطوارئ الخاص بك.';

  @override
  String get helpMonthlyEssentialsTitle => 'مساعدة الأساسيات الشهرية';

  @override
  String get helpRiskProfileText =>
      'اختر ملف مخاطر يتناسب مع أهدافك الاستثمارية والأفق الزمني. المحافظ يفضل السندات والنقد، النمو يفضل الأسهم، المتوازن بينهما.';

  @override
  String get helpRiskProfileTitle => 'مساعدة ملف المخاطر';

  @override
  String get hindi => 'الهندية';

  @override
  String get howWeProtectData => 'كيف نحمي بياناتك';

  @override
  String get importAccountsDebtsIncome => 'استيراد الحسابات والديون والدخل';

  @override
  String get importAndExport => 'الاستيراد والتصدير';

  @override
  String get importCSV => 'استيراد CSV';

  @override
  String get income1099 => 'دخل 1099';

  @override
  String get incomeBonus => 'مكافأة';

  @override
  String get incomeFreelance => 'عمل حر';

  @override
  String get incomeInvestment => 'استثمار';

  @override
  String get incomePension => 'معاش تقاعدي';

  @override
  String get incomeRental => 'إيجار';

  @override
  String get incomeSalary => 'راتب';

  @override
  String get incomeSocialSecurity => 'الضمان الاجتماعي';

  @override
  String get incomeSourceAdded => 'تمت إضافة مصدر الدخل';

  @override
  String get incomeSourceDeleted => 'تم حذف مصدر الدخل';

  @override
  String get incomeSourceUpdated => 'تم تحديث مصدر الدخل';

  @override
  String get incomeW2 => 'دخل W-2';

  @override
  String get internationalEquity => 'أسهم دولية';

  @override
  String get intlEquity => 'أسهم دولية';

  @override
  String get justNow => 'الآن';

  @override
  String get lastPayment => 'آخر دفعة';

  @override
  String get legalTermsAndConditions => 'الشروط والأحكام القانونية';

  @override
  String get lessPunitive => 'أقل عقوبة';

  @override
  String get liabilityDetails => 'تفاصيل الالتزام';

  @override
  String get liabilityName => 'اسم الالتزام';

  @override
  String get liabilityNameHint => 'على سبيل المثال، Chase Visa، قرض طلابي';

  @override
  String get liabilitySavedSuccessfully => 'تم حفظ الالتزام بنجاح';

  @override
  String get light => 'فاتح';

  @override
  String get minPayment => 'الحد الأدنى للدفع';

  @override
  String get monthlyEssentialExpenses => 'النفقات الأساسية الشهرية';

  @override
  String get monthlyEssentialsHelper => 'أدخل نفقاتك الأساسية الشهرية';

  @override
  String get monthlyEssentialsHelperUSD =>
      'على سبيل المثال، 3000 دولار للإيجار والمرافق والبقالة';

  @override
  String get monthlyInterest => 'الفائدة الشهرية';

  @override
  String get monthlyPaymentDay => 'يوم الدفع الشهري';

  @override
  String get monthlyPayments => 'المدفوعات الشهرية';

  @override
  String get net => 'صافي';

  @override
  String get netIncome => 'صافي الدخل';

  @override
  String get nextPaymentDueDate => 'تاريخ استحقاق الدفعة التالية';

  @override
  String get noDebtsTracked => 'لا توجد ديون متعقبة حتى الآن';

  @override
  String get noIncomeSourcesYet => 'لا توجد مصادر دخل حتى الآن';

  @override
  String get noPaymentsRecordedYet => 'لم يتم تسجيل مدفوعات حتى الآن';

  @override
  String get offMute => 'إيقاف/كتم';

  @override
  String get optimizePayoffStrategy => 'تحسين استراتيجية السداد';

  @override
  String get paymentHistory => 'سجل المدفوعات';

  @override
  String get paymentSchedule => 'جدول الدفع';

  @override
  String get paymentsWillAppearHere => 'ستظهر المدفوعات هنا';

  @override
  String get percentageMustBeBetween => 'يجب أن تكون النسبة بين 0 و 100';

  @override
  String get persian => 'الفارسية';

  @override
  String get pleaseEnterAPR => 'الرجاء إدخال APR';

  @override
  String get pleaseEnterCurrentBalance => 'الرجاء إدخال الرصيد الحالي';

  @override
  String get pleaseEnterLiabilityName => 'الرجاء إدخال اسم الالتزام';

  @override
  String get pleaseEnterValidAPR => 'الرجاء إدخال APR صالح';

  @override
  String get pleaseEnterValidCreditLimit => 'الرجاء إدخال حد ائتمان صالح';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get proFeature => 'ميزة برو';

  @override
  String get proStatus => 'حالة برو';

  @override
  String get pts => 'نقاط';

  @override
  String get quickStats => 'إحصائيات سريعة';

  @override
  String get realEstateREITs => 'العقارات وREITs';

  @override
  String get requestLanguage => 'طلب لغة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get riskBalanced => 'متوازن';

  @override
  String get riskBalancedAllocation => '60% أسهم، 35% سندات، 5% نقد';

  @override
  String get riskBalancedDescription => 'نمو معتدل مع بعض الاستقرار';

  @override
  String get riskConservative => 'محافظ';

  @override
  String get riskConservativeAllocation => '30% أسهم، 50% سندات، 20% نقد';

  @override
  String get riskConservativeDescription =>
      'إعطاء الأولوية للاستقرار والحفاظ على رأس المال';

  @override
  String get riskGrowth => 'نمو';

  @override
  String get riskGrowthAllocation => '80% أسهم، 15% سندات، 5% نقد';

  @override
  String get riskGrowthDescription => 'تعظيم إمكانات النمو على المدى الطويل';

  @override
  String get riskProfile => 'ملف المخاطر';

  @override
  String get riskProfileDescription => 'حدد قدرتك على تحمل المخاطر الاستثمارية';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get selectNextPaymentDueDate => 'حدد تاريخ استحقاق الدفعة التالية';

  @override
  String get sendFeedback => 'إرسال ملاحظات';

  @override
  String get setTargetsAndThresholds => 'تعيين الأهداف والعتبات';

  @override
  String get settingsSavedSuccessfully => 'تم حفظ الإعدادات بنجاح';

  @override
  String get shareThoughtsAndSuggestions => 'شارك أفكارك واقتراحاتك';

  @override
  String get showAll => 'عرض الكل';

  @override
  String get source => 'مصدر';

  @override
  String get sources => 'مصادر';

  @override
  String get stable => 'مستقر';

  @override
  String get standard => 'قياسي';

  @override
  String get tapToSelectDate => 'انقر لتحديد التاريخ';

  @override
  String get targetsAndAlerts => 'الأهداف والتنبيهات';

  @override
  String get targetsAndAlertsHelp => 'مساعدة الأهداف والتنبيهات';

  @override
  String get taxRate => 'معدل الضريبة';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get testingAsFreeUser => 'الاختبار كمستخدم مجاني';

  @override
  String get testingAsProUser => 'الاختبار كمستخدم برو';

  @override
  String get timeframe30d => '30 يوم';

  @override
  String get totalAllocation => 'إجمالي التخصيص';

  @override
  String get totalDebt => 'إجمالي الديون';

  @override
  String get totalMonthlyIncome => 'إجمالي الدخل الشهري';

  @override
  String get totalPaid => 'إجمالي المدفوع';

  @override
  String get totalPayments => 'إجمالي المدفوعات';

  @override
  String get trackCreditCardsAndLoans => 'تتبع بطاقات الائتمان والقروض';

  @override
  String get trackYourIncomeSources => 'تتبع مصادر دخلك';

  @override
  String get trackYourNetWorth => 'تتبع صافي ثروتك';

  @override
  String get trend => 'اتجاه';

  @override
  String get unlockAdvancedFeatures => 'فتح الميزات المتقدمة';

  @override
  String get unsavedChanges => 'تغييرات غير محفوظة';

  @override
  String get unsavedChangesMessage =>
      'لديك تغييرات غير محفوظة. هل تريد تجاهلها؟';

  @override
  String get updateAccount => 'تحديث الحساب';

  @override
  String get updateLiability => 'تحديث الالتزام';

  @override
  String get used => 'مستخدم';

  @override
  String get useDarkTheme => 'استخدام السمة الداكنة';

  @override
  String get usEquity => 'أسهم أمريكية';

  @override
  String get usEquityTarget => 'هدف الأسهم الأمريكية';

  @override
  String get usEquityTargetHelper => 'النسبة المستهدفة للأسهم الأمريكية';

  @override
  String get view => 'عرض';

  @override
  String get viewAllAccounts => 'عرض جميع الحسابات';

  @override
  String get whatTypesOfDebt => 'ما أنواع الديون التي يمكنك تتبعها؟';

  @override
  String get why => 'لماذا';

  @override
  String cutConcentration(String details) {
    return 'تقليل التركيز: $details';
  }

  @override
  String errorSavingIncome(String error) {
    return 'خطأ في حفظ الدخل: $error';
  }

  @override
  String deleteIncomeConfirm(String name) {
    return 'هل أنت متأكد أنك تريد حذف $name؟';
  }

  @override
  String errorLoadingSettings(String error) {
    return 'خطأ في تحميل الإعدادات: $error';
  }

  @override
  String failedToSaveSettings(String error) {
    return 'فشل في حفظ الإعدادات: $error';
  }

  @override
  String dayOfMonth(String day) {
    return 'يوم الشهر: $day';
  }

  @override
  String errorLoadingIncome(String error) {
    return 'خطأ في تحميل الدخل: $error';
  }

  @override
  String errorDeletingIncome(String error) {
    return 'خطأ في حذف الدخل: $error';
  }

  @override
  String get mixAndDials => 'المزيج والأقراص';

  @override
  String errorLoadingDataWithError(String error) {
    return 'خطأ في تحميل البيانات: $error';
  }

  @override
  String errorLoadingDebtData(String error) {
    return 'خطأ في تحميل بيانات الديون: $error';
  }

  @override
  String get noDataAvailable => 'لا توجد بيانات متاحة';

  @override
  String get dollarCostAveragingCalculations => 'حسابات متوسط تكلفة الدولار';

  @override
  String get primarySecondaryRebalancingTargets =>
      'أهداف إعادة التوازن الأولية/الثانوية';

  @override
  String get timelineWithMonitoringAlerts =>
      'الجدول الزمني مع تنبيهات المراقبة';

  @override
  String get adjustTargetAllocation => 'تعديل التخصيص المستهدف';

  @override
  String get savePlan => 'حفظ الخطة';

  @override
  String get previewPdf => 'معاينة PDF';

  @override
  String get back => 'رجوع';

  @override
  String get aboutMixAndDials => 'حول المزيج والأقراص';

  @override
  String get mixAndDialsDescription =>
      'توفر هذه الشاشة تحليلاً مفصلاً لمحفظتك:';

  @override
  String get assetAllocationBreakdown =>
      '• توزيع الأصول - تفصيل مرئي لاستثماراتك';

  @override
  String get diversificationDials =>
      '• أقراص التنويع - توزيع المخاطر والجغرافيا';

  @override
  String get rebalancingPlansRecommendations =>
      '• خطط إعادة التوازن - توصيات قابلة للتنفيذ';

  @override
  String get rebalancingPlanSavedSuccessfully =>
      'تم حفظ خطة إعادة التوازن بنجاح!';

  @override
  String get planSaved => 'تم حفظ الخطة';

  @override
  String get ok => 'موافق';

  @override
  String get pdfPreview => 'معاينة PDF';

  @override
  String get close => 'إغلاق';

  @override
  String get pdfExportFeatureComingSoon => 'ميزة تصدير PDF قادمة قريباً!';

  @override
  String get downloadPdf => 'تنزيل PDF';

  @override
  String get maybeLater => 'ربما لاحقاً';

  @override
  String errorLoadingAccountsWithError(String error) {
    return 'خطأ في تحميل الحسابات: $error';
  }

  @override
  String get gettingStartedGuide => 'دليل البدء';

  @override
  String get previewWithSampleData => 'معاينة مع بيانات عينة';

  @override
  String get archiveAccount => 'أرشفة الحساب';

  @override
  String get archived => 'مؤرشف';

  @override
  String get archive => 'أرشفة';

  @override
  String get loadSampleData => 'تحميل بيانات عينة';

  @override
  String get sampleDataLoaded => 'تم تحميل بيانات العينة!';

  @override
  String get load => 'تحميل';

  @override
  String get viewAccountsWithUsEquity => 'عرض الحسابات مع أسهم أمريكية';

  @override
  String get learnMore => 'معرفة المزيد';

  @override
  String get riskNudgeSnoozed => 'تم تأجيل تنبيه المخاطر لمدة 30 يوماً';

  @override
  String get riskMarkedAsResolved => 'تم وضع علامة على المخاطرة كمحلولة';

  @override
  String get howWeCalculateThis => 'كيف نحسب هذا';

  @override
  String get yourFinancialHealthScoreBasedOn => 'تعتمد نتيجة صحتك المالية على:';

  @override
  String get concentrationRiskPercent => '• مخاطر التركيز (30%)';

  @override
  String get fixedIncomeBalancePercent => '• توازن الدخل الثابت (25%)';

  @override
  String get liquidityBufferPercent => '• احتياطي السيولة (20%)';

  @override
  String get internationalExposurePercent => '• التعرض الدولي (15%)';

  @override
  String get debtManagementPercent => '• إدارة الديون (10%)';

  @override
  String get addAccounts => 'إضافة حسابات';

  @override
  String get addMonthlyEssentials => 'إضافة الأساسيات الشهرية';

  @override
  String get noTrendDataAvailable => 'لا توجد بيانات اتجاه متاحة';

  @override
  String get exportPdfReport => 'تصدير تقرير PDF';

  @override
  String get saveAsSnapshot => 'حفظ كلقطة';

  @override
  String get viewScoreHistory => 'عرض تاريخ النتيجة';

  @override
  String get compare => 'مقارنة';

  @override
  String get create => 'إنشاء';

  @override
  String get saved => 'محفوظ';

  @override
  String failedToCreateSnapshot(String error) {
    return 'فشل في إنشاء اللقطة: $error';
  }

  @override
  String get snapshotDetail => 'تفاصيل اللقطة';

  @override
  String get snapshotNote => 'ملاحظة اللقطة';

  @override
  String savedToDownloads(String filename) {
    return 'حفظ في Downloads/$filename';
  }

  @override
  String downloadFailed(String error) {
    return 'فشل التنزيل: $error';
  }

  @override
  String isAvailableWithRebalancePro(String feature) {
    return '$feature متاح مع Rebalance Pro.';
  }

  @override
  String get startCompare => 'بدء المقارنة';

  @override
  String get selectThisAsStartingPoint => 'حدد هذا كنقطة بداية للمقارنة';

  @override
  String get deleteSnapshot => 'حذف اللقطة؟';

  @override
  String failedToDeleteSnapshot(String error) {
    return 'فشل في حذف اللقطة: $error';
  }

  @override
  String get unlockTaxOptimization => 'فتح تحسين الضرائب';

  @override
  String get estimatedAnnualTaxSavings => 'التوفير الضريبي السنوي المقدر';

  @override
  String potentialSavings(String amount) {
    return 'التوفير المحتمل: $amount / سنة';
  }

  @override
  String get yourAssetsAreAlreadyTaxEfficient =>
      'أصولك موجودة بالفعل بطريقة فعالة من حيث الضرائب. 👍';

  @override
  String get suggestedReallocation => 'إعادة التخصيص المقترحة';

  @override
  String get assumptionsAndMethodology => 'الافتراضات والمنهجية';

  @override
  String get enableNotifications => 'تمكين الإشعارات';

  @override
  String get getAlertsAboutDrift =>
      'احصل على تنبيهات حول الانحراف وفرص إعادة التوازن';

  @override
  String get set => 'تعيين';

  @override
  String get howItWorks => 'كيف يعمل';

  @override
  String get averageAnnualReturn => '• متوسط العائد السنوي: 7%';

  @override
  String get marketVolatility => '• تقلبات السوق: 15%';

  @override
  String get inflationRate => '• التضخم: 3% سنوياً';

  @override
  String get noDebtsToOptimize => 'لا توجد ديون لتحسينها!';

  @override
  String get addLiabilitiesFromTab =>
      'أضف الالتزامات من علامة تبويب الالتزامات لاستخدام هذه الأداة.';

  @override
  String get currentDebt => 'الدين الحالي';

  @override
  String liabilityCount(int count, String minPayment) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'التزامات',
      one: 'التزام',
    );
    return '$count $_temp0 • $minPayment/شهر كحد أدنى';
  }

  @override
  String get extraMonthlyPayment => 'دفعة شهرية إضافية';

  @override
  String totalMonthlyPayment(String amount) {
    return 'إجمالي الدفع الشهري: $amount';
  }

  @override
  String get payoffStrategies => 'استراتيجيات السداد';

  @override
  String get strategyRecommendation =>
      'نوصي بالخيار ذو الفائدة الإجمالية الأقل. يمكنك اختيار الآخر للحصول على انتصارات تحفيزية.';

  @override
  String get avalanche => 'الانهيار الجليدي';

  @override
  String get avalancheRecommended => 'الانهيار الجليدي (موصى به)';

  @override
  String get avalancheDescription =>
      'أعلى معدل فائدة أولاً – يقلل من إجمالي الفائدة';

  @override
  String get snowball => 'كرة الثلج';

  @override
  String get snowballRecommended => 'كرة الثلج (موصى به)';

  @override
  String get snowballDescription => 'أصغر رصيد أولاً – انتصارات نفسية أسرع';

  @override
  String get unlockDetailedPayoffSchedule => 'فتح جدول السداد التفصيلي';

  @override
  String get monthByMonthBreakdown => 'احصل على تفصيل الدفع شهرياً يظهر:';

  @override
  String get exactPayoffDate => 'تاريخ السداد الدقيق لكل دين';

  @override
  String get principalVsInterest => 'تفصيل الأصل مقابل الفائدة';

  @override
  String get remainingBalanceTracking => 'تتبع الرصيد المتبقي';

  @override
  String totalInterestSaved(String amount) {
    return 'إجمالي الفائدة الموفرة: $amount';
  }

  @override
  String get debtPayoffOrder => 'ترتيب سداد الديون';

  @override
  String debtsWillBePaidInOrder(String strategy) {
    return 'سيتم سداد الديون بهذا الترتيب (استراتيجية $strategy):';
  }

  @override
  String get paidOff => 'تم السداد';

  @override
  String get payoffTime => 'وقت السداد';

  @override
  String monthsCount(int count) {
    return '$count شهر';
  }

  @override
  String get totalInterest => 'إجمالي الفائدة';

  @override
  String saveVsMinimum(String amount) {
    return 'وفر $amount مقابل الحد الأدنى من الدفعات';
  }

  @override
  String get detailedPaymentSchedule => 'جدول الدفع التفصيلي';

  @override
  String monthByMonthStrategy(String strategy) {
    return 'تفصيل شهرياً (استراتيجية $strategy):';
  }

  @override
  String monthNumber(int number) {
    return 'الشهر $number';
  }

  @override
  String principalAndInterest(String principal, String interest) {
    return '$principal أصل • $interest فائدة';
  }

  @override
  String remaining(String amount) {
    return 'متبقي: $amount';
  }

  @override
  String moreMonths(int count) {
    return '... $count شهر إضافي';
  }

  @override
  String get strategyComparison => 'مقارنة الاستراتيجية';

  @override
  String strategySavingsComparison(
      String strategy, String interestDiff, String monthsInfo) {
    return '$strategy توفر $interestDiff فائدة أكثر$monthsInfo مقابل النهج الآخر.';
  }

  @override
  String andFinishesEarlier(int months, String plural) {
    return ' وتنتهي $months شهر$plural مبكراً';
  }

  @override
  String get unlockDebtPayoffOptimizer => 'فتح محسّن سداد الديون';

  @override
  String get fastestPathToDebtFreedom => 'ابحث عن أسرع طريق للتحرر من الديون';

  @override
  String get compareAvalancheSnowball =>
      'قارن بين استراتيجيات الانهيار الجليدي وكرة الثلج';

  @override
  String get seeExactPayoffDates => 'اطلع على تواريخ السداد الدقيقة لكل دين';

  @override
  String get calculateInterestSavings => 'احسب إجمالي توفير الفائدة';

  @override
  String get getMonthlySchedule => 'احصل على جدول الدفع الشهري';

  @override
  String get best => 'الأفضل';

  @override
  String get selected => 'المحدد';

  @override
  String get selectStrategy => 'اختر استراتيجية';

  @override
  String get typesOfDebtYouCanTrack => 'أنواع الديون التي يمكنك تتبعها';

  @override
  String get creditCardsDescription =>
      '• بطاقات الائتمان - تتبع الأرصدة واستخدام الائتمان';

  @override
  String get mortgagesDescription =>
      '• الرهن العقاري - قروض المنازل وإعادة التمويل';

  @override
  String get autoLoansDescription =>
      '• قروض السيارات - تمويل السيارات والمركبات';

  @override
  String get studentLoansDescription => '• قروض الطلاب - ديون التعليم';

  @override
  String get personalLoansDescription =>
      '• القروض الشخصية - الديون غير المضمونة';

  @override
  String get helocDescription => '• HELOC - خطوط ائتمان ملكية المنزل';

  @override
  String get businessLoansDescription => '• قروض الأعمال - الديون التجارية';

  @override
  String get upgradeForProFeatures =>
      'قم بالترقية إلى النسخة الاحترافية للحصول على خطط غير محدودة وتصدير PDF وتحليلات متقدمة.';

  @override
  String get upgradeForPdfExports =>
      'قم بالترقية إلى النسخة الاحترافية لتصدير PDF والخطط غير المحدودة والتحليلات المتقدمة.';

  @override
  String get pdfExportAvailable => 'تصدير PDF متاح مع Rebalance Pro.';

  @override
  String get pdfExportProMessage =>
      'تصدير PDF متاح مع Rebalance Pro.\n\nقم بالترقية إلى النسخة الاحترافية لتصدير PDF والخطط غير المحدودة والتحليلات المتقدمة.';

  @override
  String get taxOptimizationDescription =>
      'راجع تقدير السحب الضريبي السنوي وكيفية تقليله بوضع أفضل للأصول.';

  @override
  String potentialSavingsPerYear(String amount) {
    return 'التوفير المحتمل: $amount / سنة';
  }

  @override
  String get assetsAlreadyTaxEfficient =>
      'أصولك موجودة بالفعل بكفاءة ضريبية. 👍';

  @override
  String estimatedYearlyImpact(String amount) {
    return 'التأثير السنوي المقدر: $amount';
  }

  @override
  String get unlockCustomAlerts => 'فتح التنبيهات المخصصة';

  @override
  String get alertSettingsSaved => 'تم حفظ إعدادات التنبيه';

  @override
  String failedToSave(String error) {
    return 'فشل الحفظ: $error';
  }

  @override
  String get thresholds => 'العتبات';

  @override
  String get driftThreshold => 'عتبة الانحراف';

  @override
  String get concentrationCap => 'حد التركيز';

  @override
  String get employerStockCap => 'حد أسهم صاحب العمل';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get enableAlertNotifications => 'تمكين إشعارات التنبيه';

  @override
  String get receiveAlertNotificationsDescription =>
      'تلقي تنبيهات داخل التطبيق عند تجاوز العتبات';

  @override
  String get dollarImpactPreview => 'معاينة التأثير بالدولار';

  @override
  String get exampleImpact => 'مثال على التأثير';

  @override
  String get exampleImpactDescription =>
      'عند تجاوز العتبة، ستظهر التنبيهات مبلغًا تقديريًا بالدولار مرتبطًا بالتعرض الزائد حتى يعرف المستخدمون التأثير المالي الحقيقي.';

  @override
  String get scenarioA => 'السيناريو A';

  @override
  String get scenarioB => 'السيناريو B';

  @override
  String get monthlyContribution => 'المساهمة الشهرية';

  @override
  String get expectedReturn => 'العائد المتوقع';

  @override
  String get volatility => 'التقلب';

  @override
  String get years => 'السنوات';

  @override
  String get goalAmount => 'مبلغ الهدف';

  @override
  String get resultsA => 'النتائج A';

  @override
  String get resultsB => 'النتائج B';

  @override
  String get successProbability => 'احتمالية النجاح';

  @override
  String get medianEnding => 'النهاية المتوسطة';

  @override
  String get tenthPercentile => 'العاشر المئوي';

  @override
  String get ninetiethPercentile => 'التسعون المئوي';

  @override
  String get retirementSimulationDescription =>
      'تقوم هذه الحاسبة بتشغيل 1000 محاكاة لتقدير احتمالية نجاح تقاعدك.';

  @override
  String get yourRetirementPlan => 'خطة التقاعد الخاصة بك';

  @override
  String get currentSavings => 'المدخرات الحالية';

  @override
  String get yearsUntilRetirement => 'سنوات حتى التقاعد';

  @override
  String get desiredMonthlyIncome => 'الدخل الشهري المطلوب';

  @override
  String get yearsInRetirement => 'سنوات التقاعد';

  @override
  String get outcomeDistribution => 'توزيع النتائج';

  @override
  String get outcomeLikelihood => 'مدى احتمالية النتائج المختلفة';

  @override
  String get fail => 'فشل';

  @override
  String get low => 'منخفض';

  @override
  String get med => 'متوسط';

  @override
  String get high => 'عالٍ';

  @override
  String get recommendations => 'التوصيات';

  @override
  String moveToTaxAdvantaged(Object amount, Object asset) {
    return 'انقل $amount من $asset إلى حساب ذو امتياز ضريبي';
  }

  @override
  String get estimatedAnnualImpact => 'التأثير السنوي المقدر';

  @override
  String considerIncreasingContributions(Object amount) {
    return 'فكر في زيادة المساهمات الشهرية إلى $amount لتحسين فرصك.';
  }

  @override
  String get excellentOnTrack =>
      'ممتاز! خطة التقاعد الخاصة بك على المسار الصحيح.';

  @override
  String incomeExceedsSafeWithdrawal(Object desired, Object safe) {
    return 'دخلك المطلوب ($desired) يتجاوز مبلغ السحب الآمن وفقًا لـ \"قاعدة 4٪\" ($safe).';
  }

  @override
  String timeIsAdvantage(Object years) {
    return 'مع $years سنة حتى التقاعد، الوقت هو أكبر ميزة لك. ابق متسقًا مع المساهمات.';
  }

  @override
  String get planReasonable =>
      'خطتك معقولة. راجعها سنويًا وقم بالتعديل مع تغير وضعك.';

  @override
  String get successProbabilityLabel => 'احتمالية النجاح';

  @override
  String grade(Object grade) {
    return 'الدرجة $grade';
  }

  @override
  String get atRetirement => 'عند التقاعد';

  @override
  String get medianAfterRetirement => 'الوسيط بعد التقاعد';

  @override
  String get bestCase90th => 'أفضل حالة (المئوية 90)';

  @override
  String simulationsYears(Object simulations, Object years) {
    return 'المحاكاة: $simulations\\nالسنوات: $years';
  }

  @override
  String get distributionSortedOutcomes => 'التوزيع (النتائج المرتبة)';
}
