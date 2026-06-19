"""
API 集成测试。
"""
import pytest
from fastapi.testclient import TestClient
from app.main import app


@pytest.fixture
def client():
    return TestClient(app)


class TestHealthEndpoint:
    def test_health(self, client):
        resp = client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"
        assert "douyin" in data["supported_platforms"]
        assert "tiktok" in data["supported_platforms"]
        assert "bilibili" in data["supported_platforms"]
        assert "xiaohongshu" in data["supported_platforms"]


class TestDetectEndpoint:
    def test_detect_douyin(self, client):
        resp = client.post("/api/v1/detect", json={"url": "https://v.douyin.com/iRNBho5e/"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["supported"] is True
        assert data["platform"] == "douyin"

    def test_detect_unsupported(self, client):
        resp = client.post("/api/v1/detect", json={"url": "https://youtube.com/watch?v=abc"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["supported"] is False


class TestConvertEndpoint:
    def test_convert_no_url(self, client):
        resp = client.post("/api/v1/convert", json={"url": "没有链接"})
        assert resp.status_code == 400

    def test_convert_unsupported(self, client):
        resp = client.post("/api/v1/convert", json={"url": "https://youtube.com/watch?v=abc"})
        assert resp.status_code == 400


class TestAuthEndpoints:
    def test_register_device(self, client):
        resp = client.post("/api/v1/auth/register-device")
        assert resp.status_code == 200
        data = resp.json()
        assert "device_id" in data
        assert "token" in data
        assert data["daily_quota"] == 10

    def test_get_me_anonymous(self, client):
        resp = client.get("/api/v1/auth/me")
        assert resp.status_code == 200
        data = resp.json()
        assert "device_id" in data

    def test_get_me_with_token(self, client):
        # 先注册设备
        reg = client.post("/api/v1/auth/register-device").json()
        token = reg["token"]
        # 用 token 查询
        resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["device_id"] == reg["device_id"]


class TestTaskStatus:
    def test_nonexistent_task(self, client):
        resp = client.get("/api/v1/tasks/nonexistent-id")
        assert resp.status_code == 404
