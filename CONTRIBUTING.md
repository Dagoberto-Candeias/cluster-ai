# Guia de Contribuição - Cluster AI

## Como Contribuir
1. Faça um fork do repositório
2. Crie um branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para o branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Diretrizes de Desenvolvimento

### Estilo de Código
- Siga o estilo de código existente (PEP 8 para Python, ShellCheck para Bash)
- Use nomes descritivos para variáveis e funções
- Adicione comentários para lógica complexa
- Mantenha linhas com no máximo 88 caracteres

### Testes
- Adicione testes unitários para novas funcionalidades (`tests/unit/`)
- Inclua testes de integração para APIs e serviços (`tests/integration/`)
- Adicione testes de performance para otimizações (`tests/performance/`)
- Testes de segurança para autenticação e validação (`tests/security/`)
- Cobertura mínima de 80% (`pytest --cov`)
- Execute `pytest` antes de commitar

### Segurança
- Nunca commite secrets ou chaves (use .env.example)
- Valide todas as entradas do usuário
- Use HTTPS para todas as comunicações externas
- Implemente rate limiting em APIs públicas
- Execute `bandit` para análise de segurança
- Siga OWASP guidelines para web apps

### Documentação
- Atualize README.md para mudanças significativas
- Adicione docstrings em Python (Google style)
- Documente APIs com OpenAPI/Swagger
- Atualize guias em `docs/` conforme necessário

### Commits
- Use mensagens claras e descritivas
- Prefixe com tipo: `feat:`, `fix:`, `docs:`, `test:`, `security:`
- Mantenha commits pequenos e focados

### Pull Requests
- Descreva claramente as mudanças
- Referencie issues relacionadas
- Inclua screenshots para mudanças de UI
- Aguarde aprovação de pelo menos 1 reviewer

### Ambiente de Desenvolvimento
```bash
# Configurar ambiente
pip install -r requirements-dev.txt
pre-commit install

# Executar testes
pytest --cov --html=tests/reports/report.html

# Verificar segurança
bandit -r . --exclude tests
safety check

# Lint
flake8 --max-line-length 88
shellcheck scripts/*.sh
```

### Tipos de Contribuição
- 🐛 **Bug Fixes**: Correções com testes reprodutores
- ✨ **Features**: Novas funcionalidades com documentação
- 📚 **Documentação**: Melhorias na documentação
- 🧪 **Testes**: Novos testes ou melhorias na cobertura
- 🔒 **Segurança**: Correções e melhorias de segurança
- ⚡ **Performance**: Otimizações com benchmarks
