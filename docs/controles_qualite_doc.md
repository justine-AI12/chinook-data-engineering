# Contrôles qualité de la base Chinook

Ce document explique **pourquoi** nous vérifions la base Chinook avant de la modéliser en étoile, et **comment** fonctionnent les 17 requêtes du fichier [`sql/00_controles_qualite.sql`](../sql/00_controles_qualite.sql).

**Question métier :** comment les ventes évoluent-elles dans le temps, et quels genres, artistes et pays génèrent le plus de chiffre d'affaires ?

## 1. Pourquoi ces requêtes

On ne construit pas un modèle en étoile sur une source qu'on n'a pas contrôlée. Chaque groupe de requêtes répond à une question précise.

| Groupe | Question posée | Pourquoi c'est nécessaire |
| --- | --- | --- |
| 1. Complétude | L'import est-il complet ? | Prouver qu'aucune ligne ne manque ; ces chiffres serviront ensuite à valider l'ETL |
| 2. Dimension temps | Les factures couvrent-elles une période assez longue, sans trous ? | La question métier parle d'évolution dans le temps |
| 3. Chiffre d'affaires | Peut-on mesurer le CA, et les deux tables de ventes sont-elles cohérentes ? | Le CA est la mesure principale du futur modèle |
| 4. Analyse | Peut-on obtenir le CA par genre, artiste et pays ? | C'est le test direct de la question métier |
| 5. Qualité | Y a-t-il des valeurs vides, des orphelins ou des montants anormaux ? | Chaque anomalie devient une règle de nettoyage dans l'ETL |
| 6. Pays | Le pays du client et celui de la facture sont-ils identiques ? | Choisir quelle colonne utiliser pour l'analyse par pays |

## 2. Les tables utilisées

Une facture contient des lignes ; chaque ligne vise un morceau, qui appartient à un album, un artiste et un genre.

| Table | Une ligne représente | Utilité pour le projet |
| --- | --- | --- |
| `invoice` | Un achat (client, date, pays, total) | Dimension temps, pays, total par achat |
| `invoice_line` | Un morceau acheté dans un achat (prix, quantité) | Seule table qui dit quel morceau a été vendu |
| `track` | Un morceau | Lien vers album et genre |
| `album` | Un album | Lien vers l'artiste |
| `artist` | Un artiste | Analyse par artiste |
| `genre` | Un genre musical | Analyse par genre |
| `customer` | Un client | Pays du client |

**Exemple concret : la facture n°1.** Elle est datée du 1er janvier 2021, pour le client n°2 (Stuttgart, Allemagne), avec un total de 1,98. Elle contient 2 lignes : *Balls to the Wall* (0,99 × 1) et *Restless and Wild* (0,99 × 1). Comme 0,99 + 0,99 = 1,98, le total de la facture est bien la somme de ses lignes.

Avec 2 240 lignes de facture pour 412 factures, une facture compte en moyenne environ 5 morceaux.

## 3. Les notions SQL utilisées

### Fonctions sur les dates

| Notion | Ce qu'elle fait | Exemple | Pourquoi ici |
| --- | --- | --- | --- |
| `EXTRACT(YEAR FROM date)` | Extrait une partie de la date (année, mois, jour) sous forme de nombre | `EXTRACT(YEAR FROM '2021-03-17')` donne `2021` | Regrouper les factures par année |
| `DATE_TRUNC('month', date)` | Ramène une date au début de sa période en gardant une vraie date | `DATE_TRUNC('month', '2021-03-17')` donne `2021-03-01` | Regrouper par mois tout en gardant l'année |

**Pourquoi deux fonctions différentes ?** `EXTRACT(MONTH ...)` renvoie un simple nombre : `3` pour mars 2021 comme pour mars 2022, et les deux années seraient mélangées. `DATE_TRUNC` conserve l'année (`2021-03-01` et `2022-03-01` restent distincts) et permet de trier dans l'ordre chronologique. On utilise donc `EXTRACT` pour l'année seule, et `DATE_TRUNC` pour le mois.

### Calculs et regroupements

| Notion | Ce qu'elle fait | Pourquoi ici |
| --- | --- | --- |
| `COUNT(*)` | Compte les lignes | Nombre de lignes par table, nombre de factures |
| `SUM(colonne)` | Additionne les valeurs | Chiffre d'affaires |
| `MIN` / `MAX` | Plus petite / plus grande valeur | Première et dernière date de facture |
| `GROUP BY` | Regroupe les lignes de même valeur pour calculer un résultat par groupe | CA par année, par genre, par pays |
| `HAVING` | Filtre après le regroupement (`WHERE` filtre avant) | Garder les factures dont le total diffère de la somme des lignes |
| `ORDER BY` / `DESC` | Trie le résultat (`DESC` : du plus grand au plus petit) | Classements |
| `LIMIT` | Ne garde que les N premières lignes | Top 10 artistes |

### Jointures et valeurs vides

| Notion | Ce qu'elle fait | Pourquoi ici |
| --- | --- | --- |
| `JOIN ... ON` | Relie deux tables par une clé commune (ne garde que les lignes qui se correspondent) | Relier facture, ligne, morceau, album, artiste |
| `LEFT JOIN` | Garde toutes les lignes de la table de gauche, même sans correspondance | Trouver les factures sans lignes ou les clients sans facture |
| `IS NULL` | Teste si une valeur est vide (on n'écrit jamais `= NULL`) | Repérer les valeurs manquantes, et les orphelins après un `LEFT JOIN` |
| `COUNT(*) FILTER (WHERE ...)` | Compte seulement les lignes qui respectent la condition | Compter plusieurs anomalies en une seule requête |
| `UNION ALL` | Empile les résultats de plusieurs requêtes | Un seul tableau avec le nombre de lignes de chaque table |
| `AS` | Donne un nom à une colonne ou à une table | Lisibilité des résultats |

## 4. Les 17 requêtes une par une

Le code complet se trouve dans [`sql/00_controles_qualite.sql`](../sql/00_controles_qualite.sql) ; les numéros ci-dessous sont les mêmes que dans ce fichier.

### Groupe 1 : complétude

**Requête 1 : lignes par table.** `COUNT(*)` compte les lignes de chaque table et `UNION ALL` empile les 11 résultats dans un seul tableau. Attendu : 15 607 lignes au total, comme dans le fichier source.

### Groupe 2 : dimension temps

- **Requête 2 : période couverte.** `MIN` et `MAX` de `invoice_date`. Il faut plusieurs années de ventes, sinon l'analyse d'évolution n'a pas de sens.
- **Requête 3 : factures et CA par année.** `EXTRACT(YEAR FROM invoice_date)` isole l'année, `GROUP BY` crée un groupe par année, `COUNT(*)` compte les factures et `SUM(total)` additionne leur montant.
- **Requête 4 : factures et CA par mois.** Même logique avec `DATE_TRUNC('month', ...)`, qui garde l'année avec le mois. Permet de repérer un mois manquant ou anormal.

### Groupe 3 : chiffre d'affaires

- **Requêtes 5 et 6 : CA total par deux chemins.** La première additionne les totaux des factures, la seconde additionne prix × quantité de chaque ligne. Les deux résultats doivent être identiques.
- **Requête 7 : factures dont le total diffère de la somme des lignes.** `JOIN` relie chaque facture à ses lignes, `GROUP BY` recalcule la somme par facture, et `HAVING` ne garde que les factures où le total est différent. Un `WHERE` ne peut pas filtrer sur une somme, d'où `HAVING`. Attendu : aucune ligne.

### Groupe 4 : analyse par genre, artiste, pays

- **Requête 8 : CA par genre.** On part de `invoice_line` (ce qui est vendu), on joint `track` puis `genre`, et on additionne par genre.
- **Requête 9 : top 10 artistes.** Chaîne de jointures plus longue : ligne de facture, morceau, album, artiste. `LIMIT 10` ne garde que les dix premiers. Cette longueur est un indice utile pour la modélisation en étoile.
- **Requête 10 : CA par pays de facturation.** Aucune jointure : le pays est déjà dans `invoice`.

### Groupe 5 : qualité des données

- **Requête 11 : clients sans pays, sans état.** `COUNT(*) FILTER (WHERE ... IS NULL)` compte deux anomalies en une seule requête.
- **Requêtes 12 et 13 : morceaux sans genre, sans album.** Un morceau sans genre disparaîtrait de l'analyse par genre ; sans album, de l'analyse par artiste.
- **Requête 14 : factures sans lignes.** `LEFT JOIN` garde toutes les factures, puis `WHERE ... IS NULL` ne conserve que celles sans ligne. C'est la technique classique pour trouver des orphelins.
- **Requête 15 : clients sans facture.** Même technique, entre `customer` et `invoice`.
- **Requête 16 : prix ou quantités anormaux.** Une vente à zéro ou négative est suspecte.

### Groupe 6 : pays

**Requête 17 : pays du client contre pays de facturation.** On relie chaque facture à son client et on compte les cas où les deux pays diffèrent. Sert à choisir quelle colonne utiliser pour l'analyse par pays.

## 5. Résultats obtenus

Résultats observés sur la base importée (PostgreSQL, Chinook 1.4.5).

| Requête | Résultat observé | Conclusion |
| --- | --- | --- |
| 1. Lignes par table | Les 11 tables correspondent au fichier source (15 607 lignes au total) | OK |
| 2. Période | Du 01/01/2021 au 22/12/2025 | OK |
| 3. Par année | 83 factures par an (80 en 2025) ; CA entre 449,46 et 481,45 | OK |
| 4. Par mois | 7 factures par mois en général ; aucun mois manquant | OK |
| 5-6. CA total | 2 328,60, égal à la somme des 5 années | OK |
| 7. Total ≠ somme des lignes | Aucune ligne renvoyée | OK |
| 8. CA par genre | Rock (826,65), Latin (382,14), Metal (261,36) en tête | OK |
| 9. Top artistes | Iron Maiden (138,60), U2 (105,93), Metallica (90,09) | OK |
| 10. CA par pays | USA (523,06), Canada (303,96), France (195,10) | OK |
| 11. Sans pays / sans état | 0 sans pays ; 29 clients sur 59 sans état | À nettoyer (léger) |
| 12-13. Sans genre / sans album | 0 et 0 | OK |
| 14-15. Factures sans lignes / clients sans facture | Aucune ligne renvoyée | OK |
| 16. Prix ou quantités anormaux | 0 | OK |
| 17. Pays client ≠ pays facturation | 0 écart | OK |

## 6. Conclusion

La base est cohérente et répond à la question métier : elle couvre cinq ans de ventes sans trou et permet d'obtenir le chiffre d'affaires par genre, artiste et pays. À retenir pour la suite :

- La colonne `state` est vide pour 29 clients sur 59. Elle n'est pas nécessaire à l'analyse par pays ; il reste à décider si on la garde avec une valeur de remplacement ou si on l'écarte, et à justifier ce choix.
- Le pays du client et celui de la facture sont toujours identiques : l'un ou l'autre peut servir.
- 2025 compte 3 factures de moins que les autres années : la couverture est complète, mais il faut le garder en tête pour comparer les années.
