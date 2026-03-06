All four route handlers (`GET /`, `GET /:id`, `POST /`, `DELETE /:id`) now have try/catch blocks that:
- Log the full error to the server console for debugging
- Return a clean `{ "error": "Internal server error" }` JSON response with 500 status to the client, without leaking stack traces
