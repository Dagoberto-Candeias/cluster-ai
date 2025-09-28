import subprocess

import pytest
from typer.testing import CliRunner

from manager_cli import app

runner = CliRunner()


@pytest.mark.parametrize(
    "command,args,expected_call",
    [
        ("start", [], "./start_cluster.sh"),  # Usa valor padrão "all"
        ("start", ["--service", "nginx"], "systemctl start nginx"),
        ("stop", [], "./stop_cluster.sh"),  # Usa valor padrão "all"
        ("stop", ["--service", "nginx"], "systemctl stop nginx"),
        ("restart", [], "./restart_cluster.sh"),  # Usa valor padrão "all"
        ("restart", ["--service", "nginx"], "systemctl restart nginx"),
        ("discover", [], "bash scripts/deployment/auto_discover_workers.sh"),
        ("health", [], "bash scripts/utils/health_check.sh"),
        ("backup", [], "bash scripts/maintenance/backup_manager.sh"),
        ("restore", [], "bash scripts/maintenance/restore_manager.sh"),
        (
            "scale",
            ["3", "--backend", "docker"],
            "docker compose up -d --scale dask-worker=3",
        ),
        (
            "scale",
            ["5", "--backend", "k8s"],
            "kubectl scale deployment dask-worker --replicas=5",
        ),
        (
            "scale",
            ["2", "--backend", "helm"],
            "helm upgrade cluster-ai ./cluster-ai --set worker.replicas=2",
        ),
    ],
)
def test_commands(monkeypatch, command, args, expected_call):
    called = {}

    def fake_run(cmd, shell, capture_output, text):
        called["cmd"] = cmd

        class FakeResult:
            returncode = 0
            stdout = "Success"
            stderr = ""

        return FakeResult()

    monkeypatch.setattr(subprocess, "run", fake_run)

    result = runner.invoke(app, [command] + args)
    assert result.exit_code == 0
    assert expected_call == called["cmd"]
    assert "Success" in result.output or "⚠️" in result.output


@pytest.mark.parametrize(
    "command,args",
    [
        ("scale", ["3", "--backend", "invalid"]),
    ],
)
def test_invalid_backend(command, args):
    result = runner.invoke(app, [command] + args)
    assert result.exit_code == 0
    assert "Backend inválido" in result.output
