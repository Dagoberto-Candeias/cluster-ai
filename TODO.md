# TODO: Fix Dask Scheduler Connection Issues

## Issues Identified
- IPv4/IPv6 mismatch: Scheduler bound to IPv4 (192.168.0.6:8786), but connections from IPv6 localhost ([::1])
- Missing jupyter-server-proxy for workers diagnostics routing
- cluster.conf has incorrect ports (8788/8789) vs actual usage (8786/8787)

## Tasks
- [x] Update cluster.conf with correct ports (8786/8787)
- [x] Install jupyter-server-proxy
- [x] Update scheduler start scripts to bind to all interfaces (::)
- [x] Restart Dask scheduler with new configuration
- [x] Test connections and verify fixes

## Additional Fixes Completed
- [x] Fixed IPv6 binding in scripts/management/manager.sh and scripts/auto_init_project.sh
- [x] Fixed worker configuration sync script (scripts/utils/sync_config.sh)
- [x] Verified cluster services are running and accessible
- [x] Tested Dask client connection successfully
