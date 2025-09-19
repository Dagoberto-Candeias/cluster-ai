#!/bin/bash

echo "🚀 Iniciando Cluster Dask..."
echo "=============================="

# Ativar ambiente virtual
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "✅ Ambiente virtual ativado"
elif [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    echo "✅ Ambiente virtual ativado"
else
    echo "⚠️ Ambiente virtual não encontrado"
fi

# Verificar se o scheduler já está rodando
if lsof -Pi :8786 -sTCP:LISTEN -t >/dev/null ; then
    echo "✅ Dask Scheduler já está rodando na porta 8786"
else
    echo "🔄 Iniciando Dask Scheduler..."
    dask-scheduler --host 0.0.0.0 --port 8786 &
    SCHEDULER_PID=$!
    echo $SCHEDULER_PID > .scheduler_pid
    echo "✅ Dask Scheduler iniciado (PID: $SCHEDULER_PID)"
    sleep 2
fi

# Verificar se o worker já está rodando
if lsof -Pi :8787 -sTCP:LISTEN -t >/dev/null ; then
    echo "✅ Dask Dashboard já está rodando na porta 8787"
else
    echo "🔄 Iniciando Dask Worker..."
    dask-worker localhost:8786 --nworkers auto --nthreads 2 &
    WORKER_PID=$!
    echo $WORKER_PID > .worker_pid
    echo "✅ Dask Worker iniciado (PID: $WORKER_PID)"
fi

echo ""
echo "🌐 Serviços do Cluster:"
echo "  - Dask Scheduler: tcp://localhost:8786"
echo "  - Dask Dashboard: http://localhost:8787"
echo ""
echo "📊 Para monitorar: abra http://localhost:8787 no navegador"
echo "🔧 Para parar: execute ./stop_cluster.sh"
echo ""
echo "🎉 Cluster Dask iniciado com sucesso!"
