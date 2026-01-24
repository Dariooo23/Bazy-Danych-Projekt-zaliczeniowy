-- ============================================================================
-- WIDOK 1: v_ZleceniaAktywne
-- Lista wszystkich aktywnych zleceń (nie wydane)
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
    o_klient.Imie || ' ' || o_klient.Nazwisko AS Klient,
    o_klient.Telefon AS TelefonKlienta,
    o_prac.Imie || ' ' || o_prac.Nazwisko AS PracownikPrzyjmujacy
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

COMMENT ON TABLE v_ZleceniaAktywne IS 'Widok pokazujący wszystkie aktywne zlecenia (nie wydane klientowi)';

-- ============================================================================
-- WIDOK 2: v_PojazdyKlientow
-- Lista pojazdów z danymi właścicieli
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
    mk.NazwaMarki || ' ' || m.NazwaModelu AS Pojazd,
    o.ID_Osoby AS ID_Klienta,
    o.Imie || ' ' || o.Nazwisko AS Wlasciciel,
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

COMMENT ON TABLE v_PojazdyKlientow IS 'Widok łączący pojazdy z danymi ich właścicieli';

-- ============================================================================
-- WIDOK 3: v_MagazynNiskiStan
-- Części z ilością poniżej minimalnego stanu alarmowego
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

COMMENT ON TABLE v_MagazynNiskiStan IS 'Widok pokazujący części z ilością poniżej minimalnego stanu - do zamówienia';

-- ============================================================================
-- WIDOK 4: v_PracownicyAktywni
-- Lista aktywnych pracowników z ich stanowiskami
-- ============================================================================
CREATE OR REPLACE VIEW v_PracownicyAktywni AS
SELECT 
    o.ID_Osoby AS ID_Pracownika,
    o.Imie,
    o.Nazwisko,
    o.Imie || ' ' || o.Nazwisko AS PelneNazwisko,
    o.Telefon,
    o.Email,
    o.Miasto,
    p.DataZatrudnienia,
    TRUNC(MONTHS_BETWEEN(SYSDATE, p.DataZatrudnienia) / 12) AS LatPracy,
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

COMMENT ON TABLE v_PracownicyAktywni IS 'Widok pokazujący aktywnych pracowników wraz ze statystykami';

-- ============================================================================
-- WIDOK 5: v_HistoriaZlecenia
-- Pełna historia zmian statusów zlecenia
-- ============================================================================
CREATE OR REPLACE VIEW v_HistoriaZlecenia AS
SELECT 
    z.ID_Zlecenia,
    z.NumerZlecenia,
    hz.DataZmiany,
    sp.NazwaStatusu AS StatusPoprzedni,
    sn.NazwaStatusu AS StatusNowy,
    hz.Komentarz,
    o.Imie || ' ' || o.Nazwisko AS ZmienilPracownik
FROM HistoriaZmian hz
JOIN Zlecenie z ON hz.ID_Zlecenia = z.ID_Zlecenia
LEFT JOIN StatusyZlecen sp ON hz.ID_StatusuPoprzedni = sp.ID_Statusu
JOIN StatusyZlecen sn ON hz.ID_StatusuNowy = sn.ID_Statusu
JOIN Pracownik p ON hz.ID_Pracownika = p.ID_Osoby
JOIN Osoba o ON p.ID_Osoby = o.ID_Osoby
ORDER BY z.NumerZlecenia, hz.DataZmiany;

COMMENT ON TABLE v_HistoriaZlecenia IS 'Widok pokazujący pełną historię zmian statusów zleceń';

-- ============================================================================
-- WIDOK 6: v_SzczegolZlecenia
-- Szczegółowy widok zlecenia z usługami i częściami
-- ============================================================================
CREATE OR REPLACE VIEW v_SzczegolyZlecenia AS
SELECT 
    z.ID_Zlecenia,
    z.NumerZlecenia,
    z.DataPrzyjecia,
    z.DataPlanowanegoOdbioru,
    z.DataRzeczywistegOdbioru,
    s.NazwaStatusu AS Status,
    mk.NazwaMarki || ' ' || m.NazwaModelu AS Pojazd,
    p.NrRejestracyjny,
    p.VIN,
    o_kl.Imie || ' ' || o_kl.Nazwisko AS Klient,
    o_kl.Telefon AS TelefonKlienta,
    z.OpisUsterki,
    z.Uwagi,
    (SELECT NVL(SUM(pu.CenaKoncowa), 0) 
     FROM PozycjeZlecenia_Uslugi pu 
     WHERE pu.ID_Zlecenia = z.ID_Zlecenia) AS KosztUslug,
    (SELECT NVL(SUM(pc.CenaKoncowa), 0) 
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

COMMENT ON TABLE v_SzczegolyZlecenia IS 'Szczegółowy widok zlecenia z podsumowaniem kosztów usług i części';

-- ============================================================================
-- WIDOK 7: v_RaportMiesieczny
-- Raport miesięczny - podsumowanie zleceń
-- ============================================================================
CREATE OR REPLACE VIEW v_RaportMiesieczny AS
SELECT 
    TO_CHAR(z.DataPrzyjecia, 'YYYY-MM') AS Miesiac,
    COUNT(*) AS LiczbaZlecen,
    COUNT(CASE WHEN s.NazwaStatusu = 'Wydane' THEN 1 END) AS Zakonczonych,
    COUNT(CASE WHEN s.NazwaStatusu NOT IN ('Wydane', 'Anulowane') THEN 1 END) AS WTrakcie,
    SUM(CASE WHEN s.NazwaStatusu = 'Wydane' THEN z.KosztCalkowity ELSE 0 END) AS PrzychodyZrealizowane,
    ROUND(AVG(CASE WHEN s.NazwaStatusu = 'Wydane' THEN z.KosztCalkowity END), 2) AS SredniKoszt,
    MAX(z.KosztCalkowity) AS NajwiekszeZlecenie
FROM Zlecenie z
JOIN StatusyZlecen s ON z.ID_AktualnegoStatusu = s.ID_Statusu
GROUP BY TO_CHAR(z.DataPrzyjecia, 'YYYY-MM')
ORDER BY Miesiac DESC;

COMMENT ON TABLE v_RaportMiesieczny IS 'Raport miesięczny z podsumowaniem zleceń i przychodów';

-- ============================================================================
-- FUNKCJA 1: fn_GenerujNumerZlecenia
-- Generuje unikalny numer zlecenia w formacie ZLC/RRRR/NNNNN
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_GenerujNumerZlecenia
RETURN VARCHAR2
IS
    v_rok VARCHAR2(4);
    v_numer NUMBER;
    v_numer_zlecenia VARCHAR2(20);
BEGIN
    v_rok := TO_CHAR(SYSDATE, 'YYYY');
    
    -- Pobierz następny numer z sekwencji
    SELECT SEQ_NUMER_ZLECENIA.NEXTVAL INTO v_numer FROM DUAL;
    
    -- Sformatuj numer zlecenia
    v_numer_zlecenia := 'ZLC/' || v_rok || '/' || LPAD(v_numer, 5, '0');
    
    RETURN v_numer_zlecenia;
END fn_GenerujNumerZlecenia;
/

-- ============================================================================
-- FUNKCJA 2: fn_ObliczWartoscZlecenia
-- Oblicza całkowitą wartość zlecenia (usługi + części)
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_ObliczWartoscZlecenia(
    p_id_zlecenia IN NUMBER
) RETURN NUMBER
IS
    v_koszt_uslug NUMBER(12,2) := 0;
    v_koszt_czesci NUMBER(12,2) := 0;
    v_suma NUMBER(12,2);
BEGIN
    -- Suma kosztów usług
    SELECT NVL(SUM(CenaKoncowa), 0)
    INTO v_koszt_uslug
    FROM PozycjeZlecenia_Uslugi
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    -- Suma kosztów części
    SELECT NVL(SUM(CenaKoncowa), 0)
    INTO v_koszt_czesci
    FROM PozycjeZlecenia_Czesci
    WHERE ID_Zlecenia = p_id_zlecenia;
    
    v_suma := v_koszt_uslug + v_koszt_czesci;
    
    RETURN v_suma;
END fn_ObliczWartoscZlecenia;
/

-- ============================================================================
-- FUNKCJA 3: fn_PobierzRabatKlienta
-- Pobiera stały rabat klienta na podstawie ID pojazdu
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_PobierzRabatKlienta(
    p_id_pojazdu IN NUMBER
) RETURN NUMBER
IS
    v_rabat NUMBER(5,2) := 0;
BEGIN
    SELECT NVL(k.RabatStaly, 0)
    INTO v_rabat
    FROM Pojazd p
    JOIN Klient k ON p.ID_Klienta = k.ID_Osoby
    WHERE p.ID_Pojazdu = p_id_pojazdu;
    
    RETURN v_rabat;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END fn_PobierzRabatKlienta;
/

-- ============================================================================
-- FUNKCJA 4: fn_SprawdzDostepnoscCzesci
-- Sprawdza czy część jest dostępna w wymaganej ilości
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_SprawdzDostepnoscCzesci(
    p_id_czesci IN NUMBER,
    p_wymagana_ilosc IN NUMBER
) RETURN VARCHAR2
IS
    v_dostepna NUMBER(10);
    v_nazwa VARCHAR2(100);
BEGIN
    SELECT IloscDostepna, NazwaCzesci
    INTO v_dostepna, v_nazwa
    FROM MagazynCzesc
    WHERE ID_Czesci = p_id_czesci;
    
    IF v_dostepna >= p_wymagana_ilosc THEN
        RETURN 'DOSTEPNA';
    ELSE
        RETURN 'BRAK - dostępne tylko ' || v_dostepna || ' szt.';
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'NIEZNANA CZESC';
END fn_SprawdzDostepnoscCzesci;
/