# Wealth Dial Improvement Tracker

Last updated: April 16, 2026

## Purpose
This file is the single source of truth for what we are fixing, building, and completing.
We will update this file every session so progress is not lost.

## Status Legend
- `Not Started`
- `In Progress`
- `Blocked`
- `Done`

## Current Focus
- `In Progress`: PR-03 Goal planner with Monte Carlo confidence discovery and implementation.

## Baseline Snapshot (March 24, 2026)
- `flutter analyze` (entire repo): 678 issues (includes backup/archive folders).
- `flutter analyze lib test`: 120 issues (active source only).
- `flutter test`: failing test in `test/homebias_modes_test.dart`.

---

## Phase 1: Critical Fixes (Do First)

| ID | Item | Priority | Status | Notes |
|---|---|---|---|---|
| P1-01 | Implement real purchase verification (server-side) | Critical | Done | Implemented, deployed, Play API permissions validated, live purchase flow verified, and release define pipeline configured. |
| P1-02 | Fix backup/restore data integrity and coverage | Critical | Done | Backup/restore now covers all persisted domains with centralized serialization and consistent restore behavior. |
| P1-03 | Align privacy claims with analytics behavior | High | Done | Runtime telemetry removed (no-op analytics service + Firebase deps removed) and privacy/store/readme claims aligned with actual network behavior. |
| P1-04 | Fix `markAllRead()` no-op | High | Done | Implemented persistence loop in repository and verified with analyzer. |
| P1-05 | Fix failing test (`homebias_modes_test`) and mode expectation mismatch | High | Done | Test now sets mode explicitly (`standard` vs `off`) and passes reliably. |

## Phase 2: Quality and Maintainability

| ID | Item | Priority | Status | Notes |
|---|---|---|---|---|
| P2-01 | Exclude backup/archive folders from analyzer scope | High | Done | Added broad backup/archive directory excludes and re-baselined analyzer signal. |
| P2-02 | Add missing `uuid` dependency in `pubspec.yaml` | Medium | Done | Added `uuid` dependency; analyzer package warning resolved for new imports. |
| P2-03 | Replace silent FX 1:1 fallback with user-visible stale-rate handling | Medium | Done | Added FX source statuses (live/cache/stale/fallback) and user-visible stale/fallback messaging in conversion formatting and currency preview UI. |
| P2-04 | Complete localization pass in expense flow | Medium | Done | Replaced hardcoded strings in expense detail/list flows with l10n keys and added missing EN/FR translations. |
| P2-05 | Refactor oversized dashboard screen into smaller modules | Medium | Done | Extracted major dashboard modules into dedicated files and removed dead code paths from dashboard/reports for maintainability. |
| P2-06 | Reduce deprecated API usage (`withOpacity`, radio API, etc.) | Medium | Done | Replaced deprecated `withOpacity` usage, migrated radio groups to `RadioGroup`, and removed deprecated color channel accessors. |
| P2-07 | Resolve async `BuildContext` lint violations | Medium | Done | Removed async-gap context usage by anchoring parent contexts, adding `mounted` guards, and avoiding delayed context access. |

## Phase 3: Premium Enhancements Roadmap

| ID | Enhancement | Priority | Status | Notes |
|---|---|---|---|---|
| PR-01 | Household mode (multi-profile/shared goals) | High | Done | Completed slices: profile model/UI, active-profile partitioning, backup ownership mapping, move workflows (pair + all-to-active + type-selective), EN/FR household UX localization, pre-action movable-data visibility, active-profile summary visibility, per-profile net-worth context, shared/private goal management, split-based shared-goal coordination, and Pro surfacing updates. Verified with `flutter analyze lib` and full `flutter test` pass on 2026-04-16. |
| PR-02 | Tax center (withdrawal order/tax drag) | High | Not Started | High perceived Pro value. |
| PR-03 | Goal planner with Monte Carlo confidence | High | In Progress | Started implementation slice with reusable Monte Carlo goal planner service (`GoalPlannerService`) including confidence probability, percentile outcomes, and required-monthly-contribution targeting. |
| PR-04 | Rule-based smart automation | Medium | Not Started | Rebalancing and proactive recommendations. |
| PR-05 | Advisor-ready premium reports | Medium | Not Started | Exportable financial review packets. |
| PR-06 | Advanced scenario stress testing (regime shocks) | Medium | Not Started | Pro+ modeling depth. |
| PR-07 | Pro onboarding concierge | Medium | Not Started | Improves conversion and activation. |
| PR-08 | Encrypted backup with passphrase + integrity checks | High | Done | Completed: encrypted envelope, integrity validation, retry-safe restore UX, and EN/FR localization coverage for export/backup flows. |

---

## Session Log

### 2026-03-24
- Created this tracker file.
- Loaded baseline findings from full project review.
- Defined phased backlog with priorities and statuses.
- Started P1-01 implementation.
- Confirmed architecture decision: backend stores entitlement metadata only (purchase tokens/product/expiry/status), never user financial records.
- Added backend service at `backend/entitlements/` with Google Play verification endpoints.
- Added app integration via `lib/services/entitlement_backend_service.dart`.
- Updated purchase flow to require backend verification (with optional debug bypass via `ALLOW_UNVERIFIED_PURCHASES=true`).
- Added startup entitlement sync from backend (`purchaseService.syncEntitlementFromBackend`).
- Added setup guide: `docs/ENTITLEMENT_BACKEND_SETUP.md`.

## P1-01 Progress Checklist
- [x] Backend service scaffolded.
- [x] Google Play verification endpoint implemented.
- [x] Entitlement persistence implemented (metadata-only).
- [x] Flutter purchase flow switched from local trust to backend verification.
- [x] App startup entitlement sync added.
- [x] Deployment assets prepared (Dockerfile, Cloud Run scripts, deployment runbook).
- [x] Backend deployed (HTTPS endpoint available).
- [x] Google Play API credentials configured in deployment runtime.
- [x] Production dart-defines configured in CI/release pipeline.
- [x] End-to-end validation with real sandbox/internal test purchases.

### 2026-03-24 (cont.)
- Added deployment assets:
  - `backend/entitlements/Dockerfile`
  - `backend/entitlements/.dockerignore`
  - `backend/entitlements/scripts/deploy_cloud_run.ps1`
  - `backend/entitlements/scripts/deploy_cloud_run.sh`
- Added deployment runbook: `docs/ENTITLEMENT_DEPLOYMENT_RUNBOOK.md`.
- Generated `backend/entitlements/package-lock.json` for reproducible installs.
- Attempted Cloud Run deployment setup on project `rebalance-632cf`.
- Blocker encountered: project billing not enabled (`UREQ_PROJECT_BILLING_NOT_FOUND`) prevents enabling `run.googleapis.com`, `cloudbuild.googleapis.com`, and `secretmanager.googleapis.com`.
- Billing enabled and blocker resolved.
- Enabled required APIs for entitlement backend deployment.
- Created runtime service account: `wealth-dial-entitlement-sa@rebalance-632cf.iam.gserviceaccount.com`.
- Created `ENTITLEMENT_API_KEY` in Secret Manager and granted secret access to runtime service account.
- Deployed Cloud Run service:
  - Name: `wealth-dial-entitlements`
  - Region: `us-central1`
  - URL: `https://wealth-dial-entitlements-645757352413.us-central1.run.app`
- Health check passed (`GET /health` returned 200).
- Auth smoke tests passed:
  - Without API key: `401`
  - With API key on unknown user: `404` (expected until a purchase is verified)
- Play API permission propagation validated:
  - Previously: `verification_error_401` (`insufficient permissions`)
  - Now: `verification_error_400` (`Invalid Value`) for fake token, indicating auth/permissions are fixed and backend is reaching Google Play successfully.
- Live runtime validation log captured:
  - `Applied entitlement from backend: isPro=true, expiry=null, status=active_lifetime`
  - `Purchase success: pro_monthly (...)`
  - Confirms backend entitlement response is being applied in-app during purchase flow.
- Configured production release define pipeline:
  - Added `config/dart_defines.production.example.json`
  - Added secure build scripts: `tools/build_release_appbundle.ps1` and `tools/build_release_appbundle.sh`
  - Updated release docs/checklists to use `--dart-define-from-file=config/dart_defines.production.json`
  - Added `.gitignore` protection for `config/dart_defines.production.json`
- Marked `P1-01` complete and shifted current focus to `P1-04`.
- Created local `config/dart_defines.production.json` with deployed backend URL and API key for release builds.
- Completed `P1-04`:
  - Implemented `RepositoryService.markAllRead()` to set unread notifications to `read=true` and persist each record.
  - Verification: `flutter analyze lib/data/repositories.dart lib/app.dart` returned no issues.
  - Shifted current focus to `P1-05`.
- Completed `P1-05`:
  - Updated `test/homebias_modes_test.dart` to explicitly set `globalDiversificationMode: 'standard'` in the standard scenario.
  - Root cause: `Settings` defaults to `globalDiversificationMode: 'off'`, so implicit assumptions in the test became invalid.
  - Verification:
    - `flutter test test/homebias_modes_test.dart` -> passed.
    - `flutter analyze test/homebias_modes_test.dart` -> no issues.
  - Shifted current focus to `P2-01`.
- Completed `P2-01`:
  - Updated `analysis_options.yaml` excludes to cover broad backup/archive directory patterns:
    - `backup*/**`
    - `archive*/**`
  - Verification:
    - `flutter analyze` now reports `124 issues` (vs prior `678` noisy full-repo baseline).
    - Signal is now aligned with active code quality work instead of historical backup directories.
  - Shifted current focus to `P1-02`.
- Completed `P1-02`:
  - Fixed data reset integrity in `RepositoryService.clearAllData()`:
    - Added missing close/delete coverage for `incomes` and `expenses` boxes.
  - Expanded repository export/import coverage to include all persisted domains:
    - accounts, liabilities, incomes, expenses, settings, snapshots, action cards, payments, notifications.
  - Hardened import parsing for legacy backup compatibility:
    - Supports enum values stored as either `.name` or `Type.value`.
    - Converts legacy percent-style ratio values (e.g., `5`, `60`) to decimal ratios where required.
    - Handles invalid/legacy diversification mode values safely (`off` fallback).
  - Added missing snapshot/settings fields to serialization to prevent silent data loss.
  - Consolidated `BackupService` to use `RepositoryService.exportData()/importData()` instead of duplicate serializers.
  - Expanded restore summary to report all restored domains.
  - Verification:
    - `flutter analyze lib/data/repositories.dart lib/services/backup_service.dart lib/features/export/export_screen.dart` -> no issues.
  - Shifted current focus to `P1-03`.
- Completed `P1-03`:
  - Runtime behavior alignment:
    - Replaced analytics implementation with no-op service in `lib/services/analytics_service.dart`.
    - Removed Firebase initialization from `lib/main.dart`.
    - Removed `firebase_core` and `firebase_analytics` from `pubspec.yaml` and refreshed dependencies.
  - Documentation alignment:
    - Updated `README.md` privacy wording to remove inaccurate "No Network" language and clarify limited optional network calls.
    - Updated store listing copy in `docs/STORE_LISTING.md` to match runtime behavior.
    - Updated privacy policy docs:
      - `docs/PRIVACY_POLICY.md`
      - `docs/privacy.html`
      - `docs/privacy_policy.html`
    - Policies now consistently state:
      - no behavioral analytics/telemetry
      - financial records remain local
      - limited network use for FX rates and Pro purchase entitlement verification
  - Verification:
    - `rg -n "firebase_core|firebase_analytics|Firebase\\.initializeApp|FirebaseAnalytics" lib pubspec.yaml` -> no matches.
    - `flutter analyze lib/main.dart lib/services/analytics_service.dart` -> no issues.
  - Shifted current focus to `P2-03`.
- Completed `P2-03`:
  - Implemented explicit FX conversion source/status model in `lib/services/exchange_rate_service.dart`:
    - `ExchangeRateInfo` + `ExchangeRateSource` (`live`, `cacheFresh`, `cacheStale`, `fallbackOneToOne`, etc.).
    - Added `getRateInfo(from, to)` so callers can detect stale/fallback states.
  - Updated conversion formatting in `lib/utils/currency_formatter.dart`:
    - Prevents misleading target-currency output on fallback.
    - Adds user-visible indicators: `(stale)` and `(FX unavailable)` when applicable.
  - Updated `lib/widgets/currency_text.dart`:
    - Removed silent/print-based fallback path.
    - Displays explicit `(FX unavailable)` text on conversion failure.
  - Updated currency preview UI in `lib/features/targets/targets_screen.dart`:
    - Uses `getRateInfo(...)` and shows warning styling/messages for stale/fallback rates.
  - Verification:
    - `flutter analyze lib/services/exchange_rate_service.dart lib/utils/currency_formatter.dart lib/widgets/currency_text.dart` -> no issues.
  - Shifted current focus to `P2-04`.
- Completed `P2-04`:
  - Replaced hardcoded strings in:
    - `lib/features/expenses/expense_detail_screen.dart`
    - `lib/features/expenses/expenses_screen.dart`
  - Added missing localization keys in:
    - `lib/l10n/app_en.arb`
    - `lib/l10n/app_fr.arb`
  - Regenerated localization outputs via `flutter gen-l10n`.
  - Included localized category labels and expense lifecycle messaging (add/edit/delete/error states).
  - Verification:
    - `flutter analyze lib/features/expenses/expense_detail_screen.dart lib/features/expenses/expenses_screen.dart` -> no issues.
  - Shifted current focus to `P2-06`.
  
### 2026-03-26
- Completed `P2-06`:
  - Replaced deprecated `withOpacity(...)` calls across active `lib/` sources with `withValues(alpha: ...)`.
  - Migrated deprecated radio selection APIs to `RadioGroup` patterns in:
    - `lib/features/rebalancing/rebalancing_plan_screen.dart`
    - `lib/features/targets/targets_screen.dart`
  - Updated `lib/utils/color_extensions.dart` to remove deprecated channel/property access usage.
  - Verification:
    - `flutter analyze lib/features/dashboard/dashboard_screen.dart lib/features/dashboard/guardrails_detail_screen.dart lib/features/import/csv_import_screen.dart lib/features/rebalancing/rebalancing_plan_screen.dart lib/features/targets/targets_screen.dart lib/utils/color_extensions.dart`
    - `flutter analyze lib` -> `40 issues found` (down from prior `111`), with deprecated API warnings removed.
  - Shifted current focus to `P2-07`.
- Completed `P2-07`:
  - Fixed async `BuildContext` usage patterns in:
    - `lib/features/accounts/accounts_screen.dart`
    - `lib/features/income/income_screen.dart`
    - `lib/features/liabilities/liabilities_screen.dart`
    - `lib/features/targets/targets_detail_screen.dart`
    - `lib/features/dashboard/dashboard_screen.dart`
  - Changes included:
    - use of parent/dialog contexts to avoid stale dialog context access after `await`
    - `mounted`/`parentContext.mounted` guards before snackbar/navigation after async operations
    - route push in delayed callback switched to captured router instance instead of delayed context usage
  - Verification:
    - `flutter analyze lib/features/accounts/accounts_screen.dart lib/features/income/income_screen.dart lib/features/liabilities/liabilities_screen.dart lib/features/targets/targets_detail_screen.dart lib/features/dashboard/dashboard_screen.dart`
    - `flutter analyze lib` -> `29 issues found` (down from `40`), with async `BuildContext` warnings cleared.
  - Shifted current focus to `P2-05`.
- Progress on `P2-05`:
  - Extracted dashboard UI modules into dedicated widget files:
    - `lib/features/dashboard/widgets/risk_nudge_card.dart`
    - `lib/features/dashboard/widgets/onboarding_steps_sheet.dart`
    - `lib/features/dashboard/widgets/score_details_sheet.dart`
    - `lib/features/dashboard/widgets/net_worth_history_sheet.dart`
    - `lib/features/dashboard/widgets/due_soon_card.dart`
  - Updated `lib/features/dashboard/dashboard_screen.dart` to import and use extracted modules.
  - Size reduction:
    - `dashboard_screen.dart` reduced from ~10,792 lines to ~5,189 lines.
  - Verification:
    - `flutter analyze lib/features/dashboard/dashboard_screen.dart lib/features/dashboard/widgets/due_soon_card.dart lib/features/dashboard/widgets/net_worth_history_sheet.dart lib/features/dashboard/widgets/risk_nudge_card.dart lib/features/dashboard/widgets/onboarding_steps_sheet.dart lib/features/dashboard/widgets/score_details_sheet.dart`
    - `flutter analyze lib` remains at `29 issues found` (no regression vs prior baseline).
- Completed `P2-05`:
  - Continued extraction and cleanup:
    - `lib/features/dashboard/widgets/net_worth_history_sheet.dart`
    - `lib/features/dashboard/widgets/due_soon_card.dart`
  - Removed dead/unused dashboard and report methods after extraction.
  - Additional maintainability cleanup:
    - Removed stale unused methods/fields in:
      - `lib/data/calculators/debtload.dart`
      - `lib/features/dashboard/guardrails_detail_screen.dart`
      - `lib/features/reports/reports_screen.dart`
      - `lib/features/targets/targets_detail_screen.dart`
  - Size reduction:
    - `dashboard_screen.dart` reduced from ~10,792 lines to ~4,372 lines.
  - Verification:
    - `flutter analyze lib/features/dashboard/dashboard_screen.dart` -> no issues.
    - `flutter analyze lib` -> no issues.
  - Shifted current focus to `PR-08`.
- Progress on `PR-08`:
  - Added encrypted backup crypto service:
    - `lib/services/backup_crypto_service.dart`
    - AES-256-GCM encrypted envelope format (`wd_backup_encrypted_v1`) with PBKDF2-HMAC-SHA256 key derivation.
  - Enhanced backup/restore service:
    - `lib/services/backup_service.dart`
    - `createBackup({String? passphrase})` now supports encrypted backups.
    - Restore path auto-detects encrypted envelope and returns passphrase-required result when needed.
  - Added encrypted backup UI flows:
    - `lib/features/export/export_screen.dart`
    - New "Create Encrypted Backup" option.
    - Restore flow now prompts for passphrase when an encrypted backup is selected.
  - Dependency updates:
    - Added `cryptography` package in `pubspec.yaml`.
  - Verification:
    - `flutter analyze lib/services/backup_crypto_service.dart lib/services/backup_service.dart lib/features/export/export_screen.dart` -> no issues.
    - `flutter analyze lib` -> no issues.
- Progress on `PR-08` (polish pass):
  - Security/integrity hardening:
    - Added plaintext SHA-256 checksum to encrypted backup envelope and verify on decrypt.
    - Added explicit decrypt failure handling (`SecretBoxAuthenticationError`) with user-facing passphrase retry path.
  - UX improvements:
    - Passphrase prompt now supports show/hide visibility toggles.
    - New encrypted-backup passphrase policy for creation: minimum 12 chars with upper/lower/digit/symbol.
    - Restore flow now loops passphrase prompt when encrypted backup requires/rejects passphrase, instead of failing once.
  - Verification:
    - `flutter analyze lib/services/backup_crypto_service.dart lib/services/backup_service.dart lib/features/export/export_screen.dart` -> no issues.
    - Crypto sanity check script: roundtrip + wrong-pass + tamper handling passed (`backup_crypto_roundtrip_wrongpass_tamper_ok`).
    - Added automated test: `test/services/backup_crypto_service_test.dart`
      - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
    - `flutter analyze lib` -> no issues.
- Completed `PR-08`:
  - Localized export/backup/restore flows in:
    - `lib/features/export/export_screen.dart`
    - `lib/l10n/app_en.arb`
    - `lib/l10n/app_fr.arb`
  - Regenerated localization outputs via `flutter gen-l10n`.
  - Final encrypted restore polish now includes:
    - bounded passphrase retry handling (`maxPassphraseAttempts`)
    - localized passphrase validation and restore error messaging
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
  - Shifted current focus to `PR-01`.
- Progress on `PR-01` (first implementation slice):
  - Added persisted household profile model:
    - `lib/data/models.dart` (`HouseholdProfile`, Hive `typeId: 13`)
    - `lib/data/models.g.dart` (generated adapter)
  - Added repository support:
    - `lib/data/repositories.dart`
    - New encrypted boxes: `householdProfiles`, `householdMeta`
    - Default bootstrap: primary profile + active profile fallback
    - CRUD + switch APIs:
      - `getHouseholdProfiles`
      - `getActiveHouseholdProfileId`
      - `setActiveHouseholdProfile`
      - `addHouseholdProfile`
      - `renameHouseholdProfile`
      - `deleteHouseholdProfile`
    - Backup/restore now includes:
      - `householdProfiles`
      - `activeHouseholdProfileId`
  - Added settings UI for profile management:
    - `lib/features/targets/targets_screen.dart`
    - New "Household Profiles (Beta)" card with add/rename/delete/switch actions.
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (data partitioning slice):
  - Implemented active-profile partitioning for core financial domains in `RepositoryService`:
    - accounts
    - liabilities
    - incomes
    - expenses
  - Added encrypted ownership-mapping boxes:
    - `accountOwners`
    - `liabilityOwners`
    - `incomeOwners`
    - `expenseOwners`
  - Added ownership bootstrap for legacy users so existing records are assigned to default profile.
  - Added ownership self-healing: invalid/missing owner mappings are reassigned to a valid default profile.
  - Added backup/restore support for ownership maps:
    - `accountOwners`
    - `liabilityOwners`
    - `incomeOwners`
    - `expenseOwners`
  - Updated profile switch UX in settings card to reload domain providers immediately after switching.
  - Added delete guardrail: profiles with assigned financial data cannot be deleted.
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (data transfer utility slice):
  - Added repository-level move operation for reassigning financial data between profiles:
    - `moveFinancialDataToProfile(fromProfileId, toProfileId)`
    - Moves ownership mappings for accounts, liabilities, incomes, and expenses.
    - Returns typed move counts for user feedback.
  - Hardened profile deletion guard to check real assigned records (not just raw owner-map values).
  - Added in-app transfer UX to Household Profiles card:
    - "Move Data Between Profiles" dialog with source/target selectors.
    - Post-transfer provider reload so UI reflects moved data immediately.
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (profile counts visibility slice):
  - Added repository API for per-profile financial counts:
    - `getHouseholdProfileFinancialCounts()`
    - Includes counts for accounts, liabilities, incomes, and expenses.
  - Updated Household Profiles UI to show inline profile-level counts (`A/L/I/E`) in:
    - active profile selector
    - move-data dialog selectors
    - profile list rows
  - Improved delete UX:
    - Delete action is disabled when a profile still has assigned financial records.
    - Tooltip now explains whether deletion is blocked by minimum-profile constraint or assigned data.
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (household UX localization slice):
  - Localized newly added household-profile UI copy for EN/FR:
    - `lib/l10n/app_en.arb`
    - `lib/l10n/app_fr.arb`
    - `lib/features/targets/targets_screen.dart`
  - Regenerated l10n outputs via `flutter gen-l10n`.
  - Coverage includes:
    - add/rename/delete dialogs
    - move-data dialog labels and errors
    - profile option/count labels
    - status and tooltip copy
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (quick-consolidate slice):
  - Added repository operation to move all financial records to a target profile:
    - `moveAllFinancialDataToProfile(targetProfileId)`
  - Added Household Profiles quick action:
    - "Move All Data To Active Profile"
    - confirmation dialog with movable-record count and active profile name
  - Added EN/FR localization keys for the quick-consolidate workflow and regenerated l10n outputs.
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (quick-consolidate impact badge slice):
  - Added pre-action movable-data indicator beside quick-consolidate action:
    - "Movable from other profiles: {count}" badge/chip
    - quick-consolidate button now disables automatically when movable count is zero
  - Added EN/FR localization keys for badge copy and regenerated l10n outputs.
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (active snapshot summary slice):
  - Added active-profile snapshot block in Household Profiles card:
    - active profile name
    - active profile financial counts (`A/L/I/E`)
    - active profile net worth (computed from active-profile accounts/liabilities providers)
  - Purpose:
    - gives immediate confidence about "which profile am I viewing" and current profile financial context before running move/switch actions
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (profile financial summaries slice):
  - Added repository summary API for household profiles:
    - `getHouseholdProfileFinancialSummaries()`
    - includes per-profile counts + assets/liabilities totals + monthly income/expense totals + net worth helper
  - Updated Household Profiles card to use summary data and surface net-worth context in:
    - active profile snapshot block
    - move-data source/target selectors
    - profile list rows
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (selective transfer slice):
  - Extended move workflow to support type-selective transfers between profiles:
    - accounts
    - liabilities
    - incomes
    - expenses
  - Repository API update:
    - `moveFinancialDataToProfile(...)` now supports optional booleans (`moveAccounts`, `moveLiabilities`, `moveIncomes`, `moveExpenses`).
  - Household move dialog update:
    - added data-type checkboxes with source-profile counts
    - added validation when no data types are selected
  - Localization updates (EN/FR) for:
    - data-type section label
    - select-at-least-one-type validation message
  - Regenerated localizations via `flutter gen-l10n`.
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (household goals data-layer slice):
  - Added persisted household goal model:
    - `HouseholdGoal` (Hive `typeId: 14`)
    - fields for shared vs profile-owned goals (`isShared`, `ownerProfileId`)
  - Added repository support:
    - new encrypted box: `householdGoals`
    - APIs: `getAllHouseholdGoals`, `getHouseholdGoals`, `addHouseholdGoal`, `saveHouseholdGoal`, `deleteHouseholdGoal`
    - ownership normalization for legacy/invalid goal ownership mapping
  - Extended profile move operations to support goals:
    - selective move now supports `moveGoals`
    - move-all-to-active now includes private goals
    - `HouseholdDataMoveResult` now reports `goalsMoved`
  - Extended profile financial counts to include goal counts (`G`) and updated compact count labels accordingly.
  - Backup/restore coverage expanded to include household goals:
    - repository export/import now reads/writes `householdGoals`
    - backup service restore summary now includes household goal counts
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (household goals UI slice):
  - Added goal management UI in Household Profiles card:
    - add goal dialog (name, target amount, shared toggle, owner profile)
    - active-profile goal list (includes shared goals + profile-owned goals)
    - goal deletion flow with confirmation
  - Updated transfer dialog to include goals as a selectable data type.
  - Added EN/FR localization keys for household goal management and regenerated l10n outputs.
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (contribution splits + progress slice):
  - Extended `HouseholdGoal` model with:
    - `currentAmount` progress tracking
    - `contributionSplits` map (`profileId -> weight`) for shared goals
  - Added robust split normalization and ownership hygiene in repository defaults/migrations.
  - Added shared-goal split editor UI:
    - per-profile percentage inputs
    - normalization to 100% total on save
  - Added goal editing UI:
    - name/target/current amount/shared-owner updates
    - progress summary + progress bar in goal list
  - Updated profile deletion gating logic to avoid shared-goal false positives.
  - Updated transfer preview logic so movable totals use only movable (non-shared) goals.
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.
- Progress on `PR-01` (premium surfacing update for new feature):
  - Updated Pro screen (active + upgrade) to include:
    - "Shared Household Goals" premium feature card
    - contribution-split/progress messaging
    - navigation hook to household settings workflow
  - Added EN/FR localization for new Pro feature copy and regenerated l10n outputs.
  - Verification:
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/backup_crypto_service_test.dart` -> passed.

### 2026-04-16
- Resumed after interrupted session and reconstructed state from local git diff + tracker.
- Re-validated current codebase snapshot:
  - `flutter analyze lib` -> no issues.
  - `flutter test` -> all tests passed.
- Closed `PR-01` as `Done` based on completed implementation slices and successful validation run.
- Shifted current focus to `PR-03` (Goal planner with Monte Carlo confidence) discovery and implementation.
- Progress on `PR-03` (foundation service slice):
  - Added reusable goal planner service:
    - `lib/services/goal_planner_service.dart`
    - Supports generic goal projections with Monte Carlo confidence metrics.
    - Outputs success probability, p10/p50/p90 ending values, and required monthly contribution to reach desired confidence.
    - Added household-goal helper path via `calculateForHouseholdGoal(...)`.
  - Added deterministic unit tests:
    - `test/services/goal_planner_service_test.dart`
    - Coverage includes probability monotonicity by contribution, required-contribution targeting, and target-date validation.
  - Verification:
    - `flutter analyze lib/services/goal_planner_service.dart test/services/goal_planner_service_test.dart` -> no issues.
    - `flutter test test/services/goal_planner_service_test.dart` -> passed.
- Experience uplift (cross-cutting visual/system foundation):
  - Added premium typography dependency (`google_fonts`) and upgraded app-wide type scale with Sora (headings) + Manrope (body) in `lib/theme.dart`.
  - Refined global design language:
    - stronger card geometry and borders
    - cleaner button/input system
    - tuned nav/app-bar typography and spacing
  - Redesigned app shell navigation in `lib/routes.dart`:
    - floating glass-style bottom dock
    - radial ambient shell background
    - animated screen transitions via `AnimatedSwitcher`
  - Verification:
    - `flutter pub get` -> success.
    - `flutter analyze lib/theme.dart lib/routes.dart` -> no issues.
    - `flutter analyze lib` -> no issues.
- Experience uplift (dashboard command center implementation slice):
  - Added new dashboard command layer in:
    - `lib/features/dashboard/widgets/command_center_section.dart`
    - mounted in `lib/features/dashboard/dashboard_screen.dart`
  - New UX modules shipped:
    - Command Center hero panel with live profile metrics (net worth, monthly surplus/gap, cash runway, liability count)
    - Urgency Timeline with prioritized actionable risks (due payments, concentration risk, cash-buffer weakness, negative cashflow)
    - Scenario Playbook horizontal deck (Shock Test, Debt Blitz, Rebalance Lift, Tax Lens) with direct deep links into feature workflows
  - Verification:
    - `flutter analyze lib/features/dashboard/widgets/command_center_section.dart lib/features/dashboard/dashboard_screen.dart` -> no issues.
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/goal_planner_service_test.dart test/services/backup_crypto_service_test.dart` -> passed.
- Experience uplift (command center executable workflows slice):
  - Routed command-center scenario cards to launch execution-ready screens with prefilled context via route query params.
  - Added router query parsing and preset handoff in:
    - `lib/routes.dart`
  - Added preset application UX in destination screens:
    - `lib/features/debt/debt_optimizer_screen.dart` (prefilled extra payment + strategy from command center)
    - `lib/features/rebalancing/rebalancing_plan_screen.dart` (suggested move context + strategy/glide preselect)
    - `lib/features/scenario/scenario_engine_screen.dart` (supports `shock20` preset and applies route-provided scenario inputs)
  - Updated command-center scenario deck to open executable routes:
    - `lib/features/dashboard/widgets/command_center_section.dart`
  - Verification:
    - `flutter analyze lib/features/dashboard/widgets/command_center_section.dart lib/routes.dart lib/features/debt/debt_optimizer_screen.dart lib/features/rebalancing/rebalancing_plan_screen.dart lib/features/scenario/scenario_engine_screen.dart` -> no issues.
    - `flutter analyze lib` -> no issues.
    - `flutter test test/services/goal_planner_service_test.dart test/services/backup_crypto_service_test.dart` -> passed.

## Working Agreement For Updates
1. At session start: update `Last updated` and set one item to `In Progress`.
2. During work: append notes under the relevant item.
3. At completion: mark item `Done`, list files changed, and summarize verification run.
4. If blocked: mark `Blocked` and include the exact blocker and decision needed.

## Next Recommended Task Order
1. PR-03 (goal planner with Monte Carlo confidence) - core premium modeling value.
2. PR-02 (tax center) - high perceived Pro value with strong monetization potential.
3. PR-04 (rule-based smart automation) - multiplies value from planning outputs.
