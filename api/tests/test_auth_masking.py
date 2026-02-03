
import pytest
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient

# Fix import path for test execution
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from dpp_api.main import app
from dpp_api.auth import _opa_mask, apply_masking

@pytest.fixture
def client():
    return TestClient(app)

def test_apply_masking_simple():
    payload = {
        "a": 1,
        "b": 2,
        "c": 3
    }
    mask_paths = ["b"]
    masked = apply_masking(payload, mask_paths)
    assert "a" in masked
    assert "b" not in masked
    assert "c" in masked

def test_apply_masking_nested():
    payload = {
        "user": {
            "name": "Alice",
            "email": "alice@example.com",
            "address": {
                "street": "123 Main St",
                "city": "Wonderland"
            }
        },
        "meta": "data"
    }
    mask_paths = ["user.email", "user.address.street"]
    masked = apply_masking(payload, mask_paths)
    
    assert masked["user"]["name"] == "Alice"
    assert "email" not in masked["user"]
    assert "street" not in masked["user"]["address"]
    assert masked["user"]["address"]["city"] == "Wonderland"
    assert masked["meta"] == "data"

def test_apply_masking_missing_path():
    payload = {"a": 1}
    # Should safely ignore missing paths
    masked = apply_masking(payload, ["b", "a.b"])
    assert masked == payload

@patch("dpp_api.auth.requests.post")
def test_opa_mask_returns_list(mock_post):
    mock_response = MagicMock()
    # OPA returns result object with allow and mask
    mock_response.json.return_value = {
        "result": {
            "allow": True,
            "mask": ["field1", "nested.field2"]
        }
    }
    mock_post.return_value = mock_response
    
    # We need to set OPA_URL for this to work, or mock the env var
    with patch("dpp_api.auth.OPA_URL", "http://mock-opa"):
        result = _opa_mask({})
        assert result == ["field1", "nested.field2"]

@patch("dpp_api.auth.requests.post")
def test_opa_mask_empty_on_error(mock_post):
    mock_post.side_effect = Exception("OPA down")
    
    with patch("dpp_api.auth.OPA_URL", "http://mock-opa"):
        result = _opa_mask({})
        assert result == []
