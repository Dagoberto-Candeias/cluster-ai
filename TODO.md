# Cluster AI Manager Refactoring Plan

## Overview
Refactor the main `manager.sh` script to use the new modular core scripts instead of duplicated functions.

## Current State Analysis
- `manager.sh` is ~2000+ lines with many duplicated functions
- Core modules (`security.sh`, `services.sh`, `workers.sh`, `ui.sh`) provide comprehensive functionality
- Many functions in `manager.sh` are already implemented in the core modules

## Refactoring Plan

### Phase 1: Source Core Modules
- [ ] Replace `source "${SCRIPT_DIR}/scripts/utils/common.sh"` with core module sources
- [ ] Add sourcing for all core modules: `security.sh`, `services.sh`, `workers.sh`, `ui.sh`
- [ ] Ensure proper initialization order

### Phase 2: Remove Duplicated Functions
- [ ] Remove `log()` function (use from common.sh)
- [ ] Remove `confirm_operation()` (use from security.sh)
- [ ] Remove `audit_log()` (use from security.sh)
- [ ] Remove `validate_input()` (use from security.sh)
- [ ] Remove `check_user_authorization()` (use from security.sh)
- [ ] Remove `confirm_critical_operation()` (use from security.sh)

### Phase 3: Replace Service Management Functions
- [ ] Replace `manage_systemd_service()` with `manage_systemd_service()` from services.sh
- [ ] Replace `manage_docker_container()` with `manage_docker_container()` from services.sh
- [ ] Replace `start_process()` with `start_background_process()` from services.sh
- [ ] Replace `stop_process_by_pid()` with `stop_background_process()` from services.sh

### Phase 4: Replace Worker Management Functions
- [ ] Replace `check_all_workers_status()` with `check_all_workers_status()` from workers.sh
- [ ] Replace `test_worker_connection_interactive()` with `test_worker_connectivity()` from workers.sh
- [ ] Replace `manage_remote_workers()` with functions from workers.sh
- [ ] Replace `manage_auto_registered_workers()` with functions from workers.sh

### Phase 5: Replace UI Functions
- [ ] Replace menu display functions with functions from ui.sh
- [ ] Replace `show_banner()` with `ui_header()` from ui.sh
- [ ] Replace `section()`, `subsection()` with functions from ui.sh
- [ ] Replace `success()`, `error()`, `warn()`, `info()` with `ui_status()` from ui.sh

### Phase 6: Update Main Menu Structure
- [ ] Replace main menu with `main_menu()` from ui.sh
- [ ] Update menu navigation to use core module functions
- [ ] Ensure all menu options call appropriate core functions

### Phase 7: Update Command Line Arguments
- [ ] Ensure all CLI commands still work with refactored functions
- [ ] Update function calls to use core module functions
- [ ] Test all command line options

### Phase 8: Update Configuration and File Paths
- [ ] Ensure all file paths work with new structure
- [ ] Update any hardcoded paths to use variables from core modules
- [ ] Verify configuration file handling

### Phase 9: Testing and Validation
- [ ] Test all menu options
- [ ] Test all command line arguments
- [ ] Verify audit logging works correctly
- [ ] Test error handling and user authorization
- [ ] Validate all service management operations
- [ ] Test worker management functionality

### Phase 10: Documentation Update
- [ ] Update any inline documentation
- [ ] Ensure function comments are consistent
- [ ] Update help text if needed

## Dependencies
- All core modules must be properly sourced
- Core modules must be initialized before use
- Common.sh must be sourced first (dependency for other modules)

## Risk Assessment
- **High Risk**: Breaking existing functionality during refactoring
- **Medium Risk**: Command line interface changes
- **Low Risk**: UI improvements and function consolidation

## Testing Strategy
1. Test each phase individually
2. Verify all menu options work
3. Test all CLI commands
4. Validate error handling
5. Test with different user permissions
6. Verify audit logging

## Rollback Plan
- Keep backup of original manager.sh
- Test thoroughly before deployment
- Have ability to revert to original if issues arise

## Success Criteria
- All existing functionality preserved
- Code is more maintainable and modular
- No breaking changes to user interface
- Improved error handling and logging
- Better separation of concerns
