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
