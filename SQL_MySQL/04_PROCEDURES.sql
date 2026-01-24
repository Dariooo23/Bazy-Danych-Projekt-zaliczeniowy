-- ============================================================================
-- PROCEDURY SKLADOWANE - MySQL
-- ============================================================================

DELIMITER //

-- ============================================================================
-- PROCEDURA 1: sp_NoweZlecenie
-- Tworzy nowe zlecenie serwisowe z automatycznym numerowaniem
-- ============================================================================
CREATE PROCEDURE sp_NoweZlecenie(
    IN p_id_pojazdu INT,
    IN p_id_pracownika INT,
    IN p_opis_usterki TEXT,
    IN p_data_planowana DATE,
    IN p_uwagi VARCHAR(1000),
    OUT p_id_zlecenia INT,
    OUT p_numer_zlecenia VARCHAR(20)
)
BEGIN
    DECLARE v_id_statusu INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Pobierz ID statusu "Nowe"
    SELECT ID_Statusu INTO v_id_statusu 
    FROM StatusyZlecen 
    WHERE NazwaStatusu = 'Nowe';
    
    -- Wygeneruj numer zlecenia
    SET p_numer_zlecenia = fn_GenerujNumerZlecenia();
    
    -- Utworz zlecenie
    INSERT INTO Zlecenie (
        NumerZlecenia, DataPrzyjecia, 
        DataPlanowanegoOdbioru, OpisUsterki, Uwagi,
        KosztCalkowity, ID_Pojazdu, ID_Pracownika, ID_AktualnegoStatusu
    ) VALUES (
        p_numer_zlecenia, CURRENT_DATE,
        p_data_planowana, p_opis_usterki, p_uwagi,
        0, p_id_pojazdu, p_id_pracownika, v_id_statusu
    );
    
    SET p_id_zlecenia = LAST_INSERT_ID();
    
    -- Dodaj pierwszy wpis w historii
    INSERT INTO HistoriaZmian (
        DataZmiany, Komentarz, ID_Zlecenia,
        ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika
    ) VALUES (
        NOW(3), 'Utworzono nowe zlecenie',
        p_id_zlecenia, NULL, v_id_statusu, p_id_pracownika
    );
    
    COMMIT;
    
    SELECT CONCAT('Utworzono zlecenie: ', p_numer_zlecenia) AS Komunikat;
END //

-- ============================================================================
-- PROCEDURA 2: sp_ZmienStatusZlecenia
-- Zmienia status zlecenia i rejestruje zmiane w historii
-- ============================================================================
CREATE PROCEDURE sp_ZmienStatusZlecenia(
    IN p_id_zlecenia INT,
    IN p_nowy_status VARCHAR(50),
    IN p_id_pracownika INT,
    IN p_komentarz VARCHAR(500)
)
BEGIN
    DECLARE v_stary_status_id INT;
    DECLARE v_nowy_status_id INT;
    DECLARE v_stary_status_nazwa VARCHAR(50);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Pobierz aktualny status
    SELECT z.ID_AktualnegoStatusu, s.NazwaStatusu
    INTO v_stary_status_id, v_stary_status_nazwa
    FROM Zlecenie z
    JOIN StatusyZlecen s ON z.ID_AktualnegoStatusu = s.ID_Statusu
    WHERE z.ID_Zlecenia = p_id_zlecenia;
    
    -- Pobierz ID nowego statusu
    SELECT ID_Statusu INTO v_nowy_status_id
    FROM StatusyZlecen
    WHERE NazwaStatusu = p_nowy_status;
    
    IF v_nowy_status_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nie znaleziono statusu';
    END IF;
    
    -- Sprawdz czy to ta sama wartosc
    IF v_stary_status_id = v_nowy_status_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Zlecenie ma juz ten status';
    END IF;
    
    -- Zaktualizuj status
    UPDATE Zlecenie
    SET ID_AktualnegoStatusu = v_nowy_status_id
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Jesli status = Wydane, ustaw date odbioru
    IF p_nowy_status = 'Wydane' THEN
        UPDATE Zlecenie
        SET DataRzeczywistegOdbioru = CURRENT_DATE
        WHERE ID_Zlecenia = p_id_zlecenia;
    END IF;
    
    -- Dodaj wpis do historii
    INSERT INTO HistoriaZmian (
        DataZmiany, Komentarz, ID_Zlecenia,
        ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika
    ) VALUES (
        NOW(3), 
        IFNULL(p_komentarz, CONCAT('Zmiana statusu z ', v_stary_status_nazwa, ' na ', p_nowy_status)),
        p_id_zlecenia, v_stary_status_id, v_nowy_status_id, p_id_pracownika
    );
    
    COMMIT;
    
    SELECT CONCAT('Status zmieniony z ', v_stary_status_nazwa, ' na ', p_nowy_status) AS Komunikat;
END //

-- ============================================================================
-- PROCEDURA 3: sp_DodajUslugeDoZlecenia
-- Dodaje usluge do zlecenia z uwzglednieniem rabatu klienta
-- ============================================================================
CREATE PROCEDURE sp_DodajUslugeDoZlecenia(
    IN p_id_zlecenia INT,
    IN p_id_uslugi INT,
    IN p_krotnosc INT,
    IN p_id_pracownika_wyk INT,
    IN p_rabat_dodatkowy DECIMAL(5,2)
)
BEGIN
    DECLARE v_cena_bazowa DECIMAL(10,2);
    DECLARE v_rabat_klienta DECIMAL(5,2);
    DECLARE v_rabat_calkowity DECIMAL(5,2);
    DECLARE v_cena_koncowa DECIMAL(12,2);
    DECLARE v_id_pojazdu INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    -- Domyslne wartosci
    IF p_krotnosc IS NULL THEN SET p_krotnosc = 1; END IF;
    IF p_rabat_dodatkowy IS NULL THEN SET p_rabat_dodatkowy = 0; END IF;
    
    START TRANSACTION;
    
    -- Pobierz ID pojazdu ze zlecenia
    SELECT ID_Pojazdu INTO v_id_pojazdu
    FROM Zlecenie WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Pobierz cene bazowa uslugi
    SELECT CenaBazowa INTO v_cena_bazowa
    FROM KatalogUslug WHERE ID_Uslugi = p_id_uslugi;
    
    -- Pobierz rabat klienta
    SET v_rabat_klienta = fn_PobierzRabatKlienta(v_id_pojazdu);
    
    -- Oblicz rabat calkowity (nie wiecej niz 100%)
    SET v_rabat_calkowity = LEAST(v_rabat_klienta + p_rabat_dodatkowy, 100);
    
    -- Oblicz cene koncowa
    SET v_cena_koncowa = v_cena_bazowa * p_krotnosc * (1 - v_rabat_calkowity / 100);
    
    -- Dodaj pozycje
    INSERT INTO PozycjeZlecenia_Uslugi (
        Krotnosc, RabatNaUsluge, 
        CenaJednostkowa, CenaKoncowa, 
        ID_Zlecenia, ID_Uslugi, ID_Pracownika
    ) VALUES (
        p_krotnosc, v_rabat_calkowity,
        v_cena_bazowa, v_cena_koncowa,
        p_id_zlecenia, p_id_uslugi, p_id_pracownika_wyk
    );
    
    -- Zaktualizuj koszt calkowity zlecenia
    UPDATE Zlecenie
    SET KosztCalkowity = fn_ObliczWartoscZlecenia(p_id_zlecenia)
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    COMMIT;
    
    SELECT CONCAT('Dodano usluge. Cena koncowa: ', v_cena_koncowa, ' PLN') AS Komunikat;
END //

-- ============================================================================
-- PROCEDURA 4: sp_DodajCzescDoZlecenia
-- Dodaje czesc do zlecenia i zmniejsza stan magazynowy
-- ============================================================================
CREATE PROCEDURE sp_DodajCzescDoZlecenia(
    IN p_id_zlecenia INT,
    IN p_id_czesci INT,
    IN p_ilosc INT,
    IN p_rabat DECIMAL(5,2)
)
BEGIN
    DECLARE v_cena_sprzedazy DECIMAL(10,2);
    DECLARE v_dostepna_ilosc INT;
    DECLARE v_rabat_klienta DECIMAL(5,2);
    DECLARE v_rabat_calkowity DECIMAL(5,2);
    DECLARE v_cena_koncowa DECIMAL(12,2);
    DECLARE v_id_pojazdu INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    -- Domyslne wartosci
    IF p_ilosc IS NULL THEN SET p_ilosc = 1; END IF;
    IF p_rabat IS NULL THEN SET p_rabat = 0; END IF;
    
    START TRANSACTION;
    
    -- Pobierz ID pojazdu ze zlecenia
    SELECT ID_Pojazdu INTO v_id_pojazdu
    FROM Zlecenie WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Sprawdz dostepnosc
    SELECT CenaSprzedazy, IloscDostepna 
    INTO v_cena_sprzedazy, v_dostepna_ilosc
    FROM MagazynCzesc WHERE ID_Czesci = p_id_czesci;
    
    IF v_dostepna_ilosc < p_ilosc THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Niewystarczajaca ilosc na magazynie';
    END IF;
    
    -- Pobierz rabat klienta
    SET v_rabat_klienta = fn_PobierzRabatKlienta(v_id_pojazdu);
    SET v_rabat_calkowity = LEAST(v_rabat_klienta + p_rabat, 100);
    
    -- Oblicz cene koncowa
    SET v_cena_koncowa = v_cena_sprzedazy * p_ilosc * (1 - v_rabat_calkowity / 100);
    
    -- Dodaj pozycje
    INSERT INTO PozycjeZlecenia_Czesci (
        Ilosc, CenaWChwiliSprzedazy, 
        Rabat, CenaKoncowa, ID_Zlecenia, ID_Czesci
    ) VALUES (
        p_ilosc, v_cena_sprzedazy,
        v_rabat_calkowity, v_cena_koncowa, p_id_zlecenia, p_id_czesci
    );
    
    -- Zmniejsz stan magazynowy
    UPDATE MagazynCzesc
    SET IloscDostepna = IloscDostepna - p_ilosc
    WHERE ID_Czesci = p_id_czesci;
    
    -- Zaktualizuj koszt calkowity zlecenia
    UPDATE Zlecenie
    SET KosztCalkowity = fn_ObliczWartoscZlecenia(p_id_zlecenia)
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    COMMIT;
    
    SELECT CONCAT('Dodano czesc. Cena koncowa: ', v_cena_koncowa, ' PLN') AS Komunikat;
END //

-- ============================================================================
-- PROCEDURA 5: sp_RejestrujDostawe
-- Rejestruje dostawe czesci i aktualizuje stan magazynowy
-- ============================================================================
CREATE PROCEDURE sp_RejestrujDostawe(
    IN p_id_czesci INT,
    IN p_id_dostawcy INT,
    IN p_ilosc INT,
    IN p_cena_jednostkowa DECIMAL(10,2),
    IN p_numer_faktury VARCHAR(50)
)
BEGIN
    DECLARE v_wartosc_calkowita DECIMAL(12,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    SET v_wartosc_calkowita = p_ilosc * p_cena_jednostkowa;
    
    -- Dodaj dostawe
    INSERT INTO Dostawy (
        DataDostawy, NumerFaktury,
        IloscSztuk, CenaJednostkowa, WartoscCalkowita,
        ID_Czesci, ID_Dostawcy
    ) VALUES (
        CURRENT_DATE, p_numer_faktury,
        p_ilosc, p_cena_jednostkowa, v_wartosc_calkowita,
        p_id_czesci, p_id_dostawcy
    );
    
    -- Stan magazynowy zostanie zaktualizowany przez trigger
    
    -- Opcjonalnie: zaktualizuj cene zakupu jesli sie zmienila
    UPDATE MagazynCzesc
    SET Cena_Zakupu = p_cena_jednostkowa
    WHERE ID_Czesci = p_id_czesci
    AND Cena_Zakupu != p_cena_jednostkowa;
    
    COMMIT;
    
    SELECT CONCAT('Zarejestrowano dostawe: ', p_ilosc, ' szt. Wartosc: ', v_wartosc_calkowita, ' PLN') AS Komunikat;
END //

-- ============================================================================
-- PROCEDURA 6: sp_ZamknijZlecenie
-- Zamyka zlecenie i przelicza koszty
-- ============================================================================
CREATE PROCEDURE sp_ZamknijZlecenie(
    IN p_id_zlecenia INT,
    IN p_id_pracownika INT
)
BEGIN
    DECLARE v_liczba_uslug INT;
    DECLARE v_liczba_czesci INT;
    DECLARE v_koszt_calkowity DECIMAL(12,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Sprawdz czy sa pozycje
    SELECT COUNT(*) INTO v_liczba_uslug
    FROM PozycjeZlecenia_Uslugi WHERE ID_Zlecenia = p_id_zlecenia;
    
    SELECT COUNT(*) INTO v_liczba_czesci
    FROM PozycjeZlecenia_Czesci WHERE ID_Zlecenia = p_id_zlecenia;
    
    IF v_liczba_uslug = 0 AND v_liczba_czesci = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Nie mozna zamknac zlecenia bez pozycji';
    END IF;
    
    -- Przelicz koszt
    SET v_koszt_calkowity = fn_ObliczWartoscZlecenia(p_id_zlecenia);
    
    UPDATE Zlecenie
    SET KosztCalkowity = v_koszt_calkowity
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    COMMIT;
    
    -- Zmien status na Zakonczone
    CALL sp_ZmienStatusZlecenia(p_id_zlecenia, 'Zakonczone', p_id_pracownika, 
                               CONCAT('Zlecenie zamkniete. Koszt: ', v_koszt_calkowity, ' PLN'));
    
    SELECT CONCAT('Zlecenie zamkniete. Koszt: ', v_koszt_calkowity, ' PLN. Uslugi: ', 
                  v_liczba_uslug, ', Czesci: ', v_liczba_czesci) AS Komunikat;
END //

DELIMITER ;
