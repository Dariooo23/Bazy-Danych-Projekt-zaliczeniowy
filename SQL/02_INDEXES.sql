-- ============================================================================
-- SKRYPT TWORZĄCY INDEKSY
-- System Zarządzania Warsztatem Samochodowym
-- Data utworzenia: 2026-01-18
-- ============================================================================
-- INDEKSY przyspieszają wyszukiwanie danych kosztem wolniejszych operacji
-- INSERT/UPDATE/DELETE oraz dodatkowej przestrzeni dyskowej.
-- Tworzymy indeksy na:
--   - Kolumnach kluczy obcych (FK) - przyspieszają JOIN
--   - Kolumnach często używanych w WHERE (wyszukiwanie)
--   - Kolumnach używanych w ORDER BY
-- ============================================================================

-- ============================================================================
-- INDEKSY NA KLUCZACH OBCYCH (przyspieszają JOIN i kaskadowe usuwanie)
-- ============================================================================

-- Model
CREATE INDEX IDX_Model_Marka ON Model(ID_Marki);

-- Pracownik
CREATE INDEX IDX_Pracownik_Stanowisko ON Pracownik(ID_Stanowiska);

-- Pojazd
CREATE INDEX IDX_Pojazd_Model ON Pojazd(ID_Modelu);
CREATE INDEX IDX_Pojazd_Klient ON Pojazd(ID_Klienta);

-- Zlecenie
CREATE INDEX IDX_Zlecenie_Pojazd ON Zlecenie(ID_Pojazdu);
CREATE INDEX IDX_Zlecenie_Pracownik ON Zlecenie(ID_Pracownika);
CREATE INDEX IDX_Zlecenie_Status ON Zlecenie(ID_AktualnegoStatusu);

-- HistoriaZmian
CREATE INDEX IDX_Historia_Zlecenie ON HistoriaZmian(ID_Zlecenia);
CREATE INDEX IDX_Historia_Pracownik ON HistoriaZmian(ID_Pracownika);
CREATE INDEX IDX_Historia_StatusNowy ON HistoriaZmian(ID_StatusuNowy);

-- PozycjeZlecenia_Uslugi
CREATE INDEX IDX_PozUslugi_Zlecenie ON PozycjeZlecenia_Uslugi(ID_Zlecenia);
CREATE INDEX IDX_PozUslugi_Usluga ON PozycjeZlecenia_Uslugi(ID_Uslugi);
CREATE INDEX IDX_PozUslugi_Pracownik ON PozycjeZlecenia_Uslugi(ID_Pracownika);

-- MagazynCzesc
CREATE INDEX IDX_Magazyn_Kategoria ON MagazynCzesc(ID_Kategorii);
CREATE INDEX IDX_Magazyn_Dostawca ON MagazynCzesc(ID_Dostawcy);

-- PozycjeZlecenia_Czesci
CREATE INDEX IDX_PozCzesci_Zlecenie ON PozycjeZlecenia_Czesci(ID_Zlecenia);
CREATE INDEX IDX_PozCzesci_Czesc ON PozycjeZlecenia_Czesci(ID_Czesci);

-- Dostawy
CREATE INDEX IDX_Dostawy_Czesc ON Dostawy(ID_Czesci);
CREATE INDEX IDX_Dostawy_Dostawca ON Dostawy(ID_Dostawcy);

-- ============================================================================
-- INDEKSY NA KOLUMNACH WYSZUKIWANIA (WHERE, ORDER BY)
-- ============================================================================

-- Wyszukiwanie pojazdów po VIN i numerze rejestracyjnym
-- (UNIQUE constraint automatycznie tworzy indeks, ale dodajemy dla pewności)
-- CREATE INDEX IDX_Pojazd_VIN ON Pojazd(VIN); -- już istnieje z UNIQUE
-- CREATE INDEX IDX_Pojazd_Rejestracja ON Pojazd(NrRejestracyjny); -- już istnieje

-- Wyszukiwanie osób po nazwisku (częste zapytanie)
CREATE INDEX IDX_Osoba_Nazwisko ON Osoba(Nazwisko);

-- Wyszukiwanie osób po nazwisku i imieniu (composite index)
CREATE INDEX IDX_Osoba_NazwiskoImie ON Osoba(Nazwisko, Imie);

-- Wyszukiwanie zleceń po dacie przyjęcia (raporty)
CREATE INDEX IDX_Zlecenie_DataPrzyjecia ON Zlecenie(DataPrzyjecia);

-- Wyszukiwanie zleceń po dacie planowanego odbioru (harmonogram)
CREATE INDEX IDX_Zlecenie_DataPlanowana ON Zlecenie(DataPlanowanegoOdbioru);

-- Historia zmian - wyszukiwanie po dacie (audyt)
CREATE INDEX IDX_Historia_DataZmiany ON HistoriaZmian(DataZmiany);

-- Magazyn - wyszukiwanie części o niskim stanie (alerty)
CREATE INDEX IDX_Magazyn_NiskiStan ON MagazynCzesc(IloscDostepna, MinStanAlarmowy);

-- Dostawy - wyszukiwanie po dacie (raporty)
CREATE INDEX IDX_Dostawy_Data ON Dostawy(DataDostawy);

-- Klient - wyszukiwanie po dacie rejestracji (raporty)
CREATE INDEX IDX_Klient_DataRejestracji ON Klient(DataRejestracji);

-- Pracownik - wyszukiwanie aktywnych pracowników
CREATE INDEX IDX_Pracownik_DataZwolnienia ON Pracownik(DataZwolnienia);

-- ============================================================================
-- INDEKS FUNKCYJNY - wyszukiwanie po roku zlecenia
-- ============================================================================
CREATE INDEX IDX_Zlecenie_Rok ON Zlecenie(EXTRACT(YEAR FROM DataPrzyjecia));

-- ============================================================================
-- PODSUMOWANIE UTWORZONYCH INDEKSÓW
-- ============================================================================
-- Łącznie: 24 indeksów
-- - 18 indeksów na kluczach obcych (FK)
-- - 5 indeksów na kolumnach wyszukiwania
-- - 1 indeks funkcyjny
-- ============================================================================
