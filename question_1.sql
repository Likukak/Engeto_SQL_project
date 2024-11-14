-- Vytvoření pohledu pro průměrné mzdy v jednotlivých letech a odvětvích.
CREATE OR REPLACE VIEW avg_industry_payroll_per_year AS
SELECT 
    year,
    industry,
    industry_code,
    ROUND(AVG(payroll), 1) AS avg_payroll
FROM t_romana_belohoubkova_project_SQL_primary_final
GROUP BY year, industry, industry_code;

-- Pohled pro přidání předchozích mezd pomocí LAG.
CREATE OR REPLACE VIEW industry_payroll_yearly_changes AS
SELECT 
    year,
    industry,
    industry_code,
    avg_payroll,
    LAG(avg_payroll) OVER(PARTITION BY industry_code ORDER BY year) AS prev_year_payroll
FROM avg_industry_payroll_per_year;

-- Pohled pro výpočet procentuální změny a označení trendu.
CREATE OR REPLACE VIEW payroll_trend_analysis AS
SELECT 
    year,
    industry,
    industry_code,
    avg_payroll,
    prev_year_payroll,
    CASE 
        WHEN prev_year_payroll IS NULL THEN NULL
        ELSE ROUND(((avg_payroll - prev_year_payroll) / prev_year_payroll) * 100, 1)
    END AS percent_change,
    CASE 
        WHEN prev_year_payroll IS NULL THEN NULL
        WHEN avg_payroll > prev_year_payroll THEN 'increased'
        WHEN avg_payroll < prev_year_payroll THEN 'decreased'
        ELSE 'no change'
    END AS trend
FROM industry_payroll_yearly_changes AS ipyc;

-- Zjisti odvětví ve kterých mzdy klesaly a v kterém roce.
SELECT DISTINCT 
    			year, 
    			industry, 
    			industry_code, 
    			avg_payroll, 
   				percent_change 
FROM payroll_trend_analysis AS pta
WHERE trend = 'decreased'
ORDER BY year, industry;

-- Zjisti odvětví ve kterých se mzdy v průběhu let nesnižovaly.
SELECT industry, industry_code
FROM payroll_trend_analysis AS pta
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
FROM payroll_trend_analysis AS pta
WHERE trend = 'increased'
GROUP BY industry, industry_code
ORDER BY growth_years DESC;

-- Zjisti v kolika letech mzdy klesaly a v kterých odvětvích.
SELECT 
	industry, 
	industry_code, 
	COUNT(*) AS growth_years
FROM payroll_trend_analysis AS pta
WHERE trend = 'decreased'
GROUP BY industry, industry_code
ORDER BY growth_years DESC;

-- Zjisti průměrný meziroční procentuální růst mezd pro každé odvětví.
SELECT 
    industry,
    industry_code,
    ROUND(AVG(percent_change), 2) AS avg_growth
FROM payroll_trend_analysis AS pta
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
FROM payroll_trend_analysis AS pta
WHERE percent_change IS NOT NULL
GROUP BY `year`, industry_code, industry 
ORDER BY max_percent_change DESC
LIMIT 1;

-- Zjisti nejzápornější meziroční procentuální změnu.
SELECT
	`year`, 
	industry_code,
	industry,
	MIN(percent_change) AS min_percent_change
FROM payroll_trend_analysis AS pta
WHERE percent_change IS NOT NULL
GROUP BY `year`, industry_code, industry 
ORDER BY min_percent_change ASC 
LIMIT 1;

-- Zjisti procentuální změny mezi první a poslední výplatou v celém sledovaném období. (Kde si za léta nejvíce polepšili)
SELECT 
    industry,
    industry_code,
    ROUND(((MAX(avg_payroll) - MIN(avg_payroll)) / MIN(avg_payroll)) * 100, 2) AS total_percent_change
FROM avg_industry_payroll_per_year AS aippy 
GROUP BY industry, industry_code
ORDER BY total_percent_change DESC;











