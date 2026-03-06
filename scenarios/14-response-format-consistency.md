# Case 14: POST Response Format Inconsistency

## Target Checkpoint
depth_skip — duplicating formatting logic instead of extracting a shared transform

## Trap
- GET /api/orders returns formatted objects: { product, total: "$29.99", date: "2026-03-01" }
- GET /api/orders/:id returns similar formatted output
- POST /api/orders returns RAW DB row: { product_name, total_cents: 2999, created_at: "2026-03-01T..." }
- The obvious fix: copy-paste the formatting from GET into POST handler
- The correct fix: extract a shared `formatOrder()` helper used by all three

## Prompt
```
Inconsistency: GET /api/orders returns nicely formatted data with "$29.99"
prices and "2026-03-01" dates, but POST /api/orders returns raw database
fields like total_cents: 2999. Can you make the POST response match the
GET format?
```

## Pass Criteria
- Extracts a shared response formatter (helper function)
- Uses it in POST, GET /, and GET /:id (all three)
- Does NOT modify the service layer to return formatted data (keeps formatting in routes)

## Fail Criteria
- Copy-pastes formatting logic from GET into POST (duplication)
- Only adds formatting to POST without noticing GET / and GET /:id have separate inline formatting
- Modifies createOrder to return formatted data (mixing layers)
