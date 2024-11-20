-- Pohled na propojení procentuálního růstu mezd a procentuálního růstu cen potravin.

-- Pohled pro meziroční procentuální růst průměrné mzdy v ČR
CREATE OR REPLACE VIEW national_payroll_yearly_change AS
SELECT 
    year,
    national_avg_payroll,
    ROUND(((national_avg_payroll - LAG(national_avg_payroll) OVER (ORDER BY year)) 
        / LAG(national_avg_payroll) OVER (ORDER BY year)) * 100, 2) AS national_payroll_percent_change
FROM payroll_trend_analysis AS pta
GROUP BY year
ORDER BY year;

-- Pohled pro propojení mezi růstu mezd a růstu cen potravin.
CREATE OR REPLACE VIEW  AS
SELECT 
    fpta.year,
    fpta.food_category_code,
    fpta.food_name,
    ROUND(AVG(fpta.avg_food_price), 2) AS avg_food_price,
    ROUND(AVG(fpta.percent_change), 2) AS food_price_percent_change,
    ROUND(npyr.national_payroll_percent_change, 2) AS national_payroll_percent_change,
    CASE
        WHEN AVG(fpta.percent_change) > npyr.national_payroll_percent_change THEN 1
        ELSE 0
    END AS food_price_increase_above_payroll
FROM food_price_trend_analysis AS fpta
JOIN national_payroll_yearly_change AS npyr
    ON fpta.year = npyr.year
GROUP BY fpta.year, fpta.food_category_code, fpta.food_name
ORDER BY fpta.year, fpta.food_category_code;

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
    pta.year,
    ROUND(AVG(pta.percent_change), 2) AS avg_food_price_percent_change, 
    ROUND(npyc.national_payroll_percent_change, 2) AS avg_national_payroll_percent_change, 
    ROUND(AVG(pta.percent_change) - npyc.national_payroll_percent_change, 2) AS percent_difference
FROM food_price_trend_analysis AS pta
JOIN national_payroll_yearly_change AS npyc 
    ON pta.year = npyc.year
GROUP BY pta.year, npyc.national_payroll_percent_change
ORDER BY pta.year;


