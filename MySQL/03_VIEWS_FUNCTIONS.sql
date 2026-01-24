-- ============================================================================
-- WIDOKI I FUNKCJE - MySQL
-- ============================================================================

-- ============================================================================
-- WIDOK 1: v_ZleceniaAktywne
-- Lista wszystkich aktywnych zlecen (nie wydane)
-- ============================================================================
CREATE OR REPLACE VIEW v_ZleceniaAktywne AS
SELECT 
    z.ID_Zlecenia,
    z.NumerZlecenia,
    z.DataPrzyjecia,
    z.DataPlanowanegoOdbioru,
    z.OpisUsterki,
    z.KosztCalkowity,
    s.NazwaStatusu AS Status,
    p.VIN,
    p.NrRejestracyjny,
    m.NazwaModelu,
    mk.NazwaMarki,
    CONCAT(o_klient.Imie, ' ', o_klient.Nazwisko) AS Klient,
    o_klient.Telefon AS TelefonKlienta,
    CONCAT(o_prac.Imie, ' ', o_prac.Nazwisko) AS PracownikPrzyjmujacy
FROM Zlecenie z
JOIN StatusyZlecen s ON z.ID_AktualnegoStatusu = s.ID_Statusu
JOIN Pojazd p ON z.ID_Pojazdu = p.ID_Pojazdu
JOIN Model m ON p.ID_Modelu = m.ID_Modelu
JOIN Marka mk ON m.ID_Marki = mk.ID_Marki
JOIN Klient k ON p.ID_Klienta = k.ID_Osoby
JOIN Osoba o_klient ON k.ID_Osoby = o_klient.ID_Osoby
JOIN Pracownik pr ON z.ID_Pracownika = pr.ID_Osoby
JOIN Osoba o_prac ON pr.ID_Osoby = o_prac.ID_Osoby
WHERE s.NazwaStatusu NOT IN ('Wydane', 'Anulowane')
ORDER BY z.DataPrzyjecia DESC;

-- ============================================================================
-- WIDOK 2: v_PojazdyKlientow
-- Lista pojazdow z danymi wlascicieli
-- ============================================================================
CREATE OR REPLACE VIEW v_PojazdyKlientow AS
SELECT 
    p.ID_Pojazdu,
    p.VIN,
    p.NrRejestracyjny,
    p.RokProdukcji,
    p.PojemnoscSilnika,
    mk.NazwaMarki,
    m.NazwaModelu,
    CONCAT(mk.NazwaMarki, ' ', m.NazwaModelu) AS Pojazd,
    o.ID_Osoby AS ID_Klienta,
    CONCAT(o.Imie, ' ', o.Nazwisko) AS Wlasciciel,
    o.Telefon,
    o.Email,
    o.Miasto,
    k.NIP,
    k.RabatStaly,
    (SELECT COUNT(*) FROM Zlecenie z WHERE z.ID_Pojazdu = p.ID_Pojazdu) AS LiczbaZlecen
FROM Pojazd p
JOIN Model m ON p.ID_Modelu = m.ID_Modelu
JOIN Marka mk ON m.ID_Marki = mk.ID_Marki
JOIN Klient k ON p.ID_Klienta = k.ID_Osoby
JOIN Osoba o ON k.ID_Osoby = o.ID_Osoby
ORDER BY o.Nazwisko, o.Imie;

-- ============================================================================
-- WIDOK 3: v_MagazynNiskiStan
-- Czesci z iloscia ponizej minimalnego stanu alarmowego
-- ============================================================================
CREATE OR REPLACE VIEW v_MagazynNiskiStan AS
SELECT 
    mc.ID_Czesci,
    mc.NazwaCzesci,
    mc.KodProducenta,
    mc.IloscDostepna,
    mc.MinStanAlarmowy,
    mc.MinStanAlarmowy - mc.IloscDostepna AS Brakuje,
    mc.Cena_Zakupu,
    mc.CenaSprzedazy,
    mc.Lokalizacja,
    kc.NazwaKategorii AS Kategoria,
    d.NazwaFirmy AS GlownyDostawca,
    d.Telefon AS TelefonDostawcy
FROM MagazynCzesc mc
JOIN KategoriaCzesci kc ON mc.ID_Kategorii = kc.ID_Kategorii
LEFT JOIN Dostawca d ON mc.ID_Dostawcy = d.ID_Dostawcy
WHERE mc.IloscDostepna < mc.MinStanAlarmowy
ORDER BY (mc.MinStanAlarmowy - mc.IloscDostepna) DESC;

-- ============================================================================
-- WIDOK 4: v_PracownicyAktywni
-- Lista aktywnych pracownikow z ich stanowiskami
-- ============================================================================
CREATE OR REPLACE VIEW v_PracownicyAktywni AS
SELECT 
    o.ID_Osoby AS ID_Pracownika,
    o.Imie,
    o.Nazwisko,
    CONCAT(o.Imie, ' ', o.Nazwisko) AS PelneNazwisko,
    o.Telefon,
    o.Email,
    o.Miasto,
    p.DataZatrudnienia,
    FLOOR(DATEDIFF(CURRENT_DATE, p.DataZatrudnienia) / 365) AS LatPracy,
    p.PensjaPodstawowa,
    s.NazwaStanowiska,
    s.StawkaGodzinowa,
    (SELECT COUNT(*) FROM Zlecenie z WHERE z.ID_Pracownika = p.ID_Osoby) AS PrzyjetychZlecen,
    (SELECT COUNT(*) FROM PozycjeZlecenia_Uslugi pu WHERE pu.ID_Pracownika = p.ID_Osoby) AS WykonanychUslug
FROM Pracownik p
JOIN Osoba o ON p.ID_Osoby = o.ID_Osoby
JOIN Stanowisko s ON p.ID_Stanowiska = s.ID_Stanowiska
WHERE p.DataZwolnienia IS NULL
ORDER BY o.Nazwisko, o.Imie;

-- ============================================================================
-- WIDOK 5: v_HistoriaZlecenia
-- Pelna historia zmian statusow zlecenia
-- ============================================================================
CREATE OR REPLACE VIEW v_HistoriaZlecenia AS
SELECT 
    z.ID_Zlecenia,
    z.NumerZlecenia,
    hz.DataZmiany,
    sp.NazwaStatusu AS StatusPoprzedni,
    sn.NazwaStatusu AS StatusNowy,
    hz.Komentarz,
    CONCAT(o.Imie, ' ', o.Nazwisko) AS ZmienilPracownik
FROM HistoriaZmian hz
JOIN Zlecenie z ON hz.ID_Zlecenia = z.ID_Zlecenia
LEFT JOIN StatusyZlecen sp ON hz.ID_StatusuPoprzedni = sp.ID_Statusu
JOIN StatusyZlecen sn ON hz.ID_StatusuNowy = sn.ID_Statusu
JOIN Pracownik p ON hz.ID_Pracownika = p.ID_Osoby
JOIN Osoba o ON p.ID_Osoby = o.ID_Osoby
ORDER BY z.NumerZlecenia, hz.DataZmiany;

-- ============================================================================
-- WIDOK 6: v_SzczegolyZlecenia
-- Szczegolowy widok zlecenia z uslugami i czesciami
-- ============================================================================
CREATE OR REPLACE VIEW v_SzczegolyZlecenia AS
SELECT 
    z.ID_Zlecenia,
    z.NumerZlecenia,
    z.DataPrzyjecia,
    z.DataPlanowanegoOdbioru,
    z.DataRzeczywistegOdbioru,
    s.NazwaStatusu AS Status,
    CONCAT(mk.NazwaMarki, ' ', m.NazwaModelu) AS Pojazd,
    p.NrRejestracyjny,
    p.VIN,
    CONCAT(o_kl.Imie, ' ', o_kl.Nazwisko) AS Klient,
    o_kl.Telefon AS TelefonKlienta,
    z.OpisUsterki,
    z.Uwagi,
    (SELECT IFNULL(SUM(pu.CenaKoncowa), 0) 
     FROM PozycjeZlecenia_Uslugi pu 
     WHERE pu.ID_Zlecenia = z.ID_Zlecenia) AS KosztUslug,
    (SELECT IFNULL(SUM(pc.CenaKoncowa), 0) 
     FROM PozycjeZlecenia_Czesci pc 
     WHERE pc.ID_Zlecenia = z.ID_Zlecenia) AS KosztCzesci,
    z.KosztCalkowity
FROM Zlecenie z
JOIN StatusyZlecen s ON z.ID_AktualnegoStatusu = s.ID_Statusu
JOIN Pojazd p ON z.ID_Pojazdu = p.ID_Pojazdu
JOIN Model m ON p.ID_Modelu = m.ID_Modelu
JOIN Marka mk ON m.ID_Marki = mk.ID_Marki
JOIN Klient k ON p.ID_Klienta = k.ID_Osoby
JOIN Osoba o_kl ON k.ID_Osoby = o_kl.ID_Osoby;

-- ============================================================================
-- WIDOK 7: v_RaportMiesieczny
-- Raport miesieczny - podsumowanie zlecen
-- ============================================================================
CREATE OR REPLACE VIEW v_RaportMiesieczny AS
SELECT 
    DATE_FORMAT(z.DataPrzyjecia, '%Y-%m') AS Miesiac,
    COUNT(*) AS LiczbaZlecen,
    SUM(CASE WHEN s.NazwaStatusu = 'Wydane' THEN 1 ELSE 0 END) AS Zakonczonych,
    SUM(CASE WHEN s.NazwaStatusu NOT IN ('Wydane', 'Anulowane') THEN 1 ELSE 0 END) AS WTrakcie,
    SUM(CASE WHEN s.NazwaStatusu = 'Wydane' THEN z.KosztCalkowity ELSE 0 END) AS PrzychodyZrealizowane,
    ROUND(AVG(CASE WHEN s.NazwaStatusu = 'Wydane' THEN z.KosztCalkowity END), 2) AS SredniKoszt,
    MAX(z.KosztCalkowity) AS NajwiekszeZlecenie
FROM Zlecenie z
JOIN StatusyZlecen s ON z.ID_AktualnegoStatusu = s.ID_Statusu
GROUP BY DATE_FORMAT(z.DataPrzyjecia, '%Y-%m')
ORDER BY Miesiac DESC;

-- ============================================================================
-- FUNKCJA 1: fn_GenerujNumerZlecenia
-- Generuje unikalny numer zlecenia w formacie ZLC/RRRR/NNNNN
-- ============================================================================
DELIMITER //

DROP FUNCTION IF EXISTS fn_GenerujNumerZlecenia //

CREATE FUNCTION fn_GenerujNumerZlecenia()
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_rok VARCHAR(4);
    DECLARE v_numer INT;
    DECLARE v_numer_zlecenia VARCHAR(20);
    
    SET v_rok = YEAR(CURRENT_DATE);
    
    -- Pobierz najwyzszy numer z biezacego roku + 1
    SELECT IFNULL(MAX(CAST(SUBSTRING(NumerZlecenia, 10, 5) AS UNSIGNED)), 0) + 1
    INTO v_numer
    FROM Zlecenie
    WHERE NumerZlecenia LIKE CONCAT('ZLC/', v_rok, '/%');
    
    SET v_numer_zlecenia = CONCAT('ZLC/', v_rok, '/', LPAD(v_numer, 5, '0'));
    
    RETURN v_numer_zlecenia;
END //

DELIMITER ;

-- ============================================================================
-- FUNKCJA 2: fn_ObliczWartoscZlecenia
-- Oblicza calkowita wartosc zlecenia (uslugi + czesci)
-- ============================================================================
DELIMITER //

DROP FUNCTION IF EXISTS fn_ObliczWartoscZlecenia //

CREATE FUNCTION fn_ObliczWartoscZlecenia(p_id_zlecenia INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_koszt_uslug DECIMAL(12,2) DEFAULT 0;
    DECLARE v_koszt_czesci DECIMAL(12,2) DEFAULT 0;
    
    SELECT IFNULL(SUM(CenaKoncowa), 0)
    INTO v_koszt_uslug
    FROM PozycjeZlecenia_Uslugi
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    SELECT IFNULL(SUM(CenaKoncowa), 0)
    INTO v_koszt_czesci
    FROM PozycjeZlecenia_Czesci
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    RETURN v_koszt_uslug + v_koszt_czesci;
END //

DELIMITER ;

-- ============================================================================
-- FUNKCJA 3: fn_PobierzRabatKlienta
-- Pobiera staly rabat klienta na podstawie ID pojazdu
-- ============================================================================
DELIMITER //

DROP FUNCTION IF EXISTS fn_PobierzRabatKlienta //

CREATE FUNCTION fn_PobierzRabatKlienta(p_id_pojazdu INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_rabat DECIMAL(5,2) DEFAULT 0;
    
    SELECT IFNULL(k.RabatStaly, 0)
    INTO v_rabat
    FROM Pojazd p
    JOIN Klient k ON p.ID_Klienta = k.ID_Osoby
    WHERE p.ID_Pojazdu = p_id_pojazdu;
    
    RETURN IFNULL(v_rabat, 0);
END //

DELIMITER ;

-- ============================================================================
-- FUNKCJA 4: fn_SprawdzDostepnoscCzesci
-- Sprawdza czy czesc jest dostepna w wymaganej ilosci
-- ============================================================================
DELIMITER //

DROP FUNCTION IF EXISTS fn_SprawdzDostepnoscCzesci //

CREATE FUNCTION fn_SprawdzDostepnoscCzesci(
    p_id_czesci INT,
    p_wymagana_ilosc INT
)
RETURNS VARCHAR(100)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_dostepna INT DEFAULT 0;
    DECLARE v_nazwa VARCHAR(100);
    
    SELECT IloscDostepna, NazwaCzesci
    INTO v_dostepna, v_nazwa
    FROM MagazynCzesc
    WHERE ID_Czesci = p_id_czesci;
    
    IF v_dostepna IS NULL THEN
        RETURN 'NIEZNANA CZESC';
    ELSEIF v_dostepna >= p_wymagana_ilosc THEN
        RETURN 'DOSTEPNA';
    ELSE
        RETURN CONCAT('BRAK - dostepne tylko ', v_dostepna, ' szt.');
    END IF;
END //

DELIMITER ;
