-- ============================================================================
-- SKRYPT TWORZÄ„CY PROCEDURY SKĹADOWANE
-- System ZarzÄ…dzania Warsztatem Samochodowym
-- Data utworzenia: 2026-01-18
-- ============================================================================
-- WYMAGANIE: minimum 5 procedur skĹ‚adowanych
-- Ten skrypt zawiera: 6 procedur
-- ============================================================================

-- ============================================================================
-- PROCEDURA 1: sp_NoweZlecenie
-- Tworzy nowe zlecenie serwisowe wraz z pierwszym wpisem w historii
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_NoweZlecenie(
    p_id_pojazdu        IN NUMBER,
    p_id_pracownika     IN NUMBER,
    p_opis_usterki      IN CLOB,
    p_data_planowana    IN DATE DEFAULT NULL,
    p_uwagi             IN VARCHAR2 DEFAULT NULL,
    p_id_zlecenia       OUT NUMBER,
    p_numer_zlecenia    OUT VARCHAR2
)
IS
    v_id_statusu_nowe NUMBER;
BEGIN
    -- Pobierz ID statusu "Nowe"
    SELECT ID_Statusu INTO v_id_statusu_nowe
    FROM StatusyZlecen
    WHERE NazwaStatusu = 'Nowe';
    
    -- Generuj numer zlecenia
    p_numer_zlecenia := fn_GenerujNumerZlecenia();
    
    -- Pobierz ID z sekwencji
    SELECT SEQ_ZLECENIE.NEXTVAL INTO p_id_zlecenia FROM DUAL;
    
    -- UtwĂłrz zlecenie
    INSERT INTO Zlecenie (
        ID_Zlecenia, NumerZlecenia, DataPrzyjecia, DataPlanowanegoOdbioru,
        OpisUsterki, Uwagi, KosztCalkowity, ID_Pojazdu, ID_Pracownika, ID_AktualnegoStatusu
    ) VALUES (
        p_id_zlecenia, p_numer_zlecenia, SYSDATE, p_data_planowana,
        p_opis_usterki, p_uwagi, 0, p_id_pojazdu, p_id_pracownika, v_id_statusu_nowe
    );
    
    -- Dodaj wpis do historii (pierwszy wpis - brak poprzedniego statusu)
    INSERT INTO HistoriaZmian (
        ID_Historii, DataZmiany, Komentarz, ID_Zlecenia,
        ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika
    ) VALUES (
        SEQ_HISTORIAZMIAN.NEXTVAL, SYSTIMESTAMP, 'Utworzono nowe zlecenie',
        p_id_zlecenia, NULL, v_id_statusu_nowe, p_id_pracownika
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Utworzono zlecenie: ' || p_numer_zlecenia);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'BĹ‚Ä…d tworzenia zlecenia: ' || SQLERRM);
END sp_NoweZlecenie;
/

COMMENT ON PROCEDURE sp_NoweZlecenie IS 'Tworzy nowe zlecenie serwisowe z automatycznym numerem i wpisem w historii';

-- ============================================================================
-- PROCEDURA 2: sp_ZmienStatusZlecenia
-- Zmienia status zlecenia i rejestruje zmianÄ™ w historii
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_ZmienStatusZlecenia(
    p_id_zlecenia       IN NUMBER,
    p_nowy_status       IN VARCHAR2,
    p_id_pracownika     IN NUMBER,
    p_komentarz         IN VARCHAR2 DEFAULT NULL
)
IS
    v_id_starego_statusu NUMBER;
    v_id_nowego_statusu NUMBER;
    v_stary_status_nazwa VARCHAR2(50);
BEGIN
    -- Pobierz aktualny status zlecenia
    SELECT ID_AktualnegoStatusu INTO v_id_starego_statusu
    FROM Zlecenie
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    SELECT NazwaStatusu INTO v_stary_status_nazwa
    FROM StatusyZlecen
    WHERE ID_Statusu = v_id_starego_statusu;
    
    -- Pobierz ID nowego statusu
    SELECT ID_Statusu INTO v_id_nowego_statusu
    FROM StatusyZlecen
    WHERE NazwaStatusu = p_nowy_status;
    
    -- SprawdĹş czy to ta sama wartoĹ›Ä‡
    IF v_id_starego_statusu = v_id_nowego_statusu THEN
        RAISE_APPLICATION_ERROR(-20002, 'Zlecenie ma juĹĽ status: ' || p_nowy_status);
    END IF;
    
    -- Zaktualizuj status zlecenia
    UPDATE Zlecenie
    SET ID_AktualnegoStatusu = v_id_nowego_statusu,
        DataRzeczywistegOdbioru = CASE 
            WHEN p_nowy_status = 'Wydane' THEN SYSDATE 
            ELSE DataRzeczywistegOdbioru 
        END
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Dodaj wpis do historii
    INSERT INTO HistoriaZmian (
        ID_Historii, DataZmiany, Komentarz, ID_Zlecenia,
        ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika
    ) VALUES (
        SEQ_HISTORIAZMIAN.NEXTVAL, SYSTIMESTAMP, 
        NVL(p_komentarz, 'Zmiana statusu z "' || v_stary_status_nazwa || '" na "' || p_nowy_status || '"'),
        p_id_zlecenia, v_id_starego_statusu, v_id_nowego_statusu, p_id_pracownika
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Zmieniono status z "' || v_stary_status_nazwa || '" na "' || p_nowy_status || '"');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Nie znaleziono zlecenia lub statusu');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'BĹ‚Ä…d zmiany statusu: ' || SQLERRM);
END sp_ZmienStatusZlecenia;
/

COMMENT ON PROCEDURE sp_ZmienStatusZlecenia IS 'Zmienia status zlecenia i automatycznie loguje zmianÄ™ w historii';

-- ============================================================================
-- PROCEDURA 3: sp_DodajUslugeDoZlecenia
-- Dodaje usĹ‚ugÄ™ do zlecenia z uwzglÄ™dnieniem rabatu klienta
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_DodajUslugeDoZlecenia(
    p_id_zlecenia       IN NUMBER,
    p_id_uslugi         IN NUMBER,
    p_krotnosc          IN NUMBER DEFAULT 1,
    p_id_pracownika_wyk IN NUMBER DEFAULT NULL,
    p_rabat_dodatkowy   IN NUMBER DEFAULT 0
)
IS
    v_cena_bazowa NUMBER(10,2);
    v_rabat_klienta NUMBER(5,2);
    v_rabat_calkowity NUMBER(5,2);
    v_cena_koncowa NUMBER(12,2);
    v_id_pojazdu NUMBER;
BEGIN
    -- Pobierz cenÄ™ bazowÄ… usĹ‚ugi
    SELECT CenaBazowa INTO v_cena_bazowa
    FROM KatalogUslug
    WHERE ID_Uslugi = p_id_uslugi AND CzyAktywna = 'T';
    
    -- Pobierz ID pojazdu zlecenia
    SELECT ID_Pojazdu INTO v_id_pojazdu
    FROM Zlecenie
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Pobierz rabat klienta
    v_rabat_klienta := fn_PobierzRabatKlienta(v_id_pojazdu);
    
    -- Oblicz rabat caĹ‚kowity (nie wiÄ™cej niĹĽ 100%)
    v_rabat_calkowity := LEAST(v_rabat_klienta + p_rabat_dodatkowy, 100);
    
    -- Oblicz cenÄ™ koĹ„cowÄ…
    v_cena_koncowa := v_cena_bazowa * p_krotnosc * (1 - v_rabat_calkowity / 100);
    
    -- Dodaj pozycjÄ™
    INSERT INTO PozycjeZlecenia_Uslugi (
        ID_PozycjiUslugi, Krotnosc, RabatNaUsluge, CenaJednostkowa,
        CenaKoncowa, ID_Zlecenia, ID_Uslugi, ID_Pracownika
    ) VALUES (
        SEQ_POZYCJEZLECENIA_USLUGI.NEXTVAL, p_krotnosc, v_rabat_calkowity,
        v_cena_bazowa, v_cena_koncowa, p_id_zlecenia, p_id_uslugi, p_id_pracownika_wyk
    );
    
    -- Aktualizuj koszt caĹ‚kowity zlecenia
    UPDATE Zlecenie
    SET KosztCalkowity = fn_ObliczWartoscZlecenia(p_id_zlecenia)
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Dodano usĹ‚ugÄ™. Cena koĹ„cowa: ' || v_cena_koncowa || ' PLN (rabat: ' || v_rabat_calkowity || '%)');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20005, 'Nie znaleziono usĹ‚ugi lub zlecenia');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20006, 'BĹ‚Ä…d dodawania usĹ‚ugi: ' || SQLERRM);
END sp_DodajUslugeDoZlecenia;
/

COMMENT ON PROCEDURE sp_DodajUslugeDoZlecenia IS 'Dodaje usĹ‚ugÄ™ do zlecenia z automatycznym naliczeniem rabatu klienta';

-- ============================================================================
-- PROCEDURA 4: sp_DodajCzescDoZlecenia
-- Dodaje czÄ™Ĺ›Ä‡ do zlecenia i zmniejsza stan magazynowy
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_DodajCzescDoZlecenia(
    p_id_zlecenia       IN NUMBER,
    p_id_czesci         IN NUMBER,
    p_ilosc             IN NUMBER DEFAULT 1,
    p_rabat             IN NUMBER DEFAULT 0
)
IS
    v_cena_sprzedazy NUMBER(10,2);
    v_ilosc_dostepna NUMBER(10);
    v_cena_koncowa NUMBER(12,2);
    v_rabat_klienta NUMBER(5,2);
    v_rabat_calkowity NUMBER(5,2);
    v_id_pojazdu NUMBER;
BEGIN
    -- SprawdĹş dostÄ™pnoĹ›Ä‡ czÄ™Ĺ›ci
    SELECT CenaSprzedazy, IloscDostepna INTO v_cena_sprzedazy, v_ilosc_dostepna
    FROM MagazynCzesc
    WHERE ID_Czesci = p_id_czesci;
    
    IF v_ilosc_dostepna < p_ilosc THEN
        RAISE_APPLICATION_ERROR(-20007, 
            'NiewystarczajÄ…ca iloĹ›Ä‡ czÄ™Ĺ›ci. DostÄ™pne: ' || v_ilosc_dostepna || ', ĹĽÄ…dane: ' || p_ilosc);
    END IF;
    
    -- Pobierz ID pojazdu zlecenia
    SELECT ID_Pojazdu INTO v_id_pojazdu
    FROM Zlecenie
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Pobierz rabat klienta
    v_rabat_klienta := fn_PobierzRabatKlienta(v_id_pojazdu);
    v_rabat_calkowity := LEAST(v_rabat_klienta + p_rabat, 100);
    
    -- Oblicz cenÄ™ koĹ„cowÄ…
    v_cena_koncowa := v_cena_sprzedazy * p_ilosc * (1 - v_rabat_calkowity / 100);
    
    -- Dodaj pozycjÄ™
    INSERT INTO PozycjeZlecenia_Czesci (
        ID_PozycjiCzesci, Ilosc, CenaWChwiliSprzedazy, Rabat,
        CenaKoncowa, ID_Zlecenia, ID_Czesci
    ) VALUES (
        SEQ_POZYCJEZLECENIA_CZESCI.NEXTVAL, p_ilosc, v_cena_sprzedazy,
        v_rabat_calkowity, v_cena_koncowa, p_id_zlecenia, p_id_czesci
    );
    
    -- Zmniejsz stan magazynowy
    UPDATE MagazynCzesc
    SET IloscDostepna = IloscDostepna - p_ilosc
    WHERE ID_Czesci = p_id_czesci;
    
    -- Aktualizuj koszt caĹ‚kowity zlecenia
    UPDATE Zlecenie
    SET KosztCalkowity = fn_ObliczWartoscZlecenia(p_id_zlecenia)
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Dodano czÄ™Ĺ›Ä‡. IloĹ›Ä‡: ' || p_ilosc || ', Cena koĹ„cowa: ' || v_cena_koncowa || ' PLN');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20008, 'Nie znaleziono czÄ™Ĺ›ci lub zlecenia');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, 'BĹ‚Ä…d dodawania czÄ™Ĺ›ci: ' || SQLERRM);
END sp_DodajCzescDoZlecenia;
/

COMMENT ON PROCEDURE sp_DodajCzescDoZlecenia IS 'Dodaje czÄ™Ĺ›Ä‡ do zlecenia, zmniejsza stan magazynowy i nalicza rabat';

-- ============================================================================
-- PROCEDURA 5: sp_RejestrujDostawe
-- Rejestruje dostawÄ™ czÄ™Ĺ›ci i aktualizuje stan magazynowy
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_RejestrujDostawe(
    p_id_czesci         IN NUMBER,
    p_id_dostawcy       IN NUMBER,
    p_ilosc             IN NUMBER,
    p_cena_jednostkowa  IN NUMBER,
    p_numer_faktury     IN VARCHAR2
)
IS
    v_wartosc_calkowita NUMBER(12,2);
BEGIN
    -- Oblicz wartoĹ›Ä‡ caĹ‚kowitÄ…
    v_wartosc_calkowita := p_ilosc * p_cena_jednostkowa;
    
    -- Zarejestruj dostawÄ™
    INSERT INTO Dostawy (
        ID_Dostawy, DataDostawy, NumerFaktury, IloscSztuk,
        CenaJednostkowa, WartoscCalkowita, ID_Czesci, ID_Dostawcy
    ) VALUES (
        SEQ_DOSTAWY.NEXTVAL, SYSDATE, p_numer_faktury, p_ilosc,
        p_cena_jednostkowa, v_wartosc_calkowita, p_id_czesci, p_id_dostawcy
    );
    
    -- ZwiÄ™ksz stan magazynowy
    UPDATE MagazynCzesc
    SET IloscDostepna = IloscDostepna + p_ilosc,
        -- Opcjonalnie: aktualizuj cenÄ™ zakupu na podstawie ostatniej dostawy
        Cena_Zakupu = p_cena_jednostkowa
    WHERE ID_Czesci = p_id_czesci;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Zarejestrowano dostawÄ™: ' || p_ilosc || ' szt., wartoĹ›Ä‡: ' || v_wartosc_calkowita || ' PLN');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'BĹ‚Ä…d rejestracji dostawy: ' || SQLERRM);
END sp_RejestrujDostawe;
/

COMMENT ON PROCEDURE sp_RejestrujDostawe IS 'Rejestruje dostawÄ™ czÄ™Ĺ›ci i automatycznie aktualizuje stan magazynowy';

-- ============================================================================
-- PROCEDURA 6: sp_ZamknijZlecenie
-- Zamyka zlecenie (zmienia status na "ZakoĹ„czone") i przelicza koszty
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_ZamknijZlecenie(
    p_id_zlecenia       IN NUMBER,
    p_id_pracownika     IN NUMBER
)
IS
    v_koszt_calkowity NUMBER(12,2);
    v_status_aktualny VARCHAR2(50);
BEGIN
    -- SprawdĹş aktualny status
    SELECT s.NazwaStatusu INTO v_status_aktualny
    FROM Zlecenie z
    JOIN StatusyZlecen s ON z.ID_AktualnegoStatusu = s.ID_Statusu
    WHERE z.ID_Zlecenia = p_id_zlecenia;
    
    IF v_status_aktualny IN ('ZakoĹ„czone', 'Wydane') THEN
        RAISE_APPLICATION_ERROR(-20011, 'Zlecenie jest juĹĽ zakoĹ„czone lub wydane');
    END IF;
    
    -- Przelicz koszt caĹ‚kowity
    v_koszt_calkowity := fn_ObliczWartoscZlecenia(p_id_zlecenia);
    
    -- Aktualizuj koszt
    UPDATE Zlecenie
    SET KosztCalkowity = v_koszt_calkowity
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- ZmieĹ„ status na "ZakoĹ„czone"
    sp_ZmienStatusZlecenia(
        p_id_zlecenia,
        'ZakoĹ„czone',
        p_id_pracownika,
        'ZamkniÄ™cie zlecenia. Koszt caĹ‚kowity: ' || v_koszt_calkowity || ' PLN'
    );
    
    DBMS_OUTPUT.PUT_LINE('Zlecenie zamkniÄ™te. Koszt caĹ‚kowity: ' || v_koszt_calkowity || ' PLN');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20012, 'Nie znaleziono zlecenia');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_ZamknijZlecenie;
/

COMMENT ON PROCEDURE sp_ZamknijZlecenie IS 'Zamyka zlecenie, przelicza koszty i zmienia status na ZakoĹ„czone';

-- ============================================================================
-- PODSUMOWANIE
-- ============================================================================
-- Utworzono 6 procedur skĹ‚adowanych (wymagane minimum 5):
--   1. sp_NoweZlecenie - tworzenie nowego zlecenia
--   2. sp_ZmienStatusZlecenia - zmiana statusu z logowaniem
--   3. sp_DodajUslugeDoZlecenia - dodawanie usĹ‚ugi z rabatem
--   4. sp_DodajCzescDoZlecenia - dodawanie czÄ™Ĺ›ci z aktualizacjÄ… magazynu
--   5. sp_RejestrujDostawe - rejestracja dostawy czÄ™Ĺ›ci
--   6. sp_ZamknijZlecenie - zamkniÄ™cie zlecenia z przeliczeniem
-- ============================================================================
