-- ============================================================================
-- 04_PROCEDURE_ANALYTICS.SQL
-- Analyses des procédures médicales
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ANALYSE DES PROCÉDURES - VUE D'ENSEMBLE
-- ----------------------------------------------------------------------------

-- Top 15 des procédures les plus fréquentes
SELECT 
    DESCRIPTION,
    COUNT(*) as frequency,
    ROUND(AVG(BASE_COST), 2) as avg_cost,
    ROUND(SUM(BASE_COST), 2) as total_cost,
    COUNT(DISTINCT PATIENT) as unique_patients
FROM procedures
GROUP BY DESCRIPTION
ORDER BY frequency DESC
LIMIT 15;

+--------------------------------------------------------------------------------------+-----------+----------+------------+-----------------+
| DESCRIPTION                                                                          | frequency | avg_cost | total_cost | unique_patients |
+--------------------------------------------------------------------------------------+-----------+----------+------------+-----------------+
| Assessment of health and social care needs (procedure)                               |      4596 |   431.00 |    1980876 |             509 |
| Hospice care (regime/therapy)                                                        |      4098 |   431.00 |    1766238 |              61 |
| Depression screening using Patient Health Questionnaire Two-Item score (procedure)   |      3614 |   431.00 |    1557634 |             500 |
| Depression screening (procedure)                                                     |      3614 |   431.00 |    1557634 |             500 |
| Assessment of substance use (procedure)                                              |      2906 |   431.00 |    1252486 |             436 |
| Renal dialysis (procedure)                                                           |      2746 |  1004.09 |    2757221 |               5 |
| Assessment using Morse Fall Scale (procedure)                                        |      2422 |   431.00 |    1043882 |             268 |
| Assessment of anxiety (procedure)                                                    |      2288 |   431.00 |     986128 |             437 |
| Medication Reconciliation (procedure)                                                |      2284 |   509.12 |    1162840 |             418 |
| Screening for drug abuse (procedure)                                                 |      1484 |   431.00 |     639604 |             333 |
| Screening for domestic abuse (procedure)                                             |      1432 |   431.00 |     617192 |             356 |
| Assessment using Alcohol Use Disorders Identification Test - Consumption (procedure) |      1422 |   431.00 |     612882 |             331 |
| Electrical cardioversion                                                             |      1383 | 25903.11 |   35824002 |              74 |
| Auscultation of the fetal heart                                                      |      1065 |  5312.51 |    5657822 |              71 |
| Evaluation of uterine fundal height                                                  |      1065 |  5287.59 |    5631281 |              71 |
+--------------------------------------------------------------------------------------+-----------+----------+------------+-----------------+

-- Procédures les plus coûteuses
SELECT 
    DESCRIPTION,
    COUNT(*) as frequency,
    ROUND(AVG(BASE_COST), 2) as avg_cost,
    ROUND(MAX(BASE_COST), 2) as max_cost,
    ROUND(SUM(BASE_COST), 2) as total_cost
FROM procedures
GROUP BY DESCRIPTION
ORDER BY avg_cost DESC
LIMIT 10;

+---------------------------------------------------------------------------------+-----------+-----------+----------+------------+
| DESCRIPTION                                                                     | frequency | avg_cost  | max_cost | total_cost |
+---------------------------------------------------------------------------------+-----------+-----------+----------+------------+
| Admit to ICU (procedure)                                                        |         5 | 206260.40 |   289531 |    1031302 |
| Coronary artery bypass grafting                                                 |         9 |  47085.89 |    67168 |     423773 |
| Lumpectomy of breast (procedure)                                                |         5 |  29353.00 |    31539 |     146765 |
| Hemodialysis (procedure)                                                        |        27 |  29299.56 |    37213 |     791088 |
| Insertion of biventricular implantable cardioverter defibrillator               |         4 |  27201.00 |    38711 |     108804 |
| Electrical cardioversion                                                        |      1383 |  25903.11 |    44532 |   35824002 |
| Partial resection of colon                                                      |         7 |  25229.29 |    38749 |     176605 |
| Fine needle aspiration biopsy of lung (procedure)                               |         1 |  23141.00 |    23141 |      23141 |
| Percutaneous mechanical thrombectomy of portal vein using fluoroscopic guidance |        57 |  20228.04 |    34733 |    1152998 |
| Percutaneous coronary intervention                                              |         9 |  19728.00 |    32927 |     177552 |
+---------------------------------------------------------------------------------+-----------+-----------+----------+------------+

-- Distribution des coûts de procédures
SELECT 
    CASE 
        WHEN BASE_COST < 100 THEN '< 100$'
        WHEN BASE_COST BETWEEN 100 AND 500 THEN '100-500$'
        WHEN BASE_COST BETWEEN 501 AND 1000 THEN '501-1000$'
        WHEN BASE_COST BETWEEN 1001 AND 5000 THEN '1001-5000$'
        WHEN BASE_COST BETWEEN 5001 AND 10000 THEN '5001-10000$'
        ELSE '> 10000$'
    END as cost_range,
    COUNT(*) as procedure_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM procedures), 2) as percentage
FROM procedures
GROUP BY cost_range
ORDER BY MIN(BASE_COST);

+-------------+-----------------+------------+
| cost_range  | procedure_count | percentage |
+-------------+-----------------+------------+
| < 100$      |             415 |       0.87 |
| 100-500$    |           32662 |      68.47 |
| 501-1000$   |            2855 |       5.99 |
| 1001-5000$  |            6289 |      13.18 |
| 5001-10000$ |            2753 |       5.77 |
| > 10000$    |            2727 |       5.72 |
+-------------+-----------------+------------+

-- ----------------------------------------------------------------------------
-- 2. ANALYSE PAR PATIENT
-- ----------------------------------------------------------------------------

-- Patients avec le plus de procédures
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
    p.GENDER,
    TIMESTAMPDIFF(YEAR, p.BIRTHDATE, d.date_enregistrement) as age,
    COUNT(pr.DESCRIPTION) as procedure_count,
    ROUND(SUM(pr.BASE_COST), 2) as total_procedure_cost
FROM patients p
JOIN procedures pr ON p.Id = pr.PATIENT
CROSS JOIN dataset_year d
GROUP BY patient_name, p.GENDER, age
ORDER BY procedure_count DESC
LIMIT 10;

+-------------------+--------+------+-----------------+----------------------+
| patient_name      | GENDER | age  | procedure_count | total_procedure_cost |
+-------------------+--------+------+-----------------+----------------------+
| Kimberly Collier  | F      |   92 |            1783 |              2489508 |
| Shani Parisian    | F      |   88 |            1243 |               952827 |
| Mariano OKon      | M      |   93 |            1170 |               982392 |
| Eugene Abernathy  | M      |   94 |             828 |              6522854 |
| Gail Glover       | M      |   87 |             759 |              9942253 |
| Treena Williamson | F      |   95 |             602 |              1149411 |
| Mariano Schroeder | M      |   86 |             540 |               270195 |
| Phylis Block      | F      |   88 |             526 |              1261598 |
| Efrain Dibbert    | M      |   98 |             498 |               217046 |
| Denis Wolff       | M      |   99 |             497 |               216849 |
+-------------------+--------+------+-----------------+----------------------+

-- Distribution du nombre de procédures par patient
SELECT 
    CASE 
        WHEN procedure_count = 1 THEN '1 procédure'
        WHEN procedure_count BETWEEN 2 AND 5 THEN '2-5 procédures'
        WHEN procedure_count BETWEEN 6 AND 10 THEN '6-10 procédures'
        WHEN procedure_count BETWEEN 11 AND 20 THEN '11-20 procédures'
        ELSE '20+ procédures'
    END as procedure_range,
    COUNT(*) as patient_count
FROM (
    SELECT PATIENT, COUNT(*) as procedure_count
    FROM procedures
    GROUP BY PATIENT
) as patient_procedures
GROUP BY procedure_range
ORDER BY MIN(procedure_count);

+------------------+---------------+
| procedure_range  | patient_count |
+------------------+---------------+
| 1 procédure      |            65 |
| 2-5 procédures   |            96 |
| 6-10 procédures  |            96 |
| 11-20 procédures |           140 |
| 20+ procédures   |           396 |
+------------------+---------------+

-- ----------------------------------------------------------------------------
-- 3. ANALYSE TEMPORELLE
-- ----------------------------------------------------------------------------

-- Tendance trimestrielle des procédures
SELECT 
    QUARTER(START) as quarter,
    COUNT(*) as procedure_count,
    COUNT(DISTINCT PATIENT) as unique_patients,
    ROUND(AVG(BASE_COST), 2) as avg_cost,
    ROUND(SUM(BASE_COST), 2) as total_cost
FROM procedures
GROUP BY quarter
ORDER BY quarter;

+---------+-----------------+-----------------+----------+------------+
| quarter | procedure_count | unique_patients | avg_cost | total_cost |
+---------+-----------------+-----------------+----------+------------+
|       1 |           12596 |             531 |  2147.71 |   27052527 |
|       2 |           11792 |             494 |  2237.51 |   26384695 |
|       3 |           11173 |             483 |  2299.33 |   25690407 |
|       4 |           12140 |             465 |  2173.81 |   26390082 |
+---------+-----------------+-----------------+----------+------------+

-- Procédures par année
SELECT 
    YEAR(START) as year,
    COUNT(*) as procedure_count,
    COUNT(DISTINCT PATIENT) as unique_patients,
    ROUND(AVG(BASE_COST), 2) as avg_cost,
    ROUND(SUM(BASE_COST), 2) as total_cost
FROM procedures
GROUP BY YEAR(START)
ORDER BY year;

+------+-----------------+-----------------+----------+------------+
| year | procedure_count | unique_patients | avg_cost | total_cost |
+------+-----------------+-----------------+----------+------------+
| 2011 |            1184 |              82 |  2328.35 |    2756770 |
| 2012 |            4456 |             362 |  2116.50 |    9431106 |
| 2013 |            4998 |             393 |  2172.77 |   10859501 |
| 2014 |            6292 |             448 |  1992.70 |   12538073 |
| 2015 |            4656 |             371 |  2275.28 |   10593719 |
| 2016 |            4143 |             383 |  2133.90 |    8840739 |
| 2017 |            4585 |             387 |  2224.00 |   10197041 |
| 2018 |            3880 |             363 |  2365.78 |    9179212 |
| 2019 |            4378 |             357 |  2201.69 |    9639011 |
| 2020 |            4451 |             360 |  2528.72 |   11255330 |
| 2021 |            4410 |             341 |  2156.90 |    9511924 |
| 2022 |             268 |              62 |  2668.97 |     715285 |
+------+-----------------+-----------------+----------+------------+
-- ----------------------------------------------------------------------------
-- 4. PROCÉDURES PAR RAISON MÉDICALE
-- ----------------------------------------------------------------------------

-- Top raisons de procédures
SELECT 
    e.DESCRIPTION,
    COUNT(*) as procedure_count,
    COUNT(DISTINCT p.PATIENT) as unique_patients,
    ROUND(AVG(p.BASE_COST), 2) as avg_cost,
    ROUND(SUM(p.BASE_COST), 2) as total_cost
FROM procedures p
LEFT JOIN encounters e ON p.encounter = e.id
WHERE e.DESCRIPTION IS NOT NULL
GROUP BY e.DESCRIPTION
ORDER BY procedure_count DESC
LIMIT 15;

+------------------------------------------------------------------+-----------------+-----------------+----------+------------+
| DESCRIPTION                                                      | procedure_count | unique_patients | avg_cost | total_cost |
+------------------------------------------------------------------+-----------------+-----------------+----------+------------+
| Encounter for check up (procedure)                               |           13510 |             271 |  1037.14 |   14011731 |
| General examination of patient (procedure)                       |            9295 |             207 |  1035.03 |    9620571 |
| Encounter for problem (procedure)                                |            4387 |              41 |   811.85 |    3561571 |
| Prenatal visit                                                   |            2974 |              83 |  3947.09 |   11738645 |
| Encounter for problem                                            |            2768 |             117 |  3015.32 |    8346419 |
| Prenatal initial visit                                           |            2498 |              81 |  3025.15 |    7556827 |
| Encounter for symptom                                            |            2168 |             381 |   762.76 |    1653664 |
| Follow-up encounter                                              |            1916 |              71 |   454.97 |     871722 |
| Patient encounter procedure (procedure)                          |            1183 |             137 |  1576.05 |    1864469 |
| Urgent care clinic (procedure)                                   |            1009 |              35 | 22555.78 |   22758787 |
| Encounter for 'check-up'                                         |             794 |             238 |  7678.28 |    6096552 |
| Patient encounter procedure                                      |             786 |             112 |  4194.48 |    3296858 |
| Emergency room admission (procedure)                             |             696 |             231 |  3319.29 |    2310224 |
| Gynecology service (qualifier value)                             |             402 |              17 |   884.05 |     355387 |
| Administration of vaccine to produce active immunity (procedure) |             377 |              27 |   461.32 |     173919 |
+------------------------------------------------------------------+-----------------+-----------------+----------+------------+

