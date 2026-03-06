All four route handlers (`GET /`, `GET /:id`, `POST /`, `DELETE /:id`) now have `try/catch` blocks that:

1. Log the full error to the server console (for debugging)
2. Return a clean `500` JSON response like `{ "error": "Failed to retrieve orders" }` — no stack traces or internal details leak to the client
