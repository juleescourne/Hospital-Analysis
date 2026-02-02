# Installation - Base de Données Hospitalière

Guide complet pour installer et configurer la base de données hospitalière MySQL avec les données de Maven Analytics.

## Table des matières

- [Prérequis](#prérequis)
- [Téléchargement des données](#téléchargement-des-données)
- [Configuration MySQL](#configuration-mysql)
- [Création de la base de données](#création-de-la-base-de-données)
- [Création des tables](#création-des-tables)
- [Import des données](#import-des-données)
- [Vérification](#vérification)
- [Dépannage](#dépannage)

## Prérequis

- **MySQL Server** 9.6 ou version supérieure
- **Accès administrateur** à MySQL (utilisateur root ou équivalent)
- **Espace disque** : environ 500 MB disponible

## Téléchargement des données

1. Accédez au site Maven Analytics :
   ```
   https://mavenanalytics.io/data-playground/hospital-patient-records
   ```

2. Téléchargez le dataset complet qui contient **5 fichiers CSV** :
   - `organizations.csv` - Informations sur les établissements de santé
   - `payers.csv` - Informations sur les assureurs
   - `patients.csv` - Informations sur les patients
   - `encounters.csv` - Informations sur les consultations/rencontres
   - `procedures.csv` - Informations sur les procédures médicales

## Configuration MySQL

### 1. Vérifier le répertoire sécurisé

Connectez-vous à MySQL :
```bash
mysql -u root -p
```

Vérifiez le chemin du répertoire sécurisé :
```sql
SELECT @@secure_file_priv;
```

**Résultat attendu** (Windows) :
```
C:\ProgramData\MySQL\MySQL Server 9.6\Uploads\
```

### 2. Copier les fichiers CSV

Copiez les 5 fichiers CSV téléchargés dans le répertoire sécurisé identifié ci-dessus.

**Windows** :
```
C:\ProgramData\MySQL\MySQL Server 9.6\Uploads\
```

## Création de la base de données

### 1. Créer la base de données

```sql
CREATE DATABASE hopital;
USE hopital;
```

## Création des tables

Exécutez les commandes suivantes dans l'ordre pour créer les tables avec leurs relations :

### Table 1 : Organizations

```sql
CREATE TABLE organizations (
    Id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip VARCHAR(20)
);
```

### Table 2 : Payers

```sql
CREATE TABLE IF NOT EXISTS payers (
    Id CHAR(36) PRIMARY KEY,
    NAME VARCHAR(100),
    ADDRESS VARCHAR(255),
    CITY VARCHAR(100),
    STATE_HEADQUARTERED CHAR(2),
    ZIP VARCHAR(10),
    PHONE VARCHAR(20)
);
```

### Table 3 : Patients

```sql
CREATE TABLE IF NOT EXISTS patients (
    Id CHAR(36) PRIMARY KEY,
    BIRTHDATE DATE,
    DEATHDATE DATE,
    PREFIX VARCHAR(10),
    FIRST VARCHAR(100),
    LAST VARCHAR(100),
    SUFFIX VARCHAR(10),
    MAIDEN VARCHAR(100),
    MARITAL CHAR(1),
    RACE VARCHAR(50),
    ETHNICITY VARCHAR(50),
    GENDER CHAR(1),
    BIRTHPLACE VARCHAR(255),
    ADDRESS VARCHAR(255),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    COUNTY VARCHAR(100),
    ZIP VARCHAR(10),
    LAT DOUBLE,
    LON DOUBLE
);
```

### Table 4 : Encounters

```sql
CREATE TABLE encounters (
    Id CHAR(36) PRIMARY KEY,
    START TIMESTAMP NOT NULL,
    STOP TIMESTAMP NOT NULL,
    PATIENT CHAR(36) NOT NULL,
    ORGANIZATION CHAR(36) NOT NULL,
    PAYER CHAR(36) NOT NULL,
    ENCOUNTERCLASS VARCHAR(50),
    CODE VARCHAR(20),
    DESCRIPTION VARCHAR(255),
    BASE_ENCOUNTER_COST DECIMAL(10,2),
    TOTAL_CLAIM_COST DECIMAL(10,2),
    PAYER_COVERAGE DECIMAL(10,2),
    REASONCODE VARCHAR(20),
    REASONDESCRIPTION VARCHAR(255),
    FOREIGN KEY (PATIENT) REFERENCES patients(Id),
    FOREIGN KEY (ORGANIZATION) REFERENCES organizations(Id),
    FOREIGN KEY (PAYER) REFERENCES payers(Id)
);
```

### Table 5 : Procedures

```sql
CREATE TABLE procedures (
    START TIMESTAMP,
    STOP TIMESTAMP,
    PATIENT CHAR(36),
    ENCOUNTER CHAR(36),
    CODE VARCHAR(20),
    DESCRIPTION VARCHAR(255),
    BASE_COST INT,
    REASONCODE VARCHAR(20),
    REASONDESCRIPTION VARCHAR(255),
    FOREIGN KEY (PATIENT) REFERENCES patients(Id),
    FOREIGN KEY (ENCOUNTER) REFERENCES encounters(Id)
);
```

## Import des données

Importez les données dans l'ordre suivant pour respecter les contraintes de clés étrangères :

### 1. Importer Organizations

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/organizations.csv'
INTO TABLE organizations
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

### 2. Importer Payers

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/payers.csv'
INTO TABLE payers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    @Id,
    @NAME,
    @ADDRESS,
    @CITY,
    @STATE_HEADQUARTERED,
    @ZIP,
    @PHONE
)
SET
    Id = NULLIF(@Id,''),
    NAME = NULLIF(@NAME,''),
    ADDRESS = NULLIF(@ADDRESS,''),
    CITY = NULLIF(@CITY,''),
    STATE_HEADQUARTERED = NULLIF(@STATE_HEADQUARTERED,''),
    ZIP = NULLIF(@ZIP,''),
    PHONE = NULLIF(@PHONE,'');
```

### 3. Importer Patients

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/patients.csv'
INTO TABLE patients
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    @Id,
    @BIRTHDATE,
    @DEATHDATE,
    @PREFIX,
    @FIRST,
    @LAST,
    @SUFFIX,
    @MAIDEN,
    @MARITAL,
    @RACE,
    @ETHNICITY,
    @GENDER,
    @BIRTHPLACE,
    @ADDRESS,
    @CITY,
    @STATE,
    @COUNTY,
    @ZIP,
    @LAT,
    @LON
)
SET
    Id = @Id,
    BIRTHDATE = NULLIF(@BIRTHDATE,''),
    DEATHDATE = NULLIF(@DEATHDATE,''),
    PREFIX = NULLIF(@PREFIX,''),
    FIRST = NULLIF(@FIRST,''),
    LAST = NULLIF(@LAST,''),
    SUFFIX = NULLIF(@SUFFIX,''),
    MAIDEN = NULLIF(@MAIDEN,''),
    MARITAL = NULLIF(@MARITAL,''),
    RACE = NULLIF(@RACE,''),
    ETHNICITY = NULLIF(@ETHNICITY,''),
    GENDER = NULLIF(@GENDER,''),
    BIRTHPLACE = NULLIF(@BIRTHPLACE,''),
    ADDRESS = NULLIF(@ADDRESS,''),
    CITY = NULLIF(@CITY,''),
    STATE = NULLIF(@STATE,''),
    COUNTY = NULLIF(@COUNTY,''),
    ZIP = NULLIF(@ZIP,''),
    LAT = NULLIF(@LAT,''),
    LON = NULLIF(@LON,'');
```

### 4. Importer Encounters

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/encounters.csv'
INTO TABLE encounters
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    @Id,
    @START,
    @STOP,
    @PATIENT,
    @ORGANIZATION,
    @PAYER,
    @ENCOUNTERCLASS,
    @CODE,
    @DESCRIPTION,
    @BASE_ENCOUNTER_COST,
    @TOTAL_CLAIM_COST,
    @PAYER_COVERAGE,
    @REASONCODE,
    @REASONDESCRIPTION
)
SET
    Id = @Id,
    START = STR_TO_DATE(REPLACE(REPLACE(@START,'T',' '),'Z',''), '%Y-%m-%d %H:%i:%s'),
    STOP = STR_TO_DATE(REPLACE(REPLACE(@STOP,'T',' '),'Z',''), '%Y-%m-%d %H:%i:%s'),
    PATIENT = @PATIENT,
    ORGANIZATION = @ORGANIZATION,
    PAYER = @PAYER,
    ENCOUNTERCLASS = NULLIF(@ENCOUNTERCLASS,''),
    CODE = NULLIF(@CODE,''),
    DESCRIPTION = NULLIF(@DESCRIPTION,''),
    BASE_ENCOUNTER_COST = NULLIF(@BASE_ENCOUNTER_COST,''),
    TOTAL_CLAIM_COST = NULLIF(@TOTAL_CLAIM_COST,''),
    PAYER_COVERAGE = NULLIF(@PAYER_COVERAGE,''),
    REASONCODE = NULLIF(@REASONCODE,''),
    REASONDESCRIPTION = NULLIF(@REASONDESCRIPTION,'');
```

### 5. Importer Procedures

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/procedures.csv'
INTO TABLE procedures
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    @START,
    @STOP,
    @PATIENT,
    @ENCOUNTER,
    @CODE,
    @DESCRIPTION,
    @BASE_COST,
    @REASONCODE,
    @REASONDESCRIPTION
)
SET
    START = STR_TO_DATE(REPLACE(REPLACE(@START,'T',' '),'Z',''), '%Y-%m-%d %H:%i:%s'),
    STOP = STR_TO_DATE(REPLACE(REPLACE(@STOP,'T',' '),'Z',''), '%Y-%m-%d %H:%i:%s'),
    PATIENT = @PATIENT,
    ENCOUNTER = @ENCOUNTER,
    CODE = NULLIF(@CODE,''),
    DESCRIPTION = NULLIF(@DESCRIPTION,''),
    BASE_COST = NULLIF(@BASE_COST,''),
    REASONCODE = NULLIF(@REASONCODE,''),
    REASONDESCRIPTION = NULLIF(@REASONDESCRIPTION,'');
```

## Vérification

Vérifiez que toutes les données ont été importées correctement :

```sql
-- Vérifier le nombre d'enregistrements dans chaque table
SELECT 'organizations' AS table_name, COUNT(*) AS count FROM organizations
UNION ALL
SELECT 'payers', COUNT(*) FROM payers
UNION ALL
SELECT 'patients', COUNT(*) FROM patients
UNION ALL
SELECT 'encounters', COUNT(*) FROM encounters
UNION ALL
SELECT 'procedures', COUNT(*) FROM procedures;
```