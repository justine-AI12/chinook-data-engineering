# Chinook — Ingénierie des données et pipelines SQL

**Projet de groupe | PostgreSQL 18 | Chinook Database 1.4.5**

## Présentation

Ce projet étudie les **ventes et les préférences musicales** à partir de la base d'exemple Chinook. Nous utilisons PostgreSQL pour explorer un modèle relationnel, réaliser des analyses SQL, puis approfondir les performances et la construction d'un pipeline de transformation.

**Question métier :** *Quels clients, genres musicaux et marchés contribuent le plus au chiffre d'affaires, et comment les ventes évoluent-elles dans le temps ?*

**Groupe :** à compléter  
**Membres :** à compléter

## Jeu de données et licence

- **Source :** [Chinook Database — dépôt de Luis Rocha](https://github.com/lerocha/chinook-database)
- **Fichier source :** [Chinook_PostgreSql.sql](https://github.com/lerocha/chinook-database/blob/master/ChinookDatabase/DataSources/Chinook_PostgreSql.sql)
- **Version utilisée :** 1.4.5
- **Licence du jeu de données :** [MIT](https://github.com/lerocha/chinook-database/blob/master/LICENSE.md)
- **Modèle source :** 11 tables relationnelles (artistes, albums, morceaux, clients, factures, etc.)

### Adéquation aux six critères du cours

| Critère | Application à Chinook |
| --- | --- |
| Au moins 4 à 5 tables reliées | 11 tables avec clés primaires et étrangères |
| Dimension temporelle | `invoice.invoice_date` |
| Catégories ou groupes | Genres musicaux, types de médias, pays |
| Hiérarchie | Artiste → album → morceau ; exercice de CTE récursive à définir |
| Volume | Données suffisantes pour les premières analyses ; augmentation du volume envisagée pour les benchmarks jusqu'à 10 M de lignes |
| Licence ouverte | MIT, source citée |

## Environnement de travail

- Windows
- PostgreSQL 18
- pgAdmin 4
- Git et GitHub
- Pour la suite du cours : Python 3.10+ et dbt avec l'adaptateur PostgreSQL

Chaque membre travaille sur sa **propre base PostgreSQL locale** et synchronise les scripts grâce à GitHub. **Aucun mot de passe ne doit être ajouté au dépôt.**

## Organisation du dépôt

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
└── README.md
```

> Vérifier les noms des fichiers dans le dépôt si vous les avez renommés. Le fichier `Chinook_Import.sql` est une **copie adaptée à pgAdmin** du script Chinook original : les commandes de suppression/création de la base et `\c chinook` ont été retirées.

## Installation et importation

1. Installer PostgreSQL et pgAdmin.
2. Dans pgAdmin, créer une **base vide** nommée `chinook`.
3. Ouvrir le **Query Tool** connecté à `chinook`.
4. Charger `data/Chinook_Import.sql` puis exécuter le script **une seule fois** sur cette base vide.
5. Actualiser `Schemas > public > Tables` : le modèle contient 11 tables.

**Attention :** ne pas relancer le script d'importation sur une base déjà remplie sans avoir prévu une réinitialisation.

## Modélisation relationnelle

Le modèle Chinook relie notamment :

- `artist` → `album` → `track`
- `customer` → `invoice` → `invoice_line`
- `genre` → `track`, `media_type` → `track`
- `playlist` ↔ `track` via `playlist_track`

Les **clés primaires (PK)** identifient les lignes ; les **clés étrangères (FK)** assurent les relations et l'intégrité référentielle. Le diagramme réalisé avec pgAdmin se trouve dans [`schemas/chinook_schema_relationnel.png`](schemas/chinook_schema_relationnel.png).

## Trois analyses SQL du projet

| Fichier | Question étudiée | Notions utilisées |
| --- | --- | --- |
| [`01_ca_par_client.sql`](sql/01_ca_par_client.sql) | Quels clients génèrent le plus de chiffre d'affaires ? | `JOIN`, `SUM`, `GROUP BY`, `ORDER BY` |
| [`02_ca_par_genre.sql`](sql/02_ca_par_genre.sql) | Quels genres musicaux génèrent le plus de chiffre d'affaires ? | Jointures multiples, agrégation |
| [`03_ca_mensuel.sql`](sql/03_ca_mensuel.sql) | Comment évolue le chiffre d'affaires par mois ? | Jointure, `DATE_TRUNC`, agrégation |

**Convention SQL importante :** la version utilisée nomme les colonnes avec des underscores, par exemple `customer_id`, `invoice_id`, `invoice_date`, `track_id`, et la table `invoice_line`. Vérifier que les fichiers SQL suivent bien cette convention.

## Avancement et prochaines étapes

- [x] Sujet et dataset choisis
- [x] Environnement PostgreSQL installé
- [x] Dataset importé
- [x] Schéma relationnel exporté
- [x] Trois premières requêtes SQL rédigées et exécutées
- [x] Dépôt GitHub partagé
- [ ] Fiche projet finale déposée sur Moodle
- [ ] Fonctions de fenêtre et CTE récursive
- [ ] Index et `EXPLAIN ANALYZE` sur des volumes adaptés
- [ ] Projet dbt (staging → marts), tests et documentation
- [ ] Schéma en étoile et restitution finale

## Collaboration

Pour récupérer les derniers changements :

```bash
git pull origin main
```

Pour publier un changement validé :

```bash
git add .
git commit -m "Description du changement"
git push origin main
```

Pour le travail simultané, privilégier des branches de travail et des pull requests afin d'éviter les conflits sur `main`.

---

*Projet pédagogique — Ingénierie des données et pipelines SQL. Les données Chinook restent soumises à leur licence MIT d'origine.*
