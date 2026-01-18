-- ============================================================================
-- STRATEGIA BACKUPU I ODTWARZANIA
-- System Zarządzania Warsztatem Samochodowym
-- Data utworzenia: 2026-01-18
-- ============================================================================
-- Ten dokument opisuje strategię backupu i zawiera skrypty pomocnicze
-- ============================================================================

-- ============================================================================
-- 1. STRATEGIA BACKUPU - PODSUMOWANIE
-- ============================================================================
/*
RODZAJE BACKUPÓW:
-----------------
1. PEŁNY (FULL) - codziennie o 02:00
   - Kopia całej bazy danych
   - Retencja: 30 dni

2. PRZYROSTOWY (INCREMENTAL) - co 4 godziny (06:00, 10:00, 14:00, 18:00, 22:00)
   - Tylko zmiany od ostatniego backupu
   - Retencja: 7 dni

3. ARCHIVELOG - ciągły
   - Archiwizacja logów transakcji
   - Umożliwia Point-in-Time Recovery
   - Retencja: 14 dni

LOKALIZACJE:
------------
- Backup lokalny: /backup/warsztat/
- Backup zdalny: NAS lub chmura (opcjonalnie)

HARMONOGRAM (CRON lub Oracle Scheduler):
----------------------------------------
0 2 * * *     - Full backup (codziennie 02:00)
0 6,10,14,18,22 * * * - Incremental (co 4h w godzinach pracy)
*/

-- ============================================================================
-- 2. SKRYPT RMAN - PEŁNY BACKUP
-- ============================================================================
/*
RMAN (Recovery Manager) - uruchamiany z linii poleceń:

-- Połączenie z RMAN
rman target /

-- Konfiguracja (jednorazowo)
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 30 DAYS;
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/backup/warsztat/cf_%F';
CONFIGURE DEVICE TYPE DISK PARALLELISM 2;

-- Pełny backup
RUN {
    ALLOCATE CHANNEL ch1 DEVICE TYPE DISK FORMAT '/backup/warsztat/full_%d_%T_%U';
    BACKUP DATABASE PLUS ARCHIVELOG;
    DELETE NOPROMPT OBSOLETE;
    RELEASE CHANNEL ch1;
}
*/

-- ============================================================================
-- 3. SKRYPT RMAN - BACKUP PRZYROSTOWY
-- ============================================================================
/*
RUN {
    ALLOCATE CHANNEL ch1 DEVICE TYPE DISK FORMAT '/backup/warsztat/incr_%d_%T_%U';
    BACKUP INCREMENTAL LEVEL 1 DATABASE;
    BACKUP ARCHIVELOG ALL NOT BACKED UP;
    RELEASE CHANNEL ch1;
}
*/

-- ============================================================================
-- 4. BACKUP LOGICZNY (Data Pump) - EKSPORT SCHEMATU
-- ============================================================================
/*
-- Eksport całego schematu (uruchamiany z linii poleceń OS)
expdp system/password@ORCL \
    SCHEMAS=WARSZTAT \
    DIRECTORY=BACKUP_DIR \
    DUMPFILE=warsztat_full_%date%.dmp \
    LOGFILE=warsztat_export_%date%.log \
    COMPRESSION=ALL

-- Eksport tylko struktury (bez danych)
expdp system/password@ORCL \
    SCHEMAS=WARSZTAT \
    DIRECTORY=BACKUP_DIR \
    DUMPFILE=warsztat_schema.dmp \
    CONTENT=METADATA_ONLY
*/

-- ============================================================================
-- 5. PROCEDURA TWORZENIA KATALOGU BACKUP
-- ============================================================================
-- Tworzenie katalogu Oracle dla Data Pump (wymaga uprawnień DBA)
-- CREATE OR REPLACE DIRECTORY BACKUP_DIR AS '/backup/warsztat';
-- GRANT READ, WRITE ON DIRECTORY BACKUP_DIR TO warsztat_user;

-- ============================================================================
-- 6. PROCEDURA BACKUPU TABEL KRYTYCZNYCH (PL/SQL)
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_BackupTabelKrytycznych
IS
    v_data VARCHAR2(10) := TO_CHAR(SYSDATE, 'YYYYMMDD');
    v_sql VARCHAR2(500);
BEGIN
    -- Backup tabeli Zlecenie
    v_sql := 'CREATE TABLE Zlecenie_BKP_' || v_data || ' AS SELECT * FROM Zlecenie';
    EXECUTE IMMEDIATE v_sql;
    
    -- Backup tabeli HistoriaZmian
    v_sql := 'CREATE TABLE HistoriaZmian_BKP_' || v_data || ' AS SELECT * FROM HistoriaZmian';
    EXECUTE IMMEDIATE v_sql;
    
    -- Backup tabeli MagazynCzesc
    v_sql := 'CREATE TABLE MagazynCzesc_BKP_' || v_data || ' AS SELECT * FROM MagazynCzesc';
    EXECUTE IMMEDIATE v_sql;
    
    DBMS_OUTPUT.PUT_LINE('Backup tabel krytycznych wykonany: ' || v_data);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Błąd backupu: ' || SQLERRM);
        RAISE;
END sp_BackupTabelKrytycznych;
/

-- ============================================================================
-- 7. PROCEDURA CZYSZCZENIA STARYCH BACKUPÓW (PL/SQL)
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_CzyscStareBackupy(
    p_dni_retencji IN NUMBER DEFAULT 30
)
IS
    v_data_graniczna DATE := SYSDATE - p_dni_retencji;
BEGIN
    FOR t IN (
        SELECT table_name 
        FROM user_tables 
        WHERE table_name LIKE '%_BKP_%'
        AND TO_DATE(SUBSTR(table_name, -8), 'YYYYMMDD') < v_data_graniczna
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' PURGE';
        DBMS_OUTPUT.PUT_LINE('Usunięto: ' || t.table_name);
    END LOOP;
END sp_CzyscStareBackupy;
/

-- ============================================================================
-- 8. SKRYPT ODTWARZANIA (RESTORE)
-- ============================================================================
/*
RMAN - Odtworzenie pełne:
-------------------------
RUN {
    SHUTDOWN ABORT;
    STARTUP MOUNT;
    RESTORE DATABASE;
    RECOVER DATABASE;
    ALTER DATABASE OPEN RESETLOGS;
}

RMAN - Point-in-Time Recovery:
------------------------------
RUN {
    SHUTDOWN ABORT;
    STARTUP MOUNT;
    SET UNTIL TIME "TO_DATE('2026-01-18 14:30:00','YYYY-MM-DD HH24:MI:SS')";
    RESTORE DATABASE;
    RECOVER DATABASE;
    ALTER DATABASE OPEN RESETLOGS;
}

Data Pump - Import:
-------------------
impdp system/password@ORCL \
    SCHEMAS=WARSZTAT \
    DIRECTORY=BACKUP_DIR \
    DUMPFILE=warsztat_full_20260118.dmp \
    LOGFILE=warsztat_import.log \
    TABLE_EXISTS_ACTION=REPLACE
*/

-- ============================================================================
-- 9. HARMONOGRAM ORACLE SCHEDULER (opcjonalnie)
-- ============================================================================
/*
-- Job dla pełnego backupu (wymaga pakietu DBMS_SCHEDULER)
BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_FULL_BACKUP',
        job_type        => 'EXECUTABLE',
        job_action      => '/backup/scripts/full_backup.sh',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0',
        enabled         => TRUE,
        comments        => 'Codzienny pełny backup o 02:00'
    );
END;
/

-- Job dla backupu przyrostowego
BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_INCR_BACKUP',
        job_type        => 'EXECUTABLE',
        job_action      => '/backup/scripts/incr_backup.sh',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=6,10,14,18,22; BYMINUTE=0',
        enabled         => TRUE,
        comments        => 'Backup przyrostowy co 4 godziny'
    );
END;
/
*/

-- ============================================================================
-- 10. WIDOK MONITOROWANIA BACKUPÓW
-- ============================================================================
CREATE OR REPLACE VIEW v_StatusBackupow AS
SELECT 
    table_name AS NazwaBackupu,
    TO_DATE(SUBSTR(table_name, -8), 'YYYYMMDD') AS DataBackupu,
    ROUND(SYSDATE - TO_DATE(SUBSTR(table_name, -8), 'YYYYMMDD')) AS DniOdBackupu
FROM user_tables 
WHERE table_name LIKE '%_BKP_%'
ORDER BY DataBackupu DESC;

-- ============================================================================
-- PODSUMOWANIE STRATEGII
-- ============================================================================
/*
+------------------+-------------+------------+-----------+
| Typ backupu      | Częstotliwość| Retencja  | Metoda    |
+------------------+-------------+------------+-----------+
| Pełny            | Codziennie  | 30 dni    | RMAN      |
| Przyrostowy      | Co 4h       | 7 dni     | RMAN      |
| Archive Log      | Ciągły      | 14 dni    | RMAN      |
| Eksport logiczny | Tygodniowo  | 90 dni    | Data Pump |
| Tabele krytyczne | Codziennie  | 30 dni    | PL/SQL    |
+------------------+-------------+------------+-----------+

WAŻNE:
- Regularnie testować procedury odtwarzania!
- Przechowywać kopie w oddzielnej lokalizacji
- Monitorować powodzenie backupów
- Dokumentować wszystkie operacje restore
*/
