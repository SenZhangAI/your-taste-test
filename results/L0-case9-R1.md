The fix adds a cleanup interval that runs every 60 seconds and:

- **Removes IPs** whose timestamps have all expired (no requests in the last minute)
- **Prunes stale timestamps** from active IPs
- Uses `.unref()` so the timer doesn't prevent the process from exiting gracefully

Without this, every unique IP that ever hit the server left a permanent entry in the `hits` Map, causing the steady memory growth you observed.
