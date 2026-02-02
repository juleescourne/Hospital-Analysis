-- ============================================================================
-- 03_ENCOUNTER_ANALYTICS.SQL
-- Analyses des visites et admissions hospitalières
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ANALYSE DES ADMISSIONS ET RÉADMISSIONS
-- ----------------------------------------------------------------------------

-- Patients admis/réadmis par année
SELECT 
    YEAR(START) as year,
    COUNT(DISTINCT PATIENT) as unique_patients,
    COUNT(*) as total_encounters,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT PATIENT), 2) as encounters_per_patient
FROM encounters
GROUP BY YEAR(START)
ORDER BY year;

+------+-----------------+------------------+------------------------+
| year | unique_patients | total_encounters | encounters_per_patient |
+------+-----------------+------------------+------------------------+
| 2011 |             410 |             1336 |                   3.26 |
| 2012 |             559 |             2106 |                   3.77 |
| 2013 |             570 |             2495 |                   4.38 |
| 2014 |             630 |             3885 |                   6.17 |
| 2015 |             553 |             2469 |                   4.46 |
| 2016 |             552 |             2451 |                   4.44 |
| 2017 |             546 |             2360 |                   4.32 |
| 2018 |             535 |             2292 |                   4.28 |
| 2019 |             514 |             2228 |                   4.33 |
| 2020 |             519 |             2519 |                   4.85 |
| 2021 |             649 |             3530 |                   5.44 |
| 2022 |             103 |              220 |                   2.14 |
+------+-----------------+------------------+------------------------+

-- Taux de réadmission (patients avec plus d'un encounter)
SELECT 
    COUNT(DISTINCT PATIENT) as total_unique_patients,
    SUM(CASE WHEN encounter_count > 1 THEN 1 ELSE 0 END) as readmitted_patients,
    ROUND(SUM(CASE WHEN encounter_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT PATIENT), 2) as readmission_rate
FROM (
    SELECT PATIENT, COUNT(*) as encounter_count
    FROM encounters
    GROUP BY PATIENT
) as patient_encounter_counts;

+-----------------------+---------------------+------------------+
| total_unique_patients | readmitted_patients | readmission_rate |
+-----------------------+---------------------+------------------+
|                   974 |                 854 |            87.68 |
+-----------------------+---------------------+------------------+

-- Réadmissions dans les 30 jours
WITH patient_encounters AS (
    SELECT
        PATIENT,
        START,
        STOP,
        LEAD(START) OVER (PARTITION BY PATIENT ORDER BY START) AS next_start
    FROM encounters
)
SELECT
    COUNT(DISTINCT PATIENT) AS patient_readmissions_within_30_days,
    ROUND(COUNT(DISTINCT PATIENT)*100.0 / (SELECT COUNT(*) FROM patients),2) AS pct_readmissions_within_30_days,
    ROUND(AVG(TIMESTAMPDIFF(DAY, STOP, next_start)), 1) AS avg_day_readmissions
FROM patient_encounters
WHERE next_start IS NOT NULL
  AND TIMESTAMPDIFF(DAY, STOP, next_start) <= 30;

+-------------------------------------+---------------------------------+----------------------+
| patient_readmissions_within_30_days | pct_readmissions_within_30_days | avg_day_readmissions |
+-------------------------------------+---------------------------------+----------------------+
|                                 773 |                           79.36 |                 10.2 |
+-------------------------------------+---------------------------------+----------------------+

-- ----------------------------------------------------------------------------
-- 2. DURÉE DE SÉJOUR 
-- ----------------------------------------------------------------------------

-- Durée moyenne de séjour par classe d'encounter
SELECT 
    ENCOUNTERCLASS,
    COUNT(*) as encounter_count,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, START, STOP)), 2) as avg_hours,
    ROUND(AVG(TIMESTAMPDIFF(DAY, START, STOP)), 2) as avg_days,
    MIN(TIMESTAMPDIFF(HOUR, START, STOP)) as min_hours,
    MAX(TIMESTAMPDIFF(HOUR, START, STOP)) as max_hours
FROM encounters
WHERE STOP IS NOT NULL
GROUP BY ENCOUNTERCLASS
ORDER BY avg_hours DESC;

+----------------+-----------------+-----------+----------+-----------+-----------+
| ENCOUNTERCLASS | encounter_count | avg_hours | avg_days | min_hours | max_hours |
+----------------+-----------------+-----------+----------+-----------+-----------+
| inpatient      |            1135 |     36.81 |     1.53 |        24 |      8250 |
| ambulatory     |           12537 |      9.11 |     0.36 |         0 |     44930 |
| outpatient     |            6300 |      5.61 |     0.23 |         0 |     10704 |
| emergency      |            2322 |      1.53 |     0.02 |         1 |       589 |
| wellness       |            1931 |      0.00 |     0.00 |         0 |         0 |
| urgentcare     |            3666 |      0.00 |     0.00 |         0 |         0 |
+----------------+-----------------+-----------+----------+-----------+-----------+

-- Distribution de la durée de séjour
SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(HOUR, START, STOP) < 1 THEN '< 1 heure'
        WHEN TIMESTAMPDIFF(HOUR, START, STOP) BETWEEN 1 AND 24 THEN '1-24 heures'
        WHEN TIMESTAMPDIFF(DAY, START, STOP) BETWEEN 2 AND 3 THEN '2-3 jours'
        WHEN TIMESTAMPDIFF(DAY, START, STOP) BETWEEN 4 AND 7 THEN '4-7 jours'
        WHEN TIMESTAMPDIFF(DAY, START, STOP) BETWEEN 8 AND 14 THEN '8-14 jours'
        WHEN TIMESTAMPDIFF(DAY, START, STOP) BETWEEN 15 AND 30 THEN '15-30 jours'
        ELSE '> 30 jours'
    END as duration_range,
    COUNT(*) as encounter_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM encounters WHERE STOP IS NOT NULL), 2) as percentage
FROM encounters
WHERE STOP IS NOT NULL
GROUP BY duration_range
ORDER BY MIN(TIMESTAMPDIFF(HOUR, START, STOP));

+----------------+-----------------+------------+
| duration_range | encounter_count | percentage |
+----------------+-----------------+------------+
| < 1 heure      |           21539 |      77.23 |
| 1-24 heures    |            6294 |      22.57 |
| > 30 jours     |              20 |       0.07 |
| 2-3 jours      |               8 |       0.03 |
| 4-7 jours      |              12 |       0.04 |
| 8-14 jours     |              14 |       0.05 |
| 15-30 jours    |               4 |       0.01 |
+----------------+-----------------+------------+

-- ----------------------------------------------------------------------------
-- 3. ANALYSE PAR TYPE D'ENCOUNTER
-- ----------------------------------------------------------------------------

-- Encounters urgents vs programmés
SELECT 
    CASE 
        WHEN ENCOUNTERCLASS IN ('emergency', 'urgentcare') THEN 'Urgence'
        WHEN ENCOUNTERCLASS IN ('ambulatory', 'outpatient', 'wellness') THEN 'Programmé'
        ELSE 'Hospitalisation'
    END as encounter_type,
    COUNT(*) as count,
    ROUND(AVG(TOTAL_CLAIM_COST), 2) as avg_cost,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, START, STOP)), 2) as avg_duration_hours
FROM encounters
WHERE STOP IS NOT NULL
GROUP BY encounter_type;

+-----------------+-------+----------+--------------------+
| encounter_type  | count | avg_cost | avg_duration_hours |
+-----------------+-------+----------+--------------------+
| Programmé       | 20768 |  2821.93 |               7.20 |
| Urgence         |  5988 |  5694.62 |               0.59 |
| Hospitalisation |  1135 |  7761.35 |              36.81 |
+-----------------+-------+----------+--------------------+

-- ----------------------------------------------------------------------------
-- 4. ANALYSE TEMPORELLE
-- ----------------------------------------------------------------------------

-- Encounters par jour de la semaine
SELECT 
    DAYNAME(START) as day_of_week,
    DAYOFWEEK(START) as day_number,
    COUNT(*) as encounter_count,
    ROUND(AVG(TOTAL_CLAIM_COST), 2) as avg_cost
FROM encounters
GROUP BY DAYNAME(START), DAYOFWEEK(START)
ORDER BY day_number;

+-------------+------------+-----------------+----------+
| day_of_week | day_number | encounter_count | avg_cost |
+-------------+------------+-----------------+----------+
| Sunday      |          1 |            3973 |  2017.96 |
| Monday      |          2 |            4405 |  4398.30 |
| Tuesday     |          3 |            3644 |  4405.32 |
| Wednesday   |          4 |            4370 |  4575.51 |
| Thursday    |          5 |            3477 |  3346.62 |
| Friday      |          6 |            4059 |  3433.82 |
| Saturday    |          7 |            3963 |  3154.29 |
+-------------+------------+-----------------+----------+

-- Encounters par mois de l'année
SELECT 
    MONTHNAME(START) as month,
    MONTH(START) as month_number,
    COUNT(*) as encounter_count,
    ROUND(AVG(TOTAL_CLAIM_COST), 2) as avg_cost
FROM encounters
GROUP BY MONTHNAME(START), MONTH(START)
ORDER BY month_number;

+-----------+--------------+-----------------+----------+
| month     | month_number | encounter_count | avg_cost |
+-----------+--------------+-----------------+----------+
| January   |            1 |            2217 |  3952.31 |
| February  |            2 |            3028 |  2978.70 |
| March     |            3 |            2688 |  3157.47 |
| April     |            4 |            2312 |  3476.37 |
| May       |            5 |            2374 |  3538.79 |
| June      |            6 |            2181 |  4001.86 |
| July      |            7 |            2182 |  3804.70 |
| August    |            8 |            2129 |  4164.49 |
| September |            9 |            2113 |  3559.23 |
| October   |           10 |            2087 |  3904.28 |
| November  |           11 |            2333 |  3573.47 |
| December  |           12 |            2247 |  3963.02 |
+-----------+--------------+-----------------+----------+

-- Encounters par trimestre (saisonnalité)
SELECT 
    QUARTER(START) as quarter_number,
    COUNT(*) as encounter_count,
    ROUND(AVG(TOTAL_CLAIM_COST), 2) as avg_cost
FROM encounters
GROUP BY quarter_number
ORDER BY quarter_number;

+----------------+-----------------+----------+
| quarter_number | encounter_count | avg_cost |
+----------------+-----------------+----------+
|              1 |            7933 |  3311.36 |
|              2 |            6867 |  3664.85 |
|              3 |            6424 |  3843.20 |
|              4 |            6667 |  3808.32 |
+----------------+-----------------+----------+

-- Heures de pointe
SELECT 
    CASE 
        WHEN HOUR(START) BETWEEN 0 AND 3 THEN "0-3"
        WHEN HOUR(START) BETWEEN 4 AND 7 THEN "4-7"
        WHEN HOUR(START) BETWEEN 8 AND 11 THEN "8-11"
        WHEN HOUR(START) BETWEEN 12 AND 15 THEN "12-15"
        WHEN HOUR(START) BETWEEN 16 AND 19 THEN "16-19"
        WHEN HOUR(START) BETWEEN 20 AND 23 THEN "20-23"
        ELSE 'TIME TRAVELER' END
    AS hour_bracket,
    COUNT(*) as encounter_count
FROM encounters
GROUP BY hour_bracket
ORDER BY hour_bracket;

+--------------+-----------------+
| hour_bracket | encounter_count |
+--------------+-----------------+
| 0-3          |            4786 |
| 12-15        |            4306 |
| 16-19        |            4614 |
| 20-23        |            4458 |
| 4-7          |            5021 |
| 8-11         |            4706 |
+--------------+-----------------+


-- ----------------------------------------------------------------------------
-- 5. ANALYSE PAR PAYER (ASSURANCE)
-- ----------------------------------------------------------------------------

-- Encounters par payer
SELECT 
    p.NAME as payer_name,
    COUNT(e.Id) as encounter_count,
    COUNT(DISTINCT e.PATIENT) as unique_patients,
    ROUND(AVG(e.TOTAL_CLAIM_COST), 2) as avg_claim_cost,
    ROUND(AVG(e.PAYER_COVERAGE), 2) as avg_coverage,
    ROUND(AVG(e.PAYER_COVERAGE * 100.0 / NULLIF(e.TOTAL_CLAIM_COST, 0)), 2) as avg_coverage_rate
FROM encounters e
JOIN payers p ON e.PAYER = p.Id
GROUP BY p.Id, p.NAME
ORDER BY encounter_count DESC;

+------------------------+-----------------+-----------------+----------------+--------------+-------------------+
| payer_name             | encounter_count | unique_patients | avg_claim_cost | avg_coverage | avg_coverage_rate |
+------------------------+-----------------+-----------------+----------------+--------------+-------------------+
| Medicare               |           11371 |             449 |        2167.55 |      1689.89 |             62.95 |
| NO_INSURANCE           |            8807 |             262 |        5593.20 |         0.00 |              0.00 |
| Medicaid               |            1443 |             113 |        6205.22 |      5833.66 |             74.55 |
| Humana                 |            1084 |             219 |        3269.30 |         1.80 |              1.26 |
| Aetna                  |             936 |             207 |        2767.05 |         1.90 |              0.50 |
| Blue Cross Blue Shield |             925 |             216 |        3245.58 |      2242.70 |             32.02 |
| Dual Eligible          |             912 |              62 |        1696.19 |      1513.93 |             45.90 |
| UnitedHealthcare       |             900 |             206 |        2848.34 |         4.37 |              2.61 |
| Cigna Health           |             809 |             203 |        2996.95 |         1.20 |              0.20 |
| Anthem                 |             704 |             204 |        4236.81 |         0.00 |              0.00 |
+------------------------+-----------------+-----------------+----------------+--------------+-------------------+

-- ----------------------------------------------------------------------------
-- 7. ANALYSE DES COÛTS
-- ----------------------------------------------------------------------------

-- Statistiques de coûts globales
SELECT 
    COUNT(*) as total_encounters,
    ROUND(AVG(BASE_ENCOUNTER_COST), 2) as avg_base_cost,
    ROUND(AVG(TOTAL_CLAIM_COST), 2) as avg_total_cost,
    ROUND(AVG(PAYER_COVERAGE), 2) as avg_payer_coverage,
    ROUND(SUM(PAYER_COVERAGE)*100 / SUM(TOTAL_CLAIM_COST), 2) as coverage_pct
FROM encounters;

+------------------+---------------+----------------+--------------------+--------------+
| total_encounters | avg_base_cost | avg_total_cost | avg_payer_coverage | coverage_pct |
+------------------+---------------+----------------+--------------------+--------------+
|            27891 |        116.18 |        3639.68 |            1114.97 |        30.63 |
+------------------+---------------+----------------+--------------------+--------------+

-- Coûts moyens par classe d'encounter
SELECT 
    ENCOUNTERCLASS,
    COUNT(*) as count,
    ROUND(AVG(BASE_ENCOUNTER_COST), 2) as avg_base_cost,
    ROUND(AVG(TOTAL_CLAIM_COST), 2) as avg_total_cost,
    ROUND(AVG(PAYER_COVERAGE), 2) as avg_coverage,
    ROUND(AVG(TOTAL_CLAIM_COST - PAYER_COVERAGE), 2) as avg_patient_cost,
    ROUND(SUM(PAYER_COVERAGE)*100 / SUM(TOTAL_CLAIM_COST), 2) as coverage_pct
FROM encounters
GROUP BY ENCOUNTERCLASS
ORDER BY avg_total_cost DESC;

+----------------+-------+---------------+----------------+--------------+------------------+--------------+
| ENCOUNTERCLASS | count | avg_base_cost | avg_total_cost | avg_coverage | avg_patient_cost | coverage_pct |
+----------------+-------+---------------+----------------+--------------+------------------+--------------+
| inpatient      |  1135 |        113.67 |        7761.35 |      3250.01 |          4511.34 |        41.87 |
| urgentcare     |  3666 |        142.58 |        6369.16 |       834.40 |          5534.76 |        13.10 |
| emergency      |  2322 |        145.25 |        4629.65 |      1398.29 |          3231.36 |        30.20 |
| wellness       |  1931 |        136.80 |        4260.71 |      2289.88 |          1970.83 |        53.74 |
| ambulatory     | 12537 |        105.73 |        2894.11 |      1029.23 |          1864.88 |        35.56 |
| outpatient     |  6300 |        105.04 |        2237.30 |       599.64 |          1637.65 |        26.80 |
+----------------+-------+---------------+----------------+--------------+------------------+--------------+

-- Encounters les plus coûteux
SELECT 
    CONCAT(
        REGEXP_REPLACE(p.FIRST, '[^[:alpha:]]', ''),
        ' ',
        REGEXP_REPLACE(p.LAST, '[^[:alpha:]]', '')
     ) as patient_name,
    e.ENCOUNTERCLASS,
    e.DESCRIPTION,
    ROUND(e.PAYER_COVERAGE*100 / e.TOTAL_CLAIM_COST, 2) as coverage_pct,
    e.TOTAL_CLAIM_COST,
    py.NAME as payer_name
FROM encounters e
JOIN patients p ON e.PATIENT = p.Id
LEFT JOIN payers py ON e.PAYER = py.Id
ORDER BY e.TOTAL_CLAIM_COST DESC
LIMIT 15;

+-------------------+----------------+----------------------------------------------+--------------+------------------+---------------+
| patient_name      | ENCOUNTERCLASS | DESCRIPTION                                  | coverage_pct | TOTAL_CLAIM_COST | payer_name    |
+-------------------+----------------+----------------------------------------------+--------------+------------------+---------------+
| Tonisha Shields   | emergency      | Encounter for problem                        |         0.00 |        641882.70 | Anthem        |
| Wendell Hessel    | inpatient      | Admission to intensive care unit (procedure) |        79.98 |        309748.16 | Medicare      |
| Estrella Homenick | inpatient      | Admission to intensive care unit (procedure) |        79.98 |        199655.26 | Medicare      |
| Rivka Schumm      | inpatient      | Admission to intensive care unit (procedure) |        94.94 |        198487.11 | Dual Eligible |
| Miguel Manzanares | inpatient      | Admission to intensive care unit (procedure) |        79.96 |        146473.57 | Medicare      |
| Jay Collins       | emergency      | Myocardial Infarction                        |        79.91 |        100055.91 | Medicare      |
| Elvis Hackett     | emergency      | Myocardial Infarction                        |        79.90 |         85905.65 | Medicare      |
| Ignacio Hermiston | emergency      | Myocardial Infarction                        |         0.00 |         78693.97 | Anthem        |
| Jamar Mills       | wellness       | General examination of patient (procedure)   |        79.82 |         65633.22 | Medicare      |
| Magnolia Stark    | ambulatory     | Prenatal initial visit                       |         0.00 |         65318.86 | NO_INSURANCE  |
| Demetra Sawayn    | ambulatory     | Prenatal initial visit                       |        94.91 |         64909.01 | Medicaid      |
| Sharice Johnston  | ambulatory     | Prenatal initial visit                       |         0.00 |         64309.83 | Aetna         |
| Tonda Stamm       | ambulatory     | Prenatal initial visit                       |         0.00 |         63714.32 | NO_INSURANCE  |
| Tiny Schaefer     | ambulatory     | Prenatal initial visit                       |        94.91 |         63589.44 | Medicaid      |
| Winona VonRueden  | ambulatory     | Prenatal initial visit                       |         0.00 |         63244.54 | Cigna Health  |
+-------------------+----------------+----------------------------------------------+--------------+------------------+---------------+
