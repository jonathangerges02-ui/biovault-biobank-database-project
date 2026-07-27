"""BioVault bonus desktop UI with searchable data and validated donor CRUD."""

from __future__ import annotations

import os
import tkinter as tk
from datetime import date
from tkinter import messagebox, ttk
from typing import Any, Callable

if __package__ in (None, ""):
    from database import Database
    from repository import BiobankRepository
else:
    from .database import Database
    from .repository import BiobankRepository


COLORS = {
    "nav": "#123B4A",
    "nav_hover": "#1A5668",
    "accent": "#2BAE9B",
    "accent_dark": "#188576",
    "background": "#F3F7F8",
    "surface": "#FFFFFF",
    "text": "#18323B",
    "muted": "#607982",
    "danger": "#C94B55",
    "border": "#D8E4E7",
}


class DonorDialog(tk.Toplevel):
    FIELDS = (
        ("donor_code", "Donor code"),
        ("sex_at_birth", "Sex at birth"),
        ("birth_year", "Birth year"),
        ("blood_type", "Blood type"),
        ("ethnicity", "Ethnicity"),
        ("donor_status", "Status"),
        ("registered_on", "Registered on"),
    )

    def __init__(
        self,
        parent: tk.Misc,
        title: str,
        initial: dict[str, Any] | None,
        on_save: Callable[[dict[str, Any]], None],
    ) -> None:
        super().__init__(parent)
        self.title(title)
        self.geometry("460x520")
        self.resizable(False, False)
        self.configure(bg=COLORS["surface"])
        self.transient(parent)
        self.grab_set()
        self.on_save = on_save
        self.variables: dict[str, tk.StringVar] = {}
        initial = initial or {}

        header = tk.Frame(self, bg=COLORS["nav"], height=76)
        header.pack(fill="x")
        header.pack_propagate(False)
        tk.Label(
            header,
            text=title,
            bg=COLORS["nav"],
            fg="white",
            font=("Segoe UI Semibold", 17),
        ).pack(anchor="w", padx=28, pady=21)

        form = tk.Frame(self, bg=COLORS["surface"])
        form.pack(fill="both", expand=True, padx=28, pady=18)

        for row, (field, label) in enumerate(self.FIELDS):
            tk.Label(
                form,
                text=label,
                bg=COLORS["surface"],
                fg=COLORS["muted"],
                font=("Segoe UI", 10),
            ).grid(row=row * 2, column=0, sticky="w", pady=(3, 2))
            value = initial.get(field, "")
            if value is None:
                value = ""
            variable = tk.StringVar(value=str(value))
            self.variables[field] = variable
            if field == "sex_at_birth":
                widget: tk.Widget = ttk.Combobox(
                    form,
                    textvariable=variable,
                    values=("FEMALE", "MALE", "INTERSEX", "UNKNOWN"),
                    state="readonly",
                )
            elif field == "blood_type":
                widget = ttk.Combobox(
                    form,
                    textvariable=variable,
                    values=("", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"),
                    state="readonly",
                )
            elif field == "donor_status":
                widget = ttk.Combobox(
                    form,
                    textvariable=variable,
                    values=("ACTIVE", "INACTIVE", "WITHDRAWN", "DECEASED"),
                    state="readonly",
                )
            else:
                widget = ttk.Entry(form, textvariable=variable)
            widget.grid(row=row * 2 + 1, column=0, sticky="ew", pady=(0, 7), ipady=4)

        form.columnconfigure(0, weight=1)

        buttons = tk.Frame(self, bg=COLORS["surface"])
        buttons.pack(fill="x", padx=28, pady=(0, 22))
        ttk.Button(buttons, text="Cancel", command=self.destroy).pack(side="right")
        ttk.Button(
            buttons, text="Save donor", style="Accent.TButton", command=self.save
        ).pack(side="right", padx=(0, 10))

    def save(self) -> None:
        payload = {field: variable.get() for field, variable in self.variables.items()}
        try:
            self.on_save(payload)
        except ValueError as exc:
            messagebox.showerror("Validation error", str(exc), parent=self)
            return
        except Exception as exc:
            messagebox.showerror("Database error", str(exc), parent=self)
            return
        self.destroy()


class BioVaultApp(tk.Tk):
    def __init__(self, database: Database) -> None:
        super().__init__()
        self.database = database
        self.repository = BiobankRepository(database)
        self.title("BioVault — Biobank Management System")
        self.geometry("1280x780")
        self.minsize(1050, 680)
        self.configure(bg=COLORS["background"])
        self.search_var = tk.StringVar()
        self.current_view = "dashboard"
        self.current_tree: ttk.Treeview | None = None
        self._configure_styles()
        self._build_shell()
        self.show_dashboard()

    def _configure_styles(self) -> None:
        style = ttk.Style(self)
        style.theme_use("clam")
        style.configure(
            "Treeview",
            background=COLORS["surface"],
            fieldbackground=COLORS["surface"],
            foreground=COLORS["text"],
            rowheight=34,
            borderwidth=0,
            font=("Segoe UI", 10),
        )
        style.configure(
            "Treeview.Heading",
            background="#E7EFF1",
            foreground=COLORS["text"],
            font=("Segoe UI Semibold", 10),
            relief="flat",
            padding=(8, 10),
        )
        style.map("Treeview", background=[("selected", COLORS["accent"])])
        style.configure(
            "TEntry",
            padding=7,
            fieldbackground=COLORS["surface"],
            bordercolor=COLORS["border"],
        )
        style.configure("TCombobox", padding=6)
        style.configure("TButton", padding=(14, 8), font=("Segoe UI Semibold", 10))
        style.configure(
            "Accent.TButton",
            background=COLORS["accent"],
            foreground="white",
            borderwidth=0,
        )
        style.map(
            "Accent.TButton",
            background=[("active", COLORS["accent_dark"])],
            foreground=[("active", "white")],
        )
        style.configure(
            "Danger.TButton",
            background=COLORS["danger"],
            foreground="white",
            borderwidth=0,
        )

    def _build_shell(self) -> None:
        sidebar = tk.Frame(self, bg=COLORS["nav"], width=235)
        sidebar.pack(side="left", fill="y")
        sidebar.pack_propagate(False)

        brand = tk.Frame(sidebar, bg=COLORS["nav"], height=116)
        brand.pack(fill="x")
        brand.pack_propagate(False)
        tk.Label(
            brand,
            text="◉",
            bg=COLORS["nav"],
            fg=COLORS["accent"],
            font=("Segoe UI", 23),
        ).pack(side="left", padx=(22, 10))
        tk.Label(
            brand,
            text="BioVault",
            bg=COLORS["nav"],
            fg="white",
            font=("Segoe UI Semibold", 20),
        ).pack(side="left")

        nav_items = (
            ("Dashboard", self.show_dashboard),
            ("Donors", self.show_donors),
            ("Samples", self.show_samples),
            ("Test requests", self.show_test_requests),
        )
        for label, command in nav_items:
            button = tk.Button(
                sidebar,
                text=label,
                command=command,
                anchor="w",
                padx=28,
                pady=14,
                bg=COLORS["nav"],
                fg="#DDECEF",
                activebackground=COLORS["nav_hover"],
                activeforeground="white",
                relief="flat",
                cursor="hand2",
                font=("Segoe UI Semibold", 11),
            )
            button.pack(fill="x")

        tk.Label(
            sidebar,
            text=f"Connected to\n{self.database.display_name}",
            bg=COLORS["nav"],
            fg="#9FC2C9",
            justify="left",
            wraplength=185,
            font=("Segoe UI", 9),
        ).pack(side="bottom", anchor="w", padx=28, pady=24)

        self.main = tk.Frame(self, bg=COLORS["background"])
        self.main.pack(side="left", fill="both", expand=True)

        self.header = tk.Frame(self.main, bg=COLORS["background"], height=106)
        self.header.pack(fill="x", padx=34)
        self.header.pack_propagate(False)

        self.title_label = tk.Label(
            self.header,
            text="",
            bg=COLORS["background"],
            fg=COLORS["text"],
            font=("Segoe UI Semibold", 24),
        )
        self.title_label.pack(side="left", pady=29)

        self.header_actions = tk.Frame(self.header, bg=COLORS["background"])
        self.header_actions.pack(side="right", pady=27)

        self.content = tk.Frame(self.main, bg=COLORS["background"])
        self.content.pack(fill="both", expand=True, padx=34, pady=(0, 28))

    def _clear_view(self, title: str) -> None:
        self.title_label.configure(text=title)
        for widget in self.header_actions.winfo_children():
            widget.destroy()
        for widget in self.content.winfo_children():
            widget.destroy()
        self.search_var.set("")
        self.current_tree = None

    def _show_error(self, exc: Exception) -> None:
        messagebox.showerror(
            "Unable to complete the operation",
            f"{exc}\n\nVerify the database connection and submitted schema.",
            parent=self,
        )

    def show_dashboard(self) -> None:
        self.current_view = "dashboard"
        self._clear_view("Dashboard")
        try:
            counts = self.repository.dashboard_counts()
        except Exception as exc:
            self._show_error(exc)
            return

        tk.Label(
            self.content,
            text="Operational snapshot",
            bg=COLORS["background"],
            fg=COLORS["muted"],
            font=("Segoe UI", 11),
        ).pack(anchor="w", pady=(0, 16))

        cards = tk.Frame(self.content, bg=COLORS["background"])
        cards.pack(fill="x")
        card_data = (
            ("Anonymized donors", counts["donors"], "#2BAE9B"),
            ("Biospecimens", counts["samples"], "#4285C5"),
            ("Test requests", counts["test_requests"], "#9A6BC1"),
        )
        for index, (label, value, color) in enumerate(card_data):
            card = tk.Frame(
                cards,
                bg=COLORS["surface"],
                highlightthickness=1,
                highlightbackground=COLORS["border"],
            )
            card.grid(row=0, column=index, sticky="nsew", padx=(0, 14 if index < 2 else 0))
            tk.Frame(card, bg=color, height=5).pack(fill="x")
            tk.Label(
                card,
                text=str(value),
                bg=COLORS["surface"],
                fg=COLORS["text"],
                font=("Segoe UI Semibold", 31),
            ).pack(anchor="w", padx=22, pady=(21, 2))
            tk.Label(
                card,
                text=label,
                bg=COLORS["surface"],
                fg=COLORS["muted"],
                font=("Segoe UI", 11),
            ).pack(anchor="w", padx=22, pady=(0, 22))
            cards.columnconfigure(index, weight=1)

        info = tk.Frame(
            self.content,
            bg=COLORS["surface"],
            highlightthickness=1,
            highlightbackground=COLORS["border"],
        )
        info.pack(fill="x", pady=24)
        tk.Label(
            info,
            text="Integrity-first workflow",
            bg=COLORS["surface"],
            fg=COLORS["text"],
            font=("Segoe UI Semibold", 15),
        ).pack(anchor="w", padx=24, pady=(20, 7))
        tk.Label(
            info,
            text=(
                "Direct identifiers are excluded. Research use is accepted only when "
                "consent is active, the researcher belongs to the project, and the "
                "aliquot has sufficient remaining quantity."
            ),
            bg=COLORS["surface"],
            fg=COLORS["muted"],
            wraplength=830,
            justify="left",
            font=("Segoe UI", 11),
        ).pack(anchor="w", padx=24, pady=(0, 22))

    def _add_search_actions(self, refresh_command: Callable[[], None]) -> None:
        entry = ttk.Entry(
            self.header_actions, textvariable=self.search_var, width=28
        )
        entry.pack(side="left", padx=(0, 8))
        entry.bind("<Return>", lambda _event: refresh_command())
        ttk.Button(
            self.header_actions, text="Search", command=refresh_command
        ).pack(side="left")

    def _build_table(
        self,
        columns: tuple[tuple[str, str, int], ...],
        rows: list[dict[str, Any]],
    ) -> ttk.Treeview:
        surface = tk.Frame(
            self.content,
            bg=COLORS["surface"],
            highlightthickness=1,
            highlightbackground=COLORS["border"],
        )
        surface.pack(fill="both", expand=True)
        tree = ttk.Treeview(
            surface,
            columns=tuple(column[0] for column in columns),
            show="headings",
            selectmode="browse",
        )
        scrollbar = ttk.Scrollbar(surface, orient="vertical", command=tree.yview)
        tree.configure(yscrollcommand=scrollbar.set)
        for key, heading, width in columns:
            tree.heading(key, text=heading)
            tree.column(key, width=width, minwidth=70, anchor="w")
        for row in rows:
            tree.insert(
                "",
                "end",
                iid=str(row[columns[0][0]]),
                values=tuple("" if row[key] is None else row[key] for key, _, _ in columns),
            )
        tree.pack(side="left", fill="both", expand=True, padx=(1, 0), pady=1)
        scrollbar.pack(side="right", fill="y", pady=1)
        self.current_tree = tree
        return tree

    def show_donors(self) -> None:
        self.current_view = "donors"
        self._clear_view("Donors")
        self._add_search_actions(self.show_donors)
        ttk.Button(
            self.header_actions,
            text="+ Add donor",
            style="Accent.TButton",
            command=self.add_donor,
        ).pack(side="left", padx=(12, 0))
        try:
            rows = self.repository.list_donors(self.search_var.get())
        except Exception as exc:
            self._show_error(exc)
            return
        columns = (
            ("donor_id", "ID", 70),
            ("donor_code", "Donor code", 115),
            ("sex_at_birth", "Sex at birth", 105),
            ("birth_year", "Birth year", 90),
            ("blood_type", "Blood", 70),
            ("ethnicity", "Ethnicity", 145),
            ("donor_status", "Status", 95),
            ("registered_on", "Registered", 105),
        )
        tree = self._build_table(columns, rows)
        tree.bind("<Double-1>", lambda _event: self.edit_selected_donor())

        actions = tk.Frame(self.content, bg=COLORS["background"])
        actions.pack(fill="x", pady=(12, 0))
        ttk.Button(
            actions, text="Edit selected", command=self.edit_selected_donor
        ).pack(side="left")
        ttk.Button(
            actions,
            text="Delete selected",
            style="Danger.TButton",
            command=self.delete_selected_donor,
        ).pack(side="left", padx=8)
        tk.Label(
            actions,
            text="Tip: double-click a row to edit. Referenced donors are protected by foreign keys.",
            bg=COLORS["background"],
            fg=COLORS["muted"],
            font=("Segoe UI", 9),
        ).pack(side="right")

    def _selected_id(self) -> int | None:
        if not self.current_tree:
            return None
        selected = self.current_tree.selection()
        return int(selected[0]) if selected else None

    def add_donor(self) -> None:
        defaults = {
            "donor_code": "BIO-D",
            "sex_at_birth": "UNKNOWN",
            "birth_year": "",
            "blood_type": "",
            "ethnicity": "Not disclosed",
            "donor_status": "ACTIVE",
            "registered_on": date.today().isoformat(),
        }

        def save(payload: dict[str, Any]) -> None:
            self.repository.create_donor(payload)
            self.after(50, self.show_donors)

        DonorDialog(self, "Add anonymized donor", defaults, save)

    def edit_selected_donor(self) -> None:
        donor_id = self._selected_id()
        if donor_id is None:
            messagebox.showinfo("Select a donor", "Select one donor row first.", parent=self)
            return
        try:
            donor = self.repository.get_donor(donor_id)
        except Exception as exc:
            self._show_error(exc)
            return
        if not donor:
            messagebox.showerror("Not found", "The donor no longer exists.", parent=self)
            return

        def save(payload: dict[str, Any]) -> None:
            self.repository.update_donor(donor_id, payload)
            self.after(50, self.show_donors)

        DonorDialog(self, f"Edit {donor['donor_code']}", donor, save)

    def delete_selected_donor(self) -> None:
        donor_id = self._selected_id()
        if donor_id is None:
            messagebox.showinfo("Select a donor", "Select one donor row first.", parent=self)
            return
        if not messagebox.askyesno(
            "Confirm delete",
            "Delete the selected donor?\n\nReferenced donor records will be protected by the database.",
            parent=self,
        ):
            return
        try:
            self.repository.delete_donor(donor_id)
        except Exception as exc:
            self._show_error(exc)
            return
        self.show_donors()

    def show_samples(self) -> None:
        self.current_view = "samples"
        self._clear_view("Sample inventory")
        self._add_search_actions(self.show_samples)
        try:
            rows = self.repository.list_samples(self.search_var.get())
        except Exception as exc:
            self._show_error(exc)
            return
        columns = (
            ("sample_id", "ID", 60),
            ("sample_code", "Sample", 110),
            ("sample_type", "Type", 160),
            ("donor_code", "Donor", 105),
            ("initial_quantity", "Quantity", 90),
            ("quantity_unit", "Unit", 65),
            ("quality_status", "Quality", 100),
            ("sample_status", "Status", 100),
            ("received_at", "Received", 155),
        )
        self._build_table(columns, rows)

    def show_test_requests(self) -> None:
        self.current_view = "tests"
        self._clear_view("Test requests")
        self._add_search_actions(self.show_test_requests)
        try:
            rows = self.repository.list_test_requests(self.search_var.get())
        except Exception as exc:
            self._show_error(exc)
            return
        columns = (
            ("test_request_id", "ID", 60),
            ("request_code", "Request", 105),
            ("sample_code", "Sample", 105),
            ("test_name", "Test", 170),
            ("requested_by", "Requested by", 165),
            ("requested_on", "Requested", 100),
            ("request_status", "Status", 105),
            ("result", "Result", 200),
        )
        self._build_table(columns, rows)


def main() -> None:
    database = Database()
    if not database.is_postgres:
        database.initialize_sqlite_demo()
    database.ping()
    app = BioVaultApp(database)
    app.mainloop()


if __name__ == "__main__":
    main()
