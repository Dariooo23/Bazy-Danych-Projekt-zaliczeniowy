-- ============================================================================
-- PROCEDURA 1: sp_NoweZlecenie
-- Tworzy nowe zlecenie serwisowe z automatycznym numerowaniem
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
    v_id_statusu NUMBER;
BEGIN
    -- Pobierz ID statusu "Nowe"
    SELECT ID_Statusu INTO v_id_statusu 
    FROM StatusyZlecen 
    WHERE NazwaStatusu = 'Nowe';
    
    -- Pobierz nowy ID z sekwencji
    SELECT SEQ_ZLECENIE.NEXTVAL INTO p_id_zlecenia FROM DUAL;
    
    -- Wygeneruj numer zlecenia
    p_numer_zlecenia := fn_GenerujNumerZlecenia();
    
    -- Utworz zlecenie
    INSERT INTO Zlecenie (
        ID_Zlecenia, NumerZlecenia, DataPrzyjecia, 
        DataPlanowanegoOdbioru, OpisUsterki, Uwagi,
        KosztCalkowity, ID_Pojazdu, ID_Pracownika, ID_AktualnegoStatusu
    ) VALUES (
        p_id_zlecenia, p_numer_zlecenia, SYSDATE,
        p_data_planowana, p_opis_usterki, p_uwagi,
        0, p_id_pojazdu, p_id_pracownika, v_id_statusu
    );
    
    -- Dodaj pierwszy wpis w historii
    INSERT INTO HistoriaZmian (
        ID_Historii, DataZmiany, Komentarz, ID_Zlecenia,
        ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika
    ) VALUES (
        SEQ_HISTORIAZMIAN.NEXTVAL, SYSTIMESTAMP, 'Utworzono nowe zlecenie',
        p_id_zlecenia, NULL, v_id_statusu, p_id_pracownika
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Utworzono zlecenie: ' || p_numer_zlecenia);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Blad tworzenia zlecenia: ' || SQLERRM);
END sp_NoweZlecenie;
/

-- ============================================================================
-- PROCEDURA 2: sp_ZmienStatusZlecenia
-- Zmienia status zlecenia i rejestruje zmiane w historii
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_ZmienStatusZlecenia(
    p_id_zlecenia       IN NUMBER,
    p_nowy_status       IN VARCHAR2,
    p_id_pracownika     IN NUMBER,
    p_komentarz         IN VARCHAR2 DEFAULT NULL
)
IS
    v_stary_status_id NUMBER;
    v_nowy_status_id NUMBER;
    v_stary_status_nazwa VARCHAR2(50);
BEGIN
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
    
    -- Sprawdz czy to ta sama wartosc
    IF v_stary_status_id = v_nowy_status_id THEN
        RAISE_APPLICATION_ERROR(-20002, 'Zlecenie ma juz status: ' || p_nowy_status);
    END IF;
    
    -- Zaktualizuj status
    UPDATE Zlecenie
    SET ID_AktualnegoStatusu = v_nowy_status_id
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Jesli status = Wydane, ustaw date odbioru
    IF p_nowy_status = 'Wydane' THEN
        UPDATE Zlecenie
        SET DataRzeczywistegOdbioru = SYSDATE
        WHERE ID_Zlecenia = p_id_zlecenia;
    END IF;
    
    -- Dodaj wpis do historii
    INSERT INTO HistoriaZmian (
        ID_Historii, DataZmiany, Komentarz, ID_Zlecenia,
        ID_StatusuPoprzedni, ID_StatusuNowy, ID_Pracownika
    ) VALUES (
        SEQ_HISTORIAZMIAN.NEXTVAL, SYSTIMESTAMP, 
        NVL(p_komentarz, 'Zmiana statusu z ' || v_stary_status_nazwa || ' na ' || p_nowy_status),
        p_id_zlecenia, v_stary_status_id, v_nowy_status_id, p_id_pracownika
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Status zmieniony z ' || v_stary_status_nazwa || ' na ' || p_nowy_status);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nie znaleziono zlecenia lub statusu');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'Blad zmiany statusu: ' || SQLERRM);
END sp_ZmienStatusZlecenia;
/

-- ============================================================================
-- PROCEDURA 3: sp_DodajUslugeDoZlecenia
-- Dodaje usluge do zlecenia z uwzglednieniem rabatu klienta
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_DodajUslugeDoZlecenia(
    p_id_zlecenia           IN NUMBER,
    p_id_uslugi             IN NUMBER,
    p_krotnosc              IN NUMBER DEFAULT 1,
    p_id_pracownika_wyk     IN NUMBER DEFAULT NULL,
    p_rabat_dodatkowy       IN NUMBER DEFAULT 0
)
IS
    v_cena_bazowa NUMBER(10,2);
    v_rabat_klienta NUMBER(5,2);
    v_rabat_calkowity NUMBER(5,2);
    v_cena_koncowa NUMBER(12,2);
    v_id_pojazdu NUMBER;
BEGIN
    -- Pobierz ID pojazdu ze zlecenia
    SELECT ID_Pojazdu INTO v_id_pojazdu
    FROM Zlecenie WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Pobierz cene bazowa uslugi
    SELECT CenaBazowa INTO v_cena_bazowa
    FROM KatalogUslug WHERE ID_Uslugi = p_id_uslugi;
    
    -- Pobierz rabat klienta
    v_rabat_klienta := fn_PobierzRabatKlienta(v_id_pojazdu);
    
    -- Oblicz rabat calkowity (nie wiecej niz 100%)
    v_rabat_calkowity := LEAST(v_rabat_klienta + p_rabat_dodatkowy, 100);
    
    -- Oblicz cene koncowa
    v_cena_koncowa := v_cena_bazowa * p_krotnosc * (1 - v_rabat_calkowity / 100);
    
    -- Dodaj pozycje
    INSERT INTO PozycjeZlecenia_Uslugi (
        ID_PozycjiUslugi, Krotnosc, RabatNaUsluge, 
        CenaJednostkowa, CenaKoncowa, 
        ID_Zlecenia, ID_Uslugi, ID_Pracownika
    ) VALUES (
        SEQ_POZYCJEZLECENIA_USLUGI.NEXTVAL, p_krotnosc, v_rabat_calkowity,
        v_cena_bazowa, v_cena_koncowa,
        p_id_zlecenia, p_id_uslugi, p_id_pracownika_wyk
    );
    
    -- Zaktualizuj koszt calkowity zlecenia
    UPDATE Zlecenie
    SET KosztCalkowity = fn_ObliczWartoscZlecenia(p_id_zlecenia)
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Dodano usluge. Cena koncowa: ' || v_cena_koncowa || ' PLN');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Nie znaleziono zlecenia lub uslugi');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20006, 'Blad dodawania uslugi: ' || SQLERRM);
END sp_DodajUslugeDoZlecenia;
/

-- ============================================================================
-- PROCEDURA 4: sp_DodajCzescDoZlecenia
-- Dodaje czesc do zlecenia i zmniejsza stan magazynowy
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_DodajCzescDoZlecenia(
    p_id_zlecenia       IN NUMBER,
    p_id_czesci         IN NUMBER,
    p_ilosc             IN NUMBER DEFAULT 1,
    p_rabat             IN NUMBER DEFAULT 0
)
IS
    v_cena_sprzedazy NUMBER(10,2);
    v_dostepna_ilosc NUMBER(10);
    v_rabat_klienta NUMBER(5,2);
    v_rabat_calkowity NUMBER(5,2);
    v_cena_koncowa NUMBER(12,2);
    v_id_pojazdu NUMBER;
BEGIN
    -- Pobierz ID pojazdu ze zlecenia
    SELECT ID_Pojazdu INTO v_id_pojazdu
    FROM Zlecenie WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Sprawdz dostepnosc
    SELECT CenaSprzedazy, IloscDostepna 
    INTO v_cena_sprzedazy, v_dostepna_ilosc
    FROM MagazynCzesc WHERE ID_Czesci = p_id_czesci;
    
    IF v_dostepna_ilosc < p_ilosc THEN
        RAISE_APPLICATION_ERROR(-20007, 'Niewystarczajaca ilosc na magazynie. Dostepne: ' || v_dostepna_ilosc);
    END IF;
    
    -- Pobierz rabat klienta
    v_rabat_klienta := fn_PobierzRabatKlienta(v_id_pojazdu);
    v_rabat_calkowity := LEAST(v_rabat_klienta + p_rabat, 100);
    
    -- Oblicz cene koncowa
    v_cena_koncowa := v_cena_sprzedazy * p_ilosc * (1 - v_rabat_calkowity / 100);
    
    -- Dodaj pozycje
    INSERT INTO PozycjeZlecenia_Czesci (
        ID_PozycjiCzesci, Ilosc, CenaWChwiliSprzedazy, 
        Rabat, CenaKoncowa, ID_Zlecenia, ID_Czesci
    ) VALUES (
        SEQ_POZYCJEZLECENIA_CZESCI.NEXTVAL, p_ilosc, v_cena_sprzedazy,
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
    
    DBMS_OUTPUT.PUT_LINE('Dodano czesc. Cena koncowa: ' || v_cena_koncowa || ' PLN');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20008, 'Nie znaleziono zlecenia lub czesci');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, 'Blad dodawania czesci: ' || SQLERRM);
END sp_DodajCzescDoZlecenia;
/

-- ============================================================================
-- PROCEDURA 5: sp_RejestrujDostawe
-- Rejestruje dostawe czesci i aktualizuje stan magazynowy
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_RejestrujDostawe(
    p_id_czesci             IN NUMBER,
    p_id_dostawcy           IN NUMBER,
    p_ilosc                 IN NUMBER,
    p_cena_jednostkowa      IN NUMBER,
    p_numer_faktury         IN VARCHAR2 DEFAULT NULL
)
IS
    v_wartosc_calkowita NUMBER(12,2);
BEGIN
    v_wartosc_calkowita := p_ilosc * p_cena_jednostkowa;
    
    -- Dodaj dostawe
    INSERT INTO Dostawy (
        ID_Dostawy, DataDostawy, NumerFaktury,
        IloscSztuk, CenaJednostkowa, WartoscCalkowita,
        ID_Czesci, ID_Dostawcy
    ) VALUES (
        SEQ_DOSTAWY.NEXTVAL, SYSDATE, p_numer_faktury,
        p_ilosc, p_cena_jednostkowa, v_wartosc_calkowita,
        p_id_czesci, p_id_dostawcy
    );
    
    -- Stan magazynowy zostanie zaktualizowany przez trigger trg_Dostawy_AktualizujMagazyn
    
    -- Opcjonalnie: zaktualizuj cene zakupu jesli sie zmienila
    UPDATE MagazynCzesc
    SET Cena_Zakupu = p_cena_jednostkowa
    WHERE ID_Czesci = p_id_czesci
    AND Cena_Zakupu != p_cena_jednostkowa;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Zarejestrowano dostawe: ' || p_ilosc || ' szt. Wartosc: ' || v_wartosc_calkowita || ' PLN');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Blad rejestracji dostawy: ' || SQLERRM);
END sp_RejestrujDostawe;
/

-- ============================================================================
-- PROCEDURA 6: sp_ZamknijZlecenie
-- Zamyka zlecenie (zmienia status na "Zakonczone") i przelicza koszty
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_ZamknijZlecenie(
    p_id_zlecenia       IN NUMBER,
    p_id_pracownika     IN NUMBER
)
IS
    v_liczba_uslug NUMBER;
    v_liczba_czesci NUMBER;
    v_koszt_calkowity NUMBER(12,2);
BEGIN
    -- Sprawdz czy sa pozycje
    SELECT COUNT(*) INTO v_liczba_uslug
    FROM PozycjeZlecenia_Uslugi WHERE ID_Zlecenia = p_id_zlecenia;
    
    SELECT COUNT(*) INTO v_liczba_czesci
    FROM PozycjeZlecenia_Czesci WHERE ID_Zlecenia = p_id_zlecenia;
    
    IF v_liczba_uslug = 0 AND v_liczba_czesci = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Nie mozna zamknac zlecenia bez pozycji');
    END IF;
    
    -- Przelicz koszt
    v_koszt_calkowity := fn_ObliczWartoscZlecenia(p_id_zlecenia);
    
    UPDATE Zlecenie
    SET KosztCalkowity = v_koszt_calkowity
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Zmien status na Zakonczone
    sp_ZmienStatusZlecenia(p_id_zlecenia, 'Zakonczone', p_id_pracownika, 
                          'Zlecenie zamkniete. Koszt: ' || v_koszt_calkowity || ' PLN');
    
    DBMS_OUTPUT.PUT_LINE('Zlecenie zamkniete. Koszt calkowity: ' || v_koszt_calkowity || ' PLN');
    DBMS_OUTPUT.PUT_LINE('Uslugi: ' || v_liczba_uslug || ', Czesci: ' || v_liczba_czesci);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_ZamknijZlecenie;
/