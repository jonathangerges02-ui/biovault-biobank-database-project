from __future__ import annotations

import sqlite3

import pytest

from src.database import Database
from src.repository import BiobankRepository, validate_donor


@pytest.fixture()
def repository(tmp_path):
    database_path = tmp_path / "test_biobank.db"
    database = Database(f"sqlite:///{database_path}")
    database.initialize_sqlite_demo()
    return BiobankRepository(database)


def valid_donor(code: str = "BIO-D9001"):
    return {
        "donor_code": code,
        "sex_at_birth": "UNKNOWN",
        "birth_year": "",
        "blood_type": "",
        "ethnicity": "Not disclosed",
        "donor_status": "ACTIVE",
        "registered_on": "2026-07-27",
    }


def test_demo_database_has_required_ui_data(repository):
    assert repository.dashboard_counts() == {
        "donors": 12,
        "samples": 20,
        "test_requests": 15,
    }


def test_search_returns_meaningful_joined_records(repository):
    samples = repository.list_samples("plasma")
    requests = repository.list_test_requests("RNA")

    assert len(samples) >= 4
    assert all(row["sample_type"] == "Plasma" for row in samples)
    assert any(row["test_name"] == "RNA Integrity Number" for row in requests)


def test_donor_crud_round_trip(repository):
    donor_id = repository.create_donor(valid_donor())
    created = repository.get_donor(donor_id)
    assert created is not None
    assert created["donor_code"] == "BIO-D9001"

    changed = valid_donor()
    changed["donor_status"] = "INACTIVE"
    changed["ethnicity"] = "Withheld"
    repository.update_donor(donor_id, changed)

    updated = repository.get_donor(donor_id)
    assert updated is not None
    assert updated["donor_status"] == "INACTIVE"
    assert updated["ethnicity"] == "Withheld"

    repository.delete_donor(donor_id)
    assert repository.get_donor(donor_id) is None


@pytest.mark.parametrize(
    ("field", "value", "message"),
    [
        ("donor_code", "PERSON-12", "BIO-D0000"),
        ("sex_at_birth", "OTHER", "sex-at-birth"),
        ("birth_year", "not-a-year", "number"),
        ("registered_on", "27/07/2026", "YYYY-MM-DD"),
    ],
)
def test_donor_validation_rejects_bad_input(field, value, message):
    data = valid_donor()
    data[field] = value
    with pytest.raises(ValueError, match=message):
        validate_donor(data)


def test_foreign_keys_protect_referenced_donors(repository):
    with pytest.raises(sqlite3.IntegrityError):
        repository.delete_donor(1)
