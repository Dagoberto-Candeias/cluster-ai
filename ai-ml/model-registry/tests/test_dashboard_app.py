import pytest
import sys
import os
import importlib.util

# Adjust sys.path to import dashboard app correctly
project_root = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..")
)
sys.path.insert(0, project_root)

# Import the dashboard app module directly
spec = importlib.util.spec_from_file_location(
    "dashboard_app",
    os.path.join(project_root, "ai-ml", "model-registry", "dashboard", "app.py"),
)
dashboard_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dashboard_module)
flask_app = dashboard_module.app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    flask_app.config["WTF_CSRF_ENABLED"] = False
    with flask_app.test_client() as client:
        yield client


def test_index_page(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Modelos Registrados" in response.data or b"Dashboard" in response.data


def test_models_page(client):
    response = client.get("/models")
    assert response.status_code == 200
    assert b"Modelos Registrados" in response.data


def test_register_page_get(client):
    response = client.get("/register")
    assert response.status_code == 200
    assert b"Registrar Novo Modelo" in response.data or b"Registrar" in response.data


def test_register_post_missing_fields(client):
    response = client.post("/register", data={})
    # Should redirect back to register page due to missing required fields
    assert response.status_code == 302


def test_model_detail_not_found(client):
    response = client.get("/model/nonexistent_model")
    # Should redirect to models page with error flash
    assert response.status_code == 302


def test_delete_model_post(client):
    # Since no models exist, deleting should redirect with error flash
    response = client.post("/delete/nonexistent_model")
    assert response.status_code == 302


def test_api_models(client):
    response = client.get("/api/models")
    assert response.status_code == 200
    json_data = response.get_json()
    assert "success" in json_data


def test_api_model_detail_not_found(client):
    response = client.get("/api/model/nonexistent_model")
    assert response.status_code == 404


def test_api_register_missing_fields(client):
    response = client.post("/api/register", json={})
    assert response.status_code == 400


def test_api_delete_not_found(client):
    response = client.delete("/api/delete/nonexistent_model")
    assert response.status_code == 404


def test_api_stats(client):
    response = client.get("/api/stats")
    assert response.status_code == 200
    json_data = response.get_json()
    assert "success" in json_data
