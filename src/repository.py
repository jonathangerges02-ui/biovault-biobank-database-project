"""Validated data operations used by the BioVault desktop UI."""

from __future__ import annotations

import re
from datetime import date
from typing import Any

try:
    from .database import Database
except ImportError:  # Supports direct execution with: python src/app.py
    from database import Database


DONOR_CODE_PATTERN = re.compile(r"^BIO-D\d{4}$")
VALID_SEX_VALUES = {"FEMALE", "MALE", "INTERSEX", "UNKNOWN"}
VALID_BLOOD_TYPES = {"", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"}
VALID_DONOR_STATUSES = {"ACTIVE", "INACTIVE", "WITHDRAWN", "DECEASED"}


def validate_donor(data: dict[str, Any]) -> dict[str, Any]:
    cleaned = {
        "donor_code": str(data.get("donor_code", "")).strip().upper(),
        "sex_at_birth": str(data.get("sex_at_birth", "")).strip().upper(),
        "birth_year": data.get("birth_year"),
        "blood_type": str(data.get("blood_type", "")).strip().upper(),
        "ethnicity": str(data.get("ethnicity", "")).strip(),
        "donor_status": str(data.get("donor_status", "")).strip().upper(),
        "registered_on": str(data.get("registered_on", "")).strip(),
    }

    errors: list[str] = []
    if not DONOR_CODE_PATTERN.fullmatch(cleaned["donor_code"]):
        errors.append("Donor code must match BIO-D0000.")
    if cleaned["sex_at_birth"] not in VALID_SEX_VALUES:
        errors.append("Select a valid sex-at-birth value.")
    if cleaned["blood_type"] not in VALID_BLOOD_TYPES:
        errors.append("Select a valid blood type or leave it blank.")
    if cleaned["donor_status"] not in VALID_DONOR_STATUSES:
        errors.append("Select a valid donor status.")

    birth_year = cleaned["birth_year"]
    if birth_year in ("", None):
        cleaned["birth_year"] = None
    else:
        try:
            cleaned["birth_year"] = int(birth_year)
        except (TypeError, ValueError):
            errors.append("Birth year must be a number.")
        else:
            if not 1900 <= cleaned["birth_year"] <= date.today().year:
                errors.append(f"Birth year must be between 1900 and {date.today().year}.")

    try:
        date.fromisoformat(cleaned["registered_on"])
    except ValueError:
        errors.append("Registration date must use YYYY-MM-DD.")

    if errors:
        raise ValueError("\n".join(errors))
    return cleaned


class BiobankRepository:
    def __init__(self, database: Database) -> None:
        self.db = database

    @staticmethod
    def _rows(cursor: Any) -> list[dict[str, Any]]:
        if cursor.description is None:
            return []
        columns = [column.name if hasattr(column, "name") else column[0] for column in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]

    def dashboard_counts(self) -> dict[str, int]:
        tables = ("donors", "samples", "test_requests")
        result: dict[str, int] = {}
        with self.db.connection() as connection:
            for table in tables:
                cursor = connection.execute(
                    f"SELECT COUNT(*) AS item_count FROM {self.db.table(table)}"
                )
                result[table] = int(cursor.fetchone()[0])
        return result

    def list_donors(self, search: str = "") -> list[dict[str, Any]]:
        marker = self.db.placeholder
        pattern = f"%{search.strip()}%"
        sql = f"""
            SELECT donor_id, donor_code, sex_at_birth, birth_year, blood_type,
                   ethnicity, donor_status, registered_on
            FROM {self.db.table('donors')}
            WHERE LOWER(donor_code) LIKE LOWER({marker})
               OR LOWER(COALESCE(ethnicity, '')) LIKE LOWER({marker})
            ORDER BY donor_code
        """
        with self.db.connection() as connection:
            return self._rows(connection.execute(sql, (pattern, pattern)))

    def get_donor(self, donor_id: int) -> dict[str, Any] | None:
        marker = self.db.placeholder
        sql = f"""
            SELECT donor_id, donor_code, sex_at_birth, birth_year, blood_type,
                   ethnicity, donor_status, registered_on
            FROM {self.db.table('donors')}
            WHERE donor_id = {marker}
        """
        with self.db.connection() as connection:
            rows = self._rows(connection.execute(sql, (donor_id,)))
        return rows[0] if rows else None

    def create_donor(self, donor_data: dict[str, Any]) -> int:
        data = validate_donor(donor_data)
        marker = self.db.placeholder
        columns = (
            "donor_code", "sex_at_birth", "birth_year", "blood_type",
            "ethnicity", "donor_status", "registered_on",
        )
        values = tuple(data[column] or None for column in columns)
        sql = f"""
            INSERT INTO {self.db.table('donors')} ({', '.join(columns)})
            VALUES ({', '.join([marker] * len(columns))})
        """
        with self.db.connection() as connection:
            if self.db.is_postgres:
                cursor = connection.execute(sql + " RETURNING donor_id", values)
                return int(cursor.fetchone()[0])
            cursor = connection.execute(sql, values)
            return int(cursor.lastrowid)

    def update_donor(self, donor_id: int, donor_data: dict[str, Any]) -> None:
        data = validate_donor(donor_data)
        marker = self.db.placeholder
        columns = (
            "donor_code", "sex_at_birth", "birth_year", "blood_type",
            "ethnicity", "donor_status", "registered_on",
        )
        assignments = ", ".join(f"{column} = {marker}" for column in columns)
        values = tuple(data[column] or None for column in columns) + (donor_id,)
        sql = f"""
            UPDATE {self.db.table('donors')}
            SET {assignments}
            WHERE donor_id = {marker}
        """
        with self.db.connection() as connection:
            cursor = connection.execute(sql, values)
            if cursor.rowcount != 1:
                raise LookupError(f"Donor {donor_id} does not exist.")

    def delete_donor(self, donor_id: int) -> None:
        marker = self.db.placeholder
        sql = f"DELETE FROM {self.db.table('donors')} WHERE donor_id = {marker}"
        with self.db.connection() as connection:
            cursor = connection.execute(sql, (donor_id,))
            if cursor.rowcount != 1:
                raise LookupError(f"Donor {donor_id} does not exist.")

    def list_samples(self, search: str = "") -> list[dict[str, Any]]:
        marker = self.db.placeholder
        pattern = f"%{search.strip()}%"
        sql = f"""
            SELECT s.sample_id, s.sample_code, st.type_name AS sample_type,
                   d.donor_code, s.initial_quantity, s.quantity_unit,
                   s.quality_status, s.sample_status,
                   s.received_at
            FROM {self.db.table('samples')} s
            JOIN {self.db.table('sample_types')} st
              ON st.sample_type_id = s.sample_type_id
            JOIN {self.db.table('collection_events')} ce
              ON ce.collection_event_id = s.collection_event_id
            JOIN {self.db.table('donors')} d
              ON d.donor_id = ce.donor_id
            WHERE LOWER(s.sample_code) LIKE LOWER({marker})
               OR LOWER(st.type_name) LIKE LOWER({marker})
               OR LOWER(d.donor_code) LIKE LOWER({marker})
            ORDER BY s.sample_code
        """
        with self.db.connection() as connection:
            return self._rows(connection.execute(sql, (pattern, pattern, pattern)))

    def list_test_requests(self, search: str = "") -> list[dict[str, Any]]:
        marker = self.db.placeholder
        pattern = f"%{search.strip()}%"
        sql = f"""
            SELECT tr.test_request_id, tr.request_code, s.sample_code,
                   tt.test_name, r.full_name AS requested_by,
                   tr.requested_on, tr.request_status,
                   COALESCE(CAST(tr.numeric_result AS TEXT), tr.text_result, '') AS result
            FROM {self.db.table('test_requests')} tr
            JOIN {self.db.table('samples')} s ON s.sample_id = tr.sample_id
            JOIN {self.db.table('test_types')} tt ON tt.test_type_id = tr.test_type_id
            JOIN {self.db.table('researchers')} r ON r.researcher_id = tr.requested_by
            WHERE LOWER(tr.request_code) LIKE LOWER({marker})
               OR LOWER(s.sample_code) LIKE LOWER({marker})
               OR LOWER(tt.test_name) LIKE LOWER({marker})
            ORDER BY tr.requested_on DESC, tr.request_code
        """
        with self.db.connection() as connection:
            return self._rows(connection.execute(sql, (pattern, pattern, pattern)))
