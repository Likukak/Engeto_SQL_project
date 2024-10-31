CREATE OR REPLACE TABLE t_romana_belohoubkova_project_SQL_secondary_final AS
SELECT 
    e.year AS year,
    c.country AS country, 
    c.continent AS continent,
    e.GDP AS GDP,
    e.gini AS gini,
    e.population AS population,
    e.taxes AS tax_burden 
FROM economies e
JOIN countries c 
	ON e.country = c.country AND c.continent = 'Europe';