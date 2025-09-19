#!/bin/bash

echo "🛑 Parando Cluster Dask..."
echo "=========================="

# Função para parar processo
stop_process() {
    local pid_file=$1
    local process_name=$2

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Parando $process_name (PID: $pid)..."
            kill "$pid"
            sleep 2
            if kill -0 "$pid" 2>/dev/null; then
                echo "Forçando parada de $process_name..."
                kill -9 "$pid"
            fi
            echo "✅ $process_name parado"
        else
            echo "⚠️ $process_name já estava parado"
        fi
        rm -f "$pid_file"
    else
        echo "⚠️ Arquivo PID de $process_name não encontrado"
    fi
}

# Parar worker
stop_process ".worker_pid" "Dask Worker"

# Parar scheduler
stop_process ".scheduler_pid" "Dask Scheduler"

# Verificar se ainda há processos rodando
echo ""
echo "Verificando processos restantes..."
dask_processes=$(pgrep -f "dask-scheduler\|dask-worker" || true)
if [ -n "$dask_processes" ]; then
    echo "⚠️ Ainda há processos Dask rodando:"
    ps -p $dask_processes -o pid,ppid,cmd
    echo "Parando todos os processos Dask..."
    pkill -f "dask-scheduler\|dask-worker"
    sleep 2
    pkill -9 -f "dask-scheduler\|dask-worker" 2>/dev/null || true
else
    echo "✅ Nenhum processo Dask restante"
fi

# Verificar portas
echo ""
echo "Verificando portas..."
if lsof -Pi :8786 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️ Porta 8786 ainda em uso"
else
    echo "✅ Porta 8786 liberada"
fi

if lsof -Pi :8787 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️ Porta 8787 ainda em uso"
else
    echo "✅ Porta 8787 liberada"
fi

echo ""
echo "🎉 Cluster Dask parado com sucesso!"
