"""Database connection helpers for PostgreSQL and the local SQLite demo."""

from __future__ import annotations

import os
import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SQLITE_PATH = PROJECT_ROOT / "data" / "biobank_demo.db"


class Database:
    """Small adapter that keeps repository SQL readable across two DB backends."""

    def __init__(self, database_url: str | None = None) -> None:
        self.database_url = database_url or os.getenv("BIOBANK_DATABASE_URL")
        self.is_postgres = bool(
            self.database_url
            and self.database_url.startswith(("postgresql://", "postgres://"))
        )
        if self.is_postgres:
            self.display_name = "PostgreSQL"
            self.sqlite_path = None
        else:
            self.sqlite_path = self._sqlite_path_from_url(self.database_url)
            self.display_name = f"SQLite demo ({self.sqlite_path.name})"

    @staticmethod
    def _sqlite_path_from_url(database_url: str | None) -> Path:
        if not database_url:
            return DEFAULT_SQLITE_PATH
        if database_url.startswith("sqlite:///"):
            return Path(database_url.removeprefix("sqlite:///")).resolve()
        raise ValueError(
            "BIOBANK_DATABASE_URL must be a PostgreSQL URL or sqlite:///path."
        )

    @property
    def placeholder(self) -> str:
        return "%s" if self.is_postgres else "?"

    def table(self, name: str) -> str:
        return f"biobank.{name}" if self.is_postgres else name

    @contextmanager
    def connection(self) -> Iterator[Any]:
        if self.is_postgres:
            import psycopg

            connection = psycopg.connect(self.database_url)
            try:
                yield connection
                connection.commit()
            except Exception:
                connection.rollback()
                raise
            finally:
                connection.close()
        else:
            assert self.sqlite_path is not None
            self.sqlite_path.parent.mkdir(parents=True, exist_ok=True)
            connection = sqlite3.connect(self.sqlite_path)
            connection.row_factory = sqlite3.Row
            connection.execute("PRAGMA foreign_keys = ON")
            try:
                yield connection
                connection.commit()
            except Exception:
                connection.rollback()
                raise
            finally:
                connection.close()

    def initialize_sqlite_demo(self, force: bool = False) -> None:
        if self.is_postgres:
            return
        assert self.sqlite_path is not None
        if force and self.sqlite_path.exists():
            self.sqlite_path.unlink()
        schema_path = Path(__file__).with_name("sqlite_demo.sql")
        with self.connection() as connection:
            connection.executescript(schema_path.read_text(encoding="utf-8"))

    def ping(self) -> None:
        with self.connection() as connection:
            connection.execute("SELECT 1")
