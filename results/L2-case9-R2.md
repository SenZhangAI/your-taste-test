The fix: added a cleanup interval that runs every 60 seconds and removes IPs whose most recent hit is older than the 1-minute rate limit window. This is a cheap check — it only looks at the last timestamp in each array (since they're in chronological order), so stale IPs get evicted without iterating every timestamp.

**Root cause**: The `hits` Map accumulated an entry for every unique IP that ever made a request, and never removed them. The per-request `filter()` only pruned old timestamps within an existing entry — it didn't delete the Map key when an IP went cold.
