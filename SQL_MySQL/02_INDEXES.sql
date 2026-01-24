-- ============================================================================
-- INDEKSY - MySQL
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
-- INDEKSY NA KOLUMNACH WYSZUKIWANIA
-- ============================================================================

-- Wyszukiwanie osob po nazwisku
CREATE INDEX IDX_Osoba_Nazwisko ON Osoba(Nazwisko);
CREATE INDEX IDX_Osoba_NazwiskoImie ON Osoba(Nazwisko, Imie);

-- Wyszukiwanie zlecen po dacie
CREATE INDEX IDX_Zlecenie_DataPrzyjecia ON Zlecenie(DataPrzyjecia);
CREATE INDEX IDX_Zlecenie_DataPlanowana ON Zlecenie(DataPlanowanegoOdbioru);

-- Historia zmian po dacie
CREATE INDEX IDX_Historia_DataZmiany ON HistoriaZmian(DataZmiany);

-- Magazyn - niski stan
CREATE INDEX IDX_Magazyn_NiskiStan ON MagazynCzesc(IloscDostepna, MinStanAlarmowy);

-- Dostawy po dacie
CREATE INDEX IDX_Dostawy_Data ON Dostawy(DataDostawy);

-- Klient po dacie rejestracji
CREATE INDEX IDX_Klient_DataRejestracji ON Klient(DataRejestracji);

-- Pracownik - aktywni
CREATE INDEX IDX_Pracownik_DataZwolnienia ON Pracownik(DataZwolnienia);

-- ============================================================================
-- INDEKS NA WYRAZENIU (MySQL 8.0+) - rok zlecenia
-- ============================================================================
CREATE INDEX IDX_Zlecenie_Rok ON Zlecenie((YEAR(DataPrzyjecia)));
