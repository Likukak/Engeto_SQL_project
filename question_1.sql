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
        WHEN prev_year_payroll IS NULL THEN 'start_year'
        ELSE ROUND(((avg_payroll - prev_year_payroll) / prev_year_payroll) * 100, 1)
    END AS percent_change,
    CASE 
        WHEN prev_year_payroll IS NULL THEN 'initial_payroll'
        WHEN avg_payroll > prev_year_payroll THEN 'increased'
        WHEN avg_payroll < prev_year_payroll THEN 'decreased'
        ELSE 'no change'
    END AS trend
FROM industry_payroll_yearly_changes AS ipyc;

-- Zjisti odvětví ve kterých mzdy klesaly
SELECT * 
FROM payroll_trend_analysis AS pta
WHERE trend = 'decreased';

-- Zjisti odvětví ve kterých se mzdy v průběhu let nesnižovaly.
SELECT 
	industry, 
	industry_code 
FROM payroll_trend_analysis AS pta 
WHERE 
	trend = 'increased' 
	OR trend = 'no change' 
GROUP BY industry, industry_code
HAVING COUNT(*) = (SELECT COUNT(DISTINCT year) FROM payroll_trend_analysis);

-- Zjisti nejvyšší a nejnižší meziroční průměrný procentuální růst.
SELECT 
    industry,
    industry_code,
    ROUND(AVG(percent_change), 2) AS avg_growth
FROM payroll_trend_analysis AS pta
WHERE 
	year BETWEEN 2006 AND 2018 AND 
	percent_change NOT IN ('start_year', 'initial_payroll', 'no change')
GROUP BY industry, industry_code
ORDER BY avg_growth DESC 
LIMIT 1;

-- Zjisti odvětví s nějvětší % změnami ve sledovaním období
SELECT 
    industry,
    industry_code,
    ROUND(SUM(percent_change), 2) AS total_percent_change
FROM payroll_trend_analysis AS pta
WHERE 
	year BETWEEN 2006 AND 2018 AND
    percent_change NOT IN ('start_year', 'initial_payroll', 'no change')  -- vyloučení textových hodnot
GROUP BY industry, industry_code
ORDER BY total_percent_change DESC;

-- Celonárodní průměrná mzda.
SELECT 
	year, 
	ROUND(AVG(avg_payroll), 1) AS national_avg_payroll
FROM avg_industry_payroll_per_year
GROUP BY year;

-- Zjisti meziroční procentuální změnu.
SELECT *
FROM payroll_trend_analysis AS pta
WHERE percent_change > 5 OR percent_change < -5
ORDER BY `year`;

-- Zjisti mzdové trendy za určitý rok.
SELECT * 
FROM payroll_trend_analysis AS pta
WHERE year = 2008;

-- Zjisti v kolik letech mzdy rostly a v kterých odvětvých.
SELECT 
	industry, 
	industry_code, 
	COUNT(*) AS growth_years
FROM payroll_trend_analysis AS pta
WHERE trend = 'increased'
GROUP BY industry, industry_code
ORDER BY growth_years DESC;






