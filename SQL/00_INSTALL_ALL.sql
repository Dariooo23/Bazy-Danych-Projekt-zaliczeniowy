-- ============================================================================
-- SKRYPT INSTALACYJNY - URUCHAMIA WSZYSTKIE SKRYPTY W KOLEJNOŚCI
-- System Zarządzania Warsztatem Samochodowym
-- Data utworzenia: 2026-01-18
-- ============================================================================
-- INSTRUKCJA UŻYCIA:
-- 1. Połącz się z bazą Oracle jako użytkownik z odpowiednimi uprawnieniami
-- 2. Uruchom ten skrypt: @00_INSTALL_ALL.sql
-- LUB uruchamiaj skrypty pojedynczo w podanej kolejności
-- ============================================================================

PROMPT ============================================================
PROMPT  INSTALACJA SYSTEMU ZARZADZANIA WARSZTATEM SAMOCHODOWYM
PROMPT ============================================================
PROMPT

SET SERVEROUTPUT ON SIZE UNLIMITED
SET ECHO OFF
SET FEEDBACK ON

-- ============================================================================
-- FAZA 1: Tworzenie tabel, sekwencji, kluczy, danych słownikowych
-- ============================================================================
PROMPT [1/7] Tworzenie struktury bazy danych (tabele, klucze, dane slownikowe)...
@01_CREATE_DATABASE.sql
PROMPT [1/7] ZAKONCZONE
PROMPT

-- ============================================================================
-- FAZA 2: Tworzenie indeksów
-- ============================================================================
PROMPT [2/7] Tworzenie indeksow...
@02_INDEXES.sql
PROMPT [2/7] ZAKONCZONE
PROMPT

-- ============================================================================
-- FAZA 3: Tworzenie widoków i funkcji
-- ============================================================================
PROMPT [3/7] Tworzenie widokow i funkcji...
@03_VIEWS_FUNCTIONS.sql
PROMPT [3/7] ZAKONCZONE
PROMPT

-- ============================================================================
-- FAZA 4: Tworzenie procedur składowanych
-- ============================================================================
PROMPT [4/7] Tworzenie procedur skladowanych...
@04_PROCEDURES.sql
PROMPT [4/7] ZAKONCZONE
PROMPT

-- ============================================================================
-- FAZA 5: Tworzenie wyzwalaczy
-- ============================================================================
PROMPT [5/7] Tworzenie wyzwalaczy...
@05_TRIGGERS.sql
PROMPT [5/7] ZAKONCZONE
PROMPT

-- ============================================================================
-- FAZA 6: Strategia backupu (tylko procedury PL/SQL i widok)
-- ============================================================================
PROMPT [6/7] Tworzenie procedur backupu...
@06_BACKUP_STRATEGY.sql
PROMPT [6/7] ZAKONCZONE
PROMPT

-- ============================================================================
-- FAZA 7: Dane testowe (OPCJONALNIE - odkomentuj jeśli potrzebujesz)
-- ============================================================================
PROMPT [7/7] Wstawianie danych testowych...
@07_TEST_DATA.sql
PROMPT [7/7] ZAKONCZONE
PROMPT

-- ============================================================================
-- PODSUMOWANIE INSTALACJI
-- ============================================================================
PROMPT ============================================================
PROMPT  INSTALACJA ZAKONCZONA POMYSLNIE!
PROMPT ============================================================
PROMPT
PROMPT Utworzone obiekty:
PROMPT   - 17 tabel
PROMPT   - 16 sekwencji
PROMPT   - 19 kluczy obcych
PROMPT   - ~45 ograniczen CHECK
PROMPT   - 24 indeksy
PROMPT   - 7 widokow
PROMPT   - 4 funkcje
PROMPT   - 6 procedur skladowanych
PROMPT   - 7 wyzwalaczy
PROMPT   - Dane slownikowe i testowe
PROMPT
PROMPT ============================================================
PROMPT

-- Wyświetl podsumowanie obiektów
SELECT 'TABELE' AS OBIEKT, COUNT(*) AS LICZBA FROM user_tables
UNION ALL
SELECT 'SEKWENCJE', COUNT(*) FROM user_sequences
UNION ALL
SELECT 'WIDOKI', COUNT(*) FROM user_views
UNION ALL
SELECT 'FUNKCJE', COUNT(*) FROM user_procedures WHERE object_type = 'FUNCTION'
UNION ALL
SELECT 'PROCEDURY', COUNT(*) FROM user_procedures WHERE object_type = 'PROCEDURE'
UNION ALL
SELECT 'WYZWALACZE', COUNT(*) FROM user_triggers
UNION ALL
SELECT 'INDEKSY', COUNT(*) FROM user_indexes WHERE index_type = 'NORMAL';

PROMPT
PROMPT Instalacja zakonczona. Mozesz teraz korzystac z bazy danych.
PROMPT
