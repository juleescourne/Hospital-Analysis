# Analyse des Données Hospitalières - Projet SQL

Analyse de données hospitalières réelles avec MySQL.

## À propos du projet

Ce projet personnel explore un dataset de **environ 80,000 enregistrements** de dossiers médicaux concrets dans le domaine de la santé. L'objectif est de démontrer des compétences en analyse de données SQL à travers des requêtes progressives allant de l'exploration basique aux analyses avancées avec jointures complexes et window functions.

**Dataset** : [Maven Analytics - Hospital Patient Records](https://mavenanalytics.io/data-playground/hospital-patient-records)

Données synthétiques sur environ 1 000 patients du Massachusetts General Hospital de 2011 à 2022, incluant des informations sur la démographie des patients, la couverture d’assurance et les consultations et procédures médicales.

## Objectifs

L'objectif est avant tout technique. Le but de ce projet est d'analyser un dataset issue de données médicales réelles via des requêtes SQL.

1. **Profil démographique** : Comprendre qui sont nos patients
2. **Parcours de soins** : Analyser les trajectoires et comportements patients
3. **Performance financière** : Évaluer les coûts et la rentabilité
4. **Qualité des soins** : Identifier les axes d'amélioration

## Structure des données

```
Base de données : hopital
├── patients (données démographiques)
├── organizations (établissements de santé)
├── payers (assureurs)
├── encounters (consultations/admissions) 
└── procedures (actes médicaux) 
```

**Volume des données** :
- 974 patients
- 27891 consultations
- 47701 procédures
- 1 organisation (Massachusetts General Hospital)
- 10 assureurs

## Démarrage rapide

### Installation

*Voir [installation.md](installation.md) pour le guide complet*

## Analyses SQL réalisées

### 1. Exploration des données (`queries/01_data_exploration.sql`)
- Vue d'ensemble des tables
- Statistiques descriptives
- Distribution des variables clés

**Concepts SQL** : `SELECT`, `COUNT`, `GROUP BY`, `UNION ALL`, `CASE WHEN`

### 2. Analyse démographique (`queries/02_demographic_analysis.sql`)
- Distribution géographique
- Analyse de mortalité
- Segmentation patients

**Concepts SQL** : `TIMESTAMPDIFF`, `DATE_FORMAT`, `ROUND`, `SUBQUERIES`, `JOINS`

### 3. Parcours de soins (`queries/03_care_pathways.sql`)
- Taux de réadmission
- Durée moyenne de séjour (LOS)
- Patterns temporels (saisonnalité)

**Concepts SQL** : Fonctions fenêtres (`ROW_NUMBER`, `OVER`), `CTE`, `SELF JOIN`

### 4. Analyse financière (`queries/04_financial_analysis.sql`)
- Revenus par organisation
- Taux de couverture assurance
- Créances patients
- Rentabilité par type de soin

**Concepts SQL** : Agrégations complexes, `HAVING`, calculs de pourcentages, `NULLIF`

### 5. Indicateurs de performance (`queries/05_kpi_dashboard.sql`)
- Dashboard exécutif
- KPIs mensuels
- Alertes et anomalies

**Concepts SQL** : Vues, métriques calculées, comparaisons temporelles

## Exemples de questions métier résolues

### Question 1 : Qui sont nos patients les plus coûteux ?
```sql
-- Top 10 des patients par coûts totaux
SELECT 
    CONCAT(p.FIRST, ' ', p.LAST) as patient,
    COUNT(e.Id) as nb_visites,
    ROUND(SUM(e.TOTAL_CLAIM_COST), 2) as cout_total,
    ROUND(AVG(e.TOTAL_CLAIM_COST), 2) as cout_moyen
FROM patients p
JOIN encounters e ON p.Id = e.PATIENT
GROUP BY p.Id
ORDER BY cout_total DESC
LIMIT 10;
```

### Question 2 : Quel est notre taux de réadmission à 30 jours ?
```sql
-- Réadmissions dans les 30 jours
SELECT 
    COUNT(DISTINCT e1.PATIENT) as patients_readmis,
    ROUND(COUNT(DISTINCT e1.PATIENT) * 100.0 / 
          (SELECT COUNT(DISTINCT PATIENT) FROM encounters), 2) as taux_readmission
FROM encounters e1
JOIN encounters e2 ON e1.PATIENT = e2.PATIENT
WHERE e2.START > e1.STOP
  AND TIMESTAMPDIFF(DAY, e1.STOP, e2.START) <= 30;
```

## Compétences SQL démontrées

- Jointures multiples (INNER, LEFT, self-joins)
- Fonctions d'agrégation (COUNT, SUM, AVG, MIN, MAX)
- Sous-requêtes corrélées et non-corrélées
- Common Table Expressions (CTE)
- Fonctions fenêtres (ROW_NUMBER, RANK, OVER)
- Fonctions de date (TIMESTAMPDIFF, DATE_FORMAT)
- Expressions CASE complexes
- GROUP BY avec HAVING
- UNION et UNION ALL

## Structure du projet

```
hospital-analytics/
│
├── README.md                                   
├── INSTALLATION.md                             # Guide d'installation détaillé
│
├── queries/
│   ├── 01_data_exploration.sql                 # Exploration initiale
│   ├── 02_demographic_analysis.sql             # Analyses démographiques
│   ├── 03_care_pathways.sql                    # Parcours patients
│   └── 04_procedure_financial_analysis.sql     # Analyses financières et procédures
