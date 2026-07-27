"""Validate the generated BioVault course artifacts."""

from __future__ import annotations

import re
import zipfile
from pathlib import Path

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
COURSE_DIR = ROOT / "course"
SOURCE = COURSE_DIR / "BioVault_Database_Masterclass.md"
PDF = COURSE_DIR / "BioVault_Database_Masterclass.pdf"
DOCX = COURSE_DIR / "BioVault_Database_Masterclass.docx"

REQUIRED_TOPICS = [
    "What is data?",
    "Business rules",
    "Normalization without fear",
    "DDL: create the structure",
    "Joins: reconnect normalized facts",
    "Window functions",
    "Transactions and ACID",
    "Concurrency and row locks",
    "Functions, procedures, and triggers",
    "CRUD and application architecture",
    "Testing databases and applications",
    "Answer Key and Explanations",
    "Cheat Sheets",
    "Glossary",
]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    require(SOURCE.exists(), f"Missing source: {SOURCE}")
    require(PDF.exists(), f"Missing PDF: {PDF}")
    require(DOCX.exists(), f"Missing DOCX: {DOCX}")

    source_text = SOURCE.read_text(encoding="utf-8")
    word_count = len(re.findall(r"\b[\w'-]+\b", source_text))
    headings = re.findall(r"^#{1,3}\s+(.+)$", source_text, flags=re.MULTILINE)

    require(word_count >= 18_000, f"Course is too short: {word_count} words")
    require(len(headings) >= 100, f"Expected rich hierarchy, found {len(headings)} headings")
    for topic in REQUIRED_TOPICS:
        require(topic in source_text, f"Missing required topic: {topic}")

    with zipfile.ZipFile(DOCX) as archive:
        require(archive.testzip() is None, "Course DOCX is a damaged ZIP package")
        require("word/document.xml" in archive.namelist(), "Course DOCX is not Word OOXML")

    pdf = PdfReader(PDF)
    require(len(pdf.pages) >= 70, f"Course PDF is too short: {len(pdf.pages)} pages")

    sampled_text = "\n".join(
        (pdf.pages[index].extract_text() or "")
        for index in sorted({0, 1, len(pdf.pages) // 2, len(pdf.pages) - 1})
    )
    for phrase in ("BioVault Database Masterclass", "Normalization", "Glossary"):
        require(phrase in sampled_text or phrase in source_text, f"Missing text marker: {phrase}")

    print("Course validation passed.")
    print(f"Source words: {word_count}")
    print(f"Structured headings: {len(headings)}")
    print(f"PDF pages: {len(pdf.pages)}")
    print(f"DOCX size: {DOCX.stat().st_size:,} bytes")
    print(f"PDF size: {PDF.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()

