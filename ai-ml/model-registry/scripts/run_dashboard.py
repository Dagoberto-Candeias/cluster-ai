#!/usr/bin/env python3
"""
Script para executar o Dashboard Web do Model Registry
Cluster AI - Sistema de Gerenciamento de Modelos
"""

import os
import sys
import subprocess
from pathlib import Path

def check_dependencies():
    """Verificar se as dependências estão instaladas."""
    try:
        import flask
        print("✅ Flask está instalado")
    except ImportError:
        print("❌ Flask não está instalado. Instalando...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "flask"])
        print("✅ Flask instalado com sucesso")

def main():
    """Função principal para executar o dashboard."""
    print("🚀 Cluster AI - Model Registry Dashboard")
    print("=" * 50)

    # Verificar dependências
    check_dependencies()

    # Caminho para o app do dashboard
    dashboard_app = Path(__file__).parent.parent / "dashboard" / "app.py"

    if not dashboard_app.exists():
        print(f"❌ Arquivo do dashboard não encontrado: {dashboard_app}")
        sys.exit(1)

    print(f"📁 Dashboard localizado em: {dashboard_app}")
    print("🌐 Iniciando servidor web...")
    print("📱 Acesse: http://localhost:5000")
    print("❌ Para parar: Ctrl+C")
    print("-" * 50)

    try:
        # Executar o dashboard
        os.chdir(dashboard_app.parent)
        subprocess.run([sys.executable, str(dashboard_app)], check=True)
    except KeyboardInterrupt:
        print("\n👋 Dashboard parado pelo usuário")
    except subprocess.CalledProcessError as e:
        print(f"❌ Erro ao executar dashboard: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Erro inesperado: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
