-- ============================================================================
-- MARKI I MODELE POJAZDOW
-- ============================================================================

-- Marki
INSERT INTO Marka (ID_Marki, NazwaMarki, KrajPochodzenia) VALUES 
    (SEQ_MARKA.NEXTVAL, 'Volkswagen', 'Niemcy');
INSERT INTO Marka (ID_Marki, NazwaMarki, KrajPochodzenia) VALUES 
    (SEQ_MARKA.NEXTVAL, 'Toyota', 'Japonia');
INSERT INTO Marka (ID_Marki, NazwaMarki, KrajPochodzenia) VALUES 
    (SEQ_MARKA.NEXTVAL, 'Ford', 'USA');
INSERT INTO Marka (ID_Marki, NazwaMarki, KrajPochodzenia) VALUES 
    (SEQ_MARKA.NEXTVAL, 'BMW', 'Niemcy');
INSERT INTO Marka (ID_Marki, NazwaMarki, KrajPochodzenia) VALUES 
    (SEQ_MARKA.NEXTVAL, 'Audi', 'Niemcy');
INSERT INTO Marka (ID_Marki, NazwaMarki, KrajPochodzenia) VALUES 
    (SEQ_MARKA.NEXTVAL, 'Skoda', 'Czechy');
INSERT INTO Marka (ID_Marki, NazwaMarki, KrajPochodzenia) VALUES 
    (SEQ_MARKA.NEXTVAL, 'Opel', 'Niemcy');

-- Modele (ID_Marki odnosi sie do kolejnosci wstawionych marek)
INSERT INTO Model (ID_Modelu, NazwaModelu, RokProdukcjiOd, RokProdukcjiDo, ID_Marki) VALUES 
    (SEQ_MODEL.NEXTVAL, 'Golf', 2019, NULL, 1);
INSERT INTO Model (ID_Modelu, NazwaModelu, RokProdukcjiOd, RokProdukcjiDo, ID_Marki) VALUES 
    (SEQ_MODEL.NEXTVAL, 'Passat', 2015, NULL, 1);
INSERT INTO Model (ID_Modelu, NazwaModelu, RokProdukcjiOd, RokProdukcjiDo, ID_Marki) VALUES 
    (SEQ_MODEL.NEXTVAL, 'Corolla', 2018, NULL, 2);
INSERT INTO Model (ID_Modelu, NazwaModelu, RokProdukcjiOd, RokProdukcjiDo, ID_Marki) VALUES 
    (SEQ_MODEL.NEXTVAL, 'Yaris', 2020, NULL, 2);
INSERT INTO Model (ID_Modelu, NazwaModelu, RokProdukcjiOd, RokProdukcjiDo, ID_Marki) VALUES 
    (SEQ_MODEL.NEXTVAL, 'Focus', 2016, NULL, 3);
INSERT INTO Model (ID_Modelu, NazwaModelu, RokProdukcjiOd, RokProdukcjiDo, ID_Marki) VALUES 
    (SEQ_MODEL.NEXTVAL, 'Seria 3', 2018, NULL, 4);
INSERT INTO Model (ID_Modelu, NazwaModelu, RokProdukcjiOd, RokProdukcjiDo, ID_Marki) VALUES 
    (SEQ_MODEL.NEXTVAL, 'A4', 2017, NULL, 5);
INSERT INTO Model (ID_Modelu, NazwaModelu, RokProdukcjiOd, RokProdukcjiDo, ID_Marki) VALUES 
    (SEQ_MODEL.NEXTVAL, 'Octavia', 2019, NULL, 6);
INSERT INTO Model (ID_Modelu, NazwaModelu, RokProdukcjiOd, RokProdukcjiDo, ID_Marki) VALUES 
    (SEQ_MODEL.NEXTVAL, 'Astra', 2015, NULL, 7);

-- ============================================================================
-- OSOBY - PRACOWNICY
-- ============================================================================

-- Pracownik 1: Kierownik (ID_Osoby = 1)
INSERT INTO Osoba (ID_Osoby, Imie, Nazwisko, Telefon, Email, Ulica, Miasto, KodPocztowy) VALUES 
    (SEQ_OSOBA.NEXTVAL, 'Jan', 'Kowalski', '+48600100100', 'j.kowalski@warsztat.pl', 'ul. Glowna 1', 'Warszawa', '00-001');
INSERT INTO Pracownik (ID_Osoby, DataZatrudnienia, DataZwolnienia, PensjaPodstawowa, NrKontaBankowego, ID_Stanowiska) VALUES 
    (1, DATE '2020-01-15', NULL, 8000.00, '12345678901234567890123456', 6);

-- Pracownik 2: Mechanik (ID_Osoby = 2)
INSERT INTO Osoba (ID_Osoby, Imie, Nazwisko, Telefon, Email, Ulica, Miasto, KodPocztowy) VALUES 
    (SEQ_OSOBA.NEXTVAL, 'Adam', 'Nowak', '+48600200200', 'a.nowak@warsztat.pl', 'ul. Polna 5', 'Warszawa', '00-002');
INSERT INTO Pracownik (ID_Osoby, DataZatrudnienia, DataZwolnienia, PensjaPodstawowa, NrKontaBankowego, ID_Stanowiska) VALUES 
    (2, DATE '2021-03-01', NULL, 5500.00, '23456789012345678901234567', 1);

-- Pracownik 3: Elektryk (ID_Osoby = 3)
INSERT INTO Osoba (ID_Osoby, Imie, Nazwisko, Telefon, Email, Ulica, Miasto, KodPocztowy) VALUES 
    (SEQ_OSOBA.NEXTVAL, 'Piotr', 'Wisniewski', '+48600300300', 'p.wisniewski@warsztat.pl', 'ul. Lesna 10', 'Warszawa', '00-003');
INSERT INTO Pracownik (ID_Osoby, DataZatrudnienia, DataZwolnienia, PensjaPodstawowa, NrKontaBankowego, ID_Stanowiska) VALUES 
    (3, DATE '2022-06-15', NULL, 5800.00, '34567890123456789012345678', 2);

-- Pracownik 4: Recepcjonistka (ID_Osoby = 4)
INSERT INTO Osoba (ID_Osoby, Imie, Nazwisko, Telefon, Email, Ulica, Miasto, KodPocztowy) VALUES 
    (SEQ_OSOBA.NEXTVAL, 'Anna', 'Zielinska', '+48600400400', 'a.zielinska@warsztat.pl', 'ul. Kwiatowa 3', 'Warszawa', '00-004');
INSERT INTO Pracownik (ID_Osoby, DataZatrudnienia, DataZwolnienia, PensjaPodstawowa, NrKontaBankowego, ID_Stanowiska) VALUES 
    (4, DATE '2023-01-10', NULL, 4200.00, '45678901234567890123456789', 7);

-- Pracownik 5: Diagnosta (ID_Osoby = 5)
INSERT INTO Osoba (ID_Osoby, Imie, Nazwisko, Telefon, Email, Ulica, Miasto, KodPocztowy) VALUES 
    (SEQ_OSOBA.NEXTVAL, 'Marek', 'Dabrowski', '+48600500500', 'm.dabrowski@warsztat.pl', 'ul. Sloneczna 7', 'Warszawa', '00-005');
INSERT INTO Pracownik (ID_Osoby, DataZatrudnienia, DataZwolnienia, PensjaPodstawowa, NrKontaBankowego, ID_Stanowiska) VALUES 
    (5, DATE '2021-09-01', NULL, 6200.00, '56789012345678901234567890', 5);

-- ============================================================================
-- OSOBY - KLIENCI
-- ============================================================================

-- Klient 1 (ID_Osoby = 6)
INSERT INTO Osoba (ID_Osoby, Imie, Nazwisko, Telefon, Email, Ulica, Miasto, KodPocztowy) VALUES 
    (SEQ_OSOBA.NEXTVAL, 'Tomasz', 'Lewandowski', '+48601111111', 'tomasz.lew@email.pl', 'ul. Mickiewicza 15', 'Warszawa', '00-100');
INSERT INTO Klient (ID_Osoby, NIP, DataRejestracji, RabatStaly) VALUES 
    (6, NULL, DATE '2024-01-15', 0);

-- Klient 2 - firma (ID_Osoby = 7)
INSERT INTO Osoba (ID_Osoby, Imie, Nazwisko, Telefon, Email, Ulica, Miasto, KodPocztowy) VALUES 
    (SEQ_OSOBA.NEXTVAL, 'Katarzyna', 'Wojcik', '+48602222222', 'k.wojcik@firma.pl', 'ul. Slowackiego 22', 'Krakow', '30-001');
INSERT INTO Klient (ID_Osoby, NIP, DataRejestracji, RabatStaly) VALUES 
    (7, '1234567890', DATE '2023-05-20', 10);

-- Klient 3 (ID_Osoby = 8)
INSERT INTO Osoba (ID_Osoby, Imie, Nazwisko, Telefon, Email, Ulica, Miasto, KodPocztowy) VALUES 
    (SEQ_OSOBA.NEXTVAL, 'Michal', 'Kaminski', '+48603333333', 'michal.kam@email.pl', 'ul. Sienkiewicza 8', 'Wroclaw', '50-001');
INSERT INTO Klient (ID_Osoby, NIP, DataRejestracji, RabatStaly) VALUES 
    (8, NULL, DATE '2024-06-10', 5);

-- Klient 4 - firma (ID_Osoby = 9)
INSERT INTO Osoba (ID_Osoby, Imie, Nazwisko, Telefon, Email, Ulica, Miasto, KodPocztowy) VALUES 
    (SEQ_OSOBA.NEXTVAL, 'Ewa', 'Szymanska', '+48604444444', 'e.szymanska@transport.pl', 'ul. Prusa 45', 'Poznan', '60-001');
INSERT INTO Klient (ID_Osoby, NIP, DataRejestracji, RabatStaly) VALUES 
    (9, '9876543210', DATE '2022-11-05', 15);

-- Klient 5 (ID_Osoby = 10)
INSERT INTO Osoba (ID_Osoby, Imie, Nazwisko, Telefon, Email, Ulica, Miasto, KodPocztowy) VALUES 
    (SEQ_OSOBA.NEXTVAL, 'Robert', 'Mazur', '+48605555555', NULL, 'ul. Reja 12', 'Gdansk', '80-001');
INSERT INTO Klient (ID_Osoby, NIP, DataRejestracji, RabatStaly) VALUES 
    (10, NULL, DATE '2025-02-28', 0);

-- ============================================================================
-- POJAZDY KLIENTOW
-- ============================================================================

-- Pojazd 1 - klient 6, VW Golf
INSERT INTO Pojazd (ID_Pojazdu, VIN, NrRejestracyjny, RokProdukcji, PojemnoscSilnika, ID_Modelu, ID_Klienta) VALUES 
    (SEQ_POJAZD.NEXTVAL, 'WVWZZZ1KZAW123456', 'WA12345', 2020, 1498, 1, 6);

-- Pojazd 2 - klient 7, Toyota Corolla
INSERT INTO Pojazd (ID_Pojazdu, VIN, NrRejestracyjny, RokProdukcji, PojemnoscSilnika, ID_Modelu, ID_Klienta) VALUES 
    (SEQ_POJAZD.NEXTVAL, 'JTDKN3DU5A0123456', 'KR67890', 2019, 1798, 3, 7);

-- Pojazd 3 - klient 7, VW Passat (firma ma 2 auta)
INSERT INTO Pojazd (ID_Pojazdu, VIN, NrRejestracyjny, RokProdukcji, PojemnoscSilnika, ID_Modelu, ID_Klienta) VALUES 
    (SEQ_POJAZD.NEXTVAL, 'WVWZZZ3CZWE234567', 'KR11111', 2021, 1968, 2, 7);

-- Pojazd 4 - klient 8, BMW Seria 3
INSERT INTO Pojazd (ID_Pojazdu, VIN, NrRejestracyjny, RokProdukcji, PojemnoscSilnika, ID_Modelu, ID_Klienta) VALUES 
    (SEQ_POJAZD.NEXTVAL, 'WBA8E9C50JK345678', 'DW22222', 2018, 1998, 6, 8);

-- Pojazd 5 - klient 9, Skoda Octavia
INSERT INTO Pojazd (ID_Pojazdu, VIN, NrRejestracyjny, RokProdukcji, PojemnoscSilnika, ID_Modelu, ID_Klienta) VALUES 
    (SEQ_POJAZD.NEXTVAL, 'TMBEA61Z6J2456789', 'PO33333', 2020, 1498, 8, 9);

-- Pojazd 6 - klient 10, Ford Focus
INSERT INTO Pojazd (ID_Pojazdu, VIN, NrRejestracyjny, RokProdukcji, PojemnoscSilnika, ID_Modelu, ID_Klienta) VALUES 
    (SEQ_POJAZD.NEXTVAL, 'WF0XXXGCDX7567890', 'GD44444', 2017, 1499, 5, 10);

-- ============================================================================
-- KATALOG USLUG
-- ============================================================================

INSERT INTO KatalogUslug (ID_Uslugi, NazwaUslugi, Opis, CenaBazowa, SzacowanyCzasRbh, CzyAktywna) VALUES 
    (SEQ_KATALOGUSLUG.NEXTVAL, 'Wymiana oleju silnikowego', 'Wymiana oleju wraz z filtrem oleju', 150.00, 0.5, 'T');
INSERT INTO KatalogUslug (ID_Uslugi, NazwaUslugi, Opis, CenaBazowa, SzacowanyCzasRbh, CzyAktywna) VALUES 
    (SEQ_KATALOGUSLUG.NEXTVAL, 'Wymiana klockow hamulcowych przod', 'Wymiana klockow hamulcowych osi przedniej', 200.00, 1.0, 'T');
INSERT INTO KatalogUslug (ID_Uslugi, NazwaUslugi, Opis, CenaBazowa, SzacowanyCzasRbh, CzyAktywna) VALUES 
    (SEQ_KATALOGUSLUG.NEXTVAL, 'Wymiana klockow hamulcowych tyl', 'Wymiana klockow hamulcowych osi tylnej', 180.00, 1.0, 'T');
INSERT INTO KatalogUslug (ID_Uslugi, NazwaUslugi, Opis, CenaBazowa, SzacowanyCzasRbh, CzyAktywna) VALUES 
    (SEQ_KATALOGUSLUG.NEXTVAL, 'Diagnostyka komputerowa', 'Pelna diagnostyka komputerowa pojazdu', 100.00, 0.5, 'T');
INSERT INTO KatalogUslug (ID_Uslugi, NazwaUslugi, Opis, CenaBazowa, SzacowanyCzasRbh, CzyAktywna) VALUES 
    (SEQ_KATALOGUSLUG.NEXTVAL, 'Wymiana rozrzadu', 'Wymiana paska/lancucha rozrzadu z kompletem', 800.00, 4.0, 'T');
INSERT INTO KatalogUslug (ID_Uslugi, NazwaUslugi, Opis, CenaBazowa, SzacowanyCzasRbh, CzyAktywna) VALUES 
    (SEQ_KATALOGUSLUG.NEXTVAL, 'Geometria zawieszenia', 'Ustawienie geometrii kol', 150.00, 1.0, 'T');
INSERT INTO KatalogUslug (ID_Uslugi, NazwaUslugi, Opis, CenaBazowa, SzacowanyCzasRbh, CzyAktywna) VALUES 
    (SEQ_KATALOGUSLUG.NEXTVAL, 'Wymiana amortyzatorow przod', 'Wymiana przednich amortyzatorow (para)', 300.00, 2.0, 'T');
INSERT INTO KatalogUslug (ID_Uslugi, NazwaUslugi, Opis, CenaBazowa, SzacowanyCzasRbh, CzyAktywna) VALUES 
    (SEQ_KATALOGUSLUG.NEXTVAL, 'Wymiana sprzegla', 'Wymiana kompletu sprzegla', 600.00, 4.0, 'T');
INSERT INTO KatalogUslug (ID_Uslugi, NazwaUslugi, Opis, CenaBazowa, SzacowanyCzasRbh, CzyAktywna) VALUES 
    (SEQ_KATALOGUSLUG.NEXTVAL, 'Wymiana filtra powietrza', 'Wymiana filtra powietrza silnika', 50.00, 0.25, 'T');
INSERT INTO KatalogUslug (ID_Uslugi, NazwaUslugi, Opis, CenaBazowa, SzacowanyCzasRbh, CzyAktywna) VALUES 
    (SEQ_KATALOGUSLUG.NEXTVAL, 'Serwis klimatyzacji', 'Odgrzybianie i uzupelnienie czynnika', 200.00, 1.0, 'T');

-- ============================================================================
-- DOSTAWCY
-- ============================================================================

INSERT INTO Dostawca (ID_Dostawcy, NazwaFirmy, Adres, Telefon, Email, NIP, OsobaKontaktowa, CzyAktywny) VALUES 
    (SEQ_DOSTAWCA.NEXTVAL, 'Auto-Czesci Sp. z o.o.', 'ul. Przemyslowa 10, Warszawa', '+48221234567', 'zamowienia@autoczesci.pl', '1111111111', 'Janusz Kowalczyk', 'T');
INSERT INTO Dostawca (ID_Dostawcy, NazwaFirmy, Adres, Telefon, Email, NIP, OsobaKontaktowa, CzyAktywny) VALUES 
    (SEQ_DOSTAWCA.NEXTVAL, 'InterParts', 'ul. Magazynowa 5, Poznan', '+48612345678', 'biuro@interparts.pl', '2222222222', 'Maria Nowak', 'T');
INSERT INTO Dostawca (ID_Dostawcy, NazwaFirmy, Adres, Telefon, Email, NIP, OsobaKontaktowa, CzyAktywny) VALUES 
    (SEQ_DOSTAWCA.NEXTVAL, 'TechParts24', 'ul. Logistyczna 15, Lodz', '+48423456789', 'kontakt@techparts24.pl', '3333333333', 'Piotr Zielinski', 'T');

-- ============================================================================
-- MAGAZYN CZESCI
-- ============================================================================

INSERT INTO MagazynCzesc (ID_Czesci, NazwaCzesci, KodProducenta, Cena_Zakupu, CenaSprzedazy, IloscDostepna, MinStanAlarmowy, Lokalizacja, ID_Kategorii, ID_Dostawcy) VALUES 
    (SEQ_MAGAZYNCZESC.NEXTVAL, 'Klocki hamulcowe przod VW Golf', 'TRW-GDB1550', 120.00, 180.00, 15, 5, 'Regal A, Polka 1', 1, 1);
INSERT INTO MagazynCzesc (ID_Czesci, NazwaCzesci, KodProducenta, Cena_Zakupu, CenaSprzedazy, IloscDostepna, MinStanAlarmowy, Lokalizacja, ID_Kategorii, ID_Dostawcy) VALUES 
    (SEQ_MAGAZYNCZESC.NEXTVAL, 'Filtr oleju VW/Audi', 'MANN-W719/30', 25.00, 45.00, 30, 10, 'Regal B, Polka 2', 5, 1);
INSERT INTO MagazynCzesc (ID_Czesci, NazwaCzesci, KodProducenta, Cena_Zakupu, CenaSprzedazy, IloscDostepna, MinStanAlarmowy, Lokalizacja, ID_Kategorii, ID_Dostawcy) VALUES 
    (SEQ_MAGAZYNCZESC.NEXTVAL, 'Filtr powietrza VW Golf', 'BOSCH-F026400391', 45.00, 75.00, 20, 5, 'Regal B, Polka 3', 5, 2);
INSERT INTO MagazynCzesc (ID_Czesci, NazwaCzesci, KodProducenta, Cena_Zakupu, CenaSprzedazy, IloscDostepna, MinStanAlarmowy, Lokalizacja, ID_Kategorii, ID_Dostawcy) VALUES 
    (SEQ_MAGAZYNCZESC.NEXTVAL, 'Olej silnikowy 5W30 5L', 'CASTROL-EDGE5W30', 180.00, 250.00, 25, 10, 'Regal C, Polka 1', 6, 2);
INSERT INTO MagazynCzesc (ID_Czesci, NazwaCzesci, KodProducenta, Cena_Zakupu, CenaSprzedazy, IloscDostepna, MinStanAlarmowy, Lokalizacja, ID_Kategorii, ID_Dostawcy) VALUES 
    (SEQ_MAGAZYNCZESC.NEXTVAL, 'Amortyzator przod VW Golf', 'SACHS-315520', 250.00, 380.00, 8, 4, 'Regal D, Polka 1', 2, 3);
INSERT INTO MagazynCzesc (ID_Czesci, NazwaCzesci, KodProducenta, Cena_Zakupu, CenaSprzedazy, IloscDostepna, MinStanAlarmowy, Lokalizacja, ID_Kategorii, ID_Dostawcy) VALUES 
    (SEQ_MAGAZYNCZESC.NEXTVAL, 'Tarcza hamulcowa przod VW', 'BREMBO-09.9772.11', 150.00, 220.00, 10, 4, 'Regal A, Polka 2', 1, 1);
INSERT INTO MagazynCzesc (ID_Czesci, NazwaCzesci, KodProducenta, Cena_Zakupu, CenaSprzedazy, IloscDostepna, MinStanAlarmowy, Lokalizacja, ID_Kategorii, ID_Dostawcy) VALUES 
    (SEQ_MAGAZYNCZESC.NEXTVAL, 'Akumulator 12V 60Ah', 'VARTA-D59', 320.00, 450.00, 5, 3, 'Regal E, Polka 1', 4, 2);
INSERT INTO MagazynCzesc (ID_Czesci, NazwaCzesci, KodProducenta, Cena_Zakupu, CenaSprzedazy, IloscDostepna, MinStanAlarmowy, Lokalizacja, ID_Kategorii, ID_Dostawcy) VALUES 
    (SEQ_MAGAZYNCZESC.NEXTVAL, 'Pasek rozrzadu VW 1.4/1.6', 'CONTI-CT1028', 85.00, 130.00, 6, 3, 'Regal F, Polka 1', 10, 3);
INSERT INTO MagazynCzesc (ID_Czesci, NazwaCzesci, KodProducenta, Cena_Zakupu, CenaSprzedazy, IloscDostepna, MinStanAlarmowy, Lokalizacja, ID_Kategorii, ID_Dostawcy) VALUES 
    (SEQ_MAGAZYNCZESC.NEXTVAL, 'Zarowka H7 55W', 'OSRAM-64210', 15.00, 30.00, 50, 20, 'Regal G, Polka 1', 7, 1);
INSERT INTO MagazynCzesc (ID_Czesci, NazwaCzesci, KodProducenta, Cena_Zakupu, CenaSprzedazy, IloscDostepna, MinStanAlarmowy, Lokalizacja, ID_Kategorii, ID_Dostawcy) VALUES 
    (SEQ_MAGAZYNCZESC.NEXTVAL, 'Plyn hamulcowy DOT4 1L', 'ATE-03990164022', 35.00, 55.00, 15, 5, 'Regal C, Polka 2', 6, 2);

-- ============================================================================
-- PRZYKLADOWE ZLECENIA
-- ============================================================================

-- Zlecenie 1 - Wydane (zakonczone)
INSERT INTO Zlecenie (ID_Zlecenia, NumerZlecenia, DataPrzyjecia, DataPlanowanegoOdbioru, DataRzeczywistegOdbioru, OpisUsterki, Uwagi, KosztCalkowity, ID_Pojazdu, ID_Pracownika, ID_AktualnegoStatusu) VALUES 
    (SEQ_ZLECENIE.NEXTVAL, 'ZLC/2026/00001', DATE '2026-01-10', DATE '2026-01-12', DATE '2026-01-12', 'Wymiana oleju i filtrow, przeglad okresowy', 'Klient prosi o sprawdzenie hamulcow', 520.00, 1, 4, 7);

-- Zlecenie 2 - W realizacji
INSERT INTO Zlecenie (ID_Zlecenia, NumerZlecenia, DataPrzyjecia, DataPlanowanegoOdbioru, DataRzeczywistegOdbioru, OpisUsterki, Uwagi, KosztCalkowity, ID_Pojazdu, ID_Pracownika, ID_AktualnegoStatusu) VALUES 
    (SEQ_ZLECENIE.NEXTVAL, 'ZLC/2026/00002', DATE '2026-01-15', DATE '2026-01-18', NULL, 'Wymiana klockow hamulcowych przednich, stukanie podczas hamowania', NULL, 380.00, 2, 4, 4);

-- Zlecenie 3 - Nowe
INSERT INTO Zlecenie (ID_Zlecenia, NumerZlecenia, DataPrzyjecia, DataPlanowanegoOdbioru, DataRzeczywistegOdbioru, OpisUsterki, Uwagi, KosztCalkowity, ID_Pojazdu, ID_Pracownika, ID_AktualnegoStatusu) VALUES 
    (SEQ_ZLECENIE.NEXTVAL, 'ZLC/2026/00003', DATE '2026-01-18', DATE '2026-01-22', NULL, 'Diagnostyka - kontrolka check engine, spadek mocy silnika', 'Auto sluzbowe, pilne', 0, 3, 4, 1);

-- Zlecenie 4 - Oczekuje na czesci
INSERT INTO Zlecenie (ID_Zlecenia, NumerZlecenia, DataPrzyjecia, DataPlanowanegoOdbioru, DataRzeczywistegOdbioru, OpisUsterki, Uwagi, KosztCalkowity, ID_Pojazdu, ID_Pracownika, ID_AktualnegoStatusu) VALUES 
    (SEQ_ZLECENIE.NEXTVAL, 'ZLC/2026/00004', DATE '2026-01-12', DATE '2026-01-20', NULL, 'Wymiana rozrzadu, auto ma 120000km', NULL, 1200.00, 4, 4, 5);

-- ============================================================================
-- HISTORIA ZMIAN STATUSOW
-- ============================================================================

-- Historia zlecenia 1
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-10 08:30:00', 'Przyjeto zlecenie', 1, NULL, 1, 4);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-10 10:00:00', 'Wycena zatwierdzona', 1, 1, 2, 1);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-10 11:00:00', 'Klient zaakceptowal wycene', 1, 2, 3, 4);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-11 08:00:00', 'Rozpoczeto prace', 1, 3, 4, 2);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-12 14:00:00', 'Naprawa zakonczona', 1, 4, 6, 2);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-12 16:30:00', 'Pojazd wydany klientowi', 1, 6, 7, 4);

-- Historia zlecenia 2
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-15 09:00:00', 'Przyjeto zlecenie', 2, NULL, 1, 4);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-15 14:00:00', 'Wyceniono zlecenie', 2, 1, 2, 1);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-16 10:00:00', 'Klient potwierdzil telefonicznie', 2, 2, 3, 4);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-17 08:00:00', 'Rozpoczeto wymiane klockow', 2, 3, 4, 2);

-- Historia zlecenia 3
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-18 08:15:00', 'Przyjeto zlecenie - pilne', 3, NULL, 1, 4);

-- Historia zlecenia 4
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-12 11:00:00', 'Przyjeto zlecenie', 4, NULL, 1, 4);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-13 09:00:00', 'Wycena 1200 PLN', 4, 1, 2, 1);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-14 10:00:00', 'Zaakceptowano', 4, 2, 3, 4);
INSERT INTO HistoriaZmian (ID_Historii, DataZmiany, Komentarz, ID_Zlecenia, ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika) VALUES 
    (SEQ_HISTORIAZMIAN.NEXTVAL, TIMESTAMP '2026-01-14 14:00:00', 'Brak kompletu rozrzadu - zamowiono', 4, 3, 5, 2);

-- ============================================================================
-- POZYCJE ZLECEN - USLUGI
-- ============================================================================

-- Zlecenie 1 - uslugi
INSERT INTO PozycjeZlecenia_Uslugi (ID_PozycjiUslugi, Krotnosc, RabatNaUsluge, CenaJednostkowa, CenaKoncowa, ID_Zlecenia, ID_Uslugi, ID_Pracownika) VALUES 
    (SEQ_POZYCJEZLECENIA_USLUGI.NEXTVAL, 1, 0, 150.00, 150.00, 1, 1, 2);
INSERT INTO PozycjeZlecenia_Uslugi (ID_PozycjiUslugi, Krotnosc, RabatNaUsluge, CenaJednostkowa, CenaKoncowa, ID_Zlecenia, ID_Uslugi, ID_Pracownika) VALUES 
    (SEQ_POZYCJEZLECENIA_USLUGI.NEXTVAL, 1, 0, 50.00, 50.00, 1, 9, 2);

-- Zlecenie 2 - uslugi
INSERT INTO PozycjeZlecenia_Uslugi (ID_PozycjiUslugi, Krotnosc, RabatNaUsluge, CenaJednostkowa, CenaKoncowa, ID_Zlecenia, ID_Uslugi, ID_Pracownika) VALUES 
    (SEQ_POZYCJEZLECENIA_USLUGI.NEXTVAL, 1, 10, 200.00, 180.00, 2, 2, 2);

-- ============================================================================
-- POZYCJE ZLECEN - CZESCI
-- ============================================================================

-- Zlecenie 1 - czesci
INSERT INTO PozycjeZlecenia_Czesci (ID_PozycjiCzesci, Ilosc, CenaWChwiliSprzedazy, Rabat, CenaKoncowa, ID_Zlecenia, ID_Czesci) VALUES 
    (SEQ_POZYCJEZLECENIA_CZESCI.NEXTVAL, 1, 250.00, 0, 250.00, 1, 4);
INSERT INTO PozycjeZlecenia_Czesci (ID_PozycjiCzesci, Ilosc, CenaWChwiliSprzedazy, Rabat, CenaKoncowa, ID_Zlecenia, ID_Czesci) VALUES 
    (SEQ_POZYCJEZLECENIA_CZESCI.NEXTVAL, 1, 45.00, 0, 45.00, 1, 2);
INSERT INTO PozycjeZlecenia_Czesci (ID_PozycjiCzesci, Ilosc, CenaWChwiliSprzedazy, Rabat, CenaKoncowa, ID_Zlecenia, ID_Czesci) VALUES 
    (SEQ_POZYCJEZLECENIA_CZESCI.NEXTVAL, 1, 75.00, 0, 75.00, 1, 3);

-- Zlecenie 2 - czesci
INSERT INTO PozycjeZlecenia_Czesci (ID_PozycjiCzesci, Ilosc, CenaWChwiliSprzedazy, Rabat, CenaKoncowa, ID_Zlecenia, ID_Czesci) VALUES 
    (SEQ_POZYCJEZLECENIA_CZESCI.NEXTVAL, 1, 180.00, 10, 162.00, 2, 1);

-- ============================================================================
-- PRZYKLADOWE DOSTAWY
-- ============================================================================

INSERT INTO Dostawy (ID_Dostawy, DataDostawy, NumerFaktury, IloscSztuk, CenaJednostkowa, WartoscCalkowita, ID_Czesci, ID_Dostawcy) VALUES 
    (SEQ_DOSTAWY.NEXTVAL, DATE '2026-01-05', 'FV/2026/001', 20, 120.00, 2400.00, 1, 1);
INSERT INTO Dostawy (ID_Dostawy, DataDostawy, NumerFaktury, IloscSztuk, CenaJednostkowa, WartoscCalkowita, ID_Czesci, ID_Dostawcy) VALUES 
    (SEQ_DOSTAWY.NEXTVAL, DATE '2026-01-08', 'FV/2026/002', 50, 25.00, 1250.00, 2, 1);
INSERT INTO Dostawy (ID_Dostawy, DataDostawy, NumerFaktury, IloscSztuk, CenaJednostkowa, WartoscCalkowita, ID_Czesci, ID_Dostawcy) VALUES 
    (SEQ_DOSTAWY.NEXTVAL, DATE '2026-01-10', 'FV/IP/2026/100', 30, 180.00, 5400.00, 4, 2);

COMMIT;
