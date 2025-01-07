-- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

-- Vytvoření pohledu pro porovnání průměrných mezd v různých odvětvých, procentuální meziroční změnu a celonárodní průměrnou mzdu.
CREATE OR REPLACE VIEW v_rb_payroll_trend_analysis AS
SELECT 
    year,
    industry,
    industry_code,
    ROUND(AVG(payroll), 2) AS avg_payroll,
    LAG(ROUND(AVG(payroll), 2)) OVER (PARTITION BY industry_code ORDER BY year) AS prev_year_payroll,
    ROUND(AVG(ROUND(AVG(payroll), 2)) OVER (PARTITION BY year), 2) AS national_avg_payroll,
    CASE 
        WHEN LAG(ROUND(AVG(payroll), 2)) OVER (PARTITION BY industry_code ORDER BY year) IS NULL THEN NULL
        ELSE ROUND((
            (ROUND(AVG(payroll), 2) - LAG(ROUND(AVG(payroll), 2)) OVER (PARTITION BY industry_code ORDER BY year)) 
            / LAG(ROUND(AVG(payroll), 2)) OVER (PARTITION BY industry_code ORDER BY year)) * 100, 2)
    END AS percent_change,
    CASE 
        WHEN LAG(ROUND(AVG(payroll), 2)) OVER (PARTITION BY industry_code ORDER BY year) IS NULL THEN NULL
        WHEN ROUND(AVG(payroll), 2) > LAG(ROUND(AVG(payroll), 2)) OVER (PARTITION BY industry_code ORDER BY year) THEN 'increased'
        WHEN ROUND(AVG(payroll), 2) < LAG(ROUND(AVG(payroll), 2)) OVER (PARTITION BY industry_code ORDER BY year) THEN 'decreased'
        ELSE 'no change'
    END AS trend
FROM t_romana_belohoubkova_project_SQL_primary_final
GROUP BY year, industry, industry_code;

-- Zjisti odvětví ve kterých mzdy klesaly a v kterém roce.
SELECT DISTINCT 
    			year, 
    			industry, 
    			industry_code, 
    			avg_payroll, 
   				percent_change 
FROM v_rb_payroll_trend_analysis AS vrpta 
WHERE trend = 'decreased'
ORDER BY year, industry;

-- Zjisti v kolika odvětvých se platy v letech snižovaly.
SELECT DISTINCT industry 
FROM v_rb_payroll_trend_analysis AS vrpta 
WHERE trend = 'decreased';

-- Zjisti odvětví ve kterých se mzdy v průběhu let nesnižovaly.
SELECT 
	industry, 
	industry_code
FROM v_rb_payroll_trend_analysis AS vrpta 
GROUP BY industry, industry_code
HAVING SUM(CASE 
			WHEN trend = 'decreased' THEN 1 
			ELSE 0 
			END) = 0;	
		
-- Zjisti v kolika letech mzdy rostly a v kterých odvětvých.
SELECT 
	industry, 
	industry_code, 
	COUNT(*) AS growth_years
FROM v_rb_payroll_trend_analysis AS vrpta 
WHERE trend = 'increased'
GROUP BY industry, industry_code
ORDER BY growth_years DESC;

-- Zjisti v kolika letech mzdy klesaly a v kterých odvětvích.
SELECT 
	industry, 
	industry_code, 
	COUNT(*) AS growth_years
FROM v_rb_payroll_trend_analysis AS vrpta 
WHERE trend = 'decreased'
GROUP BY industry, industry_code
ORDER BY growth_years DESC;

-- Zjisti průměrný meziroční procentuální růst mezd pro každé odvětví.
SELECT 
    industry,
    industry_code,
    ROUND(AVG(percent_change), 2) AS avg_growth
FROM v_rb_payroll_trend_analysis AS vrpta 
WHERE trend IS NOT NULL 
  	AND percent_change IS NOT NULL 
GROUP BY industry, industry_code
ORDER BY avg_growth DESC;

-- Zjisti největší meziroční procentuální změnu.
SELECT
	`year`, 
	industry_code,
	industry,
	MAX(percent_change) AS max_percent_change
FROM v_rb_payroll_trend_analysis AS vrpta 
WHERE percent_change IS NOT NULL
GROUP BY `year`, industry_code, industry 
ORDER BY max_percent_change DESC
LIMIT 3;

-- Zjisti nejzápornější meziroční procentuální změnu.
SELECT
	`year`, 
	industry_code,
	industry,
	MIN(percent_change) AS min_percent_change
FROM v_rb_payroll_trend_analysis AS vrpta 
WHERE percent_change IS NOT NULL
GROUP BY `year`, industry_code, industry 
ORDER BY min_percent_change ASC 
LIMIT 3;

-- Zjisti procentuální změny mezi první a poslední výplatou v celém sledovaném období. (Kde si za léta nejvíce polepšili)
SELECT 
    industry,
    industry_code,
    ROUND(((MAX(avg_payroll) - MIN(avg_payroll)) / MIN(avg_payroll)) * 100, 2) AS total_percent_change
FROM v_rb_payroll_trend_analysis AS vrpta 
GROUP BY industry, industry_code
ORDER BY total_percent_change DESC;












