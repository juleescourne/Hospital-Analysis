-- ============================================================================
-- 02_PATIENT_ANALYTICS.SQL
-- Analyses démographiques et comportementales des patients
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ANALYSE DÉMOGRAPHIQUE DÉTAILLÉE
-- ----------------------------------------------------------------------------

-- Distribution par âge et genre
WITH dataset_year AS (
    SELECT MAX(START) AS date_enregistrement
    FROM encounters
)
SELECT 
    GENDER,
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement) < 18 THEN '0-17 ans'
        WHEN TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement) BETWEEN 18 AND 29 THEN '18-29 ans'
        WHEN TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement) BETWEEN 30 AND 39 THEN '30-39 ans'
        WHEN TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement) BETWEEN 40 AND 49 THEN '40-49 ans'
        WHEN TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement) BETWEEN 50 AND 59 THEN '50-59 ans'
        WHEN TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement) BETWEEN 60 AND 69 THEN '60-69 ans'
        WHEN TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement) BETWEEN 70 AND 79 THEN '70-79 ans'
        ELSE '80+ ans'
    END as bracket_age,
    COUNT(*) as patient_count
FROM patients
CROSS JOIN dataset_year d
WHERE BIRTHDATE IS NOT NULL
GROUP BY GENDER, bracket_age
ORDER BY GENDER, bracket_age;

+--------+-------------+---------------+
| GENDER | bracket_age | patient_count |
+--------+-------------+---------------+
| F      | 30-39 ans   |            46 |
| F      | 40-49 ans   |            70 |
| F      | 50-59 ans   |            55 |
| F      | 60-69 ans   |            68 |
| F      | 70-79 ans   |            71 |
| F      | 80+ ans     |           170 |
| M      | 30-39 ans   |            49 |
| M      | 40-49 ans   |            58 |
| M      | 50-59 ans   |            58 |
| M      | 60-69 ans   |            60 |
| M      | 70-79 ans   |            50 |
| M      | 80+ ans     |           219 |
+--------+-------------+---------------+

-- Analyse ethnicité
SELECT 
    ETHNICITY,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patients), 2) as percentage
FROM patients
GROUP BY ETHNICITY
ORDER BY count DESC;

+-------------+-------+------------+
| ETHNICITY   | count | percentage |
+-------------+-------+------------+
| nonhispanic |   783 |      80.39 |
| hispanic    |   191 |      19.61 |
+-------------+-------+------------+

-- Distribution par race et genre
SELECT 
    RACE,
    GENDER,
    COUNT(*) as count
FROM patients
GROUP BY RACE, GENDER
ORDER BY RACE, GENDER;

+----------+--------+-------+
| RACE     | GENDER | count |
+----------+--------+-------+
| asian    | F      |    41 |
| asian    | M      |    50 |
| black    | F      |    71 |
| black    | M      |    92 |
| hawaiian | F      |     7 |
| hawaiian | M      |     6 |
| native   | F      |     6 |
| native   | M      |     5 |
| other    | F      |     9 |
| other    | M      |     7 |
| white    | F      |   346 |
| white    | M      |   334 |
+----------+--------+-------+

-- ----------------------------------------------------------------------------
-- 2. ANALYSE DE MORTALITÉ
-- ----------------------------------------------------------------------------

-- Taux de mortalité global
SELECT 
    COUNT(*) as total_patients,
    SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) as deceased_patients,
    ROUND(SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as mortality_rate
FROM patients;

+----------------+-------------------+----------------+
| total_patients | deceased_patients | mortality_rate |
+----------------+-------------------+----------------+
|            974 |               154 |          15.81 |
+----------------+-------------------+----------------+

-- Âge moyen au décès
SELECT 
    ROUND(AVG(TIMESTAMPDIFF(YEAR, BIRTHDATE, DEATHDATE)), 2) as avg_age_at_death,
    MIN(TIMESTAMPDIFF(YEAR, BIRTHDATE, DEATHDATE)) as youngest_age_at_death,
    MAX(TIMESTAMPDIFF(YEAR, BIRTHDATE, DEATHDATE)) as oldest_age_at_death
FROM patients
WHERE DEATHDATE IS NOT NULL;

+------------------+-----------------------+---------------------+
| avg_age_at_death | youngest_age_at_death | oldest_age_at_death |
+------------------+-----------------------+---------------------+
|            79.39 |                    26 |                  97 |
+------------------+-----------------------+---------------------+

-- Mortalité par genre
SELECT 
    GENDER,
    COUNT(*) as total_patients,
    SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) as deceased,
    ROUND(SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as mortality_rate,
    ROUND(AVG(CASE WHEN DEATHDATE IS NOT NULL THEN TIMESTAMPDIFF(YEAR, BIRTHDATE, DEATHDATE) END), 2) as avg_age_at_death
FROM patients
GROUP BY GENDER;

+--------+----------------+----------+----------------+------------------+
| GENDER | total_patients | deceased | mortality_rate | avg_age_at_death |
+--------+----------------+----------+----------------+------------------+
| F      |            480 |       67 |          13.96 |            78.58 |
| M      |            494 |       87 |          17.61 |            80.01 |
+--------+----------------+----------+----------------+------------------+

-- Mortalité par race
SELECT 
    RACE,
    COUNT(*) as total_patients,
    SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) as deceased,
    ROUND(SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as mortality_rate,
    ROUND(AVG(CASE WHEN DEATHDATE IS NOT NULL THEN TIMESTAMPDIFF(YEAR, BIRTHDATE, DEATHDATE) END), 2) as avg_age_at_death
FROM patients
GROUP BY RACE
ORDER BY mortality_rate DESC;

+----------+----------------+----------+----------------+------------------+
| RACE     | total_patients | deceased | mortality_rate | avg_age_at_death |
+----------+----------------+----------+----------------+------------------+
| other    |             16 |        5 |          31.25 |            81.00 |
| native   |             11 |        3 |          27.27 |            92.33 |
| black    |            163 |       30 |          18.40 |            80.37 |
| white    |            680 |      103 |          15.15 |            78.23 |
| asian    |             91 |       13 |          14.29 |            82.69 |
| hawaiian |             13 |        0 |           0.00 |             NULL |
+----------+----------------+----------+----------------+------------------+

-- Distribution des décès par année
SELECT 
    YEAR(DEATHDATE) as year,
    COUNT(*) as deaths,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, BIRTHDATE, DEATHDATE)), 2) as avg_age_at_death
FROM patients
WHERE DEATHDATE IS NOT NULL
GROUP BY YEAR(DEATHDATE)
ORDER BY year;

+------+--------+------------------+
| year | deaths | avg_age_at_death |
+------+--------+------------------+
| 2011 |      6 |            81.67 |
| 2012 |     15 |            74.53 |
| 2013 |     12 |            77.50 |
| 2014 |     15 |            76.07 |
| 2015 |      6 |            73.50 |
| 2016 |     14 |            81.29 |
| 2017 |     17 |            82.24 |
| 2018 |     21 |            77.48 |
| 2019 |     18 |            83.06 |
| 2020 |     13 |            82.00 |
| 2021 |     16 |            81.25 |
| 2022 |      1 |            82.00 |
+------+--------+------------------+

-- ----------------------------------------------------------------------------
-- 3. ANALYSE GÉOGRAPHIQUE
-- ----------------------------------------------------------------------------

-- Distribution par ville
SELECT 
    CITY,
    STATE,
    COUNT(*) as patient_count
FROM patients
GROUP BY CITY, STATE
ORDER BY patient_count DESC
LIMIT 15;

+------------+---------------+---------------+
| CITY       | STATE         | patient_count |
+------------+---------------+---------------+
| Boston     | Massachusetts |           541 |
| Quincy     | Massachusetts |            80 |
| Cambridge  | Massachusetts |            45 |
| Revere     | Massachusetts |            42 |
| Chelsea    | Massachusetts |            39 |
| Weymouth   | Massachusetts |            37 |
| Somerville | Massachusetts |            25 |
| Winthrop   | Massachusetts |            22 |
| Hingham    | Massachusetts |            22 |
| Brookline  | Massachusetts |            17 |
| Everett    | Massachusetts |            16 |
| Hull       | Massachusetts |            15 |
| Medford    | Massachusetts |            13 |
| Braintree  | Massachusetts |            10 |
| Cohasset   | Massachusetts |            10 |
+------------+---------------+---------------+

-- Patients par comté
SELECT 
    COUNTY,
    STATE,
    COUNT(*) as patient_count
FROM patients
GROUP BY COUNTY, STATE
ORDER BY patient_count DESC
LIMIT 20;

+------------------+---------------+---------------+
| COUNTY           | STATE         | patient_count |
+------------------+---------------+---------------+
| Suffolk County   | Massachusetts |           644 |
| Norfolk County   | Massachusetts |           155 |
| Middlesex County | Massachusetts |           125 |
| Plymouth County  | Massachusetts |            49 |
| Essex County     | Massachusetts |             1 |
+------------------+---------------+---------------+

-- ----------------------------------------------------------------------------
-- 4. ANALYSE DES COMPORTEMENTS PATIENTS
-- ----------------------------------------------------------------------------

-- Patients avec le plus d'encounters
WITH dataset_year AS (
    SELECT MAX(START) AS date_enregistrement
    FROM encounters
)
SELECT 
    CONCAT(
        REGEXP_REPLACE(p.FIRST, '[^[:alpha:]]', ''),
        ' ',
        REGEXP_REPLACE(p.LAST, '[^[:alpha:]]', '')
     ) as patient_name,
    TIMESTAMPDIFF(YEAR, p.BIRTHDATE, d.date_enregistrement) as age,
    COUNT(e.Id) as encounter_count,
    DATE(MIN(e.START)) as first_encounter,
    DATE(MAX(e.START)) as last_encounter,
    TIMESTAMPDIFF(MONTH, MIN(e.START), MAX(e.START)) as months_as_patient
FROM patients p
JOIN encounters e ON p.Id = e.PATIENT
CROSS JOIN dataset_year d
GROUP BY p.FIRST, p.LAST, age, p.GENDER, p.BIRTHDATE
ORDER BY encounter_count DESC
LIMIT 15;

+-------------------+------+-----------------+-----------------+----------------+-------------------+
| patient_name      | age  | encounter_count | first_encounter | last_encounter | months_as_patient |
+-------------------+------+-----------------+-----------------+----------------+-------------------+
| Kimberly Collier  |   92 |            1381 | 2011-01-15      | 2022-01-23     |               132 |
| Shani Parisian    |   88 |             887 | 2011-02-19      | 2022-01-22     |               131 |
| Mariano OKon      |   93 |             877 | 2011-01-02      | 2017-02-11     |                73 |
| Gail Glover       |   87 |             447 | 2011-03-16      | 2022-01-26     |               130 |
| Ward Nicolas      |   91 |             441 | 2011-03-09      | 2022-01-21     |               130 |
| Marcos Parker     |   98 |             392 | 2011-01-26      | 2022-01-19     |               131 |
| Mariano Schroeder |   86 |             383 | 2011-01-26      | 2022-01-26     |               132 |
| Song Heaney       |   94 |             364 | 2011-01-16      | 2022-01-21     |               132 |
| Issac Predovic    |   96 |             296 | 2011-02-28      | 2022-01-24     |               130 |
| Eugene Abernathy  |   94 |             291 | 2011-01-10      | 2022-01-10     |               132 |
| Fredrick Gutmann  |   82 |             268 | 2011-01-20      | 2022-01-27     |               132 |
| Yuette Vandervort |   95 |             246 | 2011-04-20      | 2022-01-29     |               129 |
| Martin Konopelski |   93 |             239 | 2011-08-01      | 2016-04-25     |                56 |
| Jamey Bartell     |   96 |             232 | 2011-04-20      | 2022-01-26     |               129 |
| Tisha Yost        |   94 |             217 | 2012-03-04      | 2022-01-23     |               118 |
+-------------------+------+-----------------+-----------------+----------------+-------------------+

-- Fréquence moyenne des visites par patient
SELECT 
    ROUND(AVG(encounter_count), 2) as avg_encounters_per_patient,
    MIN(encounter_count) as min_encounters,
    MAX(encounter_count) as max_encounters
FROM (
    SELECT PATIENT, COUNT(*) as encounter_count
    FROM encounters
    GROUP BY PATIENT
) as patient_encounters;

+----------------------------+----------------+----------------+
| avg_encounters_per_patient | min_encounters | max_encounters |
+----------------------------+----------------+----------------+
|                      28.64 |              1 |           1381 |
+----------------------------+----------------+----------------+

-- Distribution du nombre d'encounters par patient
SELECT 
    CASE 
        WHEN encounter_count = 1 THEN '1 encounter'
        WHEN encounter_count BETWEEN 2 AND 10 THEN '2-10 encounters'
        WHEN encounter_count BETWEEN 11 AND 10 THEN '11-20 encounters'
        WHEN encounter_count BETWEEN 21 AND 50 THEN '21-50 encounters'
        ELSE '50+ encounters'
    END as encounter_range,
    COUNT(*) as patient_count
FROM (
    SELECT PATIENT, COUNT(*) as encounter_count
    FROM encounters
    GROUP BY PATIENT
) as patient_encounters
GROUP BY encounter_range
ORDER BY MIN(encounter_count);

+------------------+---------------+
| encounter_range  | patient_count |
+------------------+---------------+
| 1 encounter      |           120 |
| 2-10 encounters  |           300 |
| 50+ encounters   |           312 |
| 21-50 encounters |           242 |
+------------------+---------------+

-- ----------------------------------------------------------------------------
-- 5. ANALYSE PAR ÉTAT CIVIL
-- ----------------------------------------------------------------------------

-- Statistiques par état civil
WITH dataset_year AS (
    SELECT MAX(START) AS date_enregistrement
    FROM encounters
)
SELECT 
    MARITAL,
    COUNT(*) as patient_count,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement)), 2) as avg_age,
    SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) as deceased_count,
    ROUND(SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as mortality_rate
FROM patients
CROSS JOIN dataset_year d
WHERE BIRTHDATE IS NOT NULL
GROUP BY MARITAL
ORDER BY patient_count DESC;

+---------+---------------+---------+----------------+----------------+
| MARITAL | patient_count | avg_age | deceased_count | mortality_rate |
+---------+---------------+---------+----------------+----------------+
| M       |           784 |   69.56 |            123 |          15.69 |
| S       |           189 |   68.67 |             30 |          15.87 |
| NULL    |             1 |   34.00 |              1 |         100.00 |
+---------+---------------+---------+----------------+----------------+

-- ----------------------------------------------------------------------------
-- 6. PROFIL TYPE DES PATIENTS
-- ----------------------------------------------------------------------------

-- Profil démographique moyen
WITH dataset_year AS (
    SELECT MAX(START) AS date_enregistrement
    FROM encounters
)
SELECT 
    ROUND(AVG(TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement)), 2) as avg_age,
    (SELECT GENDER FROM patients GROUP BY GENDER ORDER BY COUNT(*) DESC LIMIT 1) as most_common_gender,
    (SELECT RACE FROM patients GROUP BY RACE ORDER BY COUNT(*) DESC LIMIT 1) as most_common_race,
    (SELECT MARITAL FROM patients GROUP BY MARITAL ORDER BY COUNT(*) DESC LIMIT 1) as most_common_marital_status,
    (SELECT CITY FROM patients GROUP BY CITY ORDER BY COUNT(*) DESC LIMIT 1) as most_common_city
FROM patients
CROSS JOIN dataset_year d
WHERE BIRTHDATE IS NOT NULL;

+---------+--------------------+------------------+----------------------------+------------------+
| avg_age | most_common_gender | most_common_race | most_common_marital_status | most_common_city |
+---------+--------------------+------------------+----------------------------+------------------+
|   69.35 | M                  | white            | M                          | Boston           |
+---------+--------------------+------------------+----------------------------+------------------+
