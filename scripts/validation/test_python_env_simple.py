import dask
import numpy as np
import torch
from distributed import Client


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


def test_numpy():
    try:
        arr = np.array([1, 2, 3])
        result = arr * 2
        print("NumPy array operation result:", result)
        return True
    except Exception as e:
        print("NumPy test failed:", e)
        return False


if __name__ == "__main__":
    print("Testing Python environment and key packages...")
    dask_ok = test_dask()
    torch_ok = test_torch()
    numpy_ok = test_numpy()

    if dask_ok and torch_ok and numpy_ok:
        print("All tests passed successfully.")
    else:
        print("Some tests failed. See above for details.")
