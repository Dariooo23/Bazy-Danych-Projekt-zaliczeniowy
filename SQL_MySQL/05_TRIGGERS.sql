-- ============================================================================
-- TRIGGERY (WYZWALACZE) - MySQL
-- ============================================================================

DELIMITER //

-- ============================================================================
-- TRIGGER 1: trg_Zlecenie_AutoNumer
-- Automatycznie generuje numer zlecenia przy INSERT (jesli nie podano)
-- ============================================================================
CREATE TRIGGER trg_Zlecenie_AutoNumer
BEFORE INSERT ON Zlecenie
FOR EACH ROW
BEGIN
    DECLARE v_rok VARCHAR(4);
    DECLARE v_numer INT;
    
    -- Jesli numer zlecenia nie podano, wygeneruj automatycznie
    IF NEW.NumerZlecenia IS NULL OR NEW.NumerZlecenia = '' THEN
        SET v_rok = YEAR(CURRENT_DATE);
        
        SELECT IFNULL(MAX(CAST(SUBSTRING(NumerZlecenia, 10, 5) AS UNSIGNED)), 0) + 1
        INTO v_numer
        FROM Zlecenie
        WHERE NumerZlecenia LIKE CONCAT('ZLC/', v_rok, '/%');
        
        SET NEW.NumerZlecenia = CONCAT('ZLC/', v_rok, '/', LPAD(v_numer, 5, '0'));
    END IF;
END //

-- ============================================================================
-- TRIGGER 2: trg_Magazyn_AlertNiskiStan
-- Loguje ostrzezenie gdy stan magazynowy spada ponizej minimum
-- (W MySQL triggery nie moga wyswietlac komunikatow, wiec logujemy do tabeli)
-- ============================================================================

-- Najpierw utworz tabele logowania alertow
CREATE TABLE IF NOT EXISTS LogAlertyMagazyn (
    ID_Alertu       INT AUTO_INCREMENT PRIMARY KEY,
    DataAlertu      DATETIME DEFAULT CURRENT_TIMESTAMP,
    ID_Czesci       INT,
    NazwaCzesci     VARCHAR(100),
    KodProducenta   VARCHAR(50),
    StanAktualny    INT,
    StanMinimalny   INT,
    DoZamowienia    INT
) ENGINE=InnoDB //

CREATE TRIGGER trg_Magazyn_AlertNiskiStan
AFTER UPDATE ON MagazynCzesc
FOR EACH ROW
BEGIN
    IF NEW.IloscDostepna < NEW.MinStanAlarmowy 
       AND OLD.IloscDostepna >= OLD.MinStanAlarmowy THEN
        INSERT INTO LogAlertyMagazyn (
            ID_Czesci, NazwaCzesci, KodProducenta, 
            StanAktualny, StanMinimalny, DoZamowienia
        ) VALUES (
            NEW.ID_Czesci, NEW.NazwaCzesci, NEW.KodProducenta,
            NEW.IloscDostepna, NEW.MinStanAlarmowy, 
            NEW.MinStanAlarmowy - NEW.IloscDostepna
        );
    END IF;
END //

-- ============================================================================
-- TRIGGER 3: trg_PozUslugi_ObliczCene
-- Automatycznie oblicza cene koncowa pozycji uslugi
-- ============================================================================
CREATE TRIGGER trg_PozUslugi_ObliczCene_Insert
BEFORE INSERT ON PozycjeZlecenia_Uslugi
FOR EACH ROW
BEGIN
    IF NEW.CenaKoncowa IS NULL OR NEW.CenaKoncowa = 0 THEN
        SET NEW.CenaKoncowa = NEW.CenaJednostkowa * NEW.Krotnosc * (1 - IFNULL(NEW.RabatNaUsluge, 0) / 100);
    END IF;
    
    IF NEW.CenaKoncowa < 0 THEN
        SET NEW.CenaKoncowa = 0;
    END IF;
END //

CREATE TRIGGER trg_PozUslugi_ObliczCene_Update
BEFORE UPDATE ON PozycjeZlecenia_Uslugi
FOR EACH ROW
BEGIN
    IF NEW.CenaKoncowa IS NULL OR NEW.CenaKoncowa = 0 THEN
        SET NEW.CenaKoncowa = NEW.CenaJednostkowa * NEW.Krotnosc * (1 - IFNULL(NEW.RabatNaUsluge, 0) / 100);
    END IF;
    
    IF NEW.CenaKoncowa < 0 THEN
        SET NEW.CenaKoncowa = 0;
    END IF;
END //

-- ============================================================================
-- TRIGGER 4: trg_PozCzesci_ObliczCene
-- Automatycznie oblicza cene koncowa pozycji czesci
-- ============================================================================
CREATE TRIGGER trg_PozCzesci_ObliczCene_Insert
BEFORE INSERT ON PozycjeZlecenia_Czesci
FOR EACH ROW
BEGIN
    IF NEW.CenaKoncowa IS NULL OR NEW.CenaKoncowa = 0 THEN
        SET NEW.CenaKoncowa = NEW.CenaWChwiliSprzedazy * NEW.Ilosc * (1 - IFNULL(NEW.Rabat, 0) / 100);
    END IF;
    
    IF NEW.CenaKoncowa < 0 THEN
        SET NEW.CenaKoncowa = 0;
    END IF;
END //

CREATE TRIGGER trg_PozCzesci_ObliczCene_Update
BEFORE UPDATE ON PozycjeZlecenia_Czesci
FOR EACH ROW
BEGIN
    IF NEW.CenaKoncowa IS NULL OR NEW.CenaKoncowa = 0 THEN
        SET NEW.CenaKoncowa = NEW.CenaWChwiliSprzedazy * NEW.Ilosc * (1 - IFNULL(NEW.Rabat, 0) / 100);
    END IF;
    
    IF NEW.CenaKoncowa < 0 THEN
        SET NEW.CenaKoncowa = 0;
    END IF;
END //

-- ============================================================================
-- TRIGGER 5: trg_Dostawy_AktualizujMagazyn
-- Automatycznie aktualizuje stan magazynowy po zarejestrowaniu dostawy
-- ============================================================================
CREATE TRIGGER trg_Dostawy_AktualizujMagazyn
AFTER INSERT ON Dostawy
FOR EACH ROW
BEGIN
    UPDATE MagazynCzesc
    SET IloscDostepna = IloscDostepna + NEW.IloscSztuk
    WHERE ID_Czesci = NEW.ID_Czesci;
END //

-- ============================================================================
-- TRIGGER 6: trg_Pracownik_WalidacjaDat
-- Waliduje daty zatrudnienia/zwolnienia pracownika
-- ============================================================================
CREATE TRIGGER trg_Pracownik_WalidacjaDat_Insert
BEFORE INSERT ON Pracownik
FOR EACH ROW
BEGIN
    -- Data zatrudnienia nie moze byc w przyszlosci
    IF NEW.DataZatrudnienia > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Data zatrudnienia nie moze byc w przyszlosci';
    END IF;
    
    -- Data zwolnienia musi byc >= data zatrudnienia
    IF NEW.DataZwolnienia IS NOT NULL AND NEW.DataZwolnienia < NEW.DataZatrudnienia THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Data zwolnienia nie moze byc wczesniejsza niz data zatrudnienia';
    END IF;
END //

CREATE TRIGGER trg_Pracownik_WalidacjaDat_Update
BEFORE UPDATE ON Pracownik
FOR EACH ROW
BEGIN
    -- Data zatrudnienia nie moze byc w przyszlosci
    IF NEW.DataZatrudnienia > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Data zatrudnienia nie moze byc w przyszlosci';
    END IF;
    
    -- Data zwolnienia musi byc >= data zatrudnienia
    IF NEW.DataZwolnienia IS NOT NULL AND NEW.DataZwolnienia < NEW.DataZatrudnienia THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Data zwolnienia nie moze byc wczesniejsza niz data zatrudnienia';
    END IF;
END //

DELIMITER ;
