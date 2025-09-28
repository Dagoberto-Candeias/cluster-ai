#!/usr/bin/env python3
"""
Executor Principal de Testes - Cluster AI

Este script executa todos os testes da suíte de testes do Cluster AI
de forma organizada e com relatórios detalhados.
"""

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

# Configurações
PROJECT_ROOT = Path(__file__).parent.parent
TESTS_DIR = PROJECT_ROOT / "tests"
REPORTS_DIR = TESTS_DIR / "reports"


# Cores para output
class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN = "\033[96m"
    BOLD = "\033[1m"
    END = "\033[0m"


def print_header(text):
    """Imprime um cabeçalho formatado"""
    print(f"\n{Colors.CYAN}{'='*60}{Colors.END}")
    print(f"{Colors.CYAN}{Colors.BOLD}{text.center(60)}{Colors.END}")
    print(f"{Colors.CYAN}{'='*60}{Colors.END}\n")


def print_section(text):
    """Imprime uma seção formatada"""
    print(f"\n{Colors.BLUE}{Colors.BOLD}▶ {text}{Colors.END}")
    print(f"{Colors.BLUE}{'-'*50}{Colors.END}")


def print_success(text):
    """Imprime mensagem de sucesso"""
    print(f"{Colors.GREEN}✅ {text}{Colors.END}")


def print_error(text):
    """Imprime mensagem de erro"""
    print(f"{Colors.RED}❌ {text}{Colors.END}")


def print_warning(text):
    """Imprime mensagem de aviso"""
    print(f"{Colors.YELLOW}⚠️  {text}{Colors.END}")


def print_info(text):
    """Imprime mensagem informativa"""
    print(f"{Colors.BLUE}ℹ️  {text}{Colors.END}")


def run_command(cmd, description, cwd=None, env=None):
    """Executa um comando e retorna o resultado"""
    print_info(f"Executando: {description}")

    start_time = time.time()
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            cwd=cwd or PROJECT_ROOT,
            env=env,
            capture_output=True,
            text=True,
            timeout=300,  # 5 minutos timeout
        )
        end_time = time.time()
        duration = end_time - start_time

        if result.returncode == 0:
            print_success(f"Sucesso em {duration:.2f} segundos")
            return True, duration
        else:
            print_error(f"Falhou em {duration:.2f} segundos")
            if result.stdout:
                print(f"STDOUT:\n{result.stdout}")
            if result.stderr:
                print(f"STDERR:\n{result.stderr}")
            return False, duration

    except subprocess.TimeoutExpired:
        print_error(f"Timeout após 5 minutos: {description}")
        return False, 300
    except Exception as e:
        print_error(f"Erro ao executar {description}: {e}")
        return False, 0


def create_reports_dir():
    """Cria diretório de relatórios"""
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    return REPORTS_DIR


def build_pytest_command(args, test_path, html_report_name):
    """Constrói o comando base do pytest com opções comuns."""
    cmd = ["python", "-m", "pytest", test_path]

    # Adiciona o arquivo de configuração se especificado
    if args.env and args.env != "dev":
        config_file = f"pytest.{args.env}.ini"
        if (PROJECT_ROOT / config_file).exists():
            cmd.extend(["-c", config_file])
            print_info(f"Usando configuração: {config_file}")

    # Adiciona o relatório HTML
    cmd.append(f"--html=tests/reports/{html_report_name}")

    if args.fail_fast:
        cmd.append("--exitfirst")

    if args.parallel:
        cmd.extend(["-n", "auto"])

    if args.last_failed:
        cmd.append("--last-failed")

    return cmd


def run_pytest_suite(args, test_type, description, test_path):
    """Executa uma suíte de testes pytest genérica, encapsulando a lógica comum."""
    print_section(description)
    html_report_name = f"{test_type}_tests.html"
    cmd = build_pytest_command(args, test_path, html_report_name)
    success, duration = run_command(" ".join(cmd), f"Testes de {test_type}")
    return success, duration, test_type


def run_unit_tests(args):
    """Executa testes unitários"""
    return run_pytest_suite(args, "unit", "TESTES UNITÁRIOS", "tests/unit/")


def run_integration_tests(args):
    """Executa testes de integração"""
    return run_pytest_suite(
        args, "integration", "TESTES DE INTEGRAÇÃO", "tests/integration/"
    )


def run_e2e_tests(args):
    """Executa testes end-to-end"""
    return run_pytest_suite(args, "e2e", "TESTES END-TO-END", "tests/e2e/")


def run_performance_tests(args):
    """Executa testes de performance"""
    return run_pytest_suite(
        args, "performance", "TESTES DE PERFORMANCE", "tests/performance/"
    )


def run_security_tests(args):
    """Executa testes de segurança"""
    return run_pytest_suite(args, "security", "TESTES DE SEGURANÇA", "tests/security/")


def run_smoke_tests(args):
    """Executa testes de fumaça (smoke tests)"""
    return run_pytest_suite(
        args, "smoke", "TESTES DE FUMAÇA (SMOKE TESTS)", "tests/smoke/"
    )


def run_bash_tests(args):
    """Executa testes de scripts Bash"""
    print_section("TESTES DE SCRIPTS BASH")

    # Verificar se BATS está instalado
    try:
        subprocess.run(["bats", "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print_warning("BATS não encontrado. Instalando...")
        run_command(
            "sudo apt-get update && sudo apt-get install -y bats", "Instalação do BATS"
        )

    success, duration = run_command(
        "bats tests/bash/", "Testes de scripts Bash com BATS"
    )

    return success, duration, "bash"


def run_linting():
    """Executa verificação de código"""
    print_section("VERIFICAÇÃO DE CÓDIGO")

    checks = [
        (
            "python -m flake8 . --count --show-source --statistics",
            "Erros críticos de sintaxe",
        ),
        (
            "python -m flake8 . --count --exit-zero --statistics",
            "Verificação de estilo",
        ),
        ("python -m black --check --diff .", "Formatação de código"),
    ]

    all_success = True
    total_duration = 0

    for cmd, description in checks:
        success, duration = run_command(cmd, description)
        if not success:
            all_success = False
        total_duration += duration

    return all_success, total_duration, "linting"


def run_coverage_analysis():
    """Executa análise de cobertura"""
    print_section("ANÁLISE DE COBERTURA")

    # Gera o relatório combinado em HTML e XML a partir dos dados acumulados
    cmd = (
        "python -m coverage html -d tests/reports/coverage_combined && "
        "python -m coverage xml -o tests/reports/coverage_combined.xml && "
        "python -m coverage report --fail-under=80"
    )
    success, duration = run_command(cmd, "Relatório de cobertura de código")

    return success, duration, "coverage"


def generate_summary_report(results, total_time):
    """Gera relatório de resumo"""
    print_header("RELATÓRIO DE TESTES - CLUSTER AI")

    # Estatísticas gerais
    total_tests = len(results)
    passed_tests = sum(1 for r in results if r["success"])
    failed_tests = total_tests - passed_tests

    print(f"📊 Total de suítes executadas: {total_tests}")
    print(f"⏱️  Tempo total: {total_time:.2f} segundos")
    if total_tests > 0:
        print(f"📈 Média por suíte: {total_time/total_tests:.2f} segundos")
    print()

    # Status das suítes
    print("📋 STATUS DAS SUÍTES:")
    for result in results:
        status = "✅ PASSOU" if result["success"] else "❌ FALHOU"
        color = Colors.GREEN if result["success"] else Colors.RED
        print(
            f"{color}{result['type'].upper()}: {status} ({result['duration']:.2f}s){Colors.END}"
        )
    print()

    # Cobertura (se disponível)
    coverage_file = REPORTS_DIR / "coverage_combined.xml"
    if coverage_file.exists():
        try:
            import xml.etree.ElementTree as ET

            tree = ET.parse(coverage_file)
            root = tree.getroot()
            coverage = float(root.get("line-rate", 0))
            if coverage:
                coverage_pct = coverage * 100
                print(f"📊 Cobertura de código: {coverage_pct:.1f}%")
                if coverage_pct >= 80:
                    print_success("Cobertura atende ao requisito mínimo (80%)")
                else:
                    print_error(
                        f"Cobertura de {coverage_pct:.1f}% abaixo do mínimo requerido (80%)"
                    )
        except Exception as e:
            print_warning(f"Não foi possível ler cobertura: {e}")

    # Resultado final
    print_header("RESULTADO FINAL")
    if failed_tests == 0:
        print_success("🎉 TODOS OS TESTES PASSARAM!")
        print_success("A suíte de testes está funcionando corretamente.")
    else:
        print_error(f"❌ {failed_tests} suíte(s) falharam de {total_tests} executadas")
        print_warning("Verifique os logs detalhados para mais informações.")

    # Salvar relatório em JSON
    report_data = {
        "timestamp": datetime.now().isoformat(),
        "total_suites": total_tests,
        "passed_suites": passed_tests,
        "failed_suites": failed_tests,
        "total_time": total_time,
        "results": results,
    }

    report_file = (
        REPORTS_DIR / f"test_summary_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    )
    with open(report_file, "w", encoding="utf-8") as f:
        json.dump(report_data, f, indent=2, ensure_ascii=False)

    print_info(f"Relatório salvo em: {report_file}")


def main():
    """Função principal"""
    parser = argparse.ArgumentParser(description="Executor de Testes - Cluster AI")
    parser.add_argument(
        "--unit", action="store_true", help="Executar apenas testes unitários"
    )
    parser.add_argument(
        "--integration",
        action="store_true",
        help="Executar apenas testes de integração",
    )
    parser.add_argument(
        "--e2e", action="store_true", help="Executar apenas testes end-to-end"
    )
    parser.add_argument(
        "--performance",
        action="store_true",
        help="Executar apenas testes de performance",
    )
    parser.add_argument(
        "--security", action="store_true", help="Executar apenas testes de segurança"
    )
    parser.add_argument(
        "--smoke",
        action="store_true",
        help="Executar apenas testes de fumaça (smoke tests)",
    )
    parser.add_argument(
        "--bash", action="store_true", help="Executar apenas testes Bash"
    )
    parser.add_argument(
        "--lint", action="store_true", help="Executar apenas verificação de código"
    )
    parser.add_argument(
        "--coverage", action="store_true", help="Executar apenas análise de cobertura"
    )
    parser.add_argument(
        "--fail-fast", action="store_true", help="Parar na primeira falha"
    )
    parser.add_argument(
        "--parallel", action="store_true", help="Executar testes em paralelo"
    )
    parser.add_argument(
        "--env",
        choices=["dev", "ci"],
        default="dev",
        help="Especificar o ambiente para usar a configuração pytest correta (dev ou ci)",
    )
    parser.add_argument(
        "--last-failed",
        "--lf",
        action="store_true",
        help="Executar apenas os testes que falharam na última execução",
    )
    parser.add_argument(
        "--no-lint", action="store_true", help="Pular verificação de código"
    )
    parser.add_argument(
        "--no-coverage", action="store_true", help="Pular análise de cobertura"
    )

    args = parser.parse_args()

    # Verificar se pelo menos um tipo de teste foi especificado
    test_types = [
        args.unit,
        args.integration,
        args.e2e,
        args.performance,
        args.security,
        args.smoke,
        args.bash,
        args.lint,
        args.coverage,
    ]
    if not any(test_types) and not args.no_lint and not args.no_coverage:
        # Executar todos os testes por padrão
        args.unit = args.integration = args.e2e = args.performance = args.security = (
            args.smoke
        ) = args.bash = True
        if not args.no_lint:
            args.lint = True
        if not args.no_coverage:
            args.coverage = True

    # Criar diretório de relatórios
    create_reports_dir()

    # Banner
    print_header("🚀 EXECUTOR DE TESTES - CLUSTER AI")
    print_info(f"Diretório do projeto: {PROJECT_ROOT}")
    print_info(f"Diretório de relatórios: {REPORTS_DIR}")
    print_info(f"Data/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # Executar testes
    results = []
    total_start_time = time.time()

    try:
        if args.unit:
            success, duration, test_type = run_unit_tests(args)
            results.append(
                {"type": test_type, "success": success, "duration": duration}
            )

        if args.integration:
            success, duration, test_type = run_integration_tests(args)
            results.append(
                {"type": test_type, "success": success, "duration": duration}
            )

        if args.e2e:
            success, duration, test_type = run_e2e_tests(args)
            results.append(
                {"type": test_type, "success": success, "duration": duration}
            )

        if args.performance:
            success, duration, test_type = run_performance_tests(args)
            results.append(
                {"type": test_type, "success": success, "duration": duration}
            )

        if args.security:
            success, duration, test_type = run_security_tests(args)
            results.append(
                {"type": test_type, "success": success, "duration": duration}
            )

        if args.smoke:
            success, duration, test_type = run_smoke_tests(args)
            results.append(
                {"type": test_type, "success": success, "duration": duration}
            )

        if args.bash:
            success, duration, test_type = run_bash_tests(args)
            results.append(
                {"type": test_type, "success": success, "duration": duration}
            )

        if args.lint:
            success, duration, test_type = run_linting()
            results.append(
                {"type": test_type, "success": success, "duration": duration}
            )

        if args.coverage:
            success, duration, test_type = run_coverage_analysis()
            results.append(
                {"type": test_type, "success": success, "duration": duration}
            )

    except KeyboardInterrupt:
        print_error("\nExecução interrompida pelo usuário")
        sys.exit(1)
    except Exception as e:
        print_error(f"\nErro durante execução: {e}")
        sys.exit(1)

    # Calcular tempo total
    total_time = time.time() - total_start_time

    # Gerar relatório final
    generate_summary_report(results, total_time)

    # Código de saída
    failed_tests = sum(1 for r in results if not r["success"])
    sys.exit(0 if failed_tests == 0 else 1)


if __name__ == "__main__":
    main()
