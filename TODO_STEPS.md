# TODO Steps - Completar Testes e Avançar Projeto Cluster AI

## 1. Corrigir Erro nos Testes
- [ ] Resolver erro SECRET_KEY em test_backend.py (adicionar env var ou mock)
- [ ] Executar pytest novamente para obter cobertura completa
- [ ] Se cobertura <80%, adicionar testes para performance/segurança

## 2. Segurança (já implementado parcialmente)
- [x] main_fixed.py: DB (SQLAlchemy), SECRET_KEY env, rate limiting (slowapi), input validation (Pydantic), subprocess shell=False, CSRF para WS
- [ ] scripts/security/: Melhorar generate_certificates.sh (auto-renew), adicionar security_audit.sh (bandit, safety para deps)
- [ ] compliance/: Popular reports/ com audit template, scripts/ com vuln scanner (trivy para docker)
- [ ] Global: Adicionar .env.example, gitignore secrets

## 3. Performance (parcialmente implementado)
- [x] main_fixed.py: Otimizado broadcast_realtime_updates (debounce time 5s), subprocess convertido para async em restart/stop/start worker
- [x] performance/: Redis-cluster config já existe (K8s), cache_manager.py usa Redis com fallback
- [ ] scripts/monitoring/: Melhorar advanced_dashboard.sh com Prometheus queries, adicionar autoscaling thresholds
- [ ] monitoring/: Scripts para profiling (cProfile dask)

## 4. Verificação/Checagem (2 dias)
- [ ] Executar full pytest, lint (flake8), docker-compose up -d (check logs/health), manager.sh status
- [ ] Checar specs: Garantir plug-and-play workers (auto-detect), model categories (LLM/ML), no syntax errors

## 5. Investigation/Correção de erros (3 dias)
- [ ] Backend: Corrigir uvicorn args (já via override), subprocess leaks em restart_worker
- [ ] Workers: Completar termux_worker_setup.sh (install termux deps, SSH, dask-worker)
- [ ] Models: Corrigir incomplete download_models.sh (add categories/progress)
- [ ] Init: Garantir no postgres dep em dev (confirm profiles), adicionar health checks em health_checker.sh
- [ ] Global: Investigar/fixar unbound vars (e.g., em common.sh), dep conflicts (pip check)

## 6. Workers (integrado)
- [ ] Fazer plug-and-play: worker_manager.sh auto-SSH keygen/setup, termux script com one-command install (curl | bash)

## 7. Models (integrado)
- [ ] ai-ml/: Adicionar model_install.py (categorized pull), explanations em metadata/

## 8. Followup
- [ ] Installations: pip install -r requirements-dev.txt; apt install yq whiptail (if missing)
- [ ] Testing: pytest tests/ --cov; docker-compose up -d; ./manager.sh status; curl localhost:8000/health
- [ ] Verification: Run full system (start_cluster.sh), check logs/metrics, benchmark dask tasks
