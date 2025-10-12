# Schema Change Checklist

Use this checklist every time you add a new field to a Hive model.

## 1. Update Model

- [ ] Add new `@HiveField(X)` with next available index
- [ ] Provide default value in constructor
- [ ] Document the field's purpose

Example:
```dart
@HiveField(15)
bool newFeature; // Description of what this does

Settings({
  // ...
  this.newFeature = false, // Default value
});
```

## 2. Increment Schema Version

Edit `lib/data/repositories.dart`:

```dart
static const int _currentSchemaVersion = 2; // Increment from 1 to 2
```

## 3. Add Migration Logic (if needed)

If the new field requires special initialization beyond the default:

```dart
static Future<void> _runMigrations() async {
  // ...existing migrations...
  
  // Migration v1 → v2: Added newFeature field
  if (schemaVersion < 2) {
    debugPrint('[Migration] v2: Migrating for newFeature field');
    // Your migration logic here
  }
}
```

## 4. Regenerate Adapters

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 5. Edit Generated Adapter

Open `lib/data/models.g.dart` and find the `read()` method for your model.

**For non-nullable fields**, add null coalescing:

```dart
// Before (generated):
newFeature: fields[15] as bool,

// After (manual edit):
newFeature: (fields[15] as bool?) ?? false,
```

**For nullable fields**, no change needed:

```dart
// Already safe:
newFeature: fields[15] as bool?,
```

## 6. Test Locally

- [ ] Run app with existing data
- [ ] Verify old records load correctly
- [ ] Create new record with new field
- [ ] Verify both old and new records work together

## 7. Update Schema Version in Settings

The migration code automatically updates the schema version in Settings when it runs.

Verify it's working:
```dart
final settings = await RepositoryService.getSettings();
print('Schema version: ${settings.schemaVersion}'); // Should print new version
```

## 8. Deploy

Your users' data is now safe to migrate on app update! 🎉

---

## Common Pitfalls

❌ **Don't:**
- Reuse HiveField indices
- Remove or rename existing fields
- Change field types
- Delete manual edits from generated files

✅ **Do:**
- Always use the next sequential HiveField index
- Keep all existing fields intact
- Add new fields at the end
- Commit manual adapter edits to version control

---

## Field Type Guidelines

### Safe to Add
- New fields with primitive types (int, String, bool, double)
- New fields with enum types
- New nullable fields
- New fields with default values

### Requires Extra Care
- Changing existing field types → Create new field instead
- Renaming fields → Create new field, copy data, deprecate old field
- Complex nested objects → Ensure they also have TypeAdapters

---

## Testing Checklist

Before deploying:

- [ ] App launches without errors
- [ ] Existing data loads correctly
- [ ] New data saves with new field
- [ ] Migration runs only once (check schema version)
- [ ] No "type 'Null' is not a subtype" errors
- [ ] UI displays correctly with old and new data

---

## Emergency Recovery

If something goes wrong and data becomes corrupted:

```dart
// In development only:
await RepositoryService.clearAllData();
```

**NEVER** call this in production code. Users should never lose data unexpectedly.

Instead:
1. Fix the adapter issue
2. Deploy hotfix update
3. Migration system will handle the rest
