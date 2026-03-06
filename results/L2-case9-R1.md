**Fix:** Added a cleanup interval that runs every 60 seconds, evicting IPs with no hits in the current window. This bounds the Map's size to only IPs active in the last minute, instead of every IP that ever hit the server.

The leak pattern: each unique IP added an entry that was never deleted. With enough unique clients over days, this grows without bound. The per-request `filter` only shrinks the array for *that specific IP* — it never removes the Map key itself.
