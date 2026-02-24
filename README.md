# 🔧 System Zarządzania Warsztatem Samochodowym

> Projekt zaliczeniowy z przedmiotu **Bazy Danych** — kompleksowy system do obsługi warsztatu samochodowego zbudowany w MySQL 8.0+ z graficznym interfejsem w Pythonie.

**Autorzy:** Karol Dziekan, Krzysztof Cholewa · Styczeń 2026

---

## 📋 O projekcie

System umożliwia pełne zarządzanie warsztatem samochodowym — od rejestracji klientów i ich pojazdów, przez obsługę zleceń serwisowych, aż po kontrolę stanów magazynowych i generowanie raportów. Projekt obejmuje:

- **17 tabel** z rozbudowanym systemem więzów integralności (CHECK, UNIQUE, FK)
- **Dziedziczenie tabel** (Class Table Inheritance) — Osoba → Klient / Pracownik
- **7 widoków** (raporty, aktywne zlecenia, niskie stany magazynowe)
- **4 funkcje** (generowanie numerów, obliczanie wartości, rabaty)
- **6 procedur składowanych** (CRUD zleceń, zarządzanie dostawami)
- **6 triggerów** (automatyczne numerowanie, alerty magazynowe, walidacja)
- **Indeksy** na kluczach obcych i kolumnach wyszukiwania (w tym indeks na wyrażeniu)
- **GUI** w Pythonie (Tkinter) do przeglądania i edycji danych

---

## 🗂️ Struktura projektu

```
├── MySQL/                         # Skrypty SQL
│   ├── 00_INSTALL_ALL.sql         # Skrypt instalacyjny (uruchamia wszystko)
│   ├── 01_CREATE_DATABASE.sql     # Tworzenie 17 tabel z więzami
│   ├── 02_INDEXES.sql             # Indeksy (FK + wyszukiwanie)
│   ├── 03_VIEWS_FUNCTIONS.sql     # 7 widoków + 4 funkcje
│   ├── 04_PROCEDURES.sql          # 6 procedur składowanych
│   ├── 05_TRIGGERS.sql            # 6 triggerów
│   └── 06_TEST_DATA.sql           # Dane testowe
├── GUI/
│   └── GUI.py                     # Interfejs graficzny (Tkinter)
├── Diagramy/                      # Pliki Oracle SQL Data Modeler
└── Warsztat.md                    # Pełna dokumentacja projektu
```

---

## 🏗️ Schemat bazy danych

### Tabele (17)

| Grupa | Tabele | Opis |
|-------|--------|------|
| **Osoby** | `Osoba` → `Klient`, `Pracownik` | Dziedziczenie — wspólne dane osobowe + specjalizacja |
| **Pojazdy** | `Marka`, `Model`, `Pojazd` | Słownik marek/modeli + pojazdy klientów (VIN, rejestracja) |
| **Zlecenia** | `Zlecenie`, `StatusyZlecen`, `HistoriaZmian` | Obsługa zleceń z pełną historią zmian statusów |
| **Usługi** | `KatalogUslug`, `PozycjeZlecenia_Uslugi` | Katalog usług z cenami + pozycje przypisane do zleceń |
| **Magazyn** | `KategoriaCzesci`, `MagazynCzesc`, `PozycjeZlecenia_Czesci` | Części zamienne z kontrolą stanów |
| **Dostawy** | `Dostawca`, `Dostawy` | Rejestracja dostaw od dostawców |
| **Kadry** | `Stanowisko` | Słownik stanowisk pracowniczych |

### Kluczowe mechanizmy

- **Historia zmian statusów** — każda zmiana statusu zlecenia jest logowana z timestampem i autorem (atrybuty zmienne w czasie)
- **Automatyczne numerowanie** — trigger generuje numery zleceń w formacie `ZLC/RRRR/NNNNN`
- **Kontrola magazynu** — trigger loguje alerty gdy stan części spada poniżej minimum
- **System rabatowy** — automatyczne naliczanie rabatów stałych klientów
- **Walidacja danych** — constrainty CHECK na: PESEL, NIP, email, kod pocztowy, VIN, nr rejestracyjny

---

## 🚀 Instalacja i uruchomienie

### Wymagania
- **MySQL 8.0+**
- **Python 3.x** + `mysql-connector-python` (dla GUI)

### Baza danych

```bash
# Opcja 1 — pełna instalacja jednym skryptem
cd MySQL
mysql -u root -p < 00_INSTALL_ALL.sql

# Opcja 2 — krok po kroku
mysql -u root -p < 01_CREATE_DATABASE.sql
mysql -u root -p warsztat < 02_INDEXES.sql
mysql -u root -p warsztat < 03_VIEWS_FUNCTIONS.sql
mysql -u root -p warsztat < 04_PROCEDURES.sql
mysql -u root -p warsztat < 05_TRIGGERS.sql
mysql -u root -p warsztat < 06_TEST_DATA.sql
```

### GUI

```bash
pip install mysql-connector-python
python GUI/GUI.py
```

> **Uwaga:** Konfiguracja połączenia z bazą znajduje się na początku pliku `GUI/GUI.py` — domyślnie `localhost`, użytkownik `root`.

---

## 📊 Przykładowe widoki i procedury

### Widoki
| Widok | Opis |
|-------|------|
| `v_ZleceniaAktywne` | Aktywne zlecenia z danymi klienta i pojazdu |
| `v_PojazdyKlientow` | Pojazdy z właścicielami i liczbą zleceń |
| `v_MagazynNiskiStan` | Części poniżej minimalnego stanu alarmowego |
| `v_PracownicyAktywni` | Aktywni pracownicy ze statystykami |
| `v_HistoriaZlecenia` | Pełna historia zmian statusów |
| `v_SzczegolyZlecenia` | Szczegóły zlecenia z kosztami usług i części |
| `v_RaportMiesieczny` | Podsumowanie miesięczne (przychody, liczba zleceń) |

### Procedury składowane
| Procedura | Opis |
|-----------|------|
| `sp_NoweZlecenie` | Tworzenie zlecenia z automatycznym numerowaniem |
| `sp_ZmienStatusZlecenia` | Zmiana statusu z rejestracją w historii |
| `sp_DodajUslugeDoZlecenia` | Dodanie usługi do zlecenia |
| `sp_DodajCzescDoZlecenia` | Dodanie części z kontrolą stanów magazynowych |
| `sp_RejestrujDostawe` | Rejestracja dostawy z aktualizacją magazynu |
| `sp_ZamknijZlecenie` | Zamknięcie zlecenia z przeliczeniem kosztów |

---

## 🛠️ Technologie

- **MySQL 8.0** — baza danych (InnoDB, utf8mb4, indeksy na wyrażeniach)
- **Python 3** + **Tkinter** — interfejs graficzny
- **Oracle SQL Data Modeler** — projektowanie diagramów ER i relacji
