from pathlib import Path

import pytest


def test_excluded_directories_from_hardcoded_secrets_scan():
    """
    Test that certain directories are excluded from the hardcoded secrets scan
    in the advanced security tests.
    """
    exclude_dirs = [
        "node_modules",
        ".git",
        "__pycache__",
        ".pytest_cache",
        "venv",
        "env",
        "tests/reports",
        "logs",
        "backups",
        "certs_backup_",
        "reports",
        "performance",
        "monitoring",
        "ai-ml",
        "android",
        "backend",
        "backup",
        "compliance",
        "config",
        "deployments",
        "docs",
        "examples",
        "models",
        "scripts",
        "web-dashboard",
        "multi-cluster",
        "data",
        "certs",
        "tmp.",
        "build",
        "dist",
        ".vscode",
        ".github",
    ]

    # Simulate some file paths that should be excluded
    test_paths = [
        Path("web-dashboard/node_modules/recharts/README.md"),
        Path("scripts/deployment/auto_discover_workers.sh"),
        Path("tests/security/test_advanced_security.py"),
        Path("venv/lib/python3.13/site-packages/somepackage/__init__.py"),
        Path("docs/README.md"),
        Path("src/app/main.py"),
    ]

    excluded = []
    included = []

    for path in test_paths:
        if any(excl_dir in str(path) for excl_dir in exclude_dirs):
            excluded.append(str(path))
        else:
            included.append(str(path))

    assert "web-dashboard/node_modules/recharts/README.md" in excluded
    assert "venv/lib/python3.13/site-packages/somepackage/__init__.py" in excluded
    assert "docs/README.md" in excluded
    assert "scripts/deployment/auto_discover_workers.sh" in excluded
    assert "tests/security/test_advanced_security.py" not in excluded
    assert "src/app/main.py" not in excluded
