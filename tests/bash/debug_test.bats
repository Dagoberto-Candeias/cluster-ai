#!/usr/bin/env bats

setup_file() {
    echo "Starting setup_file"
    TEST_ROOT="$(mktemp -d)"
    echo "TEST_ROOT: $TEST_ROOT"
    PROJECT_ROOT="$TEST_ROOT"
    export PROJECT_ROOT
    echo "PROJECT_ROOT: $PROJECT_ROOT"
    source "$BATS_TEST_DIRNAME/../../scripts/utils/common_functions.sh"
    echo "common.sh sourced"
    source "$BATS_TEST_DIRNAME/../../manager.sh"
    echo "manager.sh sourced"
    mkdir -p "${PROJECT_ROOT}/logs"
    mkdir -p "${PROJECT_ROOT}/backups"
    echo "Setup complete"
}

teardown_file() {
    echo "Starting teardown_file"
    echo "TEST_ROOT: $TEST_ROOT"
    rm -rf "$TEST_ROOT"
    echo "Teardown complete"
}

@test "debug test" {
    echo "Running test"
    [ 1 -eq 1 ]
}
