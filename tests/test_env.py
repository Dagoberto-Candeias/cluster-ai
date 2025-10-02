import sys

def test_print_env():
    print("Python executable:", sys.executable)
    print("sys.path:", sys.path)
    assert True
