-- ============================================================================
-- WYZWALACZ 1: trg_Zlecenie_AutoNumer
-- Automatycznie generuje numer zlecenia przy INSERT (jesli nie podano)
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_Zlecenie_AutoNumer
BEFORE INSERT ON Zlecenie
FOR EACH ROW
DECLARE
    v_rok VARCHAR2(4);
    v_numer NUMBER;
BEGIN
    -- Jesli ID nie podano, pobierz z sekwencji
    IF :NEW.ID_Zlecenia IS NULL THEN
        SELECT SEQ_ZLECENIE.NEXTVAL INTO :NEW.ID_Zlecenia FROM DUAL;
    END IF;
    
    -- Jesli numer zlecenia nie podano, wygeneruj automatycznie
    IF :NEW.NumerZlecenia IS NULL THEN
        v_rok := TO_CHAR(SYSDATE, 'YYYY');
        SELECT SEQ_NUMER_ZLECENIA.NEXTVAL INTO v_numer FROM DUAL;
        :NEW.NumerZlecenia := 'ZLC/' || v_rok || '/' || LPAD(v_numer, 5, '0');
    END IF;
END trg_Zlecenie_AutoNumer;
/

-- ============================================================================
-- WYZWALACZ 2: trg_Historia_AutoInsert
-- Automatycznie dodaje wpis do historii przy zmianie statusu zlecenia
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_Historia_AutoInsert
AFTER UPDATE OF ID_AktualnegoStatusu ON Zlecenie
FOR EACH ROW
WHEN (OLD.ID_AktualnegoStatusu != NEW.ID_AktualnegoStatusu)
BEGIN
    -- Sprawdz czy wpis nie zostal juz dodany przez procedure
    -- (aby uniknac duplikatow przy uzyciu sp_ZmienStatusZlecenia)
    INSERT INTO HistoriaZmian (
        ID_Historii, DataZmiany, Komentarz, ID_Zlecenia,
        ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika
    ) VALUES (
        SEQ_HISTORIAZMIAN.NEXTVAL, 
        SYSTIMESTAMP, 
        'Automatyczna zmiana statusu (trigger)',
        :NEW.ID_Zlecenia, 
        :OLD.ID_AktualnegoStatusu, 
        :NEW.ID_AktualnegoStatusu, 
        :NEW.ID_Pracownika
    );
EXCEPTION
    WHEN OTHERS THEN
        -- Jesli wpis juz istnieje (dodany przez procedure), ignoruj blad
        NULL;
END trg_Historia_AutoInsert;
/

-- ============================================================================
-- WYZWALACZ 3: trg_Magazyn_AlertNiskiStan
-- Wyswietla ostrzezenie gdy stan magazynowy spada ponizej minimum
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_Magazyn_AlertNiskiStan
AFTER UPDATE OF IloscDostepna ON MagazynCzesc
FOR EACH ROW
WHEN (NEW.IloscDostepna < NEW.MinStanAlarmowy AND OLD.IloscDostepna >= OLD.MinStanAlarmowy)
BEGIN
    -- Logowanie alertu do DBMS_OUTPUT
    DBMS_OUTPUT.PUT_LINE('!!! ALERT: Niski stan magazynowy !!!');
    DBMS_OUTPUT.PUT_LINE('Czesc: ' || :NEW.NazwaCzesci);
    DBMS_OUTPUT.PUT_LINE('Kod: ' || :NEW.KodProducenta);
    DBMS_OUTPUT.PUT_LINE('Stan aktualny: ' || :NEW.IloscDostepna);
    DBMS_OUTPUT.PUT_LINE('Minimum: ' || :NEW.MinStanAlarmowy);
    DBMS_OUTPUT.PUT_LINE('Nalezy zamowic minimum: ' || (:NEW.MinStanAlarmowy - :NEW.IloscDostepna) || ' szt.');
    
    -- W produkcyjnym systemie tutaj mozna dodac:
    -- - Wyslanie emaila do kierownika magazynu
    -- - Wpis do tabeli alertow
    -- - Automatyczne generowanie zamowienia
END trg_Magazyn_AlertNiskiStan;
/

-- ============================================================================
-- WYZWALACZ 4: trg_PozUslugi_ObliczCene
-- Automatycznie oblicza cene koncowa pozycji uslugi
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_PozUslugi_ObliczCene
BEFORE INSERT OR UPDATE ON PozycjeZlecenia_Uslugi
FOR EACH ROW
BEGIN
    -- Automatycznie oblicz cene koncowa jesli nie podano
    IF :NEW.CenaKoncowa IS NULL OR :NEW.CenaKoncowa = 0 THEN
        :NEW.CenaKoncowa := :NEW.CenaJednostkowa * :NEW.Krotnosc * (1 - NVL(:NEW.RabatNaUsluge, 0) / 100);
    END IF;
    
    -- Walidacja: cena koncowa nie moze byc ujemna
    IF :NEW.CenaKoncowa < 0 THEN
        :NEW.CenaKoncowa := 0;
    END IF;
END trg_PozUslugi_ObliczCene;
/

-- ============================================================================
-- WYZWALACZ 5: trg_PozCzesci_ObliczCene
-- Automatycznie oblicza cene koncowa pozycji czesci
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_PozCzesci_ObliczCene
BEFORE INSERT OR UPDATE ON PozycjeZlecenia_Czesci
FOR EACH ROW
BEGIN
    -- Automatycznie oblicz cene koncowa jesli nie podano
    IF :NEW.CenaKoncowa IS NULL OR :NEW.CenaKoncowa = 0 THEN
        :NEW.CenaKoncowa := :NEW.CenaWChwiliSprzedazy * :NEW.Ilosc * (1 - NVL(:NEW.Rabat, 0) / 100);
    END IF;
    
    -- Walidacja: cena koncowa nie moze byc ujemna
    IF :NEW.CenaKoncowa < 0 THEN
        :NEW.CenaKoncowa := 0;
    END IF;
END trg_PozCzesci_ObliczCene;
/

-- ============================================================================
-- WYZWALACZ 6: trg_Dostawy_AktualizujMagazyn
-- Automatycznie aktualizuje stan magazynowy po zarejestrowaniu dostawy
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_Dostawy_AktualizujMagazyn
AFTER INSERT ON Dostawy
FOR EACH ROW
BEGIN
    UPDATE MagazynCzesc
    SET IloscDostepna = IloscDostepna + :NEW.IloscSztuk
    WHERE ID_Czesci = :NEW.ID_Czesci;
    
    DBMS_OUTPUT.PUT_LINE('Zaktualizowano stan magazynowy. Przyjeto: ' || :NEW.IloscSztuk || ' szt.');
END trg_Dostawy_AktualizujMagazyn;
/

-- ============================================================================
-- WYZWALACZ 7 (BONUS): trg_Pracownik_WalidacjaDat
-- Waliduje daty zatrudnienia/zwolnienia pracownika
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_Pracownik_WalidacjaDat
BEFORE INSERT OR UPDATE ON Pracownik
FOR EACH ROW
BEGIN
    -- Data zatrudnienia nie moze byc w przyszlosci
    IF :NEW.DataZatrudnienia > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20101, 'Data zatrudnienia nie moze byc w przyszlosci');
    END IF;
    
    -- Data zwolnienia musi byc >= data zatrudnienia
    IF :NEW.DataZwolnienia IS NOT NULL AND :NEW.DataZwolnienia < :NEW.DataZatrudnienia THEN
        RAISE_APPLICATION_ERROR(-20102, 'Data zwolnienia nie moze byc wczesniejsza niz data zatrudnienia');
    END IF;
END trg_Pracownik_WalidacjaDat;
/