#!/usr/bin/env python3
"""
Exemplo Prático: Análise de Dados Grandes com Cluster AI
=======================================================

Este exemplo demonstra como processar datasets grandes usando Dask DataFrames
no Cluster AI, incluindo operações de agregação, filtragem e análise estatística.

Pré-requisitos:
- Cluster AI instalado e rodando
- Arquivo CSV grande para análise (ou será gerado automaticamente)

Uso:
    python data_analysis.py [--input arquivo.csv] [--output resultados.json]
"""

import argparse
import time
import json
from pathlib import Path
import pandas as pd
import dask.dataframe as dd
from dask.distributed import Client, LocalCluster
import numpy as np


def generate_sample_data(filename: str, num_rows: int = 1000000):
    """Gera dados de exemplo para demonstração."""
    print(f"📊 Gerando {num_rows:,} linhas de dados de exemplo...")

    # Gerar dados sintéticos
    np.random.seed(42)
    data = {
        'id': range(num_rows),
        'categoria': np.random.choice(['A', 'B', 'C', 'D', 'E'], num_rows),
        'valor': np.random.normal(100, 20, num_rows),
        'quantidade': np.random.randint(1, 100, num_rows),
        'data': pd.date_range('2023-01-01', periods=num_rows, freq='1min'),
        'regiao': np.random.choice(['Norte', 'Sul', 'Leste', 'Oeste'], num_rows),
        'status': np.random.choice(['Ativo', 'Inativo', 'Pendente'], num_rows, p=[0.7, 0.2, 0.1])
    }

    df = pd.DataFrame(data)

    # Salvar como CSV
    df.to_csv(filename, index=False)
    print(f"✅ Dados salvos em {filename}")
    return df


def connect_to_cluster():
    """Conecta ao cluster Dask."""
    try:
        client = Client('tcp://localhost:8786')
        print("🔗 Conectado ao cluster Dask existente")
        print(f"👷 Workers disponíveis: {len(client.scheduler_info()['workers'])}")
        return client
    except Exception as e:
        print(f"⚠️  Cluster não encontrado, iniciando cluster local: {e}")
        cluster = LocalCluster(
            n_workers=4,
            threads_per_worker=2,
            memory_limit='2GB',
            dashboard_address=':8787'
        )
        client = Client(cluster)
        print("🏠 Cluster local iniciado")
        return client


def analyze_sales_data(df: dd.DataFrame) -> dict:
    """Realiza análise completa dos dados de vendas."""
    print("\n📈 Iniciando análise de dados...")

    results = {}

    # 1. Estatísticas básicas
    print("📊 Calculando estatísticas básicas...")
    start_time = time.time()
    stats = df.describe().compute()
    results['estatisticas_basicas'] = stats.to_dict()
    print(f"⏱️ Tempo gasto: {time.time() - start_time:.2f} segundos")
    # 2. Análise por categoria
    print("📊 Analisando por categoria...")
    category_analysis = df.groupby('categoria').agg({
        'valor': ['sum', 'mean', 'count', 'std'],
        'quantidade': ['sum', 'mean']
    }).compute()
    results['analise_categoria'] = category_analysis.to_dict()

    # 3. Análise temporal (por mês)
    print("📅 Analisando dados temporais...")
    df['mes'] = df['data'].dt.to_period('M')
    monthly_analysis = df.groupby('mes').agg({
        'valor': 'sum',
        'quantidade': 'sum'
    }).compute()
    results['analise_mensal'] = monthly_analysis.to_dict()

    # 4. Análise por região
    print("🗺️  Analisando por região...")
    region_analysis = df.groupby('regiao').agg({
        'valor': ['sum', 'mean'],
        'quantidade': 'sum'
    }).compute()
    results['analise_regiao'] = region_analysis.to_dict()

    # 5. Status dos pedidos
    print("📋 Analisando status dos pedidos...")
    status_analysis = df.groupby('status').agg({
        'valor': 'sum',
        'quantidade': 'sum',
        'id': 'count'
    }).compute()
    results['analise_status'] = status_analysis.to_dict()

    # 6. Detectar outliers
    print("🔍 Detectando outliers...")
    mean_valor = df['valor'].mean().compute()
    std_valor = df['valor'].std().compute()
    outliers = df[df['valor'] > mean_valor + 3 * std_valor].compute()
    results['outliers'] = {
        'count': len(outliers),
        'total_valor': outliers['valor'].sum(),
        'exemplos': outliers.head(5).to_dict('records')
    }

    # 7. Correlação entre variáveis
    print("🔗 Calculando correlações...")
    numeric_cols = ['valor', 'quantidade']
    correlation = df[numeric_cols].corr().compute()
    results['correlacao'] = correlation.to_dict()

    return results


def create_visualization_data(results: dict) -> dict:
    """Prepara dados para visualização."""
    viz_data = {}

    # Dados para gráfico de pizza (categorias)
    if 'analise_categoria' in results:
        cat_data = results['analise_categoria']
        if 'valor' in cat_data and 'sum' in cat_data['valor']:
            viz_data['categorias_valor'] = cat_data['valor']['sum']

    # Dados para gráfico de linha (temporal)
    if 'analise_mensal' in results:
        monthly = results['analise_mensal']
        if 'valor' in monthly and 'sum' in monthly['valor']:
            viz_data['temporal_valor'] = monthly['valor']['sum']

    # Dados para gráfico de barras (regiões)
    if 'analise_regiao' in results:
        region = results['analise_regiao']
        if 'valor' in region and 'sum' in region['valor']:
            viz_data['regioes_valor'] = region['valor']['sum']

    return viz_data


def save_results(results: dict, viz_data: dict, output_file: str):
    """Salva os resultados em arquivo JSON."""
    # Função auxiliar para converter chaves tuple em string
    def convert_keys(obj):
        if isinstance(obj, dict):
            return {str(k): convert_keys(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [convert_keys(item) for item in obj]
        else:
            return obj

    # Converter resultados para formato JSON-serializable
    results_json = convert_keys(results)
    viz_data_json = convert_keys(viz_data)

    output_data = {
        'timestamp': time.time(),
        'resumo': {
            'total_registros': results.get('estatisticas_basicas', {}).get('id', {}).get('count'),
            'valor_total': results.get('analise_categoria', {}).get('valor', {}).get('sum', {}),
            'categorias_analisadas': len(results.get('analise_categoria', {})),
            'regioes_analisadas': len(results.get('analise_regiao', {})),
            'outliers_detectados': results.get('outliers', {}).get('count', 0)
        },
        'resultados_detalhados': results_json,
        'dados_visualizacao': viz_data_json
    }

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False, default=str)

    print(f"💾 Resultados salvos em {output_file}")


def print_summary(results: dict):
    """Imprime um resumo dos resultados."""
    print("\n" + "="*60)
    print("📊 RESUMO DA ANÁLISE")
    print("="*60)

    # Estatísticas básicas
    if 'estatisticas_basicas' in results:
        stats = results['estatisticas_basicas']
        if 'valor' in stats:
            valor_stats = stats['valor']
            print("💰 Valor das vendas:")
            print(f"   • Total: R$ {valor_stats.get('sum', 0):,.2f}")
            print(f"   • Média: R$ {valor_stats.get('mean', 0):,.2f}")
            print(f"   • Mínimo: R$ {valor_stats.get('min', 0):,.2f}")
            print(f"   • Máximo: R$ {valor_stats.get('max', 0):,.2f}")

    # Análise por categoria
    if 'analise_categoria' in results:
        cat = results['analise_categoria']
        if 'valor' in cat and 'sum' in cat['valor']:
            print("\n📂 Top categorias por valor:")
            top_cats = sorted(cat['valor']['sum'].items(), key=lambda x: x[1], reverse=True)
            for cat_name, valor in top_cats[:3]:
                print(f"   • {cat_name}: R$ {valor:,.2f}")

    # Análise por região
    if 'analise_regiao' in results:
        reg = results['analise_regiao']
        if 'valor' in reg and 'sum' in reg['valor']:
            print("\n🗺️  Performance por região:")
            for reg_name, valor in reg['valor']['sum'].items():
                print(f"   • {reg_name}: R$ {valor:,.2f}")

    # Outliers
    if 'outliers' in results:
        outliers = results['outliers']
        print("\n⚠️  Outliers detectados:")
        print(f"   • Quantidade: {outliers.get('count', 0)}")
        print(f"   • Valor total: R$ {outliers.get('total_valor', 0):,.2f}")

    print("="*60)


def main():
    parser = argparse.ArgumentParser(description='Análise de Dados Grandes com Cluster AI')
    parser.add_argument('--input', '-i', default='dados_vendas.csv',
                       help='Arquivo CSV de entrada (padrão: dados_vendas.csv)')
    parser.add_argument('--output', '-o', default='resultados_analise.json',
                       help='Arquivo de saída JSON (padrão: resultados_analise.json)')
    parser.add_argument('--generate', '-g', type=int, default=100000,
                       help='Gerar dados de exemplo com N linhas (padrão: 100000)')

    args = parser.parse_args()

    print("🚀 Cluster AI - Análise de Dados Grandes")
    print("="*50)

    # Verificar se arquivo existe, senão gerar dados
    if not Path(args.input).exists():
        print(f"📁 Arquivo {args.input} não encontrado. Gerando dados de exemplo...")
        generate_sample_data(args.input, args.generate)
    else:
        print(f"📁 Usando arquivo existente: {args.input}")

    # Conectar ao cluster
    client = connect_to_cluster()

    try:
        # Carregar dados com Dask
        print("\n📥 Carregando dados...")
        df = dd.read_csv(args.input, parse_dates=['data'])
        print(f"📊 Dataset carregado: {len(df):,} linhas x {len(df.columns)} colunas")

        # Executar análise
        results = analyze_sales_data(df)

        # Preparar dados de visualização
        viz_data = create_visualization_data(results)

        # Salvar resultados
        save_results(results, viz_data, args.output)

        # Imprimir resumo
        print_summary(results)

        print("\n✅ Análise concluída com sucesso!")
        print(f"📈 Resultados salvos em: {args.output}")
        print(f"🌐 Dashboard disponível em: http://localhost:8787")

    except Exception as e:
        print(f"❌ Erro durante a análise: {e}")
        raise
    finally:
        client.close()


if __name__ == "__main__":
    main()
