-- Vytvoření pohledu pro průměrné mzdy v jednotlivých letech a odvětvích
CREATE OR REPLACE VIEW avg_industry_payroll_per_year AS
SELECT 
    year,
    industry,
    industry_code,
    ROUND(AVG(payroll), 1) AS avg_payroll
FROM t_romana_belohoubkova_project_SQL_primary_final
GROUP BY year, industry, industry_code;

-- Pohled pro přidání předchozích mezd pomocí LAG
CREATE OR REPLACE VIEW industry_payroll_yearly_changes AS
SELECT 
    year,
    industry,
    industry_code,
    avg_payroll,
    LAG(avg_payroll) OVER(PARTITION BY industry_code ORDER BY year) AS prev_year_payroll
FROM avg_industry_payroll_per_year;

-- Pohled pro výpočet procentuální změny a označení trendu
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

-- Ukázkový dotaz pro zobrazení výsledků
SELECT *
FROM payroll_trend_analysis AS pta 
WHERE industry_code = 'A'
ORDER BY `year` asc;