# Exemplo de integração com Ollama
# https://github.com/Dagoberto-Candeias/cluster-ai

import requests
from dask.distributed import Client


def query_ollama(prompt, model="llama3", host="localhost"):
    """Query Ollama API"""
    try:
        response = requests.post(
            f"http://{host}:11434/api/generate",
            json={"model": model, "prompt": prompt, "stream": False},
        )
        return response.json()["response"]
    except Exception as e:
        return f"Error: {str(e)}"


def main():
    # Connect to cluster
    client = Client("localhost:8786")

    # Example usage
    result = query_ollama("Explain AI in simple terms")
    print("Ollama response:", result)

    client.close()


if __name__ == "__main__":
    main()
