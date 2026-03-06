The fix adds a cleanup interval that runs every 60 seconds and removes IPs from the `hits` Map whose timestamps have all expired (older than the 1-minute window). This prevents the Map from growing unboundedly.

**Root cause:** Every unique IP that ever hit the server got a permanent entry in the Map. The per-request filter only pruned old timestamps within an existing array but never deleted the IP key itself. Over days of traffic from many different IPs, this Map grew without bound.
