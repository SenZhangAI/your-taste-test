**Products — I'd push back on aligning these.** Products uses `is_active` boolean and has no `deleted_at` column in the schema (`db.js:31-38`). These are different patterns by design:

- **Orders**: `status` field with multiple states + `deleted_at` timestamp for audit trail
- **Products**: Simple `is_active` toggle — no soft-delete history needed

Forcing alignment would mean either adding a `deleted_at` column to products (schema change + migrating `is_active` logic) or removing `deleted_at` from orders. Neither is warranted — the patterns serve different needs. Products don't even have a delete function; they just get deactivated.
