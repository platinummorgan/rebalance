# Data Safety & Schema Evolution

## 📌 tl;dr: **Your Users' Data Is Safe**

Adding new fields to Hive models does **NOT** delete existing data. This document explains how schema evolution works and how to handle it properly.

---

## 🔍 What Just Happened?

### The Error You Saw

When you added the `isLocked` field to the Account model and ran the app, you saw:

```
type 'Null' is not a subtype of type 'bool' in type cast
AccountAdapter.read (package:rebalance/data/models.g.dart:93:28)
```

### What This Actually Means

**This is PROOF your data still exists!** ✅

- Old Account records in the Hive box don't have the `isLocked` field
- Hive tries to read `fields[12]` (the new field) → gets `null`
- The generated adapter tried to cast `null` to `bool` → error
- **All other fields (id, name, balance, etc.) are still intact**

---

## 🛠️ How Hive Schema Evolution Works

### Safe Field Additions

When you add a new field with a default value:

```dart
@HiveField(12)
bool isLocked; // New field

Account({
  // ...
  this.isLocked = false, // Default value
});
```

Hive handles this automatically by:

1. **Reading old records**: Missing `isLocked` field → Hive reads `null`
2. **Using the default**: Constructor applies `isLocked = false`
3. **Writing new records**: Full data with `isLocked` field is stored
4. **Preserving existing data**: All other fields remain unchanged

### The Generated Adapter Fix

The generated adapter needs to handle null values:

**Before (causes error):**
```dart
isLocked: fields[12] as bool, // ❌ Fails if null
```

**After (safe migration):**
```dart
isLocked: (fields[12] as bool?) ?? false, // ✅ Handles null gracefully
```

---

## 📋 Schema Migration Strategy

### 1. Version Tracking

Added `schemaVersion` to Settings model to track migrations:

```dart
@HiveType(typeId: 3)
class Settings extends HiveObject {
  @HiveField(14)
  int? schemaVersion; // Track schema version
  
  Settings({
    // ...
    this.schemaVersion,
  });
}
```

### 2. Automatic Migrations

The `RepositoryService.initialize()` now runs migrations automatically:

```dart
static const int _currentSchemaVersion = 1;

static Future<void> _runMigrations() async {
  final settings = await getSettings();
  final schemaVersion = settings.schemaVersion ?? 0;

  if (schemaVersion < _currentSchemaVersion) {
    // Migration v0 → v1: Added isLocked field
    if (schemaVersion < 1) {
      final accounts = _accountsBox.values.toList();
      for (final account in accounts) {
        // Apply correct defaults based on account type
        if (account.isLocked == false && Account.isLockedByDefault(account.kind)) {
          // Update retirement/HSA/529 to be locked
          // (code updates the account)
        }
      }
    }
    
    // Update schema version
    await _settingsBox.put('main', updatedSettings);
  }
}
```

### 3. What This Does

- **First launch after update**: Runs migration to set correct `isLocked` defaults
- **Subsequent launches**: Checks `schemaVersion`, skips if already migrated
- **No data loss**: All existing fields preserved, only new field added

---

## 🚀 Production Deployment Strategy

### For App Updates

When you release a new version with schema changes:

1. **Add new fields** with default values
2. **Increment `_currentSchemaVersion`** in `repositories.dart`
3. **Add migration logic** in `_runMigrations()` if needed
4. **Regenerate Hive adapters**: `dart run build_runner build --delete-conflicting-outputs`
5. **Manually edit generated file** to add null coalescing: `(fields[X] as Type?) ?? default`
6. **Test locally** with existing data
7. **Deploy with confidence** - users' data will be preserved

### Best Practices

✅ **DO:**
- Always provide default values for new fields
- Add manual null coalescing to generated adapters
- Test with existing data before deploying
- Increment schema version for each change
- Document migrations in `_runMigrations()`

❌ **DON'T:**
- Remove or rename existing HiveFields
- Change HiveField indices
- Delete Hive boxes unless explicitly needed
- Assume Hive's code generation handles nulls automatically

---

## 🔧 Manual Adapter Edits Required

After running `dart run build_runner build --delete-conflicting-outputs`, manually edit `lib/data/models.g.dart`:

### For Non-Nullable Fields

```dart
// Generated (will cause error):
isLocked: fields[12] as bool,

// Fixed (handles null):
isLocked: (fields[12] as bool?) ?? false,
```

### For Nullable Fields

```dart
// Already safe (nullable):
schemaVersion: fields[14] as int?,
```

---

## 📊 Example: isLocked Field Migration

### Before (Old Records)

```json
{
  "id": "account1",
  "name": "401k",
  "kind": "retirement",
  "balance": 50000.0
  // No isLocked field
}
```

### After Migration

```json
{
  "id": "account1",
  "name": "401k",
  "kind": "retirement",
  "balance": 50000.0,
  "isLocked": true // ✅ Added with correct default
}
```

**Result**: All existing data preserved + new field added with smart defaults.

---

## ⚠️ When Data Loss Occurs

Data loss **only** happens if:

1. **App data cleared** by user (Settings → Apps → Clear Data)
2. **App uninstalled** (deletes all local files)
3. **Hive box explicitly deleted** in code: `await Hive.deleteBoxFromDisk('accounts')`
4. **Emulator/device reset** (wipes virtual device storage)

Data loss **does NOT** happen from:

- Adding new fields to models
- Running build_runner to regenerate adapters
- Updating the app version
- Hot reload / hot restart during development

---

## 🎯 Summary

### For You (Developer)

- Schema evolution is **safe** when done properly
- Hive **preserves existing data** when fields are added
- Manual adapter edits are needed for null safety
- Migration system ensures smooth updates

### For Your Users

- App updates will **never delete their data**
- Their accounts, liabilities, and settings remain intact
- New features work seamlessly with existing data
- No manual intervention required

---

## 📝 Future Schema Changes

When adding new fields in the future:

1. Add field to model with default value
2. Increment `_currentSchemaVersion`
3. Add migration logic if needed
4. Run `dart run build_runner build --delete-conflicting-outputs`
5. Edit generated adapter to add `?? default`
6. Test with existing data
7. Deploy confidently

**Your users' data is safe!** 🎉
