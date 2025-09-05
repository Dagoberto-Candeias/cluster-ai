# Exemplo de uso básico do Cluster AI
# https://github.com/Dagoberto-Candeias/cluster-ai

from dask.distributed import Client


def main():
    print("Cluster AI - Basic Usage Example")

    # Connect to cluster
    client = Client("localhost:8786")

    # Your distributed processing code here
    print(
        f"Connected to cluster with {len(client.scheduler_info()['workers'])} workers"
    )

    client.close()


if __name__ == "__main__":
    main()
