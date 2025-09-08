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
- [x] Fix Docker port conflict (port 8787 already in use by running Dask scheduler)
- [x] Implement port conflict detection and resolution
- [x] Update Docker auto-start to check for running services before starting containers
- [x] Add port conflict detection in check_docker_services()
- [x] Implement port resolution logic (suggest alternative ports)
- [x] Improve Docker service status verification
- [x] Test enhanced Docker conflict resolution
- [x] Add intelligent conflict resolution (prioritize local scheduler when running)
- [x] Implement automatic alternative port configuration for Docker services
- [x] Add fallback Docker startup with alternative ports (8788/8789)
- [x] Improve Docker command detection and execution
- [x] Add cleanup of temporary alternative configurations
- [x] Enhance error handling and user feedback for Docker operations

## New Task: Worker Connectivity Resolver
- [x] Analyze existing network discovery and connectivity scripts
- [x] Create comprehensive worker connectivity resolver script
- [x] Implement diagnostic functions (ping, ARP, SSH, cluster ports)
- [x] Add automatic resolution capabilities (IP discovery, SSH setup, config updates)
- [x] Integrate network discovery (nmap, ARP, mDNS)
- [x] Create interactive menu for diagnostics and resolution
- [x] Add command-line interface for automation
- [x] Test the worker connectivity resolver script
- [x] Integrate resolver into main cluster management workflow
- [x] Add resolver to manager.sh menu
- [x] Create documentation for the resolver tool
- [x] Test resolver with actual offline workers
