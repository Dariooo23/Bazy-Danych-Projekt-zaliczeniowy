-- ============================================================================
-- SYSTEM ZARZADZANIA WARSZTATEM SAMOCHODOWYM
-- Wersja MySQL 8.0+
-- ============================================================================
-- Autorzy: Karol Dziekan, Krzysztof Cholewa
-- ============================================================================

-- Ustawienia charset
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Tworzymy baze danych (jesli uruchamiasz lokalnie)
-- CREATE DATABASE IF NOT EXISTS warsztat CHARACTER SET utf8mb4 COLLATE utf8mb4_polish_ci;
-- USE warsztat;

-- ============================================================================
-- USUWANIE TABEL (jesli istnieja) - w odpowiedniej kolejnosci
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS Dostawy;
DROP TABLE IF EXISTS PozycjeZlecenia_Czesci;
DROP TABLE IF EXISTS PozycjeZlecenia_Uslugi;
DROP TABLE IF EXISTS HistoriaZmian;
DROP TABLE IF EXISTS Zlecenie;
DROP TABLE IF EXISTS Pojazd;
DROP TABLE IF EXISTS MagazynCzesc;
DROP TABLE IF EXISTS Pracownik;
DROP TABLE IF EXISTS Klient;
DROP TABLE IF EXISTS Model;
DROP TABLE IF EXISTS Osoba;
DROP TABLE IF EXISTS Stanowisko;
DROP TABLE IF EXISTS StatusyZlecen;
DROP TABLE IF EXISTS KatalogUslug;
DROP TABLE IF EXISTS KategoriaCzesci;
DROP TABLE IF EXISTS Marka;
DROP TABLE IF EXISTS Dostawca;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- TABELA 1: MARKA
-- Przechowuje informacje o markach pojazdow
-- ============================================================================
CREATE TABLE Marka (
    ID_Marki            INT             NOT NULL AUTO_INCREMENT,
    NazwaMarki          VARCHAR(50)     NOT NULL,
    KrajPochodzenia     VARCHAR(50)     NULL,
    
    PRIMARY KEY (ID_Marki),
    UNIQUE KEY UQ_Marka_Nazwa (NazwaMarki),
    
    CONSTRAINT CHK_Marka_Nazwa CHECK (CHAR_LENGTH(TRIM(NazwaMarki)) >= 2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Tabela przechowujaca marki pojazdow';

-- ============================================================================
-- TABELA 2: MODEL
-- Przechowuje informacje o modelach pojazdow
-- ============================================================================
CREATE TABLE Model (
    ID_Modelu           INT             NOT NULL AUTO_INCREMENT,
    NazwaModelu         VARCHAR(50)     NOT NULL,
    RokProdukcjiOd      SMALLINT        NULL,
    RokProdukcjiDo      SMALLINT        NULL,
    ID_Marki            INT             NOT NULL,
    
    PRIMARY KEY (ID_Modelu),
    UNIQUE KEY UQ_Model_Marka_Nazwa (ID_Marki, NazwaModelu),
    
    CONSTRAINT CHK_Model_Nazwa CHECK (CHAR_LENGTH(TRIM(NazwaModelu)) >= 1),
    CONSTRAINT CHK_Model_RokOd CHECK (RokProdukcjiOd IS NULL OR (RokProdukcjiOd >= 1886 AND RokProdukcjiOd <= 2100)),
    CONSTRAINT CHK_Model_RokDo CHECK (RokProdukcjiDo IS NULL OR (RokProdukcjiDo >= 1886 AND RokProdukcjiDo <= 2100)),
    CONSTRAINT CHK_Model_Lata CHECK (RokProdukcjiOd IS NULL OR RokProdukcjiDo IS NULL OR RokProdukcjiOd <= RokProdukcjiDo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Tabela przechowujaca modele pojazdow';

-- ============================================================================
-- TABELA 3: STANOWISKO
-- Przechowuje informacje o stanowiskach pracy
-- ============================================================================
CREATE TABLE Stanowisko (
    ID_Stanowiska       INT             NOT NULL AUTO_INCREMENT,
    NazwaStanowiska     VARCHAR(50)     NOT NULL,
    Opis                VARCHAR(255)    NULL,
    StawkaGodzinowa     DECIMAL(10,2)   NOT NULL,
    
    PRIMARY KEY (ID_Stanowiska),
    UNIQUE KEY UQ_Stanowisko_Nazwa (NazwaStanowiska),
    
    CONSTRAINT CHK_Stanowisko_Stawka CHECK (StawkaGodzinowa >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Tabela przechowujaca stanowiska pracy w warsztacie';

-- ============================================================================
-- TABELA 4: OSOBA (NADTYP - Class Table Inheritance)
-- Przechowuje wspolne dane osob (klientow i pracownikow)
-- ============================================================================
CREATE TABLE Osoba (
    ID_Osoby            INT             NOT NULL AUTO_INCREMENT,
    Imie                VARCHAR(50)     NOT NULL,
    Nazwisko            VARCHAR(50)     NOT NULL,
    Telefon             VARCHAR(15)     NOT NULL,
    Email               VARCHAR(100)    NULL,
    Ulica               VARCHAR(100)    NULL,
    Miasto              VARCHAR(50)     NULL,
    KodPocztowy         VARCHAR(10)     NULL,
    
    PRIMARY KEY (ID_Osoby),
    
    CONSTRAINT CHK_Osoba_Imie CHECK (CHAR_LENGTH(TRIM(Imie)) >= 2),
    CONSTRAINT CHK_Osoba_Nazwisko CHECK (CHAR_LENGTH(TRIM(Nazwisko)) >= 2),
    CONSTRAINT CHK_Osoba_Telefon CHECK (Telefon REGEXP '^\\+?[0-9 -]{9,15}$'),
    CONSTRAINT CHK_Osoba_Email CHECK (Email IS NULL OR Email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT CHK_Osoba_KodPocztowy CHECK (KodPocztowy IS NULL OR KodPocztowy REGEXP '^[0-9]{2}-[0-9]{3}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Tabela nadrzedna - wspolne dane dla Klient i Pracownik (Class Table Inheritance)';

-- ============================================================================
-- TABELA 5: KLIENT (PODTYP - dziedziczy z OSOBA)
-- Przechowuje dane specyficzne dla klientow
-- ============================================================================
CREATE TABLE Klient (
    ID_Osoby            INT             NOT NULL,
    NIP                 VARCHAR(15)     NULL,
    DataRejestracji     DATE            NOT NULL DEFAULT (CURRENT_DATE),
    RabatStaly          DECIMAL(5,2)    DEFAULT 0,
    
    PRIMARY KEY (ID_Osoby),
    
    CONSTRAINT CHK_Klient_NIP CHECK (NIP IS NULL OR NIP REGEXP '^[0-9]{10}$'),
    CONSTRAINT CHK_Klient_Rabat CHECK (RabatStaly >= 0 AND RabatStaly <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Tabela podrzedna - dane specyficzne dla klientow';

-- ============================================================================
-- TABELA 6: PRACOWNIK (PODTYP - dziedziczy z OSOBA)
-- Przechowuje dane specyficzne dla pracownikow
-- ============================================================================
CREATE TABLE Pracownik (
    ID_Osoby            INT             NOT NULL,
    DataZatrudnienia    DATE            NOT NULL,
    DataZwolnienia      DATE            NULL,
    PensjaPodstawowa    DECIMAL(10,2)   NOT NULL,
    NrKontaBankowego    VARCHAR(32)     NOT NULL,
    ID_Stanowiska       INT             NOT NULL,
    
    PRIMARY KEY (ID_Osoby),
    
    CONSTRAINT CHK_Pracownik_Pensja CHECK (PensjaPodstawowa >= 0),
    CONSTRAINT CHK_Pracownik_Konto CHECK (NrKontaBankowego REGEXP '^[0-9]{26}$'),
    CONSTRAINT CHK_Pracownik_Daty CHECK (DataZwolnienia IS NULL OR DataZwolnienia >= DataZatrudnienia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Tabela podrzedna - dane specyficzne dla pracownikow';

-- ============================================================================
-- TABELA 7: POJAZD
-- Przechowuje informacje o pojazdach klientow
-- ============================================================================
CREATE TABLE Pojazd (
    ID_Pojazdu          INT             NOT NULL AUTO_INCREMENT,
    VIN                 VARCHAR(17)     NOT NULL,
    NrRejestracyjny     VARCHAR(10)     NOT NULL,
    RokProdukcji        SMALLINT        NULL,
    PojemnoscSilnika    INT             NULL COMMENT 'Pojemnosc w cm3',
    ID_Modelu           INT             NOT NULL,
    ID_Klienta          INT             NOT NULL COMMENT 'Wlasciciel pojazdu',
    
    PRIMARY KEY (ID_Pojazdu),
    UNIQUE KEY UQ_Pojazd_VIN (VIN),
    UNIQUE KEY UQ_Pojazd_Rejestracja (NrRejestracyjny),
    
    CONSTRAINT CHK_Pojazd_VIN CHECK (CHAR_LENGTH(VIN) = 17 AND VIN REGEXP '^[A-HJ-NPR-Z0-9]{17}$'),
    CONSTRAINT CHK_Pojazd_Rejestracja CHECK (NrRejestracyjny REGEXP '^[A-Z0-9]{4,8}$'),
    CONSTRAINT CHK_Pojazd_Rok CHECK (RokProdukcji IS NULL OR (RokProdukcji >= 1886 AND RokProdukcji <= 2030)),
    CONSTRAINT CHK_Pojazd_Pojemnosc CHECK (PojemnoscSilnika IS NULL OR (PojemnoscSilnika >= 50 AND PojemnoscSilnika <= 20000))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Tabela przechowujaca pojazdy klientow';

-- ============================================================================
-- TABELA 8: STATUSYZLECEN
-- Slownik statusow zlecen
-- ============================================================================
CREATE TABLE StatusyZlecen (
    ID_Statusu          INT             NOT NULL AUTO_INCREMENT,
    NazwaStatusu        VARCHAR(50)     NOT NULL,
    Opis                VARCHAR(255)    NULL,
    KolejnoscWyswietlania TINYINT       DEFAULT 0,
    CzyAktywny          CHAR(1)         DEFAULT 'T',
    
    PRIMARY KEY (ID_Statusu),
    UNIQUE KEY UQ_StatusyZlecen_Nazwa (NazwaStatusu),
    
    CONSTRAINT CHK_StatusyZlecen_Aktywny CHECK (CzyAktywny IN ('T', 'N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Slownik statusow zlecen serwisowych';

-- ============================================================================
-- TABELA 9: ZLECENIE
-- Przechowuje zlecenia serwisowe
-- ============================================================================
CREATE TABLE Zlecenie (
    ID_Zlecenia             INT             NOT NULL AUTO_INCREMENT,
    NumerZlecenia           VARCHAR(20)     NOT NULL,
    DataPrzyjecia           DATE            NOT NULL DEFAULT (CURRENT_DATE),
    DataPlanowanegoOdbioru  DATE            NULL,
    DataRzeczywistegOdbioru DATE            NULL,
    OpisUsterki             TEXT            NOT NULL,
    Uwagi                   VARCHAR(1000)   NULL,
    KosztCalkowity          DECIMAL(12,2)   DEFAULT 0,
    ID_Pojazdu              INT             NOT NULL,
    ID_Pracownika           INT             NOT NULL COMMENT 'Pracownik przyjmujacy',
    ID_AktualnegoStatusu    INT             NOT NULL,
    
    PRIMARY KEY (ID_Zlecenia),
    UNIQUE KEY UQ_Zlecenie_Numer (NumerZlecenia),
    
    CONSTRAINT CHK_Zlecenie_Numer CHECK (NumerZlecenia REGEXP '^ZLC/[0-9]{4}/[0-9]{5}$'),
    CONSTRAINT CHK_Zlecenie_DataOdbioru CHECK (DataPlanowanegoOdbioru IS NULL OR DataPlanowanegoOdbioru >= DataPrzyjecia),
    CONSTRAINT CHK_Zlecenie_DataRzeczywista CHECK (DataRzeczywistegOdbioru IS NULL OR DataRzeczywistegOdbioru >= DataPrzyjecia),
    CONSTRAINT CHK_Zlecenie_Koszt CHECK (KosztCalkowity >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Tabela przechowujaca zlecenia serwisowe';

-- ============================================================================
-- TABELA 10: HISTORIAZMIAN
-- Przechowuje historie zmian statusow zlecen
-- ============================================================================
CREATE TABLE HistoriaZmian (
    ID_Historii         INT             NOT NULL AUTO_INCREMENT,
    DataZmiany          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    Komentarz           VARCHAR(500)    NULL,
    ID_Zlecenia         INT             NOT NULL,
    ID_StatusuPoprzedni INT             NULL COMMENT 'NULL dla pierwszego wpisu',
    ID_StatusuNowy      INT             NOT NULL,
    ID_Pracownika       INT             NOT NULL COMMENT 'Kto dokonal zmiany',
    
    PRIMARY KEY (ID_Historii)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Historia zmian statusow zlecen';

-- ============================================================================
-- TABELA 11: KATALOGUSLUG
-- Katalog uslug oferowanych przez warsztat
-- ============================================================================
CREATE TABLE KatalogUslug (
    ID_Uslugi           INT             NOT NULL AUTO_INCREMENT,
    NazwaUslugi         VARCHAR(100)    NOT NULL,
    Opis                VARCHAR(500)    NULL,
    CenaBazowa          DECIMAL(10,2)   NULL,
    SzacowanyCzasRbh    DECIMAL(5,2)    NULL COMMENT 'Czas w roboczogodzinach',
    CzyAktywna          CHAR(1)         DEFAULT 'T',
    
    PRIMARY KEY (ID_Uslugi),
    UNIQUE KEY UQ_KatalogUslug_Nazwa (NazwaUslugi),
    
    CONSTRAINT CHK_KatalogUslug_Cena CHECK (CenaBazowa IS NULL OR CenaBazowa >= 0),
    CONSTRAINT CHK_KatalogUslug_Czas CHECK (SzacowanyCzasRbh IS NULL OR SzacowanyCzasRbh >= 0),
    CONSTRAINT CHK_KatalogUslug_Aktywna CHECK (CzyAktywna IN ('T', 'N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Katalog uslug serwisowych';

-- ============================================================================
-- TABELA 12: POZYCJEZLECENIA_USLUGI
-- Pozycje zlecen - uslugi
-- ============================================================================
CREATE TABLE PozycjeZlecenia_Uslugi (
    ID_PozycjiUslugi    INT             NOT NULL AUTO_INCREMENT,
    Krotnosc            SMALLINT        DEFAULT 1 NOT NULL,
    RabatNaUsluge       DECIMAL(5,2)    DEFAULT 0,
    CenaJednostkowa     DECIMAL(10,2)   NOT NULL,
    CenaKoncowa         DECIMAL(12,2)   NOT NULL,
    ID_Zlecenia         INT             NOT NULL,
    ID_Uslugi           INT             NOT NULL,
    ID_Pracownika       INT             NULL COMMENT 'Pracownik wykonujacy',
    
    PRIMARY KEY (ID_PozycjiUslugi),
    
    CONSTRAINT CHK_PozUslugi_Krotnosc CHECK (Krotnosc >= 1),
    CONSTRAINT CHK_PozUslugi_Rabat CHECK (RabatNaUsluge >= 0 AND RabatNaUsluge <= 100),
    CONSTRAINT CHK_PozUslugi_CenaJedn CHECK (CenaJednostkowa >= 0),
    CONSTRAINT CHK_PozUslugi_CenaKonc CHECK (CenaKoncowa >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Pozycje zlecen - wykonane uslugi';

-- ============================================================================
-- TABELA 13: KATEGORIACZESCI
-- Kategorie czesci zamiennych
-- ============================================================================
CREATE TABLE KategoriaCzesci (
    ID_Kategorii        INT             NOT NULL AUTO_INCREMENT,
    NazwaKategorii      VARCHAR(50)     NOT NULL,
    Opis                VARCHAR(255)    NULL,
    
    PRIMARY KEY (ID_Kategorii),
    UNIQUE KEY UQ_KategoriaCzesci_Nazwa (NazwaKategorii)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Kategorie czesci zamiennych';

-- ============================================================================
-- TABELA 14: DOSTAWCA
-- Dostawcy czesci zamiennych
-- ============================================================================
CREATE TABLE Dostawca (
    ID_Dostawcy         INT             NOT NULL AUTO_INCREMENT,
    NazwaFirmy          VARCHAR(100)    NOT NULL,
    Adres               VARCHAR(150)    NOT NULL,
    Telefon             VARCHAR(20)     NOT NULL,
    Email               VARCHAR(100)    NULL,
    NIP                 VARCHAR(15)     NOT NULL,
    OsobaKontaktowa     VARCHAR(100)    NULL,
    CzyAktywny          CHAR(1)         DEFAULT 'T',
    
    PRIMARY KEY (ID_Dostawcy),
    UNIQUE KEY UQ_Dostawca_NIP (NIP),
    
    CONSTRAINT CHK_Dostawca_NIP CHECK (NIP REGEXP '^[0-9]{10}$'),
    CONSTRAINT CHK_Dostawca_Email CHECK (Email IS NULL OR Email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT CHK_Dostawca_Aktywny CHECK (CzyAktywny IN ('T', 'N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Dostawcy czesci zamiennych';

-- ============================================================================
-- TABELA 15: MAGAZYNCZESC
-- Magazyn czesci zamiennych
-- ============================================================================
CREATE TABLE MagazynCzesc (
    ID_Czesci           INT             NOT NULL AUTO_INCREMENT,
    NazwaCzesci         VARCHAR(100)    NOT NULL,
    KodProducenta       VARCHAR(50)     NOT NULL,
    Cena_Zakupu         DECIMAL(10,2)   NOT NULL,
    CenaSprzedazy       DECIMAL(10,2)   NOT NULL,
    IloscDostepna       INT             DEFAULT 0 NOT NULL,
    MinStanAlarmowy     INT             DEFAULT 5 NOT NULL,
    Lokalizacja         VARCHAR(50)     NULL COMMENT 'np. Regal A, Polka 3',
    ID_Kategorii        INT             NOT NULL,
    ID_Dostawcy         INT             NULL COMMENT 'Glowny dostawca',
    
    PRIMARY KEY (ID_Czesci),
    UNIQUE KEY UQ_MagazynCzesc_Kod (KodProducenta),
    
    CONSTRAINT CHK_Magazyn_CenaZakupu CHECK (Cena_Zakupu >= 0),
    CONSTRAINT CHK_Magazyn_CenaSprzedazy CHECK (CenaSprzedazy >= 0),
    CONSTRAINT CHK_Magazyn_Ilosc CHECK (IloscDostepna >= 0),
    CONSTRAINT CHK_Magazyn_MinStan CHECK (MinStanAlarmowy >= 0),
    CONSTRAINT CHK_Magazyn_Marza CHECK (CenaSprzedazy >= Cena_Zakupu)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Magazyn czesci zamiennych';

-- ============================================================================
-- TABELA 16: POZYCJEZLECENIA_CZESCI
-- Pozycje zlecen - uzyte czesci
-- ============================================================================
CREATE TABLE PozycjeZlecenia_Czesci (
    ID_PozycjiCzesci    INT             NOT NULL AUTO_INCREMENT,
    Ilosc               INT             DEFAULT 1 NOT NULL,
    CenaWChwiliSprzedazy DECIMAL(10,2)  NOT NULL COMMENT 'Cena historyczna',
    Rabat               DECIMAL(5,2)    DEFAULT 0,
    CenaKoncowa         DECIMAL(12,2)   NOT NULL,
    ID_Zlecenia         INT             NOT NULL,
    ID_Czesci           INT             NOT NULL,
    
    PRIMARY KEY (ID_PozycjiCzesci),
    
    CONSTRAINT CHK_PozCzesci_Ilosc CHECK (Ilosc >= 1),
    CONSTRAINT CHK_PozCzesci_Cena CHECK (CenaWChwiliSprzedazy >= 0),
    CONSTRAINT CHK_PozCzesci_Rabat CHECK (Rabat >= 0 AND Rabat <= 100),
    CONSTRAINT CHK_PozCzesci_CenaKonc CHECK (CenaKoncowa >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Pozycje zlecen - uzyte czesci zamienne';

-- ============================================================================
-- TABELA 17: DOSTAWY
-- Rejestr dostaw czesci od dostawcow
-- ============================================================================
CREATE TABLE Dostawy (
    ID_Dostawy          INT             NOT NULL AUTO_INCREMENT,
    DataDostawy         DATE            NOT NULL DEFAULT (CURRENT_DATE),
    NumerFaktury        VARCHAR(50)     NOT NULL,
    IloscSztuk          INT             NOT NULL,
    CenaJednostkowa     DECIMAL(10,2)   NOT NULL,
    WartoscCalkowita    DECIMAL(12,2)   NOT NULL,
    ID_Czesci           INT             NOT NULL,
    ID_Dostawcy         INT             NOT NULL,
    
    PRIMARY KEY (ID_Dostawy),
    
    CONSTRAINT CHK_Dostawy_Ilosc CHECK (IloscSztuk >= 1),
    CONSTRAINT CHK_Dostawy_Cena CHECK (CenaJednostkowa >= 0),
    CONSTRAINT CHK_Dostawy_Wartosc CHECK (WartoscCalkowita >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_polish_ci
COMMENT='Rejestr dostaw czesci od dostawcow';

-- ============================================================================
-- KLUCZE OBCE (FOREIGN KEYS)
-- ============================================================================

-- Model -> Marka
ALTER TABLE Model ADD CONSTRAINT FK_Model_Marka 
    FOREIGN KEY (ID_Marki) REFERENCES Marka(ID_Marki);

-- Klient -> Osoba (dziedziczenie 1:1)
ALTER TABLE Klient ADD CONSTRAINT FK_Klient_Osoba 
    FOREIGN KEY (ID_Osoby) REFERENCES Osoba(ID_Osoby) ON DELETE CASCADE;

-- Pracownik -> Osoba (dziedziczenie 1:1)
ALTER TABLE Pracownik ADD CONSTRAINT FK_Pracownik_Osoba 
    FOREIGN KEY (ID_Osoby) REFERENCES Osoba(ID_Osoby) ON DELETE CASCADE;

-- Pracownik -> Stanowisko
ALTER TABLE Pracownik ADD CONSTRAINT FK_Pracownik_Stanowisko 
    FOREIGN KEY (ID_Stanowiska) REFERENCES Stanowisko(ID_Stanowiska);

-- Pojazd -> Model
ALTER TABLE Pojazd ADD CONSTRAINT FK_Pojazd_Model 
    FOREIGN KEY (ID_Modelu) REFERENCES Model(ID_Modelu);

-- Pojazd -> Klient
ALTER TABLE Pojazd ADD CONSTRAINT FK_Pojazd_Klient 
    FOREIGN KEY (ID_Klienta) REFERENCES Klient(ID_Osoby);

-- Zlecenie -> Pojazd
ALTER TABLE Zlecenie ADD CONSTRAINT FK_Zlecenie_Pojazd 
    FOREIGN KEY (ID_Pojazdu) REFERENCES Pojazd(ID_Pojazdu);

-- Zlecenie -> Pracownik
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

-- PozycjeZlecenia_Uslugi -> Pracownik
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
-- DANE POCZATKOWE (SLOWNIKI)
-- ============================================================================

-- Statusy zlecen
INSERT INTO StatusyZlecen (NazwaStatusu, Opis, KolejnoscWyswietlania) VALUES 
    ('Nowe', 'Zlecenie przyjete, oczekuje na wycene', 1),
    ('Wycenione', 'Zlecenie wycenione, oczekuje na akceptacje klienta', 2),
    ('Zaakceptowane', 'Klient zaakceptowal wycene', 3),
    ('W realizacji', 'Zlecenie w trakcie realizacji', 4),
    ('Oczekuje na czesci', 'Zlecenie wstrzymane - brak czesci', 5),
    ('Zakonczone', 'Naprawa zakonczona, pojazd gotowy do odbioru', 6),
    ('Wydane', 'Pojazd wydany klientowi', 7),
    ('Anulowane', 'Zlecenie anulowane', 8);

-- Stanowiska
INSERT INTO Stanowisko (NazwaStanowiska, Opis, StawkaGodzinowa) VALUES 
    ('Mechanik', 'Mechanik samochodowy', 50.00),
    ('Elektryk', 'Elektryk samochodowy', 55.00),
    ('Lakiernik', 'Lakiernik samochodowy', 60.00),
    ('Blacharz', 'Blacharz samochodowy', 55.00),
    ('Diagnosta', 'Diagnosta samochodowy', 65.00),
    ('Kierownik warsztatu', 'Kierownik warsztatu', 80.00),
    ('Recepcjonista', 'Obsluga klienta', 35.00);

-- Kategorie czesci
INSERT INTO KategoriaCzesci (NazwaKategorii, Opis) VALUES 
    ('Uklad hamulcowy', 'Klocki, tarcze, przewody hamulcowe'),
    ('Uklad zawieszenia', 'Amortyzatory, sprezyny, wahacze'),
    ('Silnik', 'Czesci silnikowe'),
    ('Uklad elektryczny', 'Akumulatory, alternatory, rozruszniki'),
    ('Filtry', 'Filtry oleju, powietrza, paliwa, kabinowe'),
    ('Oleje i plyny', 'Oleje silnikowe, plyny eksploatacyjne'),
    ('Oswietlenie', 'Zarowki, lampy, reflektory'),
    ('Uklad kierowniczy', 'Drazki, koncowki, przekladnie'),
    ('Uklad wydechowy', 'Tlumiki, katalizatory, rury'),
    ('Rozrzad', 'Paski, lancuchy, napinacze');
