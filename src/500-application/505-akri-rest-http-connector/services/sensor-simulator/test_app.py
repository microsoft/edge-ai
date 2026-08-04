"""Flask test-client coverage for the sensor simulator, focused on POST /retrieval."""

import json

import app as app_module
import pytest


@pytest.fixture
def client():
    app_module.app.config.update(TESTING=True)
    with app_module.app.test_client() as test_client:
        yield test_client


class TestPostRetrieval:
    def test_valid_request_returns_ordered_fields(self, client):
        field_ids = ["humidity-pct-01", "temp-celsius-01"]
        response = client.post(
            "/retrieval",
            data=json.dumps({"field_ids": field_ids}),
            content_type="application/json",
        )

        assert response.status_code == 200
        body = response.get_json()
        assert body["count"] == len(field_ids)
        assert [field["field_id"] for field in body["fields"]] == field_ids

    def test_duplicate_field_ids_preserved(self, client):
        field_ids = ["temp-celsius-01", "temp-celsius-01"]
        response = client.post(
            "/retrieval",
            data=json.dumps({"field_ids": field_ids}),
            content_type="application/json",
        )

        assert response.status_code == 200
        body = response.get_json()
        assert body["count"] == 2
        assert [field["field_id"] for field in body["fields"]] == field_ids

    def test_missing_body_returns_400(self, client):
        response = client.post("/retrieval", content_type="application/json")

        assert response.status_code == 400

    def test_malformed_json_returns_400(self, client):
        response = client.post(
            "/retrieval",
            data="{not valid json",
            content_type="application/json",
        )

        assert response.status_code == 400

    def test_missing_field_ids_key_returns_400(self, client):
        response = client.post(
            "/retrieval",
            data=json.dumps({}),
            content_type="application/json",
        )

        assert response.status_code == 400

    def test_empty_field_ids_returns_400(self, client):
        response = client.post(
            "/retrieval",
            data=json.dumps({"field_ids": []}),
            content_type="application/json",
        )

        assert response.status_code == 400

    def test_blank_field_id_returns_400(self, client):
        response = client.post(
            "/retrieval",
            data=json.dumps({"field_ids": ["temp-celsius-01", "   "]}),
            content_type="application/json",
        )

        assert response.status_code == 400

    def test_wrong_content_type_returns_415(self, client):
        response = client.post(
            "/retrieval",
            data=json.dumps({"field_ids": ["temp-celsius-01"]}),
            content_type="text/plain",
        )

        assert response.status_code == 415

    def test_unknown_field_id_returns_404_with_no_partial_data(self, client):
        response = client.post(
            "/retrieval",
            data=json.dumps(
                {"field_ids": ["temp-celsius-01", "does-not-exist"]}),
            content_type="application/json",
        )

        assert response.status_code == 404
        body = response.get_json()
        assert "does-not-exist" in body["error"]
        assert "fields" not in body

    def test_oversized_body_returns_413(self, client):
        # Each entry is short; repeat well past MAX_CONTENT_LENGTH (64 KiB default).
        field_ids = ["temp-celsius-01"] * 6000
        oversized_body = json.dumps({"field_ids": field_ids})
        assert len(oversized_body.encode("utf-8")
                   ) > app_module.app.config["MAX_CONTENT_LENGTH"]

        response = client.post(
            "/retrieval",
            data=oversized_body,
            content_type="application/json",
        )

        assert response.status_code == 413

    def test_large_field_id_array_under_size_limit_succeeds(self, client):
        # Body exceeds 10,000 characters but stays below the 64 KiB request limit.
        field_ids = ["temp-celsius-01"] * 550
        body = json.dumps({"field_ids": field_ids})
        assert len(body) > 10_000
        assert len(body.encode("utf-8")
                   ) < app_module.app.config["MAX_CONTENT_LENGTH"]

        response = client.post(
            "/retrieval",
            data=body,
            content_type="application/json",
        )

        assert response.status_code == 200
        response_body = response.get_json()
        assert response_body["count"] == len(field_ids)
