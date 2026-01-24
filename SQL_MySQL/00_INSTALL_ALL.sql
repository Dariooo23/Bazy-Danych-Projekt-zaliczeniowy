-- ============================================================================
-- SYSTEM ZARZADZANIA WARSZTATEM SAMOCHODOWYM
-- Skrypt instalacyjny dla MySQL 8.0+
-- ============================================================================
-- Autorzy: Karol Dziekan, Krzysztof Cholewa
-- ============================================================================

-- Ustawienia
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

SELECT '========================================' AS '';
SELECT 'INSTALACJA BAZY DANYCH WARSZTATU' AS '';
SELECT '========================================' AS '';

-- ============================================================================
-- 1. TWORZENIE STRUKTURY BAZY DANYCH
-- ============================================================================
SELECT '[1/6] Tworzenie tabel...' AS Status;
SOURCE 01_CREATE_DATABASE.sql;

-- ============================================================================
-- 2. TWORZENIE INDEKSOW
-- ============================================================================
SELECT '[2/6] Tworzenie indeksow...' AS Status;
SOURCE 02_INDEXES.sql;

-- ============================================================================
-- 3. TWORZENIE WIDOKOW I FUNKCJI
-- ============================================================================
SELECT '[3/6] Tworzenie widokow i funkcji...' AS Status;
SOURCE 03_VIEWS_FUNCTIONS.sql;

-- ============================================================================
-- 4. TWORZENIE PROCEDUR SKLADOWANYCH
-- ============================================================================
SELECT '[4/6] Tworzenie procedur skladowanych...' AS Status;
SOURCE 04_PROCEDURES.sql;

-- ============================================================================
-- 5. TWORZENIE TRIGGEROW
-- ============================================================================
SELECT '[5/6] Tworzenie triggerow...' AS Status;
SOURCE 05_TRIGGERS.sql;

-- ============================================================================
-- 6. LADOWANIE DANYCH TESTOWYCH
-- ============================================================================
SELECT '[6/6] Ladowanie danych testowych...' AS Status;
SOURCE 07_TEST_DATA.sql;

-- ============================================================================
-- PODSUMOWANIE INSTALACJI
-- ============================================================================
SELECT '========================================' AS '';
SELECT 'INSTALACJA ZAKONCZONA POMYSLNIE!' AS '';
SELECT '========================================' AS '';

SELECT 'PODSUMOWANIE OBIEKTOW:' AS '';

SELECT 'Tabele:' AS Typ, COUNT(*) AS Ilosc 
FROM information_schema.tables 
WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE';

SELECT 'Widoki:' AS Typ, COUNT(*) AS Ilosc 
FROM information_schema.views 
WHERE table_schema = DATABASE();

SELECT 'Procedury:' AS Typ, COUNT(*) AS Ilosc 
FROM information_schema.routines 
WHERE routine_schema = DATABASE() AND routine_type = 'PROCEDURE';

SELECT 'Funkcje:' AS Typ, COUNT(*) AS Ilosc 
FROM information_schema.routines 
WHERE routine_schema = DATABASE() AND routine_type = 'FUNCTION';

SELECT 'Triggery:' AS Typ, COUNT(*) AS Ilosc 
FROM information_schema.triggers 
WHERE trigger_schema = DATABASE();

SELECT '========================================' AS '';
SELECT 'Gotowe do uzycia!' AS '';
