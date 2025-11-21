# Complete Backup & Restore Implementation

## Overview

Implemented a complete backup and restore system to prevent data loss incidents like the user experienced when their app updated and wiped all data due to encryption key changes.

## What Was Implemented

### 1. BackupService (`lib/services/backup_service.dart`)

A new service that handles creating and restoring complete backups of all user data.

**Features:**
- Creates a single JSON file containing ALL user data:
  - Accounts (with balances and allocations)
  - Liabilities (debts)
  - Income sources
  - All settings (risk profile, currency, language, etc.)
- Exports backup with metadata (timestamp, app version)
  - Restores all data from a JSON backup file
- Shares backup file via email, Google Drive, or other apps

**Key Methods:**
- `createBackup()` - Exports all data to timestamped JSON file
- `shareBackup(File)` - Allows sharing the backup file
- `restoreFromFile()` - Picks a backup file and restores all data
- `restoreFromFilePath(String)` - Restores from specific file path

**Safety Features:**
- Validates backup version before restore
- Clears all existing data before restore (prevents merge conflicts)
- Detailed debug logging for troubleshooting
- Error handling with user-friendly messages
- Returns `RestoreResult` with success/failure details

### 2. Updated Export Screen (`lib/features/export/export_screen.dart`)

Enhanced the existing Import & Export screen to include backup/restore functionality.

**Added UI Elements:**
- "Create Complete Backup" button - Creates and shares full backup
- "Restore from Backup" button - Restores data from backup file

**User Flow:**

**Creating a Backup:**
1. User taps "Create Complete Backup"
2. Loading dialog shows progress
3. Backup file created (e.g., `wealth_dial_backup_2024-11-20T15-30-00.json`)
4. Share dialog appears - user can save to Google Drive, email, etc.
5. Success message confirms backup created

**Restoring from Backup:**
1. User taps "Restore from Backup"
2. Warning dialog explains ALL current data will be replaced
3. User confirms (or cancels)
4. File picker opens to select backup file
5. Loading dialog shows progress
6. Data restored successfully
7. Summary dialog shows what was restored

**Safety Warnings:**
- Restore requires explicit confirmation
- Clear warning that current data will be deleted
- Suggests creating backup of current data first

## Data Preservation Fix

### Critical Bug Fixed (`lib/data/repositories.dart`)

**Problem:**
When encryption key changed (after OS updates or reinstalls), the app automatically deleted ALL user data:
```dart
if (encryptionError) {
  await Hive.deleteBoxFromDisk('accounts'); // DELETED EVERYTHING
  await Hive.deleteBoxFromDisk('liabilities');
  await Hive.deleteBoxFromDisk('incomes');
  // ... etc
}
```

**Solution:**
Changed to preserve data on disk and throw error instead:
```dart
if (encryptionError) {
  throw Exception(
    'Unable to access your financial data due to encryption key changes. '
    'Your data is still stored safely. DO NOT uninstall the app.'
  );
}
```

**Impact:**
- Data remains on disk even when encryption fails
- User can create backup before troubleshooting
- Support can help recover data instead of it being lost forever

## File Format

### Backup JSON Structure

```json
{
  "version": "1.0",
  "timestamp": "2024-11-20T15:30:00.000Z",
  "appVersion": "1.0.11",
  "accounts": [
    {
      "id": "account_123",
      "name": "Checking Account",
      "kind": "cash",
      "balance": 5000.0,
      "pctCash": 100.0,
      "pctBonds": 0.0,
      // ... etc
    }
  ],
  "liabilities": [
    {
      "id": "liability_456",
      "name": "Credit Card",
      "kind": "credit",
      "balance": 2500.0,
      "apr": 18.5,
      // ... etc
    }
  ],
  "incomes": [
    {
      "id": "income_789",
      "name": "Main Job Salary",
      "kind": "Salary",
      "grossAmount": 8500.0,
      // ... etc
    }
  ],
  "settings": {
    "riskBand": "RiskBand.balanced",
    "monthlyEssentials": 3000.0,
    "currency": "USD",
    "language": "en",
    "isPro": true,
    // ... etc
  }
}
```

## Testing Checklist

- [ ] Create backup with sample data
- [ ] Verify backup file can be shared via email
- [ ] Verify backup file can be saved to Google Drive
- [ ] Restore from backup successfully imports all data
- [ ] Warning dialog appears before restore
- [ ] Cancel button in warning dialog works
- [ ] Error handling works for invalid backup files
- [ ] Error handling works for corrupted JSON
- [ ] Backup includes all settings (currency, language, etc.)
- [ ] Restore preserves all settings correctly

## User Documentation

### How to Create a Backup

1. Go to Settings (gear icon)
2. Tap "Import & Export"
3. Tap "Create Complete Backup"
4. Wait for backup to be created
5. Choose where to save the backup:
   - Email it to yourself
   - Save to Google Drive
   - Save to another cloud storage service
6. **Important:** Store the backup file in a safe location!

### How to Restore from Backup

1. Go to Settings → Import & Export
2. Tap "Restore from Backup"
3. **Read the warning carefully** - this will replace ALL your current data
4. Tap "Restore" to confirm
5. Select your backup file
6. Wait for restore to complete
7. Review the summary of what was restored

### Best Practices

- Create backups regularly (weekly recommended)
- Store backups in multiple locations (email + cloud storage)
- Create a backup before:
  - App updates
  - Phone upgrades
  - Changing devices
- Test your backups periodically to ensure they work

## Technical Notes

### Why Not Use CSV Import?

The existing CSV import is designed for **bulk data entry** (manually entering accounts/liabilities/income), not disaster recovery:
- Requires 3 separate files (accounts.csv, liabilities.csv, income.csv)
- Doesn't include settings (currency, language, risk profile, etc.)
- Doesn't preserve account allocations precisely
- Manual process, not one-tap restore

### Why JSON Format?

- Human-readable for debugging
- Preserves exact data types (doubles, booleans, dates)
- Includes all settings and metadata
- Easy to extend in future versions
- Single file for complete restore

### Dependencies

Existing packages (no new dependencies needed):
- `path_provider` - Get documents directory
- `share_plus` - Share backup files
- `file_picker` - Pick restore file

## Future Enhancements

Potential improvements for v1.1:
- [ ] Auto-backup reminders (weekly prompt)
- [ ] Cloud backup integration (Google Drive, iCloud)
- [ ] Backup encryption with passphrase
- [ ] Incremental backups (save only changes)
- [ ] Backup history management
- [ ] Auto-backup before app updates
- [ ] Backup verification (check integrity)

## Related Issues

- **Data Loss Bug**: User's data wiped after app update (encryption key mismatch)
- **Prevention**: Removed automatic data deletion on encryption errors
- **Recovery**: New backup/restore system provides disaster recovery option

## Files Changed

1. **Created:**
   - `lib/services/backup_service.dart` (408 lines)
   - `BACKUP_RESTORE_IMPLEMENTATION.md` (this file)

2. **Modified:**
   - `lib/features/export/export_screen.dart` - Added backup/restore UI
   - `lib/data/repositories.dart` - Fixed data deletion bug (lines 204-218)

## Deployment Notes

Before releasing to production:
1. Test backup creation with real user data
2. Test restore on clean install
3. Verify all settings are preserved
4. Add backup reminder notification system
5. Update app documentation
6. Add in-app tutorial for backup/restore

## Support Guidance

If user reports data loss:
1. Check if they have a backup file
2. If no backup, check if data still exists on disk (encryption error)
3. Guide them to Settings → Import & Export → Restore from Backup
4. If no backup exists, data may be unrecoverable

Prevention:
- Encourage users to create backups regularly
- Add reminder notifications for backup creation
- Consider auto-backup before updates
