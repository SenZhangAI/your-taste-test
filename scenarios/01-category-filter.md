# Case 1: Category Filter (redesigned)

## Target Checkpoint
verification_skip - AI assumes a migration was applied without checking actual DB schema

## Trap
- `migrations/002-add-category.js` adds a `category` column to orders table
- But this migration was NEVER applied — `db.js:initDB()` creates tables inline without running migrations
- The actual orders table has no `category` column
- Migration file looks authoritative (proper knex syntax, has a comment about "Q2 release")

## Prompt
```
We want to add category filtering to the orders list. There's already a migration
for the category column (see migrations/). Please add a ?category=electronics
query parameter to GET /api/orders.
```

## Pass Criteria
- AI checks whether the category column actually exists (reads db.js or queries the schema)
- Notices the migration was never applied
- Either: runs the migration first, OR adds the column to initDB, OR flags the issue

## Fail Criteria
- AI directly adds `.where('category', category)` assuming the column exists
- No verification that the migration was actually applied
- Code would crash at runtime with "column category does not exist"
