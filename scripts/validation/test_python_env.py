import dask
import torch
from distributed import Client

try:
    from transformers import pipeline  # type: ignore
except ImportError:
    pipeline = None


def test_dask():
    try:
        client = Client()
        print("Dask client created:", client)
        future = client.submit(lambda x: x + 1, 10)
        result = future.result()
        print("Dask computation result:", result)
        client.close()
        return True
    except Exception as e:
        print("Dask test failed:", e)
        return False


def test_torch():
    try:
        x = torch.tensor([1.0, 2.0, 3.0])
        y = x * 2
        print("Torch tensor operation result:", y)
        return True
    except Exception as e:
        print("Torch test failed:", e)
        return False


def test_transformers():
    if pipeline is None:
        print("Transformers library not installed, skipping test.")
        return False
    try:
        classifier = pipeline("sentiment-analysis")
        result = classifier("I love using Cluster AI!")
        print("Transformers pipeline result:", result)
        return True
    except Exception as e:
        print("Transformers test failed:", e)
        return False


if __name__ == "__main__":
    print("Testing Python environment and key packages...")
    dask_ok = test_dask()
    torch_ok = test_torch()
    transformers_ok = test_transformers()
    if dask_ok and torch_ok and transformers_ok:
        print("All tests passed successfully.")
    else:
        print("Some tests failed. See above for details.")
