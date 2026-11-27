# Chinook — Ingénierie des données et pipelines SQL

**Projet fil rouge de groupe · PostgreSQL 18 · pgAdmin 4 · dbt Core · GitHub**

## Présentation du projet

Nous analysons les **ventes musicales** de la base d'exemple Chinook et construisons progressivement un projet de data engineering : importation, contrôle de qualité des données, analyses SQL, passage à l'échelle, optimisation des requêtes, puis pipeline dbt testé et documenté.

**Question métier :** *Comment les ventes évoluent-elles dans le temps, et quels genres musicaux, artistes et pays génèrent le plus de chiffre d'affaires ?*

Le fil rouge couvre trois jalons : **J1 — fondations relationnelles et analyses SQL**, **J2 — SQL avancé et performances**, **J3 — dbt et schéma en étoile**, suivis de la restitution globale.

## Source, licence et environnement

- **Base :** Chinook Database 1.4.5, **11 tables relationnelles**.
- **Source :** [dépôt officiel Chinook](https://github.com/lerocha/chinook-database).
- **Script source :** [Chinook_PostgreSql.sql](https://github.com/lerocha/chinook-database/blob/master/ChinookDatabase/DataSources/Chinook_PostgreSql.sql).
- **Licence des données :** [MIT](https://github.com/lerocha/chinook-database/blob/master/LICENSE.md).
- **Environnement :** Windows, PostgreSQL 18, pgAdmin 4, SQL, Python, dbt Core, dbt-postgres, Git et GitHub.
- **Organisation des données :** base `chinook` pour le SQL initial ; base `chinook_database_dbt`, schémas `raw` et `dbt_dev`, pour les transformations dbt ; tables volumineuses distinctes pour les benchmarks.

### Six critères de sélection de la base

| Critère du cours | Application à Chinook |
| --- | --- |
| Au moins 4 à 5 tables reliées | 11 tables avec identifiants et relations |
| Dimension temporelle | `invoice.invoice_date` pour les analyses mensuelles et annuelles |
| Catégories / groupes | Genres, types de média et pays |
| Hiérarchie | Artiste → album → piste ; hiérarchie des employés (`reports_to`) |
| Volume | 15 607 lignes initiales ; jeu de benchmark dépassant 10 millions de lignes |
| Licence ouverte | Licence MIT et source citées |

## Structure du dépôt

Arborescence synthétique des fichiers et dossiers du projet (les deux scripts SQL ajoutés en fin de projet ainsi que le nouveau diagramme sont à inclure dans le prochain envoi Git s'ils n'y figurent pas encore) :

```text
chinook-data-engineering/
├── data/
│   ├── Chinook_Import.sql
│   └── Chinook_PostgreSql.sql
├── sql/
│   ├── 00_controles_qualite.sql
│   ├── 01_ca_par_client.sql
│   ├── 02_ca_par_genre.sql
│   ├── 03_evolution_ca_par_mois.sql
│   ├── exo1_filrouge.sql
│   ├── 02_requetes_avancees.sql          # nouveau : à confirmer sur Git
│   ├── 04_requetes_metier_marts.sql      # nouveau : à confirmer sur Git
│   └── benchmark/
│       ├── 01_passage_echelle.sql
│       ├── 02_explain_analyze.sql
│       └── 03_indexation.sql
├── dbt_chinook/
│   └── chinook_dbt/
│       ├── dbt_project.yml
│       ├── models/
│       │   ├── staging/                  # 11 modèles + _sources.yml
│       │   ├── intermediate/             # 2 modèles
│       │   └── marts/                    # 4 modèles + _marts.yml
│       └── tests/
│           └── assert_ca_coherent.sql
├── schemas/
│   ├── chinook_schema_relationnel.png
│   ├── lineage_dbt.png
│   └── schema_etoile.png               # export pgAdmin : à confirmer sur Git
├── docs/
│   ├── Fiche_projet_Chinook.pdf
│   ├── controles_qualite_doc.md
│   └── compte_rendu_benchmark_indexation.pdf
└── README.md
```

## Installation locale — PostgreSQL

1. Installer PostgreSQL 18 et pgAdmin 4.
2. Créer une **base vide** `chinook` dans pgAdmin.
3. Ouvrir **Query Tool** connecté à `chinook`.
4. Charger et exécuter `data/Chinook_Import.sql` **une seule fois sur la base vide**.
5. Actualiser `Schemas > public > Tables` : les 11 tables doivent apparaître.
6. Pour les requêtes d'analyse sur le schéma en étoile, utiliser **une autre base**, `chinook_database_dbt`, après chargement des données dans `raw` et exécution de dbt.

Le fichier `Chinook_Import.sql` est adapté à une exécution dans pgAdmin. **Ne pas le réexécuter sur une base déjà remplie** sans réinitialisation. Les identifiants et mots de passe PostgreSQL doivent rester locaux : ne pas les publier sur GitHub.

## J1 — Modèle relationnel et premières analyses SQL

### Modèle relationnel

L'ERD exporté depuis pgAdmin présente notamment les relations suivantes :

- `artist` → `album` → `track` ; `genre` et `media_type` → `track` ;
- `customer` → `invoice` → `invoice_line` → `track` ;
- `playlist` ↔ `track` via la table d'association `playlist_track` ;
- `employee.reports_to` pour la hiérarchie du personnel.

**Diagramme :** [schemas/chinook_schema_relationnel.png](schemas/chinook_schema_relationnel.png).

**Convention SQL :** les colonnes de la base initiale emploient des noms en `snake_case`, comme `invoice_line`, `customer_id`, `unit_price` et `invoice_date`.

### Trois premières analyses métier

| Script | Question du projet | Notions SQL mobilisées |
| --- | --- | --- |
| [`sql/01_ca_par_client.sql`](sql/01_ca_par_client.sql) | Quels clients contribuent le plus au chiffre d'affaires ? | `JOIN`, `SUM`, `GROUP BY` |
| [`sql/02_ca_par_genre.sql`](sql/02_ca_par_genre.sql) | Quels genres musicaux génèrent le plus de chiffre d'affaires ? | Jointures, agrégations |
| [`sql/03_evolution_ca_par_mois.sql`](sql/03_evolution_ca_par_mois.sql) | Comment évoluent les ventes d'un mois à l'autre ? | Regroupement temporel |

### Vérification de la source avant modélisation

**17 requêtes de contrôle**, réparties selon **six axes**, ont été documentées dans [`sql/00_controles_qualite.sql`](sql/00_controles_qualite.sql) et [`docs/controles_qualite_doc.md`](docs/controles_qualite_doc.md) :

1. **Complétude :** nombre de lignes après importation.
2. **Dimension temporelle :** dates extrêmes, volumes et chiffre d'affaires par période.
3. **Cohérence du chiffre d'affaires :** rapprochement entre le total des factures et la somme de leurs lignes.
4. **Analyses métier :** chiffre d'affaires par genre, artiste et pays.
5. **Qualité :** valeurs manquantes, factures et clients orphelins, prix et quantités anormaux.
6. **Géographie :** concordance entre pays client et pays de facturation.

### Résultats du contrôle qualité

| Indicateur | Résultat rapporté |
| --- | ---: |
| Tables / lignes dans la base initiale | **11 / 15 607** |
| Factures / lignes de facture | **412 / 2 240** |
| Période des factures | **01/01/2021 – 22/12/2025** |
| Chiffre d'affaires total | **2 328,60** (unité monétaire non précisée) |
| Genres en tête | **Rock 826,65 · Latin 382,14 · Metal 261,36** |
| Artistes en tête | **Iron Maiden 138,60 · U2 105,93 · Metallica 90,09** |
| Pays en tête | **USA 523,06 · Canada 303,96 · France 195,10** |
| Clients sans pays | **0** |
| Clients sans état/région (`state`) | **29 sur 59** |
| Écart entre facture et somme des lignes | **Aucun signalé** |
| Factures sans ligne / clients sans facture | **Aucun signalé** |
| Prix ou quantité ≤ 0 / incohérence de pays | **Aucun signalé** |

**Point de vigilance :** `customer.state` est absent pour 29 clients sur 59. Les analyses par pays restent possibles ; les analyses régionales doivent tenir compte des `NULL` plutôt que d'inventer des valeurs.

## J2 — SQL avancé, passage à l'échelle et performances

### SQL avancé — questions métier et techniques

| Script | Question / objectif | Technique |
| --- | --- | --- |
| [`sql/exo1_filrouge.sql`](sql/exo1_filrouge.sql) | Quels morceaux sont les mieux classés dans chaque genre ? | CTE enchaînées, `ROW_NUMBER()` |
| `sql/02_requetes_avancees.sql` | Comment évoluent les ventes ? Comment classer et segmenter les clients ? Comment explorer l'organigramme ? | `LAG`, `RANK`, `DENSE_RANK`, `NTILE`, `ROWS BETWEEN`, `WITH RECURSIVE`, CTE |

Le fichier `02_requetes_avancees.sql` est une **extension préparée en fin de projet** : son exécution dans pgAdmin et sa présence sur GitHub restent à confirmer. Il ne faut pas confondre code rédigé et résultat mesuré.

### Passage à l'échelle

Le script [`sql/benchmark/01_passage_echelle.sql`](sql/benchmark/01_passage_echelle.sql) crée des copies volumineuses des factures et des lignes de facture afin de mesurer l'effet des index sur des données plus importantes.

| Table de benchmark | Volume documenté |
| --- | ---: |
| `invoice_big` | **1 854 000 lignes** |
| `invoice_line_big` | **10 080 000 lignes** |

Ces volumes correspondent aux scripts et au rapport du dépôt ; ils concernent **les tables de benchmark**, pas les 2 240 lignes de ventes de la base Chinook initiale ou du Mart dbt.

### Benchmark avant / après indexation

Les essais utilisent `EXPLAIN ANALYZE` et les index du dossier [`sql/benchmark/`](sql/benchmark/). Les résultats ci-dessous sont extraits du [rapport de benchmark](docs/compte_rendu_benchmark_indexation.pdf) :

| Requête évaluée | Sans index | Avec index | Interprétation |
| --- | ---: | ---: | --- |
| Q1 — Factures d'un client | 84,4 ms | 14,0 ms | Environ **6 ×** plus rapide |
| Q2 — CA par pays (jointure complète) | 3 393,9 ms | 3 381,4 ms | Gain négligeable |
| Q3 — Lignes d'une facture | 281,2 ms | 0,029 ms | Gain très important sur une recherche sélective |
| Q4 — CA filtré par client | 700,6 ms | 378,7 ms | Environ **1,9 ×** plus rapide |

**Analyse :** les index sont particulièrement utiles pour retrouver une petite fraction des lignes ; ils n'améliorent pas nécessairement une agrégation qui parcourt presque toute la table. Les résultats restent sensibles au cache, aux statistiques et aux conditions de mesure. Les temps ci-dessus sont ceux rapportés dans le document, non des mesures reproduites ici.

## J3 — Pipeline dbt testé et schéma en étoile

### Architecture du pipeline

Le projet dbt se trouve dans [`dbt_chinook/chinook_dbt/`](dbt_chinook/chinook_dbt/). Il utilise une seconde base PostgreSQL, `chinook_database_dbt`, avec les sources dans `raw` et les objets transformés dans `dbt_dev`.

```text
11 tables sources (raw)
          ↓
11 modèles STAGING : nettoyage et renommage
          ↓
2 modèles INTERMEDIATE : enrichissement des pistes et des ventes
          ↓
4 modèles MARTS : 1 table de faits + 3 dimensions
          ↓
Requêtes analytiques et documentation
```

| Couche | Modèles réalisés | Finalité |
| --- | ---: | --- |
| `staging` | **11** | Harmoniser les noms et types de colonnes |
| `intermediate` | **2** | Réaliser les jointures et calculer les montants des lignes |
| `marts` | **4** | Exposer un schéma en étoile pour les analyses métier |

### Schéma en étoile

Le **grain** de `fct_sales` est **une ligne de facture**. Chaque ligne peut être reliée à une dimension client, piste musicale et date.

| Mart | Rôle | Nombre de lignes observé |
| --- | --- | ---: |
| `fct_sales` | Faits : quantité, prix et montant | **2 240** |
| `dim_customers` | Identité et pays des clients | **59** |
| `dim_tracks` | Morceaux, albums, artistes et genres | **3 503** |
| `dim_date` | Jour, mois, trimestre, année et week-end | **354** |

**Diagrammes :** [lignage dbt](schemas/lineage_dbt.png) · **schéma en étoile :** `schemas/schema_etoile.png` (export réalisé dans pgAdmin, à ajouter ou vérifier dans Git).

> Les tests `relationships` de dbt vérifient la cohérence des références mais n'ajoutent pas de contraintes `FOREIGN KEY`. Des PK/FK ont été ajoutées manuellement dans pgAdmin pour dessiner les relations ; une nouvelle exécution de dbt peut recréer les tables et faire disparaître ces contraintes physiques.

### Tests et documentation

- Déclaration des 11 sources dans [`models/staging/_sources.yml`](dbt_chinook/chinook_dbt/models/staging/_sources.yml).
- Tests génériques sur les Marts : `unique`, `not_null` et `relationships`.
- **14 tests validés**, d'après le résultat `PASS=14 WARN=0 ERROR=0` obtenu dans le terminal.
- Test personnalisé [`tests/assert_ca_coherent.sql`](dbt_chinook/chinook_dbt/tests/assert_ca_coherent.sql) : contrôle de cohérence du chiffre d'affaires ; **son résultat d'exécution reste à confirmer**.
- Documentation produite avec `dbt docs generate`, puis consultée via `dbt docs serve` ; graphe de lignage capturé.

### Trois questions métier sur les Marts

Le fichier `sql/04_requetes_metier_marts.sql` a été préparé pour exploiter le schéma `dbt_dev` :

| Question | Tables sollicitées | Résultat attendu |
| --- | --- | --- |
| Quels genres génèrent le plus de chiffre d'affaires ? | `fct_sales`, `dim_tracks` | CA, quantités et part du total par genre |
| Quels sont les dix meilleurs clients ? | `fct_sales`, `dim_customers` | Montant, factures et quantités par client |
| Comment les ventes évoluent-elles par mois ? | `fct_sales`, `dim_date` | CA mensuel et variation via `LAG()` |

**État :** requêtes rédigées ; exécution PostgreSQL et publication GitHub à confirmer.

### Reproduire le pipeline dbt

Le dépôt contient les modèles et le projet dbt, mais **pas le chargement automatisé des fichiers CSV dans `raw`** ni les identifiants de connexion. Après avoir importé les 11 tables dans `chinook_database_dbt.raw` et configuré localement le profil dbt `chinook_dbt` :

```bash
cd dbt_chinook/chinook_dbt
dbt debug
dbt build
dbt docs generate
dbt docs serve
```

Le mot de passe PostgreSQL doit être fourni localement à travers `DBT_POSTGRES_PASSWORD` (voir le profil dbt) ; ne jamais le commiter. Les tests et les modèles ne pourront être reproduits que si les tables sources sont bien chargées dans le schéma `raw`.

## Avancement et restitution

- [x] Sujet, source, licence et problématique métier documentés.
- [x] Base relationnelle importée et schéma relationnel exporté.
- [x] Trois premières analyses SQL et 17 contrôles qualité documentés.
- [x] Passage à l'échelle, indexation et rapport de benchmark présents dans le dépôt.
- [x] Pipeline dbt : 11 modèles Staging, 2 Intermediate, 4 Marts.
- [x] 14 tests génériques dbt validés et documentation de lignage générée.
- [x] Schéma en étoile créé et exporté depuis pgAdmin.
- [ ] Confirmer l'exécution et le push de `02_requetes_avancees.sql`.
- [ ] Confirmer l'exécution et le push de `04_requetes_metier_marts.sql`.
- [ ] Ajouter/vérifier `schemas/schema_etoile.png` dans le dépôt GitHub.
- [ ] Confirmer le résultat du test personnalisé et le dépôt Moodle, si nécessaire.
- [ ] Finaliser la présentation de restitution : sujet, modèle, SQL avancé, performances, dbt, schéma en étoile et limites.

## Collaboration Git

Le dépôt GitHub centralise les scripts SQL, les modèles dbt, les diagrammes et les documents de validation. Pour éviter d'écraser les modifications parallèles, mettre `main` à jour et privilégier une branche de travail accompagnée d'une Pull Request. Ne jamais publier de mots de passe, de fichiers `.env` ni d'informations confidentielles.

```bash
git switch main
git pull --ff-only origin main
git switch -c docs/readme-fil-rouge
# Remplacer le README.md à la racine, puis vérifier les fichiers à publier
git add README.md
git commit -m "docs: actualiser le README du fil rouge Chinook"
git push -u origin docs/readme-fil-rouge
```

Puis ouvrir une Pull Request vers `main` et vérifier que les liens du README correspondent aux fichiers effectivement publiés.

## Références

- [Chinook Database — dépôt officiel](https://github.com/lerocha/chinook-database) — licence MIT.
- Cours *Fondation SQL* : lancement du projet fil rouge et critères de sélection.
- Cours *SQL avancé* : passage à l'échelle, fonctions de fenêtre, CTE, index et benchmarks.
- Cours *dbt* : sources, Staging, Intermediate, Marts, tests, documentation et schéma en étoile.
- [Rapport de contrôle qualité](docs/controles_qualite_doc.md) et [rapport de benchmark](docs/compte_rendu_benchmark_indexation.pdf).

*Projet pédagogique — la licence MIT du jeu de données demeure applicable aux éléments réutilisés.*
