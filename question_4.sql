-- Pohled na propojení procentuálního růstu mezd a procentuálního růstu cen potravin.
CREATE OR REPLACE VIEW yearly_price_vs_payroll_trend AS
SELECT 
	pta.`year`,
	pta.food_category_code,
	pta.food_name,
	pta.avg_food_price,
	pta.percent_change AS food_percent_change,
	pta.trend AS food_price_trend,
	pta2.industry_code,
	pta2.industry,
	pta2.avg_payroll,
	pta2.percent_change AS payroll_percent_change,
	pta2.trend AS payroll_trend
FROM price_trend_analysis AS pta 
JOIN payroll_trend_analysis AS pta2
	ON pta.`year` = pta2.`year`;  

-- Pohled na meziroční procentuální růst průměrné mzdy v ČR.
CREATE OR REPLACE VIEW national_payroll_yearly_change AS
SELECT 
    year,
    avg_national_payroll,
    ROUND(
        ((avg_national_payroll - LAG(avg_national_payroll) OVER (ORDER BY year)) / LAG(avg_national_payroll) 
        OVER (ORDER BY year)) * 100, 1
    ) AS national_payroll_percent_change
FROM avg_national_payroll_per_year AS anppy
ORDER BY year;

-- Pohled průměrný meziroční procentuální růst cen potravin v ČR.
CREATE OR REPLACE VIEW avg_yearly_food_price_trend AS
SELECT 
    year,
    ROUND(AVG(food_price), 2) AS avg_food_price,
    LAG(ROUND(AVG(food_price), 2)) OVER(ORDER BY year) AS prev_year_price,
    CASE 
        WHEN LAG(ROUND(AVG(food_price), 2)) OVER(ORDER BY year) IS NULL THEN NULL
        ELSE ROUND(((ROUND(AVG(food_price), 2) - LAG(ROUND(AVG(food_price), 2)) OVER(ORDER BY year)) 
                    / LAG(ROUND(AVG(food_price), 2)) OVER(ORDER BY year)) * 100, 1)
    END AS food_percent_change
FROM t_romana_belohoubkova_project_sql_primary_final AS trbpspf 
GROUP BY year;

-- Pohled na porovnání meziroční změny cen potravin a růstu průměrné mzdy, s označením, zda růst cen potravin překročil růst mezd.
CREATE OR REPLACE VIEW price_vs_payroll_comparison AS
SELECT 
    pta.year,
    pta.food_category_code,
    pta.food_name,
    pta.percent_change AS food_price_percent_change,
    npyc.national_payroll_percent_change,
    CASE
        WHEN pta.percent_change > npyc.national_payroll_percent_change THEN 1
        ELSE 0
    END AS food_price_increase_above_payroll
FROM price_trend_analysis AS pta
JOIN national_payroll_yearly_change AS npyc
    ON pta.year = npyc.year
ORDER BY pta.year, pta.food_category_code;

-- Zjisti, kdy byl růst cen větší alespoň o 10% oproti průměrné mzdě.
SELECT 
    year,
	food_name,
    food_price_percent_change,
    national_payroll_percent_change,
    food_price_increase_above_payroll
FROM price_vs_payroll_comparison AS pvpc
WHERE food_price_percent_change > national_payroll_percent_change + 10
ORDER BY year, food_category_code;

-- Zjisti, kolik let a u kterých potravin byl nejčastěji rozdíl mezi zvýšením ceny potravin a zvýšením průměrné mzdy alespoň o 10%.
SELECT
    food_name,
    COUNT(year) AS years_with_price_above_payroll
FROM price_vs_payroll_comparison AS pta
WHERE food_price_percent_change > national_payroll_percent_change + 10
GROUP BY food_name
ORDER BY years_with_price_above_payroll DESC
LIMIT 5;

-- Zjisti, kdy a u kterých potravin byl největší rozdíl mezi zvýšením ceny potravin a zvýšením průměrné mzdy.
SELECT 
    year,
    food_name,
    food_price_percent_change,
    national_payroll_percent_change,
    (food_price_percent_change - national_payroll_percent_change) AS price_vs_payroll_percent_diff
FROM price_vs_payroll_comparison AS pvpc
WHERE food_price_percent_change > national_payroll_percent_change + 10
ORDER BY price_vs_payroll_percent_diff DESC
LIMIT 5;

-- Zjisti o kolik procent se ve sledovaných letech zvedala průměrná cena všech potravin oproti zvedání průměrné mzdy.
SELECT 
    afpt.year,
    ROUND(AVG(pta.percent_change), 1) AS avg_food_price_percent_change, 
    ROUND(AVG(npyc.national_payroll_percent_change), 1) AS avg_national_payroll_percent_change, 
    ROUND(AVG(npyc.national_payroll_percent_change) - AVG(pta.percent_change), 1) AS percent 
FROM avg_yearly_food_price_trend AS afpt
JOIN price_trend_analysis AS pta 
    ON afpt.year = pta.year
JOIN national_payroll_yearly_change AS npyc 
    ON afpt.year = npyc.year
GROUP BY afpt.year
ORDER BY afpt.YEAR;


