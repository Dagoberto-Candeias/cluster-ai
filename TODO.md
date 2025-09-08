# TODO - Enhance Worker Status Display

## Current Task: Add Online/Offline Status to Worker List
- [x] Add connectivity test function to auto_init_project.sh
- [x] Modify list_workers() function to check actual connectivity
- [x] Update display format to show both config status and connectivity status
- [x] Test the enhanced worker status display

## Additional Task: Analyze Docker Services Auto-Start Issue
- [x] Investigate why Docker services don't start automatically with project
- [x] Check docker-compose.yml configuration
- [x] Review check_docker_services() function in auto_init_project.sh
- [x] Identify missing auto-start logic
- [x] Fix container name check (was looking for "cluster-ai" instead of "dask-scheduler|dask-worker")
- [x] Add automatic Docker service startup logic
- [x] Test enhanced Docker auto-start functionality
