/* 
Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem? 
*/

-- Pohled pro výpočet procentuálních změn HDP, mezd a cen potravin pro každý rok.
CREATE OR REPLACE VIEW v_rb_gdp_payroll_food_price_comparison AS
SELECT
    vrfpta.year,
    ROUND(AVG(vrfpta.percent_change), 2) AS avg_food_price_percent_change,  
    pcn.national_payroll_percent_change AS national_payroll_percent_change,  
    gdp.gdp_percent_change AS gdp_percent_change
FROM v_rb_food_price_trend_analysis AS vrfpta
JOIN v_rb_price_vs_payroll_comparison AS pcn
    ON vrfpta.year = pcn.year
JOIN (
    SELECT 
        e.year,
        e.gdp,
        ROUND(((e.gdp - LAG(e.gdp) OVER (PARTITION BY e.country ORDER BY e.year)) / 
        LAG(e.gdp) OVER (PARTITION BY e.country ORDER BY e.year)) * 100, 2) AS gdp_percent_change
    FROM economies AS e
    WHERE e.country = 'Czech Republic'
) AS gdp 
    ON vrfpta.year = gdp.year
GROUP BY vrfpta.year, pcn.national_payroll_percent_change, gdp.gdp_percent_change
ORDER BY vrfpta.year;

-- Zjisti a porovnej procentuálních změny HDP, mezd a cen potravin.
SELECT 
    year,
    gdp_percent_change,
    national_payroll_percent_change,
    avg_food_price_percent_change
FROM v_rb_gdp_payroll_food_price_comparison
ORDER BY year;

 -- Zjisti, zda růst HDP v předchozím roce ovlivnil růst mezd nebo cen potravin.
SELECT 
    year,
    gdp_percent_change,
    LAG(gdp_percent_change) OVER (ORDER BY year) AS prev_year_gdp_change,
    national_payroll_percent_change,
    LAG(national_payroll_percent_change) OVER (ORDER BY year) AS prev_year_payroll_change,
    avg_food_price_percent_change,
    LAG(avg_food_price_percent_change) OVER (ORDER BY year) AS prev_year_food_price_change
FROM v_rb_gdp_payroll_food_price_comparison
WHERE year > 2006 
ORDER BY year;

-- Zjisti koleraci mezi HDP a platy.
SELECT 
    SUM((gdp_percent_change - avg_gdp) * (national_payroll_percent_change - avg_payroll)) / 
    (SQRT(SUM(POWER(gdp_percent_change - avg_gdp, 2)) * SUM(POWER(national_payroll_percent_change - avg_payroll, 2)))) 
    AS gdp_payroll_corr
FROM v_rb_gdp_payroll_food_price_comparison
CROSS JOIN (
    SELECT 
        AVG(gdp_percent_change) AS avg_gdp,
        AVG(national_payroll_percent_change) AS avg_payroll
    FROM v_rb_gdp_payroll_food_price_comparison
) AS averages;

-- Zjisti koleraci mezi HDP a cenami potravin.
SELECT 
    SUM((gdp_percent_change - avg_gdp) * (avg_food_price_percent_change - avg_food_price)) / 
    (SQRT(SUM(POWER(gdp_percent_change - avg_gdp, 2)) * SUM(POWER(avg_food_price_percent_change - avg_food_price, 2)))) 
    AS gdp_food_price_corr
FROM v_rb_gdp_payroll_food_price_comparison
CROSS JOIN (
    SELECT 
        AVG(gdp_percent_change) AS avg_gdp,
        AVG(avg_food_price_percent_change) AS avg_food_price
    FROM v_rb_gdp_payroll_food_price_comparison
) AS averages;

-- Analýza, zda změny v HDP mají větší vliv na mzdy nebo ceny potravin
SELECT
    vrfpta.year,
    CASE
        WHEN gdp_percent_change > 5 THEN 'HDP vysoký růst'
        WHEN gdp_percent_change < -5 THEN 'HDP pokles'
        ELSE 'HDP stabilní'
    END AS gdp_category,
    ROUND(national_payroll_percent_change, 2) AS avg_payroll_change,
    ROUND(avg_food_price_percent_change, 2) AS avg_food_price_change
FROM v_rb_gdp_payroll_food_price_comparison AS vrfpta
ORDER BY vrfpta.year;
