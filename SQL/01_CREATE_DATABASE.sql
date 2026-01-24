-- Usuwanie tabel (jeśli istnieją)
BEGIN
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN (
        'DOSTAWY', 'POZYCJEZLECENIA_CZESCI', 'POZYCJEZLECENIA_USLUGI', 
        'HISTORIAZLIAN', 'ZLECENIE', 'POJAZD', 'MAGAZYNCZESC', 
        'PRACOWNIK', 'KLIENT', 'MODEL', 'OSOBA', 'STANOWISKO', 
        'STATUSYZLECEN', 'KATALOGUSLUG', 'KATEGORIACZESCI', 'MARKA', 'DOSTAWCA'
    )) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

-- Usuwanie sekwencji (jeśli istnieją)
BEGIN
    FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'SEQ_%') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- ============================================================================
-- TWORZENIE SEKWENCJI (AUTO-INCREMENT)
-- ============================================================================

CREATE SEQUENCE SEQ_MARKA START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_MODEL START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_OSOBA START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_STANOWISKO START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_POJAZD START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_STATUSYZLECEN START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_ZLECENIE START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_HISTORIAZMIAN START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_KATALOGUSLUG START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_POZYCJEZLECENIA_USLUGI START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_KATEGORIACZESCI START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_MAGAZYNCZESC START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_POZYCJEZLECENIA_CZESCI START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_DOSTAWCA START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_DOSTAWY START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_NUMER_ZLECENIA START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ============================================================================
-- TABELA 1: MARKA
-- Przechowuje informacje o markach pojazdów
-- ============================================================================
CREATE TABLE Marka (
    ID_Marki            NUMBER(10)      NOT NULL,
    NazwaMarki          VARCHAR2(50)    NOT NULL,
    KrajPochodzenia     VARCHAR2(50)    NULL,
    
    -- Klucz główny
    CONSTRAINT PK_Marka PRIMARY KEY (ID_Marki),
    
    -- Ograniczenia unikalności
    CONSTRAINT UQ_Marka_Nazwa UNIQUE (NazwaMarki),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Marka_Nazwa CHECK (LENGTH(TRIM(NazwaMarki)) >= 2)
);

COMMENT ON TABLE Marka IS 'Tabela przechowująca marki pojazdów';
COMMENT ON COLUMN Marka.ID_Marki IS 'Unikalny identyfikator marki';
COMMENT ON COLUMN Marka.NazwaMarki IS 'Nazwa marki pojazdu';
COMMENT ON COLUMN Marka.KrajPochodzenia IS 'Kraj pochodzenia marki';

-- ============================================================================
-- TABELA 2: MODEL
-- Przechowuje informacje o modelach pojazdów
-- ============================================================================
CREATE TABLE Model (
    ID_Modelu           NUMBER(10)      NOT NULL,
    NazwaModelu         VARCHAR2(50)    NOT NULL,
    RokProdukcjiOd      NUMBER(4)       NULL,
    RokProdukcjiDo      NUMBER(4)       NULL,
    ID_Marki            NUMBER(10)      NOT NULL,
    
    -- Klucz główny
    CONSTRAINT PK_Model PRIMARY KEY (ID_Modelu),
    
    -- Ograniczenia unikalności
    CONSTRAINT UQ_Model_Marka_Nazwa UNIQUE (ID_Marki, NazwaModelu),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Model_Nazwa CHECK (LENGTH(TRIM(NazwaModelu)) >= 1),
    CONSTRAINT CHK_Model_RokOd CHECK (RokProdukcjiOd IS NULL OR (RokProdukcjiOd >= 1886 AND RokProdukcjiOd <= 2100)),
    CONSTRAINT CHK_Model_RokDo CHECK (RokProdukcjiDo IS NULL OR (RokProdukcjiDo >= 1886 AND RokProdukcjiDo <= 2100)),
    CONSTRAINT CHK_Model_Lata CHECK (RokProdukcjiOd IS NULL OR RokProdukcjiDo IS NULL OR RokProdukcjiOd <= RokProdukcjiDo)
);

COMMENT ON TABLE Model IS 'Tabela przechowująca modele pojazdów';
COMMENT ON COLUMN Model.RokProdukcjiOd IS 'Rok rozpoczęcia produkcji modelu';
COMMENT ON COLUMN Model.RokProdukcjiDo IS 'Rok zakończenia produkcji modelu (NULL = nadal produkowany)';

-- ============================================================================
-- TABELA 3: STANOWISKO
-- Przechowuje informacje o stanowiskach pracy
-- ============================================================================
CREATE TABLE Stanowisko (
    ID_Stanowiska       NUMBER(10)          NOT NULL,
    NazwaStanowiska     VARCHAR2(50)        NOT NULL,
    Opis                VARCHAR2(255)       NULL,
    StawkaGodzinowa     NUMBER(10,2)        NOT NULL,
    
    -- Klucz główny
    CONSTRAINT PK_Stanowisko PRIMARY KEY (ID_Stanowiska),
    
    -- Ograniczenia unikalności
    CONSTRAINT UQ_Stanowisko_Nazwa UNIQUE (NazwaStanowiska),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Stanowisko_Stawka CHECK (StawkaGodzinowa >= 0)
);

COMMENT ON TABLE Stanowisko IS 'Tabela przechowująca stanowiska pracy w warsztacie';

-- ============================================================================
-- TABELA 4: OSOBA (NADTYP - Class Table Inheritance)
-- Przechowuje wspólne dane osób (klientów i pracowników)
-- Jest to tabela nadrzędna w hierarchii dziedziczenia
-- ============================================================================
CREATE TABLE Osoba (
    ID_Osoby            NUMBER(10)          NOT NULL,
    Imie                VARCHAR2(50)        NOT NULL,
    Nazwisko            VARCHAR2(50)        NOT NULL,
    Telefon             VARCHAR2(15)        NOT NULL,
    Email               VARCHAR2(100)       NULL,
    Ulica               VARCHAR2(100)       NULL,
    Miasto              VARCHAR2(50)        NULL,
    KodPocztowy         VARCHAR2(10)        NULL,
    
    -- Klucz główny
    CONSTRAINT PK_Osoba PRIMARY KEY (ID_Osoby),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Osoba_Imie CHECK (LENGTH(TRIM(Imie)) >= 2),
    CONSTRAINT CHK_Osoba_Nazwisko CHECK (LENGTH(TRIM(Nazwisko)) >= 2),
    CONSTRAINT CHK_Osoba_Telefon CHECK (REGEXP_LIKE(Telefon, '^\+?[0-9\s\-]{9,15}$')),
    CONSTRAINT CHK_Osoba_Email CHECK (Email IS NULL OR REGEXP_LIKE(Email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    CONSTRAINT CHK_Osoba_KodPocztowy CHECK (KodPocztowy IS NULL OR REGEXP_LIKE(KodPocztowy, '^[0-9]{2}-[0-9]{3}$'))
);

COMMENT ON TABLE Osoba IS 'Tabela nadrzędna w hierarchii dziedziczenia (Class Table Inheritance) - wspólne dane dla Klient i Pracownik';
COMMENT ON COLUMN Osoba.ID_Osoby IS 'Unikalny identyfikator osoby - klucz główny dziedziczony przez podtypy';

-- ============================================================================
-- TABELA 5: KLIENT (PODTYP - dziedziczy z OSOBA)
-- Przechowuje dane specyficzne dla klientów
-- Relacja 1:1 z tabelą Osoba (ten sam PK)
-- ============================================================================
CREATE TABLE Klient (
    ID_Osoby            NUMBER(10)          NOT NULL,
    NIP                 VARCHAR2(15)        NULL,
    DataRejestracji     DATE                DEFAULT SYSDATE NOT NULL,
    RabatStaly          NUMBER(5,2)         DEFAULT 0,
    
    -- Klucz główny (ten sam co w Osoba - realizacja dziedziczenia)
    CONSTRAINT PK_Klient PRIMARY KEY (ID_Osoby),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Klient_NIP CHECK (NIP IS NULL OR REGEXP_LIKE(NIP, '^[0-9]{10}$')),
    CONSTRAINT CHK_Klient_Rabat CHECK (RabatStaly >= 0 AND RabatStaly <= 100)
);

COMMENT ON TABLE Klient IS 'Tabela podrzędna (podtyp) - dane specyficzne dla klientów. Dziedziczy z Osoba poprzez wspólny klucz główny';
COMMENT ON COLUMN Klient.ID_Osoby IS 'Klucz główny i obcy do tabeli Osoba - realizacja dziedziczenia 1:1';
COMMENT ON COLUMN Klient.RabatStaly IS 'Stały rabat dla klienta w procentach (0-100)';

-- ============================================================================
-- TABELA 6: PRACOWNIK (PODTYP - dziedziczy z OSOBA)
-- Przechowuje dane specyficzne dla pracowników
-- Relacja 1:1 z tabelą Osoba (ten sam PK)
-- ============================================================================
CREATE TABLE Pracownik (
    ID_Osoby            NUMBER(10)          NOT NULL,
    DataZatrudnienia    DATE                NOT NULL,
    DataZwolnienia      DATE                NULL,
    PensjaPodstawowa    NUMBER(10,2)        NOT NULL,
    NrKontaBankowego    VARCHAR2(32)        NOT NULL,
    ID_Stanowiska       NUMBER(10)          NOT NULL,
    
    -- Klucz główny (ten sam co w Osoba - realizacja dziedziczenia)
    CONSTRAINT PK_Pracownik PRIMARY KEY (ID_Osoby),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Pracownik_Pensja CHECK (PensjaPodstawowa >= 0),
    CONSTRAINT CHK_Pracownik_Konto CHECK (REGEXP_LIKE(NrKontaBankowego, '^[0-9]{26}$')),
    CONSTRAINT CHK_Pracownik_Daty CHECK (DataZwolnienia IS NULL OR DataZwolnienia >= DataZatrudnienia)
);

COMMENT ON TABLE Pracownik IS 'Tabela podrzędna (podtyp) - dane specyficzne dla pracowników. Dziedziczy z Osoba poprzez wspólny klucz główny';
COMMENT ON COLUMN Pracownik.ID_Osoby IS 'Klucz główny i obcy do tabeli Osoba - realizacja dziedziczenia 1:1';

-- ============================================================================
-- TABELA 7: POJAZD
-- Przechowuje informacje o pojazdach klientów
-- ============================================================================
CREATE TABLE Pojazd (
    ID_Pojazdu          NUMBER(10)          NOT NULL,
    VIN                 VARCHAR2(17)        NOT NULL,
    NrRejestracyjny     VARCHAR2(10)        NOT NULL,
    RokProdukcji        NUMBER(4)           NULL,
    PojemnoscSilnika    NUMBER(5)           NULL,      -- w cm³
    ID_Modelu           NUMBER(10)          NOT NULL,
    ID_Klienta          NUMBER(10)          NOT NULL,  -- właściciel (klient)
    
    -- Klucz główny
    CONSTRAINT PK_Pojazd PRIMARY KEY (ID_Pojazdu),
    
    -- Ograniczenia unikalności
    CONSTRAINT UQ_Pojazd_VIN UNIQUE (VIN),
    CONSTRAINT UQ_Pojazd_Rejestracja UNIQUE (NrRejestracyjny),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Pojazd_VIN CHECK (LENGTH(VIN) = 17 AND REGEXP_LIKE(VIN, '^[A-HJ-NPR-Z0-9]{17}$')),
    CONSTRAINT CHK_Pojazd_Rejestracja CHECK (REGEXP_LIKE(NrRejestracyjny, '^[A-Z0-9]{4,8}$')),
    CONSTRAINT CHK_Pojazd_Rok CHECK (RokProdukcji IS NULL OR (RokProdukcji >= 1886 AND RokProdukcji <= 2030)),
    CONSTRAINT CHK_Pojazd_Pojemnosc CHECK (PojemnoscSilnika IS NULL OR (PojemnoscSilnika >= 50 AND PojemnoscSilnika <= 20000))
);

COMMENT ON TABLE Pojazd IS 'Tabela przechowująca pojazdy klientów warsztatu';
COMMENT ON COLUMN Pojazd.VIN IS 'Unikalny 17-znakowy numer identyfikacyjny pojazdu (bez liter I, O, Q)';
COMMENT ON COLUMN Pojazd.PojemnoscSilnika IS 'Pojemność silnika w centymetrach sześciennych';
COMMENT ON COLUMN Pojazd.ID_Klienta IS 'Właściciel pojazdu - klucz obcy do tabeli Klient';

-- ============================================================================
-- TABELA 8: STATUSYZLECEN
-- Słownik statusów zleceń
-- ============================================================================
CREATE TABLE StatusyZlecen (
    ID_Statusu          NUMBER(10)          NOT NULL,
    NazwaStatusu        VARCHAR2(50)        NOT NULL,
    Opis                VARCHAR2(255)       NULL,
    KolejnoscWyswietlania NUMBER(3)         DEFAULT 0,
    CzyAktywny          CHAR(1)             DEFAULT 'T',
    
    -- Klucz główny
    CONSTRAINT PK_StatusyZlecen PRIMARY KEY (ID_Statusu),
    
    -- Ograniczenia unikalności
    CONSTRAINT UQ_StatusyZlecen_Nazwa UNIQUE (NazwaStatusu),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_StatusyZlecen_Aktywny CHECK (CzyAktywny IN ('T', 'N'))
);

COMMENT ON TABLE StatusyZlecen IS 'Słownik statusów zleceń serwisowych';

-- ============================================================================
-- TABELA 9: ZLECENIE
-- Przechowuje zlecenia serwisowe
-- ============================================================================
CREATE TABLE Zlecenie (
    ID_Zlecenia             NUMBER(10)          NOT NULL,
    NumerZlecenia           VARCHAR2(20)        NOT NULL,
    DataPrzyjecia           DATE                DEFAULT SYSDATE NOT NULL,
    DataPlanowanegoOdbioru  DATE                NULL,
    DataRzeczywistegOdbioru DATE                NULL,
    OpisUsterki             CLOB                NOT NULL,
    Uwagi                   VARCHAR2(1000)      NULL,
    KosztCalkowity          NUMBER(12,2)        DEFAULT 0,
    ID_Pojazdu              NUMBER(10)          NOT NULL,
    ID_Pracownika           NUMBER(10)          NOT NULL,  -- pracownik przyjmujący
    ID_AktualnegoStatusu    NUMBER(10)          NOT NULL,
    
    -- Klucz główny
    CONSTRAINT PK_Zlecenie PRIMARY KEY (ID_Zlecenia),
    
    -- Ograniczenia unikalności
    CONSTRAINT UQ_Zlecenie_Numer UNIQUE (NumerZlecenia),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Zlecenie_Numer CHECK (REGEXP_LIKE(NumerZlecenia, '^ZLC/[0-9]{4}/[0-9]{5}$')),
    CONSTRAINT CHK_Zlecenie_DataOdbioru CHECK (DataPlanowanegoOdbioru IS NULL OR DataPlanowanegoOdbioru >= DataPrzyjecia),
    CONSTRAINT CHK_Zlecenie_DataRzeczywista CHECK (DataRzeczywistegOdbioru IS NULL OR DataRzeczywistegOdbioru >= DataPrzyjecia),
    CONSTRAINT CHK_Zlecenie_Koszt CHECK (KosztCalkowity >= 0)
);

COMMENT ON TABLE Zlecenie IS 'Tabela przechowująca zlecenia serwisowe';
COMMENT ON COLUMN Zlecenie.NumerZlecenia IS 'Format: ZLC/RRRR/NNNNN (np. ZLC/2026/00001)';
COMMENT ON COLUMN Zlecenie.ID_Pracownika IS 'Pracownik przyjmujący zlecenie';

-- ============================================================================
-- TABELA 10: HISTORIAZLIAN (atrybuty zmieniające się w czasie)
-- Przechowuje historię zmian statusów zleceń
-- REALIZUJE WYMAGANIE: dane dotyczące atrybutów, których wartość zmienia się w czasie
-- ============================================================================
CREATE TABLE HistoriaZmian (
    ID_Historii         NUMBER(10)          NOT NULL,
    DataZmiany          TIMESTAMP           DEFAULT SYSTIMESTAMP NOT NULL,
    Komentarz           VARCHAR2(500)       NULL,
    ID_Zlecenia         NUMBER(10)          NOT NULL,
    ID_StatusuPoprzedni NUMBER(10)          NULL,      -- NULL dla pierwszego wpisu
    ID_StatusuNowy      NUMBER(10)          NOT NULL,
    ID_Pracownika       NUMBER(10)          NOT NULL,  -- kto dokonał zmiany
    
    -- Klucz główny
    CONSTRAINT PK_HistoriaZmian PRIMARY KEY (ID_Historii)
);

COMMENT ON TABLE HistoriaZmian IS 'Tabela przechowująca historię zmian statusów zleceń - REALIZUJE WYMAGANIE atrybutów zmieniających się w czasie';
COMMENT ON COLUMN HistoriaZmian.ID_StatusuPoprzedni IS 'Poprzedni status (NULL dla nowego zlecenia)';
COMMENT ON COLUMN HistoriaZmian.ID_StatusuNowy IS 'Nowy status zlecenia';
COMMENT ON COLUMN HistoriaZmian.ID_Pracownika IS 'Pracownik dokonujący zmiany statusu';

-- ============================================================================
-- TABELA 11: KATALOGUSLUG
-- Katalog usług oferowanych przez warsztat
-- ============================================================================
CREATE TABLE KatalogUslug (
    ID_Uslugi           NUMBER(10)          NOT NULL,
    NazwaUslugi         VARCHAR2(100)       NOT NULL,
    Opis                VARCHAR2(500)       NULL,
    CenaBazowa          NUMBER(10,2)        NULL,
    SzacowanyCzasRbh    NUMBER(5,2)         NULL,      -- w roboczogodzinach
    CzyAktywna          CHAR(1)             DEFAULT 'T',
    
    -- Klucz główny
    CONSTRAINT PK_KatalogUslug PRIMARY KEY (ID_Uslugi),
    
    -- Ograniczenia unikalności
    CONSTRAINT UQ_KatalogUslug_Nazwa UNIQUE (NazwaUslugi),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_KatalogUslug_Cena CHECK (CenaBazowa IS NULL OR CenaBazowa >= 0),
    CONSTRAINT CHK_KatalogUslug_Czas CHECK (SzacowanyCzasRbh IS NULL OR SzacowanyCzasRbh >= 0),
    CONSTRAINT CHK_KatalogUslug_Aktywna CHECK (CzyAktywna IN ('T', 'N'))
);

COMMENT ON TABLE KatalogUslug IS 'Katalog usług serwisowych oferowanych przez warsztat';
COMMENT ON COLUMN KatalogUslug.SzacowanyCzasRbh IS 'Szacowany czas wykonania w roboczogodzinach';

-- ============================================================================
-- TABELA 12: POZYCJEZLECENIA_USLUGI
-- Pozycje zleceń - usługi
-- ============================================================================
CREATE TABLE PozycjeZlecenia_Uslugi (
    ID_PozycjiUslugi    NUMBER(10)          NOT NULL,
    Krotnosc            NUMBER(5)           DEFAULT 1 NOT NULL,
    RabatNaUsluge       NUMBER(5,2)         DEFAULT 0,
    CenaJednostkowa     NUMBER(10,2)        NOT NULL,
    CenaKoncowa         NUMBER(12,2)        NOT NULL,
    ID_Zlecenia         NUMBER(10)          NOT NULL,
    ID_Uslugi           NUMBER(10)          NOT NULL,
    ID_Pracownika       NUMBER(10)          NULL,      -- pracownik wykonujący
    
    -- Klucz główny
    CONSTRAINT PK_PozycjeZlecenia_Uslugi PRIMARY KEY (ID_PozycjiUslugi),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_PozUslugi_Krotnosc CHECK (Krotnosc >= 1),
    CONSTRAINT CHK_PozUslugi_Rabat CHECK (RabatNaUsluge >= 0 AND RabatNaUsluge <= 100),
    CONSTRAINT CHK_PozUslugi_CenaJedn CHECK (CenaJednostkowa >= 0),
    CONSTRAINT CHK_PozUslugi_CenaKonc CHECK (CenaKoncowa >= 0)
);

COMMENT ON TABLE PozycjeZlecenia_Uslugi IS 'Pozycje zleceń - wykonane usługi';
COMMENT ON COLUMN PozycjeZlecenia_Uslugi.ID_Pracownika IS 'Pracownik wykonujący usługę';

-- ============================================================================
-- TABELA 13: KATEGORIACZESCI
-- Kategorie części zamiennych
-- ============================================================================
CREATE TABLE KategoriaCzesci (
    ID_Kategorii        NUMBER(10)          NOT NULL,
    NazwaKategorii      VARCHAR2(50)        NOT NULL,
    Opis                VARCHAR2(255)       NULL,
    
    -- Klucz główny
    CONSTRAINT PK_KategoriaCzesci PRIMARY KEY (ID_Kategorii),
    
    -- Ograniczenia unikalności
    CONSTRAINT UQ_KategoriaCzesci_Nazwa UNIQUE (NazwaKategorii)
);

COMMENT ON TABLE KategoriaCzesci IS 'Kategorie części zamiennych';

-- ============================================================================
-- TABELA 14: DOSTAWCA
-- Dostawcy części zamiennych
-- ============================================================================
CREATE TABLE Dostawca (
    ID_Dostawcy         NUMBER(10)          NOT NULL,
    NazwaFirmy          VARCHAR2(100)       NOT NULL,
    Adres               VARCHAR2(150)       NOT NULL,
    Telefon             VARCHAR2(20)        NOT NULL,
    Email               VARCHAR2(100)       NULL,
    NIP                 VARCHAR2(15)        NOT NULL,
    OsobaKontaktowa     VARCHAR2(100)       NULL,
    CzyAktywny          CHAR(1)             DEFAULT 'T',
    
    -- Klucz główny
    CONSTRAINT PK_Dostawca PRIMARY KEY (ID_Dostawcy),
    
    -- Ograniczenia unikalności
    CONSTRAINT UQ_Dostawca_NIP UNIQUE (NIP),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Dostawca_NIP CHECK (REGEXP_LIKE(NIP, '^[0-9]{10}$')),
    CONSTRAINT CHK_Dostawca_Email CHECK (Email IS NULL OR REGEXP_LIKE(Email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    CONSTRAINT CHK_Dostawca_Aktywny CHECK (CzyAktywny IN ('T', 'N'))
);

COMMENT ON TABLE Dostawca IS 'Dostawcy części zamiennych';

-- ============================================================================
-- TABELA 15: MAGAZYNCZESC
-- Magazyn części zamiennych
-- ============================================================================
CREATE TABLE MagazynCzesc (
    ID_Czesci           NUMBER(10)          NOT NULL,
    NazwaCzesci         VARCHAR2(100)       NOT NULL,
    KodProducenta       VARCHAR2(50)        NOT NULL,
    Cena_Zakupu         NUMBER(10,2)        NOT NULL,
    CenaSprzedazy       NUMBER(10,2)        NOT NULL,
    IloscDostepna       NUMBER(10)          DEFAULT 0 NOT NULL,
    MinStanAlarmowy     NUMBER(10)          DEFAULT 5 NOT NULL,
    Lokalizacja         VARCHAR2(50)        NULL,      -- np. "Regał A, Półka 3"
    ID_Kategorii        NUMBER(10)          NOT NULL,
    ID_Dostawcy         NUMBER(10)          NULL,      -- główny dostawca
    
    -- Klucz główny
    CONSTRAINT PK_MagazynCzesc PRIMARY KEY (ID_Czesci),
    
    -- Ograniczenia unikalności
    CONSTRAINT UQ_MagazynCzesc_Kod UNIQUE (KodProducenta),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Magazyn_CenaZakupu CHECK (Cena_Zakupu >= 0),
    CONSTRAINT CHK_Magazyn_CenaSprzedazy CHECK (CenaSprzedazy >= 0),
    CONSTRAINT CHK_Magazyn_Ilosc CHECK (IloscDostepna >= 0),
    CONSTRAINT CHK_Magazyn_MinStan CHECK (MinStanAlarmowy >= 0),
    CONSTRAINT CHK_Magazyn_Marza CHECK (CenaSprzedazy >= Cena_Zakupu)
);

COMMENT ON TABLE MagazynCzesc IS 'Magazyn części zamiennych';
COMMENT ON COLUMN MagazynCzesc.MinStanAlarmowy IS 'Minimalny stan magazynowy wywołujący alert';
COMMENT ON COLUMN MagazynCzesc.Lokalizacja IS 'Fizyczna lokalizacja części w magazynie';

-- ============================================================================
-- TABELA 16: POZYCJEZLECENIA_CZESCI
-- Pozycje zleceń - użyte części
-- ============================================================================
CREATE TABLE PozycjeZlecenia_Czesci (
    ID_PozycjiCzesci    NUMBER(10)          NOT NULL,
    Ilosc               NUMBER(10)          DEFAULT 1 NOT NULL,
    CenaWChwiliSprzedazy NUMBER(10,2)       NOT NULL,
    Rabat               NUMBER(5,2)         DEFAULT 0,
    CenaKoncowa         NUMBER(12,2)        NOT NULL,
    ID_Zlecenia         NUMBER(10)          NOT NULL,
    ID_Czesci           NUMBER(10)          NOT NULL,
    
    -- Klucz główny
    CONSTRAINT PK_PozycjeZlecenia_Czesci PRIMARY KEY (ID_PozycjiCzesci),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_PozCzesci_Ilosc CHECK (Ilosc >= 1),
    CONSTRAINT CHK_PozCzesci_Cena CHECK (CenaWChwiliSprzedazy >= 0),
    CONSTRAINT CHK_PozCzesci_Rabat CHECK (Rabat >= 0 AND Rabat <= 100),
    CONSTRAINT CHK_PozCzesci_CenaKonc CHECK (CenaKoncowa >= 0)
);

COMMENT ON TABLE PozycjeZlecenia_Czesci IS 'Pozycje zleceń - użyte części zamienne';
COMMENT ON COLUMN PozycjeZlecenia_Czesci.CenaWChwiliSprzedazy IS 'Cena części w momencie dodania do zlecenia (historyczna)';

-- ============================================================================
-- TABELA 17: DOSTAWY
-- Rejestr dostaw części od dostawców
-- ============================================================================
CREATE TABLE Dostawy (
    ID_Dostawy          NUMBER(10)          NOT NULL,
    DataDostawy         DATE                DEFAULT SYSDATE NOT NULL,
    NumerFaktury        VARCHAR2(50)        NOT NULL,
    IloscSztuk          NUMBER(10)          NOT NULL,
    CenaJednostkowa     NUMBER(10,2)        NOT NULL,
    WartoscCalkowita    NUMBER(12,2)        NOT NULL,
    ID_Czesci           NUMBER(10)          NOT NULL,
    ID_Dostawcy         NUMBER(10)          NOT NULL,
    
    -- Klucz główny
    CONSTRAINT PK_Dostawy PRIMARY KEY (ID_Dostawy),
    
    -- Ograniczenia CHECK
    CONSTRAINT CHK_Dostawy_Ilosc CHECK (IloscSztuk >= 1),
    CONSTRAINT CHK_Dostawy_Cena CHECK (CenaJednostkowa >= 0),
    CONSTRAINT CHK_Dostawy_Wartosc CHECK (WartoscCalkowita >= 0)
);

COMMENT ON TABLE Dostawy IS 'Rejestr dostaw części od dostawców';

-- ============================================================================
-- KLUCZE OBCE (FOREIGN KEYS)
-- ============================================================================

-- Model -> Marka
ALTER TABLE Model ADD CONSTRAINT FK_Model_Marka 
    FOREIGN KEY (ID_Marki) REFERENCES Marka(ID_Marki);

-- ============================================================================
-- KLUCZE OBCE DLA DZIEDZICZENIA (Class Table Inheritance)
-- ============================================================================

-- Klient -> Osoba (dziedziczenie 1:1)
ALTER TABLE Klient ADD CONSTRAINT FK_Klient_Osoba 
    FOREIGN KEY (ID_Osoby) REFERENCES Osoba(ID_Osoby) ON DELETE CASCADE;

-- Pracownik -> Osoba (dziedziczenie 1:1)
ALTER TABLE Pracownik ADD CONSTRAINT FK_Pracownik_Osoba 
    FOREIGN KEY (ID_Osoby) REFERENCES Osoba(ID_Osoby) ON DELETE CASCADE;

-- Pracownik -> Stanowisko
ALTER TABLE Pracownik ADD CONSTRAINT FK_Pracownik_Stanowisko 
    FOREIGN KEY (ID_Stanowiska) REFERENCES Stanowisko(ID_Stanowiska);

-- ============================================================================
-- POZOSTAŁE KLUCZE OBCE
-- ============================================================================

-- Pojazd -> Model
ALTER TABLE Pojazd ADD CONSTRAINT FK_Pojazd_Model 
    FOREIGN KEY (ID_Modelu) REFERENCES Model(ID_Modelu);

-- Pojazd -> Klient (właściciel)
ALTER TABLE Pojazd ADD CONSTRAINT FK_Pojazd_Klient 
    FOREIGN KEY (ID_Klienta) REFERENCES Klient(ID_Osoby);

-- Zlecenie -> Pojazd
ALTER TABLE Zlecenie ADD CONSTRAINT FK_Zlecenie_Pojazd 
    FOREIGN KEY (ID_Pojazdu) REFERENCES Pojazd(ID_Pojazdu);

-- Zlecenie -> Pracownik (przyjmujący)
ALTER TABLE Zlecenie ADD CONSTRAINT FK_Zlecenie_Pracownik 
    FOREIGN KEY (ID_Pracownika) REFERENCES Pracownik(ID_Osoby);

-- Zlecenie -> StatusyZlecen
ALTER TABLE Zlecenie ADD CONSTRAINT FK_Zlecenie_Status 
    FOREIGN KEY (ID_AktualnegoStatusu) REFERENCES StatusyZlecen(ID_Statusu);

-- HistoriaZmian -> Zlecenie
ALTER TABLE HistoriaZmian ADD CONSTRAINT FK_Historia_Zlecenie 
    FOREIGN KEY (ID_Zlecenia) REFERENCES Zlecenie(ID_Zlecenia) ON DELETE CASCADE;

-- HistoriaZmian -> StatusyZlecen (poprzedni)
ALTER TABLE HistoriaZmian ADD CONSTRAINT FK_Historia_StatusPoprzedni 
    FOREIGN KEY (ID_StatusuPoprzedni) REFERENCES StatusyZlecen(ID_Statusu);

-- HistoriaZmian -> StatusyZlecen (nowy)
ALTER TABLE HistoriaZmian ADD CONSTRAINT FK_Historia_StatusNowy 
    FOREIGN KEY (ID_StatusuNowy) REFERENCES StatusyZlecen(ID_Statusu);

-- HistoriaZmian -> Pracownik
ALTER TABLE HistoriaZmian ADD CONSTRAINT FK_Historia_Pracownik 
    FOREIGN KEY (ID_Pracownika) REFERENCES Pracownik(ID_Osoby);

-- PozycjeZlecenia_Uslugi -> Zlecenie
ALTER TABLE PozycjeZlecenia_Uslugi ADD CONSTRAINT FK_PozUslugi_Zlecenie 
    FOREIGN KEY (ID_Zlecenia) REFERENCES Zlecenie(ID_Zlecenia) ON DELETE CASCADE;

-- PozycjeZlecenia_Uslugi -> KatalogUslug
ALTER TABLE PozycjeZlecenia_Uslugi ADD CONSTRAINT FK_PozUslugi_Usluga 
    FOREIGN KEY (ID_Uslugi) REFERENCES KatalogUslug(ID_Uslugi);

-- PozycjeZlecenia_Uslugi -> Pracownik (wykonujący)
ALTER TABLE PozycjeZlecenia_Uslugi ADD CONSTRAINT FK_PozUslugi_Pracownik 
    FOREIGN KEY (ID_Pracownika) REFERENCES Pracownik(ID_Osoby);

-- MagazynCzesc -> KategoriaCzesci
ALTER TABLE MagazynCzesc ADD CONSTRAINT FK_Magazyn_Kategoria 
    FOREIGN KEY (ID_Kategorii) REFERENCES KategoriaCzesci(ID_Kategorii);

-- MagazynCzesc -> Dostawca
ALTER TABLE MagazynCzesc ADD CONSTRAINT FK_Magazyn_Dostawca 
    FOREIGN KEY (ID_Dostawcy) REFERENCES Dostawca(ID_Dostawcy);

-- PozycjeZlecenia_Czesci -> Zlecenie
ALTER TABLE PozycjeZlecenia_Czesci ADD CONSTRAINT FK_PozCzesci_Zlecenie 
    FOREIGN KEY (ID_Zlecenia) REFERENCES Zlecenie(ID_Zlecenia) ON DELETE CASCADE;

-- PozycjeZlecenia_Czesci -> MagazynCzesc
ALTER TABLE PozycjeZlecenia_Czesci ADD CONSTRAINT FK_PozCzesci_Czesc 
    FOREIGN KEY (ID_Czesci) REFERENCES MagazynCzesc(ID_Czesci);

-- Dostawy -> MagazynCzesc
ALTER TABLE Dostawy ADD CONSTRAINT FK_Dostawy_Czesc 
    FOREIGN KEY (ID_Czesci) REFERENCES MagazynCzesc(ID_Czesci);

-- Dostawy -> Dostawca
ALTER TABLE Dostawy ADD CONSTRAINT FK_Dostawy_Dostawca 
    FOREIGN KEY (ID_Dostawcy) REFERENCES Dostawca(ID_Dostawcy);

-- ============================================================================
-- DANE POCZĄTKOWE (SŁOWNIKI)
-- ============================================================================

-- Statusy zleceń
INSERT INTO StatusyZlecen (ID_Statusu, NazwaStatusu, Opis, KolejnoscWyswietlania) VALUES 
    (SEQ_STATUSYZLECEN.NEXTVAL, 'Nowe', 'Zlecenie przyjęte, oczekuje na wycenę', 1);
INSERT INTO StatusyZlecen (ID_Statusu, NazwaStatusu, Opis, KolejnoscWyswietlania) VALUES 
    (SEQ_STATUSYZLECEN.NEXTVAL, 'Wycenione', 'Zlecenie wycenione, oczekuje na akceptację klienta', 2);
INSERT INTO StatusyZlecen (ID_Statusu, NazwaStatusu, Opis, KolejnoscWyswietlania) VALUES 
    (SEQ_STATUSYZLECEN.NEXTVAL, 'Zaakceptowane', 'Klient zaakceptował wycenę', 3);
INSERT INTO StatusyZlecen (ID_Statusu, NazwaStatusu, Opis, KolejnoscWyswietlania) VALUES 
    (SEQ_STATUSYZLECEN.NEXTVAL, 'W realizacji', 'Zlecenie w trakcie realizacji', 4);
INSERT INTO StatusyZlecen (ID_Statusu, NazwaStatusu, Opis, KolejnoscWyswietlania) VALUES 
    (SEQ_STATUSYZLECEN.NEXTVAL, 'Oczekuje na części', 'Zlecenie wstrzymane - brak części', 5);
INSERT INTO StatusyZlecen (ID_Statusu, NazwaStatusu, Opis, KolejnoscWyswietlania) VALUES 
    (SEQ_STATUSYZLECEN.NEXTVAL, 'Zakończone', 'Naprawa zakończona, pojazd gotowy do odbioru', 6);
INSERT INTO StatusyZlecen (ID_Statusu, NazwaStatusu, Opis, KolejnoscWyswietlania) VALUES 
    (SEQ_STATUSYZLECEN.NEXTVAL, 'Wydane', 'Pojazd wydany klientowi', 7);
INSERT INTO StatusyZlecen (ID_Statusu, NazwaStatusu, Opis, KolejnoscWyswietlania) VALUES 
    (SEQ_STATUSYZLECEN.NEXTVAL, 'Anulowane', 'Zlecenie anulowane', 8);

-- Podstawowe stanowiska
INSERT INTO Stanowisko (ID_Stanowiska, NazwaStanowiska, Opis, StawkaGodzinowa) VALUES 
    (SEQ_STANOWISKO.NEXTVAL, 'Mechanik', 'Mechanik samochodowy', 50.00);
INSERT INTO Stanowisko (ID_Stanowiska, NazwaStanowiska, Opis, StawkaGodzinowa) VALUES 
    (SEQ_STANOWISKO.NEXTVAL, 'Elektryk', 'Elektryk samochodowy', 55.00);
INSERT INTO Stanowisko (ID_Stanowiska, NazwaStanowiska, Opis, StawkaGodzinowa) VALUES 
    (SEQ_STANOWISKO.NEXTVAL, 'Lakiernik', 'Lakiernik samochodowy', 60.00);
INSERT INTO Stanowisko (ID_Stanowiska, NazwaStanowiska, Opis, StawkaGodzinowa) VALUES 
    (SEQ_STANOWISKO.NEXTVAL, 'Blacharz', 'Blacharz samochodowy', 55.00);
INSERT INTO Stanowisko (ID_Stanowiska, NazwaStanowiska, Opis, StawkaGodzinowa) VALUES 
    (SEQ_STANOWISKO.NEXTVAL, 'Diagnosta', 'Diagnosta samochodowy', 65.00);
INSERT INTO Stanowisko (ID_Stanowiska, NazwaStanowiska, Opis, StawkaGodzinowa) VALUES 
    (SEQ_STANOWISKO.NEXTVAL, 'Kierownik warsztatu', 'Kierownik warsztatu', 80.00);
INSERT INTO Stanowisko (ID_Stanowiska, NazwaStanowiska, Opis, StawkaGodzinowa) VALUES 
    (SEQ_STANOWISKO.NEXTVAL, 'Recepcjonista', 'Obsługa klienta', 35.00);

-- Kategorie części
INSERT INTO KategoriaCzesci (ID_Kategorii, NazwaKategorii, Opis) VALUES 
    (SEQ_KATEGORIACZESCI.NEXTVAL, 'Układ hamulcowy', 'Klocki, tarcze, przewody hamulcowe');
INSERT INTO KategoriaCzesci (ID_Kategorii, NazwaKategorii, Opis) VALUES 
    (SEQ_KATEGORIACZESCI.NEXTVAL, 'Układ zawieszenia', 'Amortyzatory, sprężyny, wahacze');
INSERT INTO KategoriaCzesci (ID_Kategorii, NazwaKategorii, Opis) VALUES 
    (SEQ_KATEGORIACZESCI.NEXTVAL, 'Silnik', 'Części silnikowe');
INSERT INTO KategoriaCzesci (ID_Kategorii, NazwaKategorii, Opis) VALUES 
    (SEQ_KATEGORIACZESCI.NEXTVAL, 'Układ elektryczny', 'Akumulatory, alternatory, rozruszniki');
INSERT INTO KategoriaCzesci (ID_Kategorii, NazwaKategorii, Opis) VALUES 
    (SEQ_KATEGORIACZESCI.NEXTVAL, 'Filtry', 'Filtry oleju, powietrza, paliwa, kabinowe');
INSERT INTO KategoriaCzesci (ID_Kategorii, NazwaKategorii, Opis) VALUES 
    (SEQ_KATEGORIACZESCI.NEXTVAL, 'Oleje i płyny', 'Oleje silnikowe, płyny eksploatacyjne');
INSERT INTO KategoriaCzesci (ID_Kategorii, NazwaKategorii, Opis) VALUES 
    (SEQ_KATEGORIACZESCI.NEXTVAL, 'Oświetlenie', 'Żarówki, lampy, reflektory');
INSERT INTO KategoriaCzesci (ID_Kategorii, NazwaKategorii, Opis) VALUES 
    (SEQ_KATEGORIACZESCI.NEXTVAL, 'Układ kierowniczy', 'Drążki, końcówki, przekładnie');
INSERT INTO KategoriaCzesci (ID_Kategorii, NazwaKategorii, Opis) VALUES 
    (SEQ_KATEGORIACZESCI.NEXTVAL, 'Układ wydechowy', 'Tłumiki, katalizatory, rury');
INSERT INTO KategoriaCzesci (ID_Kategorii, NazwaKategorii, Opis) VALUES 
    (SEQ_KATEGORIACZESCI.NEXTVAL, 'Rozrząd', 'Paski, łańcuchy, napinacze');

COMMIT;
