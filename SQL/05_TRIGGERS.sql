-- ============================================================================
-- SKRYPT TWORZÄ„CY WYZWALACZE (TRIGGERS)
-- System ZarzÄ…dzania Warsztatem Samochodowym
-- Data utworzenia: 2026-01-18
-- ============================================================================
-- WYMAGANIE: minimum 5 wyzwalaczy
-- Ten skrypt zawiera: 6 wyzwalaczy
-- ============================================================================

-- ============================================================================
-- WYZWALACZ 1: trg_Zlecenie_AutoNumer
-- Automatycznie generuje numer zlecenia przy INSERT (jeĹ›li nie podano)
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_Zlecenie_AutoNumer
BEFORE INSERT ON Zlecenie
FOR EACH ROW
DECLARE
    v_rok VARCHAR2(4);
    v_numer NUMBER;
BEGIN
    -- JeĹ›li ID nie podano, pobierz z sekwencji
    IF :NEW.ID_Zlecenia IS NULL THEN
        SELECT SEQ_ZLECENIE.NEXTVAL INTO :NEW.ID_Zlecenia FROM DUAL;
    END IF;
    
    -- JeĹ›li numer zlecenia nie podano, wygeneruj automatycznie
    IF :NEW.NumerZlecenia IS NULL THEN
        v_rok := TO_CHAR(SYSDATE, 'YYYY');
        SELECT SEQ_NUMER_ZLECENIA.NEXTVAL INTO v_numer FROM DUAL;
        :NEW.NumerZlecenia := 'ZLC/' || v_rok || '/' || LPAD(v_numer, 5, '0');
    END IF;
END trg_Zlecenie_AutoNumer;
/

COMMENT ON TRIGGER trg_Zlecenie_AutoNumer IS 'Automatycznie generuje ID i numer zlecenia przy tworzeniu';

-- ============================================================================
-- WYZWALACZ 2: trg_Historia_AutoInsert
-- Automatycznie dodaje wpis do historii przy zmianie statusu zlecenia
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_Historia_AutoInsert
AFTER UPDATE OF ID_AktualnegoStatusu ON Zlecenie
FOR EACH ROW
WHEN (OLD.ID_AktualnegoStatusu != NEW.ID_AktualnegoStatusu)
BEGIN
    -- SprawdĹş czy wpis nie zostaĹ‚ juĹĽ dodany przez procedurÄ™
    -- (aby uniknÄ…Ä‡ duplikatĂłw przy uĹĽyciu sp_ZmienStatusZlecenia)
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
        -- JeĹ›li wpis juĹĽ istnieje (dodany przez procedurÄ™), ignoruj bĹ‚Ä…d
        NULL;
END trg_Historia_AutoInsert;
/

COMMENT ON TRIGGER trg_Historia_AutoInsert IS 'Automatycznie loguje zmiany statusu zlecenia w tabeli historii';

-- ============================================================================
-- WYZWALACZ 3: trg_Magazyn_AlertNiskiStan
-- WyĹ›wietla ostrzeĹĽenie gdy stan magazynowy spada poniĹĽej minimum
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_Magazyn_AlertNiskiStan
AFTER UPDATE OF IloscDostepna ON MagazynCzesc
FOR EACH ROW
WHEN (NEW.IloscDostepna < NEW.MinStanAlarmowy AND OLD.IloscDostepna >= OLD.MinStanAlarmowy)
BEGIN
    -- Logowanie alertu do DBMS_OUTPUT
    DBMS_OUTPUT.PUT_LINE('!!! ALERT: Niski stan magazynowy !!!');
    DBMS_OUTPUT.PUT_LINE('CzÄ™Ĺ›Ä‡: ' || :NEW.NazwaCzesci);
    DBMS_OUTPUT.PUT_LINE('Kod: ' || :NEW.KodProducenta);
    DBMS_OUTPUT.PUT_LINE('Stan aktualny: ' || :NEW.IloscDostepna);
    DBMS_OUTPUT.PUT_LINE('Minimum: ' || :NEW.MinStanAlarmowy);
    DBMS_OUTPUT.PUT_LINE('NaleĹĽy zamĂłwiÄ‡ minimum: ' || (:NEW.MinStanAlarmowy - :NEW.IloscDostepna) || ' szt.');
    
    -- W produkcyjnym systemie tutaj moĹĽna dodaÄ‡:
    -- - WysĹ‚anie emaila do kierownika magazynu
    -- - Wpis do tabeli alertĂłw
    -- - Automatyczne generowanie zamĂłwienia
END trg_Magazyn_AlertNiskiStan;
/

COMMENT ON TRIGGER trg_Magazyn_AlertNiskiStan IS 'Generuje alert gdy stan magazynowy spadnie poniĹĽej minimum';

-- ============================================================================
-- WYZWALACZ 4: trg_Pozycje_ObliczCene
-- Automatycznie oblicza cenÄ™ koĹ„cowÄ… pozycji usĹ‚ugi
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_PozUslugi_ObliczCene
BEFORE INSERT OR UPDATE ON PozycjeZlecenia_Uslugi
FOR EACH ROW
BEGIN
    -- Automatycznie oblicz cenÄ™ koĹ„cowÄ… jeĹ›li nie podano
    IF :NEW.CenaKoncowa IS NULL OR :NEW.CenaKoncowa = 0 THEN
        :NEW.CenaKoncowa := :NEW.CenaJednostkowa * :NEW.Krotnosc * (1 - NVL(:NEW.RabatNaUsluge, 0) / 100);
    END IF;
    
    -- Walidacja: cena koĹ„cowa nie moĹĽe byÄ‡ ujemna
    IF :NEW.CenaKoncowa < 0 THEN
        :NEW.CenaKoncowa := 0;
    END IF;
END trg_PozUslugi_ObliczCene;
/

COMMENT ON TRIGGER trg_PozUslugi_ObliczCene IS 'Automatycznie oblicza cenÄ™ koĹ„cowÄ… pozycji usĹ‚ugi z uwzglÄ™dnieniem rabatu';

-- ============================================================================
-- WYZWALACZ 5: trg_PozCzesci_ObliczCene
-- Automatycznie oblicza cenÄ™ koĹ„cowÄ… pozycji czÄ™Ĺ›ci
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_PozCzesci_ObliczCene
BEFORE INSERT OR UPDATE ON PozycjeZlecenia_Czesci
FOR EACH ROW
BEGIN
    -- Automatycznie oblicz cenÄ™ koĹ„cowÄ… jeĹ›li nie podano
    IF :NEW.CenaKoncowa IS NULL OR :NEW.CenaKoncowa = 0 THEN
        :NEW.CenaKoncowa := :NEW.CenaWChwiliSprzedazy * :NEW.Ilosc * (1 - NVL(:NEW.Rabat, 0) / 100);
    END IF;
    
    -- Walidacja: cena koĹ„cowa nie moĹĽe byÄ‡ ujemna
    IF :NEW.CenaKoncowa < 0 THEN
        :NEW.CenaKoncowa := 0;
    END IF;
END trg_PozCzesci_ObliczCene;
/

COMMENT ON TRIGGER trg_PozCzesci_ObliczCene IS 'Automatycznie oblicza cenÄ™ koĹ„cowÄ… pozycji czÄ™Ĺ›ci z uwzglÄ™dnieniem rabatu';

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
    
    DBMS_OUTPUT.PUT_LINE('Zaktualizowano stan magazynowy. PrzyjÄ™to: ' || :NEW.IloscSztuk || ' szt.');
END trg_Dostawy_AktualizujMagazyn;
/

COMMENT ON TRIGGER trg_Dostawy_AktualizujMagazyn IS 'Automatycznie zwiÄ™ksza stan magazynowy po rejestracji dostawy';

-- ============================================================================
-- WYZWALACZ 7 (BONUS): trg_Pracownik_WalidacjaDat
-- Waliduje daty zatrudnienia/zwolnienia pracownika
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_Pracownik_WalidacjaDat
BEFORE INSERT OR UPDATE ON Pracownik
FOR EACH ROW
BEGIN
    -- Data zatrudnienia nie moĹĽe byÄ‡ w przyszĹ‚oĹ›ci
    IF :NEW.DataZatrudnienia > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20101, 'Data zatrudnienia nie moĹĽe byÄ‡ w przyszĹ‚oĹ›ci');
    END IF;
    
    -- Data zwolnienia musi byÄ‡ >= data zatrudnienia
    IF :NEW.DataZwolnienia IS NOT NULL AND :NEW.DataZwolnienia < :NEW.DataZatrudnienia THEN
        RAISE_APPLICATION_ERROR(-20102, 'Data zwolnienia nie moĹĽe byÄ‡ wczeĹ›niejsza niĹĽ data zatrudnienia');
    END IF;
END trg_Pracownik_WalidacjaDat;
/

COMMENT ON TRIGGER trg_Pracownik_WalidacjaDat IS 'Waliduje poprawnoĹ›Ä‡ dat zatrudnienia i zwolnienia pracownika';

-- ============================================================================
-- PODSUMOWANIE
-- ============================================================================
-- Utworzono 7 wyzwalaczy (wymagane minimum 5):
--   1. trg_Zlecenie_AutoNumer - auto-generowanie numeru zlecenia
--   2. trg_Historia_AutoInsert - automatyczne logowanie zmian statusu
--   3. trg_Magazyn_AlertNiskiStan - alert przy niskim stanie magazynu
--   4. trg_PozUslugi_ObliczCene - auto-kalkulacja ceny usĹ‚ugi
--   5. trg_PozCzesci_ObliczCene - auto-kalkulacja ceny czÄ™Ĺ›ci
--   6. trg_Dostawy_AktualizujMagazyn - auto-aktualizacja stanu przy dostawie
--   7. trg_Pracownik_WalidacjaDat - walidacja dat pracownika (bonus)
-- ============================================================================
