import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('en'),
    Locale('fa'),
    Locale('hi')
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'Rebalance'**
  String get appTitle;

  /// No description provided for @netWorth.
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get netWorth;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @liabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get liabilities;

  /// No description provided for @cashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get cashFlow;

  /// No description provided for @healthScore.
  ///
  /// In en, this message translates to:
  /// **'Health Score'**
  String get healthScore;

  /// No description provided for @proFeatures.
  ///
  /// In en, this message translates to:
  /// **'Pro Features'**
  String get proFeatures;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get choosePlan;

  /// No description provided for @upgradeToProTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToProTitle;

  /// No description provided for @allProFeatures.
  ///
  /// In en, this message translates to:
  /// **'All Pro features'**
  String get allProFeatures;

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime'**
  String get cancelAnytime;

  /// No description provided for @freeTrialDays.
  ///
  /// In en, this message translates to:
  /// **'7-day free trial'**
  String get freeTrialDays;

  /// No description provided for @proMonthly.
  ///
  /// In en, this message translates to:
  /// **'Pro Monthly'**
  String get proMonthly;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get perMonth;

  /// No description provided for @annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annual;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get perYear;

  /// No description provided for @founderLifetime.
  ///
  /// In en, this message translates to:
  /// **'Founder Lifetime'**
  String get founderLifetime;

  /// No description provided for @oneTime.
  ///
  /// In en, this message translates to:
  /// **'one time'**
  String get oneTime;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get bestValue;

  /// No description provided for @limited.
  ///
  /// In en, this message translates to:
  /// **'LIMITED'**
  String get limited;

  /// Amount saved with annual plan
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String saveMoney(String amount);

  /// No description provided for @everythingForever.
  ///
  /// In en, this message translates to:
  /// **'Everything forever'**
  String get everythingForever;

  /// No description provided for @firstFounders.
  ///
  /// In en, this message translates to:
  /// **'First 1,000 founders'**
  String get firstFounders;

  /// No description provided for @priceIncreasesAfter.
  ///
  /// In en, this message translates to:
  /// **'Price increases after'**
  String get priceIncreasesAfter;

  /// No description provided for @retirementCalculator.
  ///
  /// In en, this message translates to:
  /// **'Retirement Calculator'**
  String get retirementCalculator;

  /// No description provided for @debtOptimizer.
  ///
  /// In en, this message translates to:
  /// **'Debt Optimizer'**
  String get debtOptimizer;

  /// No description provided for @scenarioEngine.
  ///
  /// In en, this message translates to:
  /// **'Scenario Engine'**
  String get scenarioEngine;

  /// No description provided for @taxSmartAllocation.
  ///
  /// In en, this message translates to:
  /// **'Tax-Smart Allocation'**
  String get taxSmartAllocation;

  /// No description provided for @customAlerts.
  ///
  /// In en, this message translates to:
  /// **'Custom Alerts with Context'**
  String get customAlerts;

  /// No description provided for @advancedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Portfolio Analytics'**
  String get advancedAnalytics;

  /// No description provided for @unlockWithPro.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Pro'**
  String get unlockWithPro;

  /// No description provided for @startFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get startFreeTrial;

  /// No description provided for @choosePlanButton.
  ///
  /// In en, this message translates to:
  /// **'Choose Plan'**
  String get choosePlanButton;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @colorTheme.
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get colorTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @pleaseEnterAccountName.
  ///
  /// In en, this message translates to:
  /// **'Please enter an account name'**
  String get pleaseEnterAccountName;

  /// No description provided for @exampleAccountName.
  ///
  /// In en, this message translates to:
  /// **'e.g., Chase Checking'**
  String get exampleAccountName;

  /// No description provided for @lockedAccount.
  ///
  /// In en, this message translates to:
  /// **'Locked Account'**
  String get lockedAccount;

  /// No description provided for @cannotBeRebalanced.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be rebalanced (401k, pension, restricted)'**
  String get cannotBeRebalanced;

  /// No description provided for @canBeRebalanced.
  ///
  /// In en, this message translates to:
  /// **'Can be included in rebalancing plans'**
  String get canBeRebalanced;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @pleaseEnterBalance.
  ///
  /// In en, this message translates to:
  /// **'Please enter a balance'**
  String get pleaseEnterBalance;

  /// No description provided for @pleaseEnterValidBalance.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid balance'**
  String get pleaseEnterValidBalance;

  /// No description provided for @debts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get debts;

  /// No description provided for @addDebt.
  ///
  /// In en, this message translates to:
  /// **'Add Debt'**
  String get addDebt;

  /// No description provided for @minimumPayment.
  ///
  /// In en, this message translates to:
  /// **'Minimum Payment'**
  String get minimumPayment;

  /// No description provided for @interestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate'**
  String get interestRate;

  /// No description provided for @rebalancing.
  ///
  /// In en, this message translates to:
  /// **'Rebalancing'**
  String get rebalancing;

  /// No description provided for @createPlan.
  ///
  /// In en, this message translates to:
  /// **'Create Rebalancing Plan'**
  String get createPlan;

  /// No description provided for @targetAllocation.
  ///
  /// In en, this message translates to:
  /// **'Target Allocation'**
  String get targetAllocation;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @targets.
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get targets;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @recentAccounts.
  ///
  /// In en, this message translates to:
  /// **'Recent Accounts'**
  String get recentAccounts;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get noAccountsYet;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started by adding your first account'**
  String get getStarted;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get totalAssets;

  /// No description provided for @totalLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Total Liabilities'**
  String get totalLiabilities;

  /// No description provided for @financialHealth.
  ///
  /// In en, this message translates to:
  /// **'Financial Health'**
  String get financialHealth;

  /// No description provided for @allocation.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get allocation;

  /// No description provided for @liquidity.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get liquidity;

  /// No description provided for @debtLoad.
  ///
  /// In en, this message translates to:
  /// **'Debt Load'**
  String get debtLoad;

  /// No description provided for @concentration.
  ///
  /// In en, this message translates to:
  /// **'Concentration'**
  String get concentration;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @needsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs Work'**
  String get needsWork;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @financialHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Financial Health Score'**
  String get financialHealthScore;

  /// No description provided for @howBalancedIsYourPortfolio.
  ///
  /// In en, this message translates to:
  /// **'how balanced is your portfolio?'**
  String get howBalancedIsYourPortfolio;

  /// No description provided for @wellBalanced.
  ///
  /// In en, this message translates to:
  /// **'Well balanced'**
  String get wellBalanced;

  /// No description provided for @excellentHealth.
  ///
  /// In en, this message translates to:
  /// **'Excellent Health'**
  String get excellentHealth;

  /// No description provided for @goodHealth.
  ///
  /// In en, this message translates to:
  /// **'Good Health'**
  String get goodHealth;

  /// No description provided for @fairHealth.
  ///
  /// In en, this message translates to:
  /// **'Fair Health'**
  String get fairHealth;

  /// No description provided for @needsWorkHealth.
  ///
  /// In en, this message translates to:
  /// **'Needs Work'**
  String get needsWorkHealth;

  /// No description provided for @poorHealth.
  ///
  /// In en, this message translates to:
  /// **'Poor Health'**
  String get poorHealth;

  /// No description provided for @weightedBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Weighted Breakdown'**
  String get weightedBreakdown;

  /// No description provided for @fixedIncomeBalance.
  ///
  /// In en, this message translates to:
  /// **'Fixed Income Balance'**
  String get fixedIncomeBalance;

  /// No description provided for @liquidityBuffer.
  ///
  /// In en, this message translates to:
  /// **'Liquidity Buffer'**
  String get liquidityBuffer;

  /// No description provided for @internationalExposure.
  ///
  /// In en, this message translates to:
  /// **'International Exposure'**
  String get internationalExposure;

  /// No description provided for @debtManagement.
  ///
  /// In en, this message translates to:
  /// **'Debt Management'**
  String get debtManagement;

  /// No description provided for @whatMoved.
  ///
  /// In en, this message translates to:
  /// **'What Moved'**
  String get whatMoved;

  /// No description provided for @sinceLast30d.
  ///
  /// In en, this message translates to:
  /// **'Since last 30d:'**
  String get sinceLast30d;

  /// No description provided for @reducedUsEquityPosition.
  ///
  /// In en, this message translates to:
  /// **'Reduced US Equity position'**
  String get reducedUsEquityPosition;

  /// No description provided for @addedFixedIncomeAllocation.
  ///
  /// In en, this message translates to:
  /// **'Added fixed income allocation'**
  String get addedFixedIncomeAllocation;

  /// No description provided for @noChangeInCashPosition.
  ///
  /// In en, this message translates to:
  /// **'No change in cash position'**
  String get noChangeInCashPosition;

  /// No description provided for @nextActions.
  ///
  /// In en, this message translates to:
  /// **'Next Actions'**
  String get nextActions;

  /// No description provided for @openMixAndDials.
  ///
  /// In en, this message translates to:
  /// **'Open Mix & Dials'**
  String get openMixAndDials;

  /// No description provided for @reviewDetailedAllocationBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Review detailed allocation breakdown'**
  String get reviewDetailedAllocationBreakdown;

  /// No description provided for @addToPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to Plan'**
  String get addToPlan;

  /// No description provided for @createRebalancingStrategy.
  ///
  /// In en, this message translates to:
  /// **'Create rebalancing strategy'**
  String get createRebalancingStrategy;

  /// No description provided for @setTargetAllocation.
  ///
  /// In en, this message translates to:
  /// **'Set Target Allocation'**
  String get setTargetAllocation;

  /// No description provided for @adjustYourRiskPreferences.
  ///
  /// In en, this message translates to:
  /// **'Adjust your risk preferences'**
  String get adjustYourRiskPreferences;

  /// No description provided for @financialHealthTrend.
  ///
  /// In en, this message translates to:
  /// **'Financial Health Trend'**
  String get financialHealthTrend;

  /// No description provided for @keyInsights.
  ///
  /// In en, this message translates to:
  /// **'Key Insights'**
  String get keyInsights;

  /// No description provided for @runSimulation.
  ///
  /// In en, this message translates to:
  /// **'Run Simulation'**
  String get runSimulation;

  /// No description provided for @explainGradeBands.
  ///
  /// In en, this message translates to:
  /// **'Explain Grade Bands'**
  String get explainGradeBands;

  /// No description provided for @seeHowAddingBondsAffectsScore.
  ///
  /// In en, this message translates to:
  /// **'See how adding \$1,500 to Bonds affects your score'**
  String get seeHowAddingBondsAffectsScore;

  /// No description provided for @strongUpwardTrend.
  ///
  /// In en, this message translates to:
  /// **'Strong upward trend over 6 months'**
  String get strongUpwardTrend;

  /// No description provided for @consistentImprovementPattern.
  ///
  /// In en, this message translates to:
  /// **'Consistent improvement pattern'**
  String get consistentImprovementPattern;

  /// No description provided for @approachingExcellentHealth.
  ///
  /// In en, this message translates to:
  /// **'Approaching excellent financial health'**
  String get approachingExcellentHealth;

  /// No description provided for @gradualImprovementTrend.
  ///
  /// In en, this message translates to:
  /// **'Gradual improvement trend'**
  String get gradualImprovementTrend;

  /// No description provided for @steadyProgressPattern.
  ///
  /// In en, this message translates to:
  /// **'Steady progress pattern'**
  String get steadyProgressPattern;

  /// No description provided for @decliningTrendNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Declining trend needs attention'**
  String get decliningTrendNeedsAttention;

  /// No description provided for @highVolatilityInScores.
  ///
  /// In en, this message translates to:
  /// **'High volatility in scores'**
  String get highVolatilityInScores;

  /// No description provided for @considerReviewingStrategy.
  ///
  /// In en, this message translates to:
  /// **'Consider reviewing financial strategy'**
  String get considerReviewingStrategy;

  /// No description provided for @slightDownwardTrend.
  ///
  /// In en, this message translates to:
  /// **'Slight downward trend'**
  String get slightDownwardTrend;

  /// No description provided for @monitorForContinuedDecline.
  ///
  /// In en, this message translates to:
  /// **'Monitor for continued decline'**
  String get monitorForContinuedDecline;

  /// No description provided for @stableFinancialHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Stable financial health score'**
  String get stableFinancialHealthScore;

  /// No description provided for @lowVolatilityIndicatesConsistency.
  ///
  /// In en, this message translates to:
  /// **'Low volatility indicates consistency'**
  String get lowVolatilityIndicatesConsistency;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @weakest.
  ///
  /// In en, this message translates to:
  /// **'Weakest'**
  String get weakest;

  /// No description provided for @healthCalculatedFromComponents.
  ///
  /// In en, this message translates to:
  /// **'Health calculated from 5 components'**
  String get healthCalculatedFromComponents;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @netWorthLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get netWorthLabel;

  /// No description provided for @assetAllocation.
  ///
  /// In en, this message translates to:
  /// **'Asset Allocation'**
  String get assetAllocation;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @bonds.
  ///
  /// In en, this message translates to:
  /// **'Bonds'**
  String get bonds;

  /// No description provided for @equities.
  ///
  /// In en, this message translates to:
  /// **'Equities'**
  String get equities;

  /// No description provided for @realEstate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get realEstate;

  /// No description provided for @commodities.
  ///
  /// In en, this message translates to:
  /// **'Commodities'**
  String get commodities;

  /// No description provided for @crypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get crypto;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @totalEquities.
  ///
  /// In en, this message translates to:
  /// **'Total Equities'**
  String get totalEquities;

  /// No description provided for @vsTarget.
  ///
  /// In en, this message translates to:
  /// **'vs Target'**
  String get vsTarget;

  /// No description provided for @viewFullAnalysis.
  ///
  /// In en, this message translates to:
  /// **'View Full Analysis'**
  String get viewFullAnalysis;

  /// No description provided for @reduce.
  ///
  /// In en, this message translates to:
  /// **'Reduce'**
  String get reduce;

  /// No description provided for @concentrationRisk.
  ///
  /// In en, this message translates to:
  /// **'concentration risk'**
  String get concentrationRisk;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRisk;

  /// No description provided for @mediumRisk.
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get mediumRisk;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRisk;

  /// No description provided for @spotted.
  ///
  /// In en, this message translates to:
  /// **'spotted'**
  String get spotted;

  /// No description provided for @ago.
  ///
  /// In en, this message translates to:
  /// **'ago'**
  String get ago;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @addYourFirstAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Account'**
  String get addYourFirstAccount;

  /// No description provided for @checkingAccount.
  ///
  /// In en, this message translates to:
  /// **'Checking Account'**
  String get checkingAccount;

  /// No description provided for @savingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Savings Account'**
  String get savingsAccount;

  /// No description provided for @brokerageAccount.
  ///
  /// In en, this message translates to:
  /// **'Brokerage Account'**
  String get brokerageAccount;

  /// No description provided for @retirementAccount.
  ///
  /// In en, this message translates to:
  /// **'Retirement Account'**
  String get retirementAccount;

  /// No description provided for @reduceConcentrationRisk.
  ///
  /// In en, this message translates to:
  /// **'Reduce concentration risk'**
  String get reduceConcentrationRisk;

  /// No description provided for @largestBucket.
  ///
  /// In en, this message translates to:
  /// **'Largest bucket'**
  String get largestBucket;

  /// No description provided for @capPerBucket.
  ///
  /// In en, this message translates to:
  /// **'Cap per bucket'**
  String get capPerBucket;

  /// No description provided for @targetShift.
  ///
  /// In en, this message translates to:
  /// **'Target shift'**
  String get targetShift;

  /// No description provided for @createRebalancingPlan.
  ///
  /// In en, this message translates to:
  /// **'Create Rebalancing Plan'**
  String get createRebalancingPlan;

  /// No description provided for @shiftPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Shift per month'**
  String get shiftPerMonth;

  /// No description provided for @spottedAgo.
  ///
  /// In en, this message translates to:
  /// **'spotted ago'**
  String get spottedAgo;

  /// No description provided for @updatedToday.
  ///
  /// In en, this message translates to:
  /// **'Updated today'**
  String get updatedToday;

  /// No description provided for @updatedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Updated yesterday'**
  String get updatedYesterday;

  /// No description provided for @updatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {days} days ago'**
  String updatedDaysAgo(Object days);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(Object hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(Object days);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months}mo ago'**
  String monthsAgo(Object months);

  /// No description provided for @incomeSourceName.
  ///
  /// In en, this message translates to:
  /// **'Income Source Name'**
  String get incomeSourceName;

  /// No description provided for @incomeSourceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Tech Corp Salary'**
  String get incomeSourceNameHint;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @incomeType.
  ///
  /// In en, this message translates to:
  /// **'Income Type'**
  String get incomeType;

  /// No description provided for @incomeTypeSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get incomeTypeSalary;

  /// No description provided for @incomeTypeHourlyWage.
  ///
  /// In en, this message translates to:
  /// **'Hourly Wage'**
  String get incomeTypeHourlyWage;

  /// No description provided for @incomeTypeBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get incomeTypeBonus;

  /// No description provided for @incomeTypeCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get incomeTypeCommission;

  /// No description provided for @incomeTypeFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get incomeTypeFreelance;

  /// No description provided for @incomeTypeRentalIncome.
  ///
  /// In en, this message translates to:
  /// **'Rental Income'**
  String get incomeTypeRentalIncome;

  /// No description provided for @incomeTypeInvestmentIncome.
  ///
  /// In en, this message translates to:
  /// **'Investment Income'**
  String get incomeTypeInvestmentIncome;

  /// No description provided for @incomeTypePension.
  ///
  /// In en, this message translates to:
  /// **'Pension'**
  String get incomeTypePension;

  /// No description provided for @incomeTypeSocialSecurity.
  ///
  /// In en, this message translates to:
  /// **'Social Security'**
  String get incomeTypeSocialSecurity;

  /// No description provided for @incomeTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get incomeTypeOther;

  /// No description provided for @grossAmount.
  ///
  /// In en, this message translates to:
  /// **'Gross Amount'**
  String get grossAmount;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @addTaxDeductionBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Add Tax & Deduction Breakdown'**
  String get addTaxDeductionBreakdown;

  /// No description provided for @trackFederalTaxStateTax.
  ///
  /// In en, this message translates to:
  /// **'Track federal tax, state tax, and deductions'**
  String get trackFederalTaxStateTax;

  /// No description provided for @deductionsPerPaymentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Deductions (per payment period)'**
  String get deductionsPerPaymentPeriod;

  /// No description provided for @federalTax.
  ///
  /// In en, this message translates to:
  /// **'Federal Tax'**
  String get federalTax;

  /// No description provided for @stateTax.
  ///
  /// In en, this message translates to:
  /// **'State Tax'**
  String get stateTax;

  /// No description provided for @socialSecurityTax.
  ///
  /// In en, this message translates to:
  /// **'Social Security Tax'**
  String get socialSecurityTax;

  /// No description provided for @medicareTax.
  ///
  /// In en, this message translates to:
  /// **'Medicare Tax'**
  String get medicareTax;

  /// No description provided for @retirement401k.
  ///
  /// In en, this message translates to:
  /// **'Retirement (401k, IRA)'**
  String get retirement401k;

  /// No description provided for @healthInsurancePremium.
  ///
  /// In en, this message translates to:
  /// **'Health Insurance Premium'**
  String get healthInsurancePremium;

  /// No description provided for @otherDeductions.
  ///
  /// In en, this message translates to:
  /// **'Other Deductions'**
  String get otherDeductions;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @importFromCSV.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV'**
  String get importFromCSV;

  /// No description provided for @importDataFromCSV.
  ///
  /// In en, this message translates to:
  /// **'Import Data from CSV'**
  String get importDataFromCSV;

  /// No description provided for @selectCSVFileDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a CSV file to import accounts, liabilities, or income data'**
  String get selectCSVFileDescription;

  /// No description provided for @selectCSVFile.
  ///
  /// In en, this message translates to:
  /// **'Select CSV File'**
  String get selectCSVFile;

  /// No description provided for @csvFormatRequirements.
  ///
  /// In en, this message translates to:
  /// **'CSV Format Requirements'**
  String get csvFormatRequirements;

  /// No description provided for @accountsLabel.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsLabel;

  /// No description provided for @accountsCSVFormat.
  ///
  /// In en, this message translates to:
  /// **'name,type,balance,locked,cash,bonds,usEq,intlEq,realEstate,alt'**
  String get accountsCSVFormat;

  /// No description provided for @liabilitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get liabilitiesLabel;

  /// No description provided for @liabilitiesCSVFormat.
  ///
  /// In en, this message translates to:
  /// **'name,type,balance,interestRate,minPayment'**
  String get liabilitiesCSVFormat;

  /// No description provided for @incomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeLabel;

  /// No description provided for @incomeCSVFormat.
  ///
  /// In en, this message translates to:
  /// **'name,type,grossAmount,frequency'**
  String get incomeCSVFormat;

  /// No description provided for @readyToImport.
  ///
  /// In en, this message translates to:
  /// **'Ready to Import'**
  String get readyToImport;

  /// No description provided for @rowsHadErrors.
  ///
  /// In en, this message translates to:
  /// **'rows had errors'**
  String get rowsHadErrors;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import Error'**
  String get importError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @unlockPro.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro'**
  String get unlockPro;

  /// No description provided for @yourProFeatures.
  ///
  /// In en, this message translates to:
  /// **'Your Pro Features'**
  String get yourProFeatures;

  /// No description provided for @debtPayoffOptimizer.
  ///
  /// In en, this message translates to:
  /// **'Debt Payoff Optimizer'**
  String get debtPayoffOptimizer;

  /// No description provided for @debtPayoffDescription.
  ///
  /// In en, this message translates to:
  /// **'Compare avalanche vs. snowball strategies with month-by-month payment schedules'**
  String get debtPayoffDescription;

  /// No description provided for @saveThousands.
  ///
  /// In en, this message translates to:
  /// **'Save thousands in interest'**
  String get saveThousands;

  /// No description provided for @rebalancingAutopilot.
  ///
  /// In en, this message translates to:
  /// **'Rebalancing Autopilot'**
  String get rebalancingAutopilot;

  /// No description provided for @rebalancingDescription.
  ///
  /// In en, this message translates to:
  /// **'Get specific trade instructions with before/after risk metrics'**
  String get rebalancingDescription;

  /// No description provided for @reduceRisk.
  ///
  /// In en, this message translates to:
  /// **'Reduce portfolio risk'**
  String get reduceRisk;

  /// No description provided for @whatIfScenarioEngine.
  ///
  /// In en, this message translates to:
  /// **'What-If Scenario Engine'**
  String get whatIfScenarioEngine;

  /// No description provided for @whatIfDescription.
  ///
  /// In en, this message translates to:
  /// **'Monte Carlo simulation shows success probability with adjustable parameters'**
  String get whatIfDescription;

  /// No description provided for @seeProbability.
  ///
  /// In en, this message translates to:
  /// **'See probability of success'**
  String get seeProbability;

  /// No description provided for @customAlertsWithContext.
  ///
  /// In en, this message translates to:
  /// **'Custom Alerts with Context'**
  String get customAlertsWithContext;

  /// No description provided for @customAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Set custom thresholds with dollar-impact alerts'**
  String get customAlertsDescription;

  /// No description provided for @knowImpact.
  ///
  /// In en, this message translates to:
  /// **'Know the financial impact'**
  String get knowImpact;

  /// No description provided for @taxSmartDescription.
  ///
  /// In en, this message translates to:
  /// **'Optimize account placement and identify tax-loss harvesting opportunities'**
  String get taxSmartDescription;

  /// No description provided for @saveTaxes.
  ///
  /// In en, this message translates to:
  /// **'Save on taxes annually'**
  String get saveTaxes;

  /// No description provided for @retirementDescription.
  ///
  /// In en, this message translates to:
  /// **'Monte Carlo simulation projects retirement success probability'**
  String get retirementDescription;

  /// No description provided for @advancedPortfolioAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Portfolio Analytics'**
  String get advancedPortfolioAnalytics;

  /// No description provided for @advancedAnalyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'HHI concentration index, factor exposure, multi-portfolio tracking'**
  String get advancedAnalyticsDescription;

  /// No description provided for @planDetails.
  ///
  /// In en, this message translates to:
  /// **'Plan Details'**
  String get planDetails;

  /// No description provided for @proActive.
  ///
  /// In en, this message translates to:
  /// **'Pro Active'**
  String get proActive;

  /// No description provided for @rebalancePro.
  ///
  /// In en, this message translates to:
  /// **'Rebalance Pro'**
  String get rebalancePro;

  /// No description provided for @basedOnYourPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Based on your portfolio:'**
  String get basedOnYourPortfolio;

  /// No description provided for @saveMoneyReduceRisk.
  ///
  /// In en, this message translates to:
  /// **'Save money and reduce risk with intelligent financial planning'**
  String get saveMoneyReduceRisk;

  /// No description provided for @compareStrategies.
  ///
  /// In en, this message translates to:
  /// **'Compare avalanche vs snowball strategies. Get month-by-month payment schedule and see total interest saved.'**
  String get compareStrategies;

  /// No description provided for @getSpecificTrades.
  ///
  /// In en, this message translates to:
  /// **'Get specific trade instructions. See before/after risk metrics and volatility reduction.'**
  String get getSpecificTrades;

  /// No description provided for @monteCarloSimulation.
  ///
  /// In en, this message translates to:
  /// **'Monte Carlo simulation (1,000 runs) shows success probability. Adjust contributions, returns, and timeline to optimize your plan.'**
  String get monteCarloSimulation;

  /// No description provided for @customThresholds.
  ///
  /// In en, this message translates to:
  /// **'Set custom thresholds for concentration, drift, DSCR. Each alert shows dollar impact.'**
  String get customThresholds;

  /// No description provided for @optimizeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Optimize which accounts hold which assets. Identify tax-loss harvesting opportunities. Minimize annual tax drag.'**
  String get optimizeAccounts;

  /// No description provided for @projectRetirement.
  ///
  /// In en, this message translates to:
  /// **'Monte Carlo simulation (1,000 runs) projects retirement success probability. Adjust savings, timeline, and income to optimize your plan.'**
  String get projectRetirement;

  /// No description provided for @hhiConcentration.
  ///
  /// In en, this message translates to:
  /// **'HHI concentration index, factor exposure breakdown, multi-portfolio tracking, custom scoring weights.'**
  String get hhiConcentration;

  /// No description provided for @privacy100.
  ///
  /// In en, this message translates to:
  /// **'100% Privacy'**
  String get privacy100;

  /// No description provided for @dataOnDevice.
  ///
  /// In en, this message translates to:
  /// **'All data stays on your device'**
  String get dataOnDevice;

  /// No description provided for @encryptedStorage.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Storage'**
  String get encryptedStorage;

  /// No description provided for @bankGrade.
  ///
  /// In en, this message translates to:
  /// **'Bank-grade security'**
  String get bankGrade;

  /// No description provided for @saveEst.
  ///
  /// In en, this message translates to:
  /// **'Save est. '**
  String get saveEst;

  /// No description provided for @purchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled'**
  String get purchaseCancelled;

  /// No description provided for @rebalancingPlan.
  ///
  /// In en, this message translates to:
  /// **'Rebalancing Plan'**
  String get rebalancingPlan;

  /// No description provided for @rebalancingGuide.
  ///
  /// In en, this message translates to:
  /// **'Rebalancing Guide'**
  String get rebalancingGuide;

  /// No description provided for @addAccountsForRebalancing.
  ///
  /// In en, this message translates to:
  /// **'Add accounts with holdings to build your personalized rebalancing plan'**
  String get addAccountsForRebalancing;

  /// No description provided for @rebalancingPlanProDescription.
  ///
  /// In en, this message translates to:
  /// **'Get specific trade instructions with before/after risk metrics. See exactly what to buy or sell to reach your target allocation.'**
  String get rebalancingPlanProDescription;

  /// No description provided for @yourPersonalizedPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Personalized Plan'**
  String get yourPersonalizedPlan;

  /// No description provided for @customizeTrackExecute.
  ///
  /// In en, this message translates to:
  /// **'Customize strategy, track progress, execute trades'**
  String get customizeTrackExecute;

  /// No description provided for @lockedAccountsDetected.
  ///
  /// In en, this message translates to:
  /// **'Locked Accounts Detected'**
  String get lockedAccountsDetected;

  /// No description provided for @lockedAccountsMessage.
  ///
  /// In en, this message translates to:
  /// **'is locked (e.g., 401k, pension). Plan uses only'**
  String get lockedAccountsMessage;

  /// No description provided for @inUnlockedAccounts.
  ///
  /// In en, this message translates to:
  /// **'in unlocked accounts'**
  String get inUnlockedAccounts;

  /// No description provided for @lockedAccountsTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: For 401k/pension, update your contribution allocation rather than rebalancing existing holdings.'**
  String get lockedAccountsTip;

  /// No description provided for @rebalancingStrategy.
  ///
  /// In en, this message translates to:
  /// **'Rebalancing Strategy'**
  String get rebalancingStrategy;

  /// No description provided for @dollarCostAverageRecommended.
  ///
  /// In en, this message translates to:
  /// **'Dollar-Cost Average (Recommended)'**
  String get dollarCostAverageRecommended;

  /// No description provided for @dollarCostDescription.
  ///
  /// In en, this message translates to:
  /// **'Spread trades over multiple months to reduce timing risk'**
  String get dollarCostDescription;

  /// No description provided for @immediateRebalance.
  ///
  /// In en, this message translates to:
  /// **'Immediate Rebalance'**
  String get immediateRebalance;

  /// No description provided for @immediateRebalanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Execute all trades now if you have strong conviction'**
  String get immediateRebalanceDescription;

  /// No description provided for @glidePathDuration.
  ///
  /// In en, this message translates to:
  /// **'Glide Path Duration'**
  String get glidePathDuration;

  /// No description provided for @howManyMonthsToSpread.
  ///
  /// In en, this message translates to:
  /// **'How many months do you want to spread the rebalancing over?'**
  String get howManyMonthsToSpread;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @gradual.
  ///
  /// In en, this message translates to:
  /// **'Gradual'**
  String get gradual;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @executeNow.
  ///
  /// In en, this message translates to:
  /// **'Execute Now'**
  String get executeNow;

  /// No description provided for @totalToRebalanceImmediately.
  ///
  /// In en, this message translates to:
  /// **'Total to rebalance immediately'**
  String get totalToRebalanceImmediately;

  /// No description provided for @monthlyTransferAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly Transfer Amount'**
  String get monthlyTransferAmount;

  /// No description provided for @overMonths.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get overMonths;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @beforeVsAfter.
  ///
  /// In en, this message translates to:
  /// **'Before vs. After'**
  String get beforeVsAfter;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @executionChecklist.
  ///
  /// In en, this message translates to:
  /// **'Execution Checklist'**
  String get executionChecklist;

  /// No description provided for @trackMonthlyProgress.
  ///
  /// In en, this message translates to:
  /// **'Track your monthly progress as you execute trades'**
  String get trackMonthlyProgress;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @ofMonthsCompleted.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofMonthsCompleted;

  /// No description provided for @monthsCompleted.
  ///
  /// In en, this message translates to:
  /// **'months completed'**
  String get monthsCompleted;

  /// No description provided for @exportPDF.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPDF;

  /// No description provided for @pdfExportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'PDF export coming soon!'**
  String get pdfExportComingSoon;

  /// No description provided for @whyRebalance.
  ///
  /// In en, this message translates to:
  /// **'Why Rebalance?'**
  String get whyRebalance;

  /// No description provided for @whyRebalanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Market movements cause your portfolio to drift from your target allocation, increasing risk. Rebalancing restores your desired risk/return profile.'**
  String get whyRebalanceDescription;

  /// No description provided for @dollarCostAveragingTitle.
  ///
  /// In en, this message translates to:
  /// **'Dollar-Cost Averaging'**
  String get dollarCostAveragingTitle;

  /// No description provided for @dollarCostAveragingDescription.
  ///
  /// In en, this message translates to:
  /// **'Spreading trades over time reduces timing risk and market impact. Recommended for most investors.'**
  String get dollarCostAveragingDescription;

  /// No description provided for @immediateRebalancingTitle.
  ///
  /// In en, this message translates to:
  /// **'Immediate Rebalancing'**
  String get immediateRebalancingTitle;

  /// No description provided for @immediateRebalancingDescription.
  ///
  /// In en, this message translates to:
  /// **'Execute all trades at once. Best if you have strong market conviction or need to rebalance urgently.'**
  String get immediateRebalancingDescription;

  /// No description provided for @youreWellBalanced.
  ///
  /// In en, this message translates to:
  /// **'You\'re Well-Balanced!'**
  String get youreWellBalanced;

  /// No description provided for @noRebalancingNeeded.
  ///
  /// In en, this message translates to:
  /// **'Your portfolio is within tolerance of your target allocation. No rebalancing needed at this time.'**
  String get noRebalancingNeeded;

  /// No description provided for @accountType529EducationSavings.
  ///
  /// In en, this message translates to:
  /// **'529 Education Savings'**
  String get accountType529EducationSavings;

  /// No description provided for @accountTypeBrokerage.
  ///
  /// In en, this message translates to:
  /// **'Brokerage'**
  String get accountTypeBrokerage;

  /// No description provided for @accountTypeBrokerageAccount.
  ///
  /// In en, this message translates to:
  /// **'Brokerage Account'**
  String get accountTypeBrokerageAccount;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeCashAccount.
  ///
  /// In en, this message translates to:
  /// **'Cash Account'**
  String get accountTypeCashAccount;

  /// No description provided for @accountTypeCD.
  ///
  /// In en, this message translates to:
  /// **'CD'**
  String get accountTypeCD;

  /// No description provided for @accountTypeCertificateOfDeposit.
  ///
  /// In en, this message translates to:
  /// **'Certificate of Deposit'**
  String get accountTypeCertificateOfDeposit;

  /// No description provided for @accountTypeChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get accountTypeChecking;

  /// No description provided for @accountTypeCheckingAccount.
  ///
  /// In en, this message translates to:
  /// **'Checking Account'**
  String get accountTypeCheckingAccount;

  /// No description provided for @accountTypeCrypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get accountTypeCrypto;

  /// No description provided for @accountTypeCryptocurrency.
  ///
  /// In en, this message translates to:
  /// **'Cryptocurrency'**
  String get accountTypeCryptocurrency;

  /// No description provided for @accountTypeHealthSavingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Health Savings Account (HSA)'**
  String get accountTypeHealthSavingsAccount;

  /// No description provided for @accountTypeHSA.
  ///
  /// In en, this message translates to:
  /// **'HSA'**
  String get accountTypeHSA;

  /// No description provided for @accountTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get accountTypeOther;

  /// No description provided for @accountTypeRealEstate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get accountTypeRealEstate;

  /// No description provided for @accountTypeRealEstateEquity.
  ///
  /// In en, this message translates to:
  /// **'Real Estate Equity'**
  String get accountTypeRealEstateEquity;

  /// No description provided for @accountTypeRetirement.
  ///
  /// In en, this message translates to:
  /// **'Retirement'**
  String get accountTypeRetirement;

  /// No description provided for @accountTypeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeSavingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Savings Account'**
  String get accountTypeSavingsAccount;

  /// No description provided for @liabilityTypeAutoLoan.
  ///
  /// In en, this message translates to:
  /// **'Auto Loan'**
  String get liabilityTypeAutoLoan;

  /// No description provided for @liabilityTypeCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get liabilityTypeCreditCard;

  /// No description provided for @liabilityTypeLineOfCredit.
  ///
  /// In en, this message translates to:
  /// **'Line of Credit'**
  String get liabilityTypeLineOfCredit;

  /// No description provided for @liabilityTypeMortgage.
  ///
  /// In en, this message translates to:
  /// **'Mortgage'**
  String get liabilityTypeMortgage;

  /// No description provided for @liabilityTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get liabilityTypeOther;

  /// No description provided for @liabilityTypePersonalLoan.
  ///
  /// In en, this message translates to:
  /// **'Personal Loan'**
  String get liabilityTypePersonalLoan;

  /// No description provided for @liabilityTypeStudentLoan.
  ///
  /// In en, this message translates to:
  /// **'Student Loan'**
  String get liabilityTypeStudentLoan;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeletedSuccessfully;

  /// No description provided for @accountsPlural.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsPlural;

  /// No description provided for @addIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Add Income Source'**
  String get addIncomeSource;

  /// No description provided for @addLiability.
  ///
  /// In en, this message translates to:
  /// **'Add Liability'**
  String get addLiability;

  /// No description provided for @addNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Add New Account'**
  String get addNewAccount;

  /// No description provided for @addYourFirstIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Add your first income source to track cash flow'**
  String get addYourFirstIncomeSource;

  /// No description provided for @addYourFirstLiability.
  ///
  /// In en, this message translates to:
  /// **'Add your first liability to track debts'**
  String get addYourFirstLiability;

  /// No description provided for @allocationTargets.
  ///
  /// In en, this message translates to:
  /// **'Allocation Targets'**
  String get allocationTargets;

  /// No description provided for @allocationTargetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your target asset allocation percentages'**
  String get allocationTargetsDescription;

  /// No description provided for @allPayments.
  ///
  /// In en, this message translates to:
  /// **'All Payments'**
  String get allPayments;

  /// No description provided for @alternatives.
  ///
  /// In en, this message translates to:
  /// **'Alternatives'**
  String get alternatives;

  /// No description provided for @amountCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot be negative'**
  String get amountCannotBeNegative;

  /// No description provided for @annualInterestCost.
  ///
  /// In en, this message translates to:
  /// **'Annual Interest Cost'**
  String get annualInterestCost;

  /// No description provided for @appInfoAndDisclaimers.
  ///
  /// In en, this message translates to:
  /// **'App Info & Disclaimers'**
  String get appInfoAndDisclaimers;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'APR'**
  String get apr;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @areYouSureDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account?'**
  String get areYouSureDeleteAccount;

  /// No description provided for @areYouSureDeleteIncome.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this income source?'**
  String get areYouSureDeleteIncome;

  /// No description provided for @areYouSureExit.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get areYouSureExit;

  /// No description provided for @assetAllocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Diversify across asset classes to manage risk'**
  String get assetAllocationDescription;

  /// No description provided for @avgInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Avg Interest Rate'**
  String get avgInterestRate;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @backToSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Back to Snapshot'**
  String get backToSnapshot;

  /// No description provided for @backupRestoreData.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore Data'**
  String get backupRestoreData;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get bengali;

  /// No description provided for @bondsAndFixedIncome.
  ///
  /// In en, this message translates to:
  /// **'Bonds & Fixed Income'**
  String get bondsAndFixedIncome;

  /// No description provided for @budgetAndPlanning.
  ///
  /// In en, this message translates to:
  /// **'Budget & Planning'**
  String get budgetAndPlanning;

  /// No description provided for @budgetAndPlanningDescription.
  ///
  /// In en, this message translates to:
  /// **'Track spending and plan for goals'**
  String get budgetAndPlanningDescription;

  /// No description provided for @cap.
  ///
  /// In en, this message translates to:
  /// **'Cap'**
  String get cap;

  /// No description provided for @cashAndCashEquivalents.
  ///
  /// In en, this message translates to:
  /// **'Cash & Cash Equivalents'**
  String get cashAndCashEquivalents;

  /// No description provided for @chooseColorScheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Color Scheme'**
  String get chooseColorScheme;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @closeApplication.
  ///
  /// In en, this message translates to:
  /// **'Close Application'**
  String get closeApplication;

  /// No description provided for @colorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get colorIndigo;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @componentConcentration.
  ///
  /// In en, this message translates to:
  /// **'Concentration'**
  String get componentConcentration;

  /// No description provided for @componentDebtLoad.
  ///
  /// In en, this message translates to:
  /// **'Debt Load'**
  String get componentDebtLoad;

  /// No description provided for @componentFixedIncome.
  ///
  /// In en, this message translates to:
  /// **'Fixed Income'**
  String get componentFixedIncome;

  /// No description provided for @componentHomeBias.
  ///
  /// In en, this message translates to:
  /// **'Home Bias'**
  String get componentHomeBias;

  /// No description provided for @componentLiquidity.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get componentLiquidity;

  /// No description provided for @controlInternationalExposure.
  ///
  /// In en, this message translates to:
  /// **'Control international exposure'**
  String get controlInternationalExposure;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditLimit;

  /// No description provided for @creditLimitCannotBeLessThanBalance.
  ///
  /// In en, this message translates to:
  /// **'Credit limit cannot be less than current balance'**
  String get creditLimitCannotBeLessThanBalance;

  /// No description provided for @creditUtilization.
  ///
  /// In en, this message translates to:
  /// **'Credit Utilization'**
  String get creditUtilization;

  /// No description provided for @dayOfEachMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of Each Month'**
  String get dayOfEachMonth;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @debtsAndLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Debts & Liabilities'**
  String get debtsAndLiabilities;

  /// No description provided for @debtsPlural.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get debtsPlural;

  /// No description provided for @defaultPolicyPenalizeLargeDeviations.
  ///
  /// In en, this message translates to:
  /// **'Default policy: Penalize large deviations from targets'**
  String get defaultPolicyPenalizeLargeDeviations;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfully;

  /// No description provided for @deleteIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Delete Income Source'**
  String get deleteIncomeSource;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @displayInCurrency.
  ///
  /// In en, this message translates to:
  /// **'Display in Currency'**
  String get displayInCurrency;

  /// No description provided for @editIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get editIncome;

  /// No description provided for @editLiability.
  ///
  /// In en, this message translates to:
  /// **'Edit Liability'**
  String get editLiability;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @enterMinPayment.
  ///
  /// In en, this message translates to:
  /// **'Enter minimum payment'**
  String get enterMinPayment;

  /// No description provided for @enterMonthlyEssentials.
  ///
  /// In en, this message translates to:
  /// **'Enter monthly essentials'**
  String get enterMonthlyEssentials;

  /// No description provided for @enterTargetPercentage.
  ///
  /// In en, this message translates to:
  /// **'Enter target percentage'**
  String get enterTargetPercentage;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter valid amount'**
  String get enterValidAmount;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter valid number'**
  String get enterValidNumber;

  /// No description provided for @enterValidPayment.
  ///
  /// In en, this message translates to:
  /// **'Enter valid payment'**
  String get enterValidPayment;

  /// No description provided for @errorDeletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Error deleting account'**
  String get errorDeletingAccount;

  /// No description provided for @errorLoadingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Error loading accounts'**
  String get errorLoadingAccounts;

  /// No description provided for @errorLoadingLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Error loading liabilities'**
  String get errorLoadingLiabilities;

  /// No description provided for @excludeInternationalExposure.
  ///
  /// In en, this message translates to:
  /// **'Exclude international exposure'**
  String get excludeInternationalExposure;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @filteredFromSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Filtered from snapshot'**
  String get filteredFromSnapshot;

  /// No description provided for @financialScore.
  ///
  /// In en, this message translates to:
  /// **'Financial Score'**
  String get financialScore;

  /// No description provided for @frequencyAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get frequencyAnnual;

  /// No description provided for @frequencyAnnually.
  ///
  /// In en, this message translates to:
  /// **'Annually'**
  String get frequencyAnnually;

  /// No description provided for @frequencyBiWeekly.
  ///
  /// In en, this message translates to:
  /// **'Bi-Weekly'**
  String get frequencyBiWeekly;

  /// No description provided for @frequencyBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Bi-weekly'**
  String get frequencyBiweekly;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// No description provided for @frequencyHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get frequencyHourly;

  /// No description provided for @frequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// No description provided for @frequencyQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get frequencyQuarterly;

  /// No description provided for @frequencySemiMonthly.
  ///
  /// In en, this message translates to:
  /// **'Semi-Monthly'**
  String get frequencySemiMonthly;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpAllocationTargetsText.
  ///
  /// In en, this message translates to:
  /// **'Set target percentages for each asset class. The app will alert you when your actual allocation drifts too far from these targets.'**
  String get helpAllocationTargetsText;

  /// No description provided for @helpAllocationTargetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Allocation Targets Help'**
  String get helpAllocationTargetsTitle;

  /// No description provided for @helpMonthlyEssentialsText.
  ///
  /// In en, this message translates to:
  /// **'Enter your monthly essential expenses (rent, utilities, groceries, etc.). This helps calculate your emergency fund target.'**
  String get helpMonthlyEssentialsText;

  /// No description provided for @helpMonthlyEssentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Essentials Help'**
  String get helpMonthlyEssentialsTitle;

  /// No description provided for @helpRiskProfileText.
  ///
  /// In en, this message translates to:
  /// **'Choose a risk profile that matches your investment goals and time horizon. Conservative favors bonds and cash, Growth favors stocks, Balanced is in between.'**
  String get helpRiskProfileText;

  /// No description provided for @helpRiskProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk Profile Help'**
  String get helpRiskProfileTitle;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @howWeProtectData.
  ///
  /// In en, this message translates to:
  /// **'How We Protect Your Data'**
  String get howWeProtectData;

  /// No description provided for @importAccountsDebtsIncome.
  ///
  /// In en, this message translates to:
  /// **'Import accounts, debts, and income'**
  String get importAccountsDebtsIncome;

  /// No description provided for @importAndExport.
  ///
  /// In en, this message translates to:
  /// **'Import & Export'**
  String get importAndExport;

  /// No description provided for @importCSV.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCSV;

  /// No description provided for @income1099.
  ///
  /// In en, this message translates to:
  /// **'1099 Income'**
  String get income1099;

  /// No description provided for @incomeBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get incomeBonus;

  /// No description provided for @incomeFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get incomeFreelance;

  /// No description provided for @incomeInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get incomeInvestment;

  /// No description provided for @incomePension.
  ///
  /// In en, this message translates to:
  /// **'Pension'**
  String get incomePension;

  /// No description provided for @incomeRental.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get incomeRental;

  /// No description provided for @incomeSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get incomeSalary;

  /// No description provided for @incomeSocialSecurity.
  ///
  /// In en, this message translates to:
  /// **'Social Security'**
  String get incomeSocialSecurity;

  /// No description provided for @incomeSourceAdded.
  ///
  /// In en, this message translates to:
  /// **'Income source added'**
  String get incomeSourceAdded;

  /// No description provided for @incomeSourceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Income source deleted'**
  String get incomeSourceDeleted;

  /// No description provided for @incomeSourceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Income source updated'**
  String get incomeSourceUpdated;

  /// No description provided for @incomeW2.
  ///
  /// In en, this message translates to:
  /// **'W-2 Income'**
  String get incomeW2;

  /// No description provided for @internationalEquity.
  ///
  /// In en, this message translates to:
  /// **'International Equity'**
  String get internationalEquity;

  /// No description provided for @intlEquity.
  ///
  /// In en, this message translates to:
  /// **'Intl Equity'**
  String get intlEquity;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @lastPayment.
  ///
  /// In en, this message translates to:
  /// **'Last Payment'**
  String get lastPayment;

  /// No description provided for @legalTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Legal Terms & Conditions'**
  String get legalTermsAndConditions;

  /// No description provided for @lessPunitive.
  ///
  /// In en, this message translates to:
  /// **'Less punitive'**
  String get lessPunitive;

  /// No description provided for @liabilityDetails.
  ///
  /// In en, this message translates to:
  /// **'Liability Details'**
  String get liabilityDetails;

  /// No description provided for @liabilityName.
  ///
  /// In en, this message translates to:
  /// **'Liability Name'**
  String get liabilityName;

  /// No description provided for @liabilityNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Chase Visa, Student Loan'**
  String get liabilityNameHint;

  /// No description provided for @liabilitySavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Liability saved successfully'**
  String get liabilitySavedSuccessfully;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @minPayment.
  ///
  /// In en, this message translates to:
  /// **'Min Payment'**
  String get minPayment;

  /// No description provided for @monthlyEssentialExpenses.
  ///
  /// In en, this message translates to:
  /// **'Monthly Essential Expenses'**
  String get monthlyEssentialExpenses;

  /// No description provided for @monthlyEssentialsHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter your monthly essential expenses'**
  String get monthlyEssentialsHelper;

  /// No description provided for @monthlyEssentialsHelperUSD.
  ///
  /// In en, this message translates to:
  /// **'e.g., \$3000 for rent, utilities, groceries'**
  String get monthlyEssentialsHelperUSD;

  /// No description provided for @monthlyInterest.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest'**
  String get monthlyInterest;

  /// No description provided for @monthlyPaymentDay.
  ///
  /// In en, this message translates to:
  /// **'Monthly Payment Day'**
  String get monthlyPaymentDay;

  /// No description provided for @monthlyPayments.
  ///
  /// In en, this message translates to:
  /// **'Monthly Payments'**
  String get monthlyPayments;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @netIncome.
  ///
  /// In en, this message translates to:
  /// **'Net Income'**
  String get netIncome;

  /// No description provided for @nextPaymentDueDate.
  ///
  /// In en, this message translates to:
  /// **'Next Payment Due Date'**
  String get nextPaymentDueDate;

  /// No description provided for @noDebtsTracked.
  ///
  /// In en, this message translates to:
  /// **'No debts tracked yet'**
  String get noDebtsTracked;

  /// No description provided for @noIncomeSourcesYet.
  ///
  /// In en, this message translates to:
  /// **'No income sources yet'**
  String get noIncomeSourcesYet;

  /// No description provided for @noPaymentsRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet'**
  String get noPaymentsRecordedYet;

  /// No description provided for @offMute.
  ///
  /// In en, this message translates to:
  /// **'Off/Mute'**
  String get offMute;

  /// No description provided for @optimizePayoffStrategy.
  ///
  /// In en, this message translates to:
  /// **'Optimize payoff strategy'**
  String get optimizePayoffStrategy;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @paymentSchedule.
  ///
  /// In en, this message translates to:
  /// **'Payment Schedule'**
  String get paymentSchedule;

  /// No description provided for @paymentsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Payments will appear here'**
  String get paymentsWillAppearHere;

  /// No description provided for @percentageMustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'Percentage must be between 0 and 100'**
  String get percentageMustBeBetween;

  /// No description provided for @persian.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get persian;

  /// No description provided for @pleaseEnterAPR.
  ///
  /// In en, this message translates to:
  /// **'Please enter APR'**
  String get pleaseEnterAPR;

  /// No description provided for @pleaseEnterCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Please enter current balance'**
  String get pleaseEnterCurrentBalance;

  /// No description provided for @pleaseEnterLiabilityName.
  ///
  /// In en, this message translates to:
  /// **'Please enter liability name'**
  String get pleaseEnterLiabilityName;

  /// No description provided for @pleaseEnterValidAPR.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid APR'**
  String get pleaseEnterValidAPR;

  /// No description provided for @pleaseEnterValidCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid credit limit'**
  String get pleaseEnterValidCreditLimit;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @proFeature.
  ///
  /// In en, this message translates to:
  /// **'Pro Feature'**
  String get proFeature;

  /// No description provided for @proStatus.
  ///
  /// In en, this message translates to:
  /// **'Pro Status'**
  String get proStatus;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pts;

  /// No description provided for @quickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// No description provided for @realEstateREITs.
  ///
  /// In en, this message translates to:
  /// **'Real Estate & REITs'**
  String get realEstateREITs;

  /// No description provided for @requestLanguage.
  ///
  /// In en, this message translates to:
  /// **'Request a Language'**
  String get requestLanguage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @riskBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get riskBalanced;

  /// No description provided for @riskBalancedAllocation.
  ///
  /// In en, this message translates to:
  /// **'60% stocks, 35% bonds, 5% cash'**
  String get riskBalancedAllocation;

  /// No description provided for @riskBalancedDescription.
  ///
  /// In en, this message translates to:
  /// **'Moderate growth with some stability'**
  String get riskBalancedDescription;

  /// No description provided for @riskConservative.
  ///
  /// In en, this message translates to:
  /// **'Conservative'**
  String get riskConservative;

  /// No description provided for @riskConservativeAllocation.
  ///
  /// In en, this message translates to:
  /// **'30% stocks, 50% bonds, 20% cash'**
  String get riskConservativeAllocation;

  /// No description provided for @riskConservativeDescription.
  ///
  /// In en, this message translates to:
  /// **'Prioritize stability and capital preservation'**
  String get riskConservativeDescription;

  /// No description provided for @riskGrowth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get riskGrowth;

  /// No description provided for @riskGrowthAllocation.
  ///
  /// In en, this message translates to:
  /// **'80% stocks, 15% bonds, 5% cash'**
  String get riskGrowthAllocation;

  /// No description provided for @riskGrowthDescription.
  ///
  /// In en, this message translates to:
  /// **'Maximize long-term growth potential'**
  String get riskGrowthDescription;

  /// No description provided for @riskProfile.
  ///
  /// In en, this message translates to:
  /// **'Risk Profile'**
  String get riskProfile;

  /// No description provided for @riskProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Select your investment risk tolerance'**
  String get riskProfileDescription;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @selectNextPaymentDueDate.
  ///
  /// In en, this message translates to:
  /// **'Select next payment due date'**
  String get selectNextPaymentDueDate;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @setTargetsAndThresholds.
  ///
  /// In en, this message translates to:
  /// **'Set Targets & Thresholds'**
  String get setTargetsAndThresholds;

  /// No description provided for @settingsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSavedSuccessfully;

  /// No description provided for @shareThoughtsAndSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts and suggestions'**
  String get shareThoughtsAndSuggestions;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @tapToSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Tap to select date'**
  String get tapToSelectDate;

  /// No description provided for @targetsAndAlerts.
  ///
  /// In en, this message translates to:
  /// **'Targets & Alerts'**
  String get targetsAndAlerts;

  /// No description provided for @targetsAndAlertsHelp.
  ///
  /// In en, this message translates to:
  /// **'Targets & Alerts Help'**
  String get targetsAndAlertsHelp;

  /// No description provided for @taxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate'**
  String get taxRate;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @testingAsFreeUser.
  ///
  /// In en, this message translates to:
  /// **'Testing as Free User'**
  String get testingAsFreeUser;

  /// No description provided for @testingAsProUser.
  ///
  /// In en, this message translates to:
  /// **'Testing as Pro User'**
  String get testingAsProUser;

  /// No description provided for @timeframe30d.
  ///
  /// In en, this message translates to:
  /// **'30d'**
  String get timeframe30d;

  /// No description provided for @totalAllocation.
  ///
  /// In en, this message translates to:
  /// **'Total Allocation'**
  String get totalAllocation;

  /// No description provided for @totalDebt.
  ///
  /// In en, this message translates to:
  /// **'Total Debt'**
  String get totalDebt;

  /// No description provided for @totalMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Monthly Income'**
  String get totalMonthlyIncome;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @totalPayments.
  ///
  /// In en, this message translates to:
  /// **'Total Payments'**
  String get totalPayments;

  /// No description provided for @trackCreditCardsAndLoans.
  ///
  /// In en, this message translates to:
  /// **'Track credit cards and loans'**
  String get trackCreditCardsAndLoans;

  /// No description provided for @trackYourIncomeSources.
  ///
  /// In en, this message translates to:
  /// **'Track your income sources'**
  String get trackYourIncomeSources;

  /// No description provided for @trackYourNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Track your net worth'**
  String get trackYourNetWorth;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @unlockAdvancedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock Advanced Features'**
  String get unlockAdvancedFeatures;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get unsavedChangesMessage;

  /// No description provided for @updateAccount.
  ///
  /// In en, this message translates to:
  /// **'Update Account'**
  String get updateAccount;

  /// No description provided for @updateLiability.
  ///
  /// In en, this message translates to:
  /// **'Update Liability'**
  String get updateLiability;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @useDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use Dark Theme'**
  String get useDarkTheme;

  /// No description provided for @usEquity.
  ///
  /// In en, this message translates to:
  /// **'US Equity'**
  String get usEquity;

  /// No description provided for @usEquityTarget.
  ///
  /// In en, this message translates to:
  /// **'US Equity Target'**
  String get usEquityTarget;

  /// No description provided for @usEquityTargetHelper.
  ///
  /// In en, this message translates to:
  /// **'Target percentage for US stocks'**
  String get usEquityTargetHelper;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @viewAllAccounts.
  ///
  /// In en, this message translates to:
  /// **'View All Accounts'**
  String get viewAllAccounts;

  /// No description provided for @whatTypesOfDebt.
  ///
  /// In en, this message translates to:
  /// **'What types of debt can you track?'**
  String get whatTypesOfDebt;

  /// No description provided for @why.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get why;

  /// No description provided for @cutConcentration.
  ///
  /// In en, this message translates to:
  /// **'Cut Concentration: {details}'**
  String cutConcentration(String details);

  /// No description provided for @errorSavingIncome.
  ///
  /// In en, this message translates to:
  /// **'Error saving income: {error}'**
  String errorSavingIncome(String error);

  /// No description provided for @deleteIncomeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String deleteIncomeConfirm(String name);

  /// No description provided for @errorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error loading settings: {error}'**
  String errorLoadingSettings(String error);

  /// No description provided for @failedToSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings: {error}'**
  String failedToSaveSettings(String error);

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of Month: {day}'**
  String dayOfMonth(String day);

  /// No description provided for @errorLoadingIncome.
  ///
  /// In en, this message translates to:
  /// **'Error loading income: {error}'**
  String errorLoadingIncome(String error);

  /// No description provided for @errorDeletingIncome.
  ///
  /// In en, this message translates to:
  /// **'Error deleting income: {error}'**
  String errorDeletingIncome(String error);

  /// No description provided for @mixAndDials.
  ///
  /// In en, this message translates to:
  /// **'Mix & Dials'**
  String get mixAndDials;

  /// No description provided for @errorLoadingDataWithError.
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {error}'**
  String errorLoadingDataWithError(String error);

  /// No description provided for @errorLoadingDebtData.
  ///
  /// In en, this message translates to:
  /// **'Error loading debt data: {error}'**
  String errorLoadingDebtData(String error);

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @dollarCostAveragingCalculations.
  ///
  /// In en, this message translates to:
  /// **'Dollar-cost averaging calculations'**
  String get dollarCostAveragingCalculations;

  /// No description provided for @primarySecondaryRebalancingTargets.
  ///
  /// In en, this message translates to:
  /// **'Primary/secondary rebalancing targets'**
  String get primarySecondaryRebalancingTargets;

  /// No description provided for @timelineWithMonitoringAlerts.
  ///
  /// In en, this message translates to:
  /// **'Timeline with monitoring alerts'**
  String get timelineWithMonitoringAlerts;

  /// No description provided for @adjustTargetAllocation.
  ///
  /// In en, this message translates to:
  /// **'Adjust Target Allocation'**
  String get adjustTargetAllocation;

  /// No description provided for @savePlan.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get savePlan;

  /// No description provided for @previewPdf.
  ///
  /// In en, this message translates to:
  /// **'Preview PDF'**
  String get previewPdf;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @aboutMixAndDials.
  ///
  /// In en, this message translates to:
  /// **'About Mix & Dials'**
  String get aboutMixAndDials;

  /// No description provided for @mixAndDialsDescription.
  ///
  /// In en, this message translates to:
  /// **'This screen provides detailed analysis of your portfolio:'**
  String get mixAndDialsDescription;

  /// No description provided for @assetAllocationBreakdown.
  ///
  /// In en, this message translates to:
  /// **'• Asset Allocation - Visual breakdown of your investments'**
  String get assetAllocationBreakdown;

  /// No description provided for @diversificationDials.
  ///
  /// In en, this message translates to:
  /// **'• Diversification Dials - Risk and geographic distribution'**
  String get diversificationDials;

  /// No description provided for @rebalancingPlansRecommendations.
  ///
  /// In en, this message translates to:
  /// **'• Rebalancing Plans - Actionable recommendations'**
  String get rebalancingPlansRecommendations;

  /// No description provided for @rebalancingPlanSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Rebalancing plan saved successfully!'**
  String get rebalancingPlanSavedSuccessfully;

  /// No description provided for @planSaved.
  ///
  /// In en, this message translates to:
  /// **'Plan Saved'**
  String get planSaved;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @pdfPreview.
  ///
  /// In en, this message translates to:
  /// **'PDF Preview'**
  String get pdfPreview;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @pdfExportFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'PDF export feature coming soon!'**
  String get pdfExportFeatureComingSoon;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @errorLoadingAccountsWithError.
  ///
  /// In en, this message translates to:
  /// **'Error loading accounts: {error}'**
  String errorLoadingAccountsWithError(String error);

  /// No description provided for @gettingStartedGuide.
  ///
  /// In en, this message translates to:
  /// **'Getting Started Guide'**
  String get gettingStartedGuide;

  /// No description provided for @previewWithSampleData.
  ///
  /// In en, this message translates to:
  /// **'Preview with Sample Data'**
  String get previewWithSampleData;

  /// No description provided for @archiveAccount.
  ///
  /// In en, this message translates to:
  /// **'Archive Account'**
  String get archiveAccount;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'archived'**
  String get archived;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @loadSampleData.
  ///
  /// In en, this message translates to:
  /// **'Load Sample Data'**
  String get loadSampleData;

  /// No description provided for @sampleDataLoaded.
  ///
  /// In en, this message translates to:
  /// **'Sample data loaded!'**
  String get sampleDataLoaded;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @viewAccountsWithUsEquity.
  ///
  /// In en, this message translates to:
  /// **'View accounts with US Equity'**
  String get viewAccountsWithUsEquity;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @riskNudgeSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Risk nudge snoozed for 30 days'**
  String get riskNudgeSnoozed;

  /// No description provided for @riskMarkedAsResolved.
  ///
  /// In en, this message translates to:
  /// **'Risk marked as resolved'**
  String get riskMarkedAsResolved;

  /// No description provided for @howWeCalculateThis.
  ///
  /// In en, this message translates to:
  /// **'How We Calculate This'**
  String get howWeCalculateThis;

  /// No description provided for @yourFinancialHealthScoreBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Your financial health score is based on:'**
  String get yourFinancialHealthScoreBasedOn;

  /// No description provided for @concentrationRiskPercent.
  ///
  /// In en, this message translates to:
  /// **'• Concentration Risk (30%)'**
  String get concentrationRiskPercent;

  /// No description provided for @fixedIncomeBalancePercent.
  ///
  /// In en, this message translates to:
  /// **'• Fixed Income Balance (25%)'**
  String get fixedIncomeBalancePercent;

  /// No description provided for @liquidityBufferPercent.
  ///
  /// In en, this message translates to:
  /// **'• Liquidity Buffer (20%)'**
  String get liquidityBufferPercent;

  /// No description provided for @internationalExposurePercent.
  ///
  /// In en, this message translates to:
  /// **'• International Exposure (15%)'**
  String get internationalExposurePercent;

  /// No description provided for @debtManagementPercent.
  ///
  /// In en, this message translates to:
  /// **'• Debt Management (10%)'**
  String get debtManagementPercent;

  /// No description provided for @addAccounts.
  ///
  /// In en, this message translates to:
  /// **'Add Accounts'**
  String get addAccounts;

  /// No description provided for @addMonthlyEssentials.
  ///
  /// In en, this message translates to:
  /// **'Add Monthly Essentials'**
  String get addMonthlyEssentials;

  /// No description provided for @noTrendDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No trend data available'**
  String get noTrendDataAvailable;

  /// No description provided for @exportPdfReport.
  ///
  /// In en, this message translates to:
  /// **'Export PDF Report'**
  String get exportPdfReport;

  /// No description provided for @saveAsSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Save as Snapshot'**
  String get saveAsSnapshot;

  /// No description provided for @viewScoreHistory.
  ///
  /// In en, this message translates to:
  /// **'View Score History'**
  String get viewScoreHistory;

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @failedToCreateSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Failed to create snapshot: {error}'**
  String failedToCreateSnapshot(String error);

  /// No description provided for @snapshotDetail.
  ///
  /// In en, this message translates to:
  /// **'Snapshot Detail'**
  String get snapshotDetail;

  /// No description provided for @snapshotNote.
  ///
  /// In en, this message translates to:
  /// **'Snapshot Note'**
  String get snapshotNote;

  /// No description provided for @savedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads/{filename}'**
  String savedToDownloads(String filename);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @isAvailableWithRebalancePro.
  ///
  /// In en, this message translates to:
  /// **'{feature} is available with Rebalance Pro.'**
  String isAvailableWithRebalancePro(String feature);

  /// No description provided for @startCompare.
  ///
  /// In en, this message translates to:
  /// **'Start Compare'**
  String get startCompare;

  /// No description provided for @selectThisAsStartingPoint.
  ///
  /// In en, this message translates to:
  /// **'Select this as starting point for comparison'**
  String get selectThisAsStartingPoint;

  /// No description provided for @deleteSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Delete Snapshot?'**
  String get deleteSnapshot;

  /// No description provided for @failedToDeleteSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete snapshot: {error}'**
  String failedToDeleteSnapshot(String error);

  /// No description provided for @unlockTaxOptimization.
  ///
  /// In en, this message translates to:
  /// **'Unlock Tax Optimization'**
  String get unlockTaxOptimization;

  /// No description provided for @estimatedAnnualTaxSavings.
  ///
  /// In en, this message translates to:
  /// **'Estimated Annual Tax Savings'**
  String get estimatedAnnualTaxSavings;

  /// No description provided for @potentialSavings.
  ///
  /// In en, this message translates to:
  /// **'Potential Savings: {amount} / yr'**
  String potentialSavings(String amount);

  /// No description provided for @yourAssetsAreAlreadyTaxEfficient.
  ///
  /// In en, this message translates to:
  /// **'Your assets are already tax-efficiently located. 👍'**
  String get yourAssetsAreAlreadyTaxEfficient;

  /// No description provided for @suggestedReallocation.
  ///
  /// In en, this message translates to:
  /// **'Suggested Reallocation'**
  String get suggestedReallocation;

  /// No description provided for @assumptionsAndMethodology.
  ///
  /// In en, this message translates to:
  /// **'Assumptions & Methodology'**
  String get assumptionsAndMethodology;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @getAlertsAboutDrift.
  ///
  /// In en, this message translates to:
  /// **'Get alerts about drift and rebalancing opportunities'**
  String get getAlertsAboutDrift;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @averageAnnualReturn.
  ///
  /// In en, this message translates to:
  /// **'• Average annual return: 7%'**
  String get averageAnnualReturn;

  /// No description provided for @marketVolatility.
  ///
  /// In en, this message translates to:
  /// **'• Market volatility: 15%'**
  String get marketVolatility;

  /// No description provided for @inflationRate.
  ///
  /// In en, this message translates to:
  /// **'• Inflation: 3% per year'**
  String get inflationRate;

  /// No description provided for @noDebtsToOptimize.
  ///
  /// In en, this message translates to:
  /// **'No debts to optimize!'**
  String get noDebtsToOptimize;

  /// No description provided for @addLiabilitiesFromTab.
  ///
  /// In en, this message translates to:
  /// **'Add liabilities from the Liabilities tab to use this tool.'**
  String get addLiabilitiesFromTab;

  /// No description provided for @currentDebt.
  ///
  /// In en, this message translates to:
  /// **'Current Debt'**
  String get currentDebt;

  /// No description provided for @liabilityCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{liability} other{liabilities}} • {minPayment}/month minimum'**
  String liabilityCount(int count, String minPayment);

  /// No description provided for @extraMonthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Extra Monthly Payment'**
  String get extraMonthlyPayment;

  /// No description provided for @totalMonthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Total monthly payment: {amount}'**
  String totalMonthlyPayment(String amount);

  /// No description provided for @payoffStrategies.
  ///
  /// In en, this message translates to:
  /// **'Payoff Strategies'**
  String get payoffStrategies;

  /// No description provided for @strategyRecommendation.
  ///
  /// In en, this message translates to:
  /// **'We recommend the option with lower total interest. You can still select the other for motivation wins.'**
  String get strategyRecommendation;

  /// No description provided for @avalanche.
  ///
  /// In en, this message translates to:
  /// **'Avalanche'**
  String get avalanche;

  /// No description provided for @avalancheRecommended.
  ///
  /// In en, this message translates to:
  /// **'Avalanche (Recommended)'**
  String get avalancheRecommended;

  /// No description provided for @avalancheDescription.
  ///
  /// In en, this message translates to:
  /// **'Highest APR first – minimizes total interest'**
  String get avalancheDescription;

  /// No description provided for @snowball.
  ///
  /// In en, this message translates to:
  /// **'Snowball'**
  String get snowball;

  /// No description provided for @snowballRecommended.
  ///
  /// In en, this message translates to:
  /// **'Snowball (Recommended)'**
  String get snowballRecommended;

  /// No description provided for @snowballDescription.
  ///
  /// In en, this message translates to:
  /// **'Smallest balance first – faster psychological wins'**
  String get snowballDescription;

  /// No description provided for @unlockDetailedPayoffSchedule.
  ///
  /// In en, this message translates to:
  /// **'Unlock Detailed Payoff Schedule'**
  String get unlockDetailedPayoffSchedule;

  /// No description provided for @monthByMonthBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Get month-by-month payment breakdown showing:'**
  String get monthByMonthBreakdown;

  /// No description provided for @exactPayoffDate.
  ///
  /// In en, this message translates to:
  /// **'Exact payoff date for each debt'**
  String get exactPayoffDate;

  /// No description provided for @principalVsInterest.
  ///
  /// In en, this message translates to:
  /// **'Principal vs interest breakdown'**
  String get principalVsInterest;

  /// No description provided for @remainingBalanceTracking.
  ///
  /// In en, this message translates to:
  /// **'Remaining balance tracking'**
  String get remainingBalanceTracking;

  /// No description provided for @totalInterestSaved.
  ///
  /// In en, this message translates to:
  /// **'Total interest saved: {amount}'**
  String totalInterestSaved(String amount);

  /// No description provided for @debtPayoffOrder.
  ///
  /// In en, this message translates to:
  /// **'Debt Payoff Order'**
  String get debtPayoffOrder;

  /// No description provided for @debtsWillBePaidInOrder.
  ///
  /// In en, this message translates to:
  /// **'Debts will be paid off in this order ({strategy} strategy):'**
  String debtsWillBePaidInOrder(String strategy);

  /// No description provided for @paidOff.
  ///
  /// In en, this message translates to:
  /// **'Paid off'**
  String get paidOff;

  /// No description provided for @payoffTime.
  ///
  /// In en, this message translates to:
  /// **'Payoff Time'**
  String get payoffTime;

  /// No description provided for @monthsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} months'**
  String monthsCount(int count);

  /// No description provided for @totalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total Interest'**
  String get totalInterest;

  /// No description provided for @saveVsMinimum.
  ///
  /// In en, this message translates to:
  /// **'Save {amount} vs minimum payments'**
  String saveVsMinimum(String amount);

  /// No description provided for @detailedPaymentSchedule.
  ///
  /// In en, this message translates to:
  /// **'Detailed Payment Schedule'**
  String get detailedPaymentSchedule;

  /// No description provided for @monthByMonthStrategy.
  ///
  /// In en, this message translates to:
  /// **'Month-by-month breakdown ({strategy} strategy):'**
  String monthByMonthStrategy(String strategy);

  /// No description provided for @monthNumber.
  ///
  /// In en, this message translates to:
  /// **'Month {number}'**
  String monthNumber(int number);

  /// No description provided for @principalAndInterest.
  ///
  /// In en, this message translates to:
  /// **'{principal} principal • {interest} interest'**
  String principalAndInterest(String principal, String interest);

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount}'**
  String remaining(String amount);

  /// No description provided for @moreMonths.
  ///
  /// In en, this message translates to:
  /// **'... {count} more months'**
  String moreMonths(int count);

  /// No description provided for @strategyComparison.
  ///
  /// In en, this message translates to:
  /// **'Strategy Comparison'**
  String get strategyComparison;

  /// No description provided for @strategySavingsComparison.
  ///
  /// In en, this message translates to:
  /// **'{strategy} saves {interestDiff} more interest{monthsInfo} vs the other approach.'**
  String strategySavingsComparison(
      String strategy, String interestDiff, String monthsInfo);

  /// No description provided for @andFinishesEarlier.
  ///
  /// In en, this message translates to:
  /// **' and finishes {months} month{plural} sooner'**
  String andFinishesEarlier(int months, String plural);

  /// No description provided for @unlockDebtPayoffOptimizer.
  ///
  /// In en, this message translates to:
  /// **'Unlock Debt Payoff Optimizer'**
  String get unlockDebtPayoffOptimizer;

  /// No description provided for @fastestPathToDebtFreedom.
  ///
  /// In en, this message translates to:
  /// **'Find the fastest path to debt freedom'**
  String get fastestPathToDebtFreedom;

  /// No description provided for @compareAvalancheSnowball.
  ///
  /// In en, this message translates to:
  /// **'Compare avalanche vs snowball strategies'**
  String get compareAvalancheSnowball;

  /// No description provided for @seeExactPayoffDates.
  ///
  /// In en, this message translates to:
  /// **'See exact payoff dates for each debt'**
  String get seeExactPayoffDates;

  /// No description provided for @calculateInterestSavings.
  ///
  /// In en, this message translates to:
  /// **'Calculate total interest savings'**
  String get calculateInterestSavings;

  /// No description provided for @getMonthlySchedule.
  ///
  /// In en, this message translates to:
  /// **'Get month-by-month payment schedule'**
  String get getMonthlySchedule;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get best;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'SELECTED'**
  String get selected;

  /// No description provided for @selectStrategy.
  ///
  /// In en, this message translates to:
  /// **'Select strategy'**
  String get selectStrategy;

  /// No description provided for @typesOfDebtYouCanTrack.
  ///
  /// In en, this message translates to:
  /// **'Types of Debt You Can Track'**
  String get typesOfDebtYouCanTrack;

  /// No description provided for @creditCardsDescription.
  ///
  /// In en, this message translates to:
  /// **'• Credit Cards - Track balances and credit utilization'**
  String get creditCardsDescription;

  /// No description provided for @mortgagesDescription.
  ///
  /// In en, this message translates to:
  /// **'• Mortgages - Home loans and refinances'**
  String get mortgagesDescription;

  /// No description provided for @autoLoansDescription.
  ///
  /// In en, this message translates to:
  /// **'• Auto Loans - Car and vehicle financing'**
  String get autoLoansDescription;

  /// No description provided for @studentLoansDescription.
  ///
  /// In en, this message translates to:
  /// **'• Student Loans - Education debt'**
  String get studentLoansDescription;

  /// No description provided for @personalLoansDescription.
  ///
  /// In en, this message translates to:
  /// **'• Personal Loans - Unsecured debt'**
  String get personalLoansDescription;

  /// No description provided for @helocDescription.
  ///
  /// In en, this message translates to:
  /// **'• HELOC - Home equity lines of credit'**
  String get helocDescription;

  /// No description provided for @businessLoansDescription.
  ///
  /// In en, this message translates to:
  /// **'• Business Loans - Commercial debt'**
  String get businessLoansDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'bn', 'en', 'fa', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
