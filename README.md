# Chinook — Ingénierie des données et pipelines SQL

**Projet de groupe · PostgreSQL 18 · Chinook Database 1.4.5**

## Présentation du projet

Nous analysons les **ventes musicales** de la base d'exemple Chinook et construisons progressivement un projet de data engineering : importation, contrôle de qualité des données, analyses SQL, optimisation, puis pipeline de transformations documenté.

**Question métier :** *Comment les ventes évoluent-elles dans le temps, et quels genres musicaux, artistes et pays génèrent le plus de chiffre d'affaires ?*

**Groupe :** 3  
**Membres :** 1. Justine DOUANLA 
              2. KOFFI Eliel Aurore 
              3. Lionel TOGLOBESSE 
              4. Patrick-Rasheed BEDIANG

## Source, licence et environnement

- **Base :** Chinook Database, version 1.4.5, **11 tables**.
- **Source :** [dépôt officiel Chinook](https://github.com/lerocha/chinook-database).
- **Fichier source :** [Chinook_PostgreSql.sql](https://github.com/lerocha/chinook-database/blob/master/ChinookDatabase/DataSources/Chinook_PostgreSql.sql).
- **Licence des données :** [MIT](https://github.com/lerocha/chinook-database/blob/master/LICENSE.md).
- **Environnement du groupe :** Windows, PostgreSQL 18, pgAdmin 4, Git et GitHub.
- **Étapes suivantes du cours :** SQL avancé, `EXPLAIN ANALYZE`, index, dbt avec PostgreSQL, schéma en étoile.

### Six critères de sélection de la base

| Critère du cours | Application à Chinook |
| --- | --- |
| 4 à 5 tables reliées au minimum | 11 tables avec PK, FK et contraintes |
| Dimension temporelle | `invoice.invoice_date` (analyses mensuelles et annuelles) |
| Catégories / groupes | `genre`, `media_type`, pays |
| Hiérarchie | artiste → album → piste |
| Volume | **15 607 lignes** relevées dans le rapport de contrôle ; |
| Licence ouverte | MIT ; source et licence citées |

## Structure du dépôt

```text
chinook-data-engineering/
├── data/
│   └── Chinook_Import.sql
├── sql/
│   ├── 01_ca_par_client.sql
│   ├── 02_ca_par_genre.sql
│   └── 03_ca_mensuel.sql
├── schemas/
│   └── chinook_schema_relationnel.png
├── docs/
│   └── controles_qualités
└── README.md
```


## Installation locale — PostgreSQL

1. Installer PostgreSQL 18 et pgAdmin 4.
2. Créer une **base vide** `chinook` dans pgAdmin.
3. Ouvrir **Query Tool** connecté à `chinook`.
4. Charger et exécuter `data/Chinook_Import.sql` **une seule fois sur la base vide**.
5. Actualiser `Schemas > public > Tables` : 11 tables doivent être présentes.

Le fichier `Chinook_Import.sql` est une copie du SQL PostgreSQL d'origine adaptée à pgAdmin : les instructions de suppression/création de base et `\c chinook` y ont été retirées. **Ne pas réexécuter sur une base déjà remplie** sans procédure de réinitialisation. Chaque membre utilise sa propre base locale, sans partager ses mots de passe.

## Modèle relationnel

L'ERD issu de pgAdmin décrit notamment les liens :

- `artist` → `album` → `track` ; `genre` et `media_type` → `track`.
- `customer` → `invoice` → `invoice_line` → `track`.
- `playlist` ↔ `track` par `playlist_track`.
- `employee.reports_to` : hiérarchie du personnel.

Diagramme exporté : `schemas/chinook_schema_relationnel.png` .

**Convention de nommage SQL :** la source utilise des underscores : `invoice_line`, `customer_id`, `track_id`, `unit_price`, `invoice_date`, etc.

## Trois premières analyses métier

| Script | Question | Notions |
| --- | --- | --- |
| `sql/01_ca_par_client.sql` | Quels clients contribuent le plus au chiffre d'affaires ? | `JOIN`, `SUM`, `GROUP BY` |
| `sql/02_ca_par_genre.sql` | Quels genres musicaux génèrent le plus de chiffre d'affaires ? | Jointures, agrégations |
| `sql/03_ca_mensuel.sql` | Comment évoluent les ventes mois par mois ? | `DATE_TRUNC`, `JOIN`, `GROUP BY` |

## NOUVEAU — Vérification de la source avant modélisation

M. KOFFI Eliel a réalisé **17 requêtes de vérification**, regroupées selon **six axes** :

1. **Complétude :** lignes par table après importation.
2. **Dimension temporelle :** dates extrêmes, volumes et chiffre d'affaires par année et par mois.
3. **Cohérence du chiffre d'affaires :** `SUM(invoice.total)` comparé à `SUM(invoice_line.unit_price * quantity)` et recherche des factures incohérentes.
4. **Analyses métier :** chiffre d'affaires par genre, artiste et pays.
5. **Qualité :** valeurs nulles, factures sans lignes, clients sans facture, prix et quantités anormaux.
6. **Géographie :** concordance entre pays du client et pays de facturation.

### Résultats communiqués dans le rapport de contrôle

| Indicateur | Résultat rapporté |
| --- | ---: |
| Nombre de tables / lignes | **11 / 15 607** |
| Factures / lignes de facture | **412 / 2 240** |
| Période des factures | **01/01/2021 – 22/12/2025** |
| Chiffre d'affaires total | **2 328,60** (unité monétaire du jeu de données non précisée) |
| Genres en tête | **Rock 826,65 · Latin 382,14 · Metal 261,36** |
| Artistes en tête | **Iron Maiden 138,60 · U2 105,93 · Metallica 90,09** |
| Pays en tête | **USA 523,06 · Canada 303,96 · France 195,10** |
| Clients sans pays | **0** |
| Clients sans état/région (`state`) | **29 sur 59** |
| Écart total facture / somme des lignes | **Aucun signalé** |
| Morceaux sans album ni genre | **Aucun signalé** |
| Factures sans lignes, clients sans facture | **Aucun signalé** |
| Prix ou quantité ≤ 0 ; écart de pays | **Aucun signalé** |

Les résultats des requêtes sont documentés avec le fichier Excel fourni ; ils restent vérifiables dans PostgreSQL.

### Point de vigilance pour le futur ETL / dbt

**29 clients sur 59 n'ont pas de valeur dans `customer.state`**. La colonne n'est pas requise pour l'analyse *par pays*. Avant la transformation, il faut documenter le choix : conserver les `NULL`, normaliser la dimension géographique, ou écarter cette colonne des analyses régionales. **Ne pas inventer d'États/régions**.

**Traçabilité des contrôles  nouveaux fichiers ajoutés par le groupe :**

- `Projet Chinook – Pourquoi et comment les requêtes de vérification SQL.pdf` : démarche, 17 contrôles, interprétation et résultats.
- `Chinook_resultats_requetes.xlsx` : requêtes SQL, résultats et conclusions de vérification.

> Mettre les chemins GitHub définitifs ici une fois les deux documents localisés dans le dépôt. Leur emplacement n'a pas été vérifié directement.

## Avancement

- [x] Sujet, source et licence documentés.
- [x] PostgreSQL installé et base importée.
- [x] Schéma relationnel exporté (PK, FK).
- [x] Trois premières analyses métier.
- [x] Dépôt de groupe partagé.
- [x] **Contrôle initial des données documenté : 17 requêtes et synthèse des résultats.**
- [ ] Vérifier/traiter la décision sur `customer.state`.
- [ ] Confirmer le dépôt Moodle de la fiche projet.
- [ ] Fonctions de fenêtre, CTE récursive, index et `EXPLAIN ANALYZE`.
- [ ] Jeux de données volumineux / benchmarks.
- [ ] Pipeline dbt (staging → marts), tests, documentation et schéma en étoile.
- [ ] Restitution finale.

## Collaboration Git

**Règle d'équipe : pas de travail directement sur `main` pour les nouvelles fonctionnalités.** Mettre sa branche à jour, créer une branche de tâche, faire des commits explicites, ouvrir une Pull Request et faire relire avant fusion. Ne jamais publier de mots de passe, de fichiers `.env` ou d'informations confidentielles.

```bash
git switch main
git pull --ff-only origin main
git switch -c docs/actualisation-controles
# Modifier README.md et les documents nécessaires
git add README.md
git commit -m "docs: documenter les controles qualite Chinook"
git push -u origin docs/actualisation-controles
```

Puis ouvrir une **Pull Request** sur GitHub vers `main`.

## Références

- [Chinook Database (source)](https://github.com/lerocha/chinook-database) — licence MIT.
- Cours *Fondation SQL* : diapositives 37 à 40 (projet fil rouge).
- Documents d'analyse du groupe : PDF des 17 vérifications et classeur de résultats, cités ci-dessus.

*Projet pédagogique — la licence MIT du jeu de données reste applicable aux éléments réutilisés.*
