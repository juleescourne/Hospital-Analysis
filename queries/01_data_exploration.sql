-- ============================================================================
-- 01_data_exploration.sql
-- Exploration initiale
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. VUE D'ENSEMBLE DES DONNÉES
-- ----------------------------------------------------------------------------

-- Compter les enregistrements dans toutes les tables
SELECT 'patients' as table_name, COUNT(*) as nb_lignes FROM patients
UNION ALL
SELECT 'encounters', COUNT(*) FROM encounters
UNION ALL
SELECT 'procedures', COUNT(*) FROM procedures
UNION ALL
SELECT 'organizations', COUNT(*) FROM organizations
UNION ALL
SELECT 'payers', COUNT(*) FROM payers
ORDER BY nb_lignes DESC;

+---------------+-----------+
| table_name    | nb_lignes |
+---------------+-----------+
| procedures    |     47701 |
| encounters    |     27891 |
| patients      |       974 |
| payers        |        10 |
| organizations |         1 |
+---------------+-----------+

-- Période couverte par les données
SELECT 
    MIN(START) as premiere_consultation,
    MAX(START) as derniere_consultation,
    TIMESTAMPDIFF(YEAR, MIN(START), MAX(START)) as annees_couvertes,
    TIMESTAMPDIFF(MONTH, MIN(START), MAX(START)) as mois_couverts
FROM encounters;

+-----------------------+-----------------------+------------------+---------------+
| premiere_consultation | derniere_consultation | annees_couvertes | mois_couverts |
+-----------------------+-----------------------+------------------+---------------+
| 2011-01-02 09:26:36   | 2022-02-05 20:27:36   |               11 |           133 |
+-----------------------+-----------------------+------------------+---------------+

-- ----------------------------------------------------------------------------
-- 2. PROFIL DES PATIENTS
-- ----------------------------------------------------------------------------

-- Distribution par genre
SELECT 
    CASE 
        WHEN GENDER = 'M' THEN 'Hommes'
        WHEN GENDER = 'F' THEN 'Femmes'
        ELSE 'Non renseigné'
    END as genre,
    COUNT(*) as nombre,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patients), 1) as pourcentage
FROM patients
GROUP BY GENDER
ORDER BY nombre DESC;

+--------+--------+-------------+
| genre  | nombre | pourcentage |
+--------+--------+-------------+
| Hommes |    494 |        50.7 |
| Femmes |    480 |        49.3 |
+--------+--------+-------------+

-- Bracket des âges (groupes de 10 ans)
WITH dataset_year AS (
    SELECT MAX(START) AS date_enregistrement
    FROM encounters
)
SELECT 
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
    COUNT(*) as nombre_patients,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement)), 1) as age_moyen_bracket
FROM patients
CROSS JOIN dataset_year d
WHERE BIRTHDATE IS NOT NULL
GROUP BY bracket_age
ORDER BY MIN(TIMESTAMPDIFF(YEAR, BIRTHDATE, d.date_enregistrement));

+-------------+-----------------+-------------------+
| bracket_age | nombre_patients | age_moyen_bracket |
+-------------+-----------------+-------------------+
| 30-39 ans   |              95 |              34.5 |
| 40-49 ans   |             128 |              44.7 |
| 50-59 ans   |             113 |              54.6 |
| 60-69 ans   |             128 |              64.8 |
| 70-79 ans   |             121 |              74.6 |
| 80+ ans     |             389 |              90.1 |
+-------------+-----------------+-------------------+

-- Top 5 des villes avec le plus de patients
SELECT 
    CITY as ville,
    STATE as etat,
    COUNT(*) as nb_patients
FROM patients
GROUP BY CITY, STATE
ORDER BY nb_patients DESC
LIMIT 5;

+-----------+---------------+-------------+
| ville     | etat          | nb_patients |
+-----------+---------------+-------------+
| Boston    | Massachusetts |         541 |
| Quincy    | Massachusetts |          80 |
| Cambridge | Massachusetts |          45 |
| Revere    | Massachusetts |          42 |
| Chelsea   | Massachusetts |          39 |
+-----------+---------------+-------------+

-- ----------------------------------------------------------------------------
-- 3. ANALYSE DES CONSULTATIONS (ENCOUNTERS)
-- ----------------------------------------------------------------------------

-- Types de consultations les plus fréquents
SELECT 
    ENCOUNTERCLASS as type_consultation,
    COUNT(*) as nombre,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM encounters), 1) as pct_total,
    ROUND(AVG(TOTAL_CLAIM_COST), 2) as cout_moyen_dollars
FROM encounters
GROUP BY ENCOUNTERCLASS
ORDER BY nombre DESC;

+-------------------+--------+-----------+--------------------+
| type_consultation | nombre | pct_total | cout_moyen_dollars |
+-------------------+--------+-----------+--------------------+
| ambulatory        |  12537 |      44.9 |            2894.11 |
| outpatient        |   6300 |      22.6 |            2237.30 |
| urgentcare        |   3666 |      13.1 |            6369.16 |
| emergency         |   2322 |       8.3 |            4629.65 |
| wellness          |   1931 |       6.9 |            4260.71 |
| inpatient         |   1135 |       4.1 |            7761.35 |
+-------------------+--------+-----------+--------------------+

-- Évolution annuelle du nombre de consultations
SELECT 
    YEAR(START) as annee,
    COUNT(*) as nb_consultations,
    COUNT(DISTINCT PATIENT) as nb_patients_uniques,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT PATIENT), 2) as consultations_par_patient
FROM encounters
GROUP BY YEAR(START)
ORDER BY annee;

+-------+------------------+---------------------+---------------------------+
| annee | nb_consultations | nb_patients_uniques | consultations_par_patient |
+-------+------------------+---------------------+---------------------------+
|  2011 |             1336 |                 410 |                      3.26 |
|  2012 |             2106 |                 559 |                      3.77 |
|  2013 |             2495 |                 570 |                      4.38 |
|  2014 |             3885 |                 630 |                      6.17 |
|  2015 |             2469 |                 553 |                      4.46 |
|  2016 |             2451 |                 552 |                      4.44 |
|  2017 |             2360 |                 546 |                      4.32 |
|  2018 |             2292 |                 535 |                      4.28 |
|  2019 |             2228 |                 514 |                      4.33 |
|  2020 |             2519 |                 519 |                      4.85 |
|  2021 |             3530 |                 649 |                      5.44 |
|  2022 |              220 |                 103 |                      2.14 |
+-------+------------------+---------------------+---------------------------+

-- ----------------------------------------------------------------------------
-- 4. STATISTIQUES DESCRIPTIVES CLÉS
-- ----------------------------------------------------------------------------

-- Dashboard de métriques principales
SELECT 
    (SELECT COUNT(*) FROM patients) as total_patients,
    
    (SELECT COUNT(*) FROM encounters) as total_consultations,
    
    (SELECT COUNT(*) FROM procedures) as total_procedures,
    
    (SELECT ROUND(AVG(TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE())), 1) 
     FROM patients WHERE BIRTHDATE IS NOT NULL) as age_moyen_patients,
    
    (SELECT ROUND(AVG(TOTAL_CLAIM_COST), 2) 
     FROM encounters) as cout_moyen_consultation,
    
    (SELECT ROUND(SUM(TOTAL_CLAIM_COST), 2) 
     FROM encounters) as chiffre_affaires_total,
    
    (SELECT COUNT(*) 
     FROM patients WHERE DEATHDATE IS NOT NULL) as patients_decedes;

+----------------+---------------------+------------------+--------------------
| total_patients | total_consultations | total_procedures | age_moyen_patients 
+----------------+---------------------+------------------+--------------------
|            974 |               27891 |            47701 |               73.3 
+----------------+---------------------+------------------+--------------------

+-------------------------+------------------------+------------------+
| cout_moyen_consultation | chiffre_affaires_total | patients_decedes |
+-------------------------+------------------------+------------------+
|                 3639.68 |           101514375.52 |              154 |
+-------------------------+------------------------+------------------+