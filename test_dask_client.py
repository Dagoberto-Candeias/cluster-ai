import time
from dask.distributed import Client

def inc(x):
    time.sleep(1)
    return x + 1

def add(x, y):
    time.sleep(1)
    return x + y

if __name__ == "__main__":
    try:
        # Conecta ao scheduler Dask que está rodando localmente
        client = Client('tcp://127.0.0.1:8786')
        print("✅ Conectado ao Dask Scheduler com sucesso!")
        print(f"🔗 Dashboard: {client.dashboard_link}")

        # Envia tarefas para o cluster
        a = client.submit(inc, 10)
        b = client.submit(add, a, 20)
        
        result = b.result() # Aguarda o resultado final
        print(f"🎉 Resultado da computação distribuída: {result}")
        assert result == 31

        print("✅ Teste de funcionalidade do Cluster Dask concluído com sucesso!")
        client.close()
    except Exception as e:
        print(f"❌ Erro ao conectar ou executar tarefas no cluster Dask: {e}")