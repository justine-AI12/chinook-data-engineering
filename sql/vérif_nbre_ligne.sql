/** Vérifier le nombre de table **/
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
	AND table_type = 'BASE TABLE'
ORDER BY table_name;

/** Verifier le nombre d'enregistrements **/

SELECT COUNT(*) AS nombre_morceaux
FROM public.track;