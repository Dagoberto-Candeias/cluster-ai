#!/usr/bin/env python3
"""
Dashboard Web para Model Registry - Cluster AI
Interface gráfica para gerenciamento de modelos de ML
"""

from flask import Flask, render_template, request, jsonify, flash, redirect, url_for
from flask_wtf.csrf import CSRFProtect
import os
import sys
from pathlib import Path
import json
from datetime import datetime

# Adicionar caminho do projeto para importar ModelRegistry
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from model_registry import ModelRegistry

app = Flask(__name__, template_folder=os.path.join(os.path.dirname(__file__), 'templates'))
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')

# Inicializar CSRF protection
csrf = CSRFProtect()
csrf.init_app(app)

# Inicializar Model Registry
registry = ModelRegistry()

@app.route('/')
def index():
    """Página principal do dashboard."""
    try:
        models = registry.list_models()
        # Como get_statistics não existe, criar estatísticas básicas
        stats = {
            'total_models': len(models),
            'frameworks': list(set(m['framework'] for m in models)) if models else [],
            'total_size': sum(m.get('size', 0) for m in models) if models else 0,
            'last_updated': max(m.get('created_at', '') for m in models) if models else None
        }
        return render_template('index.html', models=models, stats=stats)
    except Exception as e:
        flash(f'Erro ao carregar modelos: {str(e)}', 'error')
        return render_template('index.html', models=[], stats={})

@app.route('/models')
def models():
    """Página de listagem de modelos."""
    try:
        models = registry.list_models()
        # Corrigir para garantir que size e outros campos existam
        for m in models:
            if not isinstance(m, dict):
                continue
            if 'size' not in m:
                m['size'] = 0
            if 'created_at' not in m:
                m['created_at'] = ''
        return render_template('models.html', models=models)
    except Exception as e:
        flash(f'Erro ao carregar modelos: {str(e)}', 'error')
        return render_template('models.html', models=[])

@app.route('/model/<name>')
def model_detail(name):
    """Página de detalhes do modelo."""
    try:
        info = registry.get_model_info(name)
        if info:
            return render_template('model_detail.html', model=info)
        else:
            flash(f'Modelo "{name}" não encontrado', 'error')
            return redirect(url_for('models'))
    except Exception as e:
        flash(f'Erro ao carregar detalhes do modelo: {str(e)}', 'error')
        return redirect(url_for('models'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    """Página de registro de modelo."""
    if request.method == 'POST':
        try:
            model_path = request.form.get('model_path')
            name = request.form.get('name')
            framework = request.form.get('framework')
            version = request.form.get('version', '1.0.0')
            description = request.form.get('description', '')

            if not all([model_path, name, framework]):
                flash('Campos obrigatórios: caminho do modelo, nome e framework', 'error')
                return redirect(url_for('register'))

            # Verificar se arquivo existe
            if not os.path.exists(model_path):
                flash(f'Arquivo do modelo não encontrado: {model_path}', 'error')
                return redirect(url_for('register'))

            # Registrar modelo
            registry.register_model(
                model_path=model_path,
                name=name,
                framework=framework,
                version=version,
                description=description
            )

            flash(f'Modelo "{name}" registrado com sucesso!', 'success')
            return redirect(url_for('model_detail', name=name))

        except Exception as e:
            flash(f'Erro ao registrar modelo: {str(e)}', 'error')
            return redirect(url_for('register'))

    return render_template('register.html')

@app.route('/delete/<name>', methods=['POST'])
def delete_model(name):
    """Deletar modelo."""
    try:
        if registry.delete_model(name):
            flash(f'Modelo "{name}" deletado com sucesso!', 'success')
        else:
            flash(f'Modelo "{name}" não encontrado', 'error')
    except Exception as e:
        flash(f'Erro ao deletar modelo: {str(e)}', 'error')

    return redirect(url_for('models'))

@app.route('/api/models', methods=['GET'])
def api_models():
    """API endpoint para listar modelos."""
    try:
        models = registry.list_models()
        return jsonify({'success': True, 'models': models})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/model/<name>', methods=['GET'])
def api_model_detail(name):
    """API endpoint para detalhes do modelo."""
    try:
        info = registry.get_model_info(name)
        if info:
            return jsonify({'success': True, 'model': info})
        else:
            return jsonify({'success': False, 'error': 'Modelo não encontrado'}), 404
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/register', methods=['POST'])
def api_register():
    """API endpoint para registrar modelo."""
    try:
        data = request.get_json()
        required_fields = ['model_path', 'name', 'framework']

        for field in required_fields:
            if field not in data:
                return jsonify({'success': False, 'error': f'Campo obrigatório: {field}'}), 400

        registry.register_model(
            model_path=data['model_path'],
            name=data['name'],
            framework=data['framework'],
            version=data.get('version', '1.0.0'),
            description=data.get('description', '')
        )

        return jsonify({'success': True, 'message': f'Modelo "{data["name"]}" registrado'})

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/delete/<name>', methods=['DELETE'])
def api_delete(name):
    """API endpoint para deletar modelo."""
    try:
        if registry.delete_model(name):
            return jsonify({'success': True, 'message': f'Modelo "{name}" deletado'})
        else:
            return jsonify({'success': False, 'error': 'Modelo não encontrado'}), 404
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/stats', methods=['GET'])
def api_stats():
    """API endpoint para estatísticas."""
    try:
        stats = registry.get_registry_stats()
        return jsonify({'success': True, 'stats': stats})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

from jinja2 import Environment

def format_size(size_bytes):
    """Formatar tamanho em bytes para leitura humana."""
    if size_bytes is None:
        return "0 B"
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.1f} PB"

def format_datetime(dt_str):
    """Formatar data/hora."""
    try:
        dt = datetime.fromisoformat(dt_str.replace('Z', '+00:00'))
        return dt.strftime('%d/%m/%Y %H:%M:%S')
    except:
        return dt_str

# Registrar filtros no ambiente Jinja2
app.jinja_env.filters['format_size'] = format_size
app.jinja_env.filters['format_datetime'] = format_datetime

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print("🚀 Iniciando Dashboard do Model Registry...")
    print(f"📱 Acesse: http://localhost:{port}")
    print("❌ Para parar: Ctrl+C")
    app.run(debug=True, host='0.0.0.0', port=port)
