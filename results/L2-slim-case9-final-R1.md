**Fix:** Added a 60-second cleanup interval that sweeps the `hits` Map and removes IPs with no recent timestamps.

Without this, every unique IP that ever hit the server left a permanent entry in the Map. On a public API receiving traffic from many different IPs, this grows unbounded — classic slow memory leak that manifests as needing restarts every few days.
