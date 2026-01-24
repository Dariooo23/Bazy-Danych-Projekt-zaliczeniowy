import tkinter as tk
from tkinter import ttk, messagebox
import mysql.connector

# --- KONFIGURACJA BAZY ---
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "123",
    "database": "warsztat"
}

# --- POŁĄCZENIE ---
def connect_db():
    return mysql.connector.connect(**DB_CONFIG)

# --- APLIKACJA ---
class MySQLGui:
    def __init__(self, root):
        self.root = root
        self.root.title("MySQL GUI")

        self.conn = connect_db()
        self.cursor = self.conn.cursor()

        self.table_name = tk.StringVar()

        self.create_widgets()
        self.load_tables()

    def create_widgets(self):
        top = tk.Frame(self.root)
        top.pack(pady=5)

        tk.Label(top, text="Tabela:").pack(side=tk.LEFT)
        self.table_combo = ttk.Combobox(top, textvariable=self.table_name)
        self.table_combo.pack(side=tk.LEFT)
        self.table_combo.bind("<<ComboboxSelected>>", lambda e: self.load_data())

        # tabela danych
        self.tree = ttk.Treeview(self.root)
        self.tree.pack(expand=True, fill=tk.BOTH)

        btns = tk.Frame(self.root)
        btns.pack(pady=5)

        tk.Button(btns, text="Dodaj", command=self.add_row).pack(side=tk.LEFT, padx=5)
        tk.Button(btns, text="Edytuj", command=self.edit_row).pack(side=tk.LEFT, padx=5)
        tk.Button(btns, text="Usuń", command=self.delete_row).pack(side=tk.LEFT, padx=5)

    # --- TABELKI ---
    def load_tables(self):
        self.cursor.execute("SHOW TABLES")
        tables = [t[0] for t in self.cursor.fetchall()]
        self.table_combo["values"] = tables
        print(tables)

    def load_data(self):
        table = self.table_name.get()
        if not table:
            return
        self.cursor.execute(f"SELECT * FROM `{table}`")
        rows = self.cursor.fetchall()
        columns = [desc[0] for desc in self.cursor.description]

        self.tree.delete(*self.tree.get_children())
        self.tree["columns"] = columns
        self.tree["show"] = "headings"

        for col in columns:
            self.tree.heading(col, text=col)

        for row in rows:
            self.tree.insert("", tk.END, values=row)

    # --- CRUD ---
    def add_row(self):
        self.open_editor("Dodaj wiersz")

    def edit_row(self):
        selected = self.tree.selection()
        if not selected:
            messagebox.showwarning("Błąd", "Zaznacz wiersz")
            return
        item = selected[0]
        values = self.tree.item(item)["values"]
        self.open_editor("Edytuj wiersz", values)

    def delete_row(self):
        selected = self.tree.selection()
        if not selected:
            return
        item = selected[0]
        values = self.tree.item(item)["values"]
        table = self.table_name.get()

        # pobierz opis tabeli by znaleźć kolumny i klucze główne
        self.cursor.execute(f"DESCRIBE `{table}`")
        descs = self.cursor.fetchall()
        columns = [c[0] for c in descs]

        # znajdź wszystkie kolumny PK
        pk_cols = [d[0] for d in descs if len(d) >= 4 and d[3] == 'PRI']

        if pk_cols:
            where_cols = pk_cols
            where_vals = [values[columns.index(c)] for c in where_cols]
        else:
            where_cols = columns
            where_vals = list(values)

        where_clause = ' AND '.join(f"`{c}` <=> %s" for c in where_cols)
        query = f"DELETE FROM `{table}` WHERE {where_clause} LIMIT 1"
        print(query, where_vals)
        try:
            self.cursor.execute(query, where_vals)
            self.conn.commit()
        except mysql.connector.Error as err:
            self._handle_db_error(err)
            return
        self.load_data()

    def _handle_db_error(self, err):
        try:
            self.conn.rollback()
        except Exception:
            pass
        msg = str(err)
        sqlstate = getattr(err, 'sqlstate', None)
        if sqlstate == '23000' and 'check' in msg.lower():
            messagebox.showerror("Błąd CHECK", "Nie spełniono ograniczenia CHECK:\n" + msg)
        else:
            messagebox.showerror("Błąd bazy danych", msg)

    def open_editor(self, title, values=None):
        table = self.table_name.get()
        # (DESCRIBE zwraca: Field, Type, Null, Key, Default, Extra)
        self.cursor.execute(f"DESCRIBE `{table}`")
        descs = self.cursor.fetchall()
        columns = [c[0] for c in descs]

        null_allowed = {c[0]: (len(c) >= 3 and c[2] == 'YES') for c in descs}

        pk = None
        pk_extra = ''
        for d in descs:
            if len(d) >= 4 and d[3] == 'PRI':
                pk = d[0]
                pk_extra = d[5] if len(d) >= 6 else ''
                break

        win = tk.Toplevel(self.root)
        win.title(title)

        entries = {}

        val_map = dict(zip(columns, values)) if values else {}

        for i, col in enumerate(columns):
            tk.Label(win, text=col).grid(row=i, column=0)
            e = tk.Entry(win)
            e.grid(row=i, column=1)
            if values:
                v = val_map.get(col, '')
                e.insert(0, '' if v is None else v)
            entries[col] = e

        def _to_param(col, raw_val):
            if raw_val == '' and null_allowed.get(col, False):
                return None
            return raw_val

        def save():
            try:
                if values:
                    if pk:
                        set_cols = [c for c in columns if c != pk]
                        if not set_cols:
                            messagebox.showwarning("Błąd", "Brak kolumn do aktualizacji")
                            return
                        query = f"UPDATE `{table}` SET " + ', '.join(f"`{c}`=%s" for c in set_cols) + f" WHERE `{pk}`=%s"
                        params = [_to_param(c, entries[c].get()) for c in set_cols] + [_to_param(pk, entries[pk].get())]
                        print(query, params)
                        self.cursor.execute(query, params)
                    else:
                        set_cols = columns[:]
                        if not set_cols:
                            messagebox.showwarning("Błąd", "Brak kolumn do aktualizacji")
                            return
                        where_clause = ' AND '.join(f"`{c}` <=> %s" for c in columns)
                        query = f"UPDATE `{table}` SET " + ', '.join(f"`{c}`=%s" for c in set_cols) + f" WHERE {where_clause}"
                        params = [_to_param(c, entries[c].get()) for c in set_cols] + list(values)
                        print(query, params)
                        self.cursor.execute(query, params)
                else:
                    insert_cols = columns[:]
                    if pk and 'auto_increment' in (next((d[5] for d in descs if d[0] == pk), '') or ''):
                        insert_cols = [c for c in columns if c != pk]
                    cols_sql = ','.join(f"`{c}`" for c in insert_cols)
                    placeholders = ','.join(['%s'] * len(insert_cols))
                    params = [_to_param(c, entries[c].get()) for c in insert_cols]
                    query = f"INSERT INTO `{table}` ({cols_sql}) VALUES ({placeholders})"
                    print(query, params)
                    self.cursor.execute(query, params)

                self.conn.commit()
            except mysql.connector.Error as err:
                self._handle_db_error(err)
                return

            win.destroy()
            self.load_data()

        tk.Button(win, text="Zapisz", command=save).grid(columnspan=2)

# --- START ---
root = tk.Tk()
app = MySQLGui(root)
root.mainloop()



