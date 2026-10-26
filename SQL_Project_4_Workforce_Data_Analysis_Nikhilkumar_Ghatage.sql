/*
PROJECT 4: WORKFORCE DATA ANALYSIS
Prepared for: Nikhilkumar Ghatage
Platform: Microsoft SQL Server (T-SQL)
Source: CoachX Project-4 Workforce Income Analysis PDF (34 pages)

IMPORTANT:
- The PDF explains the dataset columns and 20 analysis tasks, but does not provide the complete underlying dataset.
- Queries below assume a table named dbo.WorkforceData with the columns listed in the PDF.
- Run read-only analysis queries after loading the real dataset.
- UPDATE statements are wrapped in transactions and rolled back by default.
*/

IF DB_ID(N'WorkforceAnalysisDB') IS NULL CREATE DATABASE WorkforceAnalysisDB;
GO
USE WorkforceAnalysisDB;
GO

-- Expected dataset columns based on pages 11-12 of the assignment:
-- work_year, experience_level, employment_type, job_title, salary,
-- salary_currency, salary_in_usd, employee_residence, remote_ratio,
-- company_location, company_size

-- Create table if it does not already exist. Load the full dataset after creating it.
IF OBJECT_ID(N'dbo.WorkforceData', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.WorkforceData (
        work_year INT NOT NULL,
        experience_level VARCHAR(10) NULL,
        employment_type VARCHAR(10) NULL,
        job_title NVARCHAR(150) NOT NULL,
        salary DECIMAL(18,2) NULL,
        salary_currency VARCHAR(10) NULL,
        salary_in_usd DECIMAL(18,2) NULL,
        employee_residence VARCHAR(10) NULL,
        remote_ratio INT NULL,
        company_location VARCHAR(10) NULL,
        company_size CHAR(1) NULL
    );
END;
GO

-- Optional quality checks after importing the dataset
SELECT COUNT(*) AS TotalRecords FROM dbo.WorkforceData;
SELECT TOP (10) * FROM dbo.WorkforceData;
SELECT work_year, COUNT(*) AS RecordCount
FROM dbo.WorkforceData GROUP BY work_year ORDER BY work_year;
SELECT experience_level, COUNT(*) AS RecordCount
FROM dbo.WorkforceData GROUP BY experience_level ORDER BY experience_level;

-- Q1. Number of employees in companies of each size in 2021.
SELECT company_size, COUNT(*) AS employee_count
FROM dbo.WorkforceData
WHERE work_year = 2021
GROUP BY company_size
ORDER BY company_size;

-- Q2. Top 3 job titles by average salary for part-time positions in 2023,
-- requiring more than 50 records per job title.
SELECT TOP (3) job_title, AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS avg_salary_usd,
       COUNT(*) AS employee_count
FROM dbo.WorkforceData
WHERE employment_type = 'PT' AND work_year = 2023
GROUP BY job_title
HAVING COUNT(*) > 50
ORDER BY AVG(CAST(salary_in_usd AS DECIMAL(18,2))) DESC;

-- Q3. Countries whose mid-level (MI) average salary in 2023 exceeds the
-- overall mid-level average for 2023. Uses employee_residence as country.
WITH MidLevel AS (
    SELECT employee_residence, AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS country_avg
    FROM dbo.WorkforceData
    WHERE experience_level = 'MI' AND work_year = 2023
    GROUP BY employee_residence
),
OverallMid AS (
    SELECT AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS overall_avg
    FROM dbo.WorkforceData
    WHERE experience_level = 'MI' AND work_year = 2023
)
SELECT m.employee_residence, m.country_avg, o.overall_avg
FROM MidLevel m CROSS JOIN OverallMid o
WHERE m.country_avg > o.overall_avg
ORDER BY m.country_avg DESC;

-- Q4. Highest and lowest average salary locations for senior-level employees in 2023.
WITH CountryAvg AS (
    SELECT company_location, AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS avg_salary
    FROM dbo.WorkforceData
    WHERE experience_level = 'SE' AND work_year = 2023
    GROUP BY company_location
)
SELECT 'Highest' AS salary_band, company_location, avg_salary
FROM CountryAvg WHERE avg_salary = (SELECT MAX(avg_salary) FROM CountryAvg)
UNION ALL
SELECT 'Lowest', company_location, avg_salary
FROM CountryAvg WHERE avg_salary = (SELECT MIN(avg_salary) FROM CountryAvg);

-- Q5. Salary growth by job title between 2023 and 2024.
WITH Yearly AS (
    SELECT job_title, work_year, AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS avg_salary
    FROM dbo.WorkforceData
    WHERE work_year IN (2023, 2024)
    GROUP BY job_title, work_year
),
Pivoted AS (
    SELECT job_title,
           MAX(CASE WHEN work_year=2023 THEN avg_salary END) AS avg_2023,
           MAX(CASE WHEN work_year=2024 THEN avg_salary END) AS avg_2024
    FROM Yearly GROUP BY job_title
)
SELECT job_title, avg_2023, avg_2024,
       CASE WHEN avg_2023 IS NULL OR avg_2023=0 OR avg_2024 IS NULL THEN NULL
            ELSE 100.0*(avg_2024-avg_2023)/avg_2023 END AS growth_pct
FROM Pivoted
WHERE avg_2023 IS NOT NULL AND avg_2024 IS NOT NULL
ORDER BY growth_pct DESC;

-- Q6. Top 3 countries by entry-level (EN) salary growth from 2020 to 2023,
-- requiring more than 50 records in the 2020-2023 subset.
WITH CountryYear AS (
    SELECT employee_residence, work_year,
           AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS avg_salary,
           COUNT(*) AS n
    FROM dbo.WorkforceData
    WHERE experience_level='EN' AND work_year IN (2020,2023)
    GROUP BY employee_residence, work_year
),
Growth AS (
    SELECT a.employee_residence, a.avg_salary AS salary_2020,
           b.avg_salary AS salary_2023,
           100.0*(b.avg_salary-a.avg_salary)/NULLIF(a.avg_salary,0) AS growth_pct
    FROM CountryYear a
    JOIN CountryYear b ON a.employee_residence=b.employee_residence
    WHERE a.work_year=2020 AND b.work_year=2023
      AND a.n > 50 AND b.n > 50
)
SELECT TOP (3) * FROM Growth ORDER BY growth_pct DESC;

-- Q7. Preview and safely demonstrate setting remote_ratio=100 for US/AU residents
-- earning > $90,000. ROLLBACK prevents persistent changes until reviewed.
BEGIN TRANSACTION;
UPDATE dbo.WorkforceData
SET remote_ratio=100
WHERE salary_in_usd > 90000 AND employee_residence IN ('US','AU');
SELECT @@ROWCOUNT AS RowsUpdated;
ROLLBACK TRANSACTION;
-- Replace ROLLBACK with COMMIT only if the change is approved.

-- Q8. Example 2024 salary increases by experience level.
-- Assumed rates because the PDF says "e.g. SE=22%, MI=30%, etc." but does not
-- specify all percentages. Change rates to the values confirmed by your instructor.
BEGIN TRANSACTION;
UPDATE dbo.WorkforceData
SET salary = salary * (1 + CASE experience_level
                              WHEN 'SE' THEN 0.22
                              WHEN 'MI' THEN 0.30
                              WHEN 'EN' THEN 0.15
                              WHEN 'EX' THEN 0.25
                              ELSE 0.00 END),
    salary_in_usd = salary_in_usd * (1 + CASE experience_level
                              WHEN 'SE' THEN 0.22
                              WHEN 'MI' THEN 0.30
                              WHEN 'EN' THEN 0.15
                              WHEN 'EX' THEN 0.25
                              ELSE 0.00 END)
WHERE work_year=2024;
SELECT @@ROWCOUNT AS RowsUpdated;
ROLLBACK TRANSACTION;
-- Do not commit until percentage assumptions and currency handling are confirmed.

-- Q9. Year with highest average salary for each job title.
WITH Yearly AS (
    SELECT job_title, work_year, AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS avg_salary
    FROM dbo.WorkforceData GROUP BY job_title, work_year
),
Ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY job_title ORDER BY avg_salary DESC) AS rnk
    FROM Yearly
)
SELECT job_title, work_year, avg_salary
FROM Ranked WHERE rnk=1 ORDER BY job_title;

-- Q10. Full-time vs part-time percentage for each job title.
SELECT job_title,
       100.0*SUM(CASE WHEN employment_type='FT' THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS full_time_pct,
       100.0*SUM(CASE WHEN employment_type='PT' THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS part_time_pct,
       COUNT(*) AS total_records
FROM dbo.WorkforceData
GROUP BY job_title ORDER BY job_title;

-- Q11. Countries of managers earning > $90,000 and fully remote.
SELECT DISTINCT employee_residence
FROM dbo.WorkforceData
WHERE job_title LIKE '%Manager%'
  AND salary_in_usd > 90000
  AND remote_ratio = 100
ORDER BY employee_residence;

-- Q12. Top 5 company locations with the most large-company records.
SELECT TOP (5) company_location, COUNT(*) AS large_company_records
FROM dbo.WorkforceData
WHERE company_size='L'
GROUP BY company_location
ORDER BY COUNT(*) DESC;

-- Q13. Percentage of all employees who are fully remote and earn > $100,000.
SELECT 100.0*SUM(CASE WHEN remote_ratio=100 AND salary_in_usd>100000 THEN 1 ELSE 0 END)
       / NULLIF(COUNT(*),0) AS pct_fully_remote_earning_over_100k,
       COUNT(*) AS total_records
FROM dbo.WorkforceData;

-- Q14. Locations where entry-level (EN) average salary exceeds global EN average.
WITH LocationAvg AS (
    SELECT employee_residence, AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS location_avg
    FROM dbo.WorkforceData WHERE experience_level='EN'
    GROUP BY employee_residence
),
GlobalAvg AS (
    SELECT AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS global_avg
    FROM dbo.WorkforceData WHERE experience_level='EN'
)
SELECT l.employee_residence, l.location_avg, g.global_avg
FROM LocationAvg l CROSS JOIN GlobalAvg g
WHERE l.location_avg > g.global_avg
ORDER BY l.location_avg DESC;

-- Q15. Country with highest average salary for each job title.
-- Uses employee_residence, consistent with the wording "country" in the task.
WITH JobCountry AS (
    SELECT job_title, employee_residence,
           AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS avg_salary
    FROM dbo.WorkforceData GROUP BY job_title, employee_residence
),
Ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY job_title ORDER BY avg_salary DESC) AS rnk
    FROM JobCountry
)
SELECT job_title, employee_residence, avg_salary
FROM Ranked WHERE rnk=1 ORDER BY job_title;

-- Q16. Countries with sustained salary growth over three years (2021-2023).
WITH Yearly AS (
    SELECT employee_residence, work_year,
           AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS avg_salary
    FROM dbo.WorkforceData
    WHERE work_year IN (2021,2022,2023)
    GROUP BY employee_residence, work_year
),
CountryTrend AS (
    SELECT employee_residence,
           MAX(CASE WHEN work_year=2021 THEN avg_salary END) AS avg_2021,
           MAX(CASE WHEN work_year=2022 THEN avg_salary END) AS avg_2022,
           MAX(CASE WHEN work_year=2023 THEN avg_salary END) AS avg_2023
    FROM Yearly GROUP BY employee_residence
)
SELECT * FROM CountryTrend
WHERE avg_2021 IS NOT NULL AND avg_2022 IS NOT NULL AND avg_2023 IS NOT NULL
  AND avg_2021 < avg_2022 AND avg_2022 < avg_2023
ORDER BY employee_residence;

-- Q17. Percentage of fully remote employees by experience level, 2021 vs 2024.
SELECT experience_level,
       100.0*SUM(CASE WHEN work_year=2021 AND remote_ratio=100 THEN 1 ELSE 0 END)
          / NULLIF(SUM(CASE WHEN work_year=2021 THEN 1 ELSE 0 END),0) AS remote_pct_2021,
       100.0*SUM(CASE WHEN work_year=2024 AND remote_ratio=100 THEN 1 ELSE 0 END)
          / NULLIF(SUM(CASE WHEN work_year=2024 THEN 1 ELSE 0 END),0) AS remote_pct_2024
FROM dbo.WorkforceData
WHERE work_year IN (2021,2024)
GROUP BY experience_level ORDER BY experience_level;

-- Q18. Average salary increase percentage by experience level and job title (2023 to 2024).
WITH Yearly AS (
    SELECT experience_level, job_title, work_year,
           AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS avg_salary
    FROM dbo.WorkforceData WHERE work_year IN (2023,2024)
    GROUP BY experience_level, job_title, work_year
),
Pivoted AS (
    SELECT experience_level, job_title,
           MAX(CASE WHEN work_year=2023 THEN avg_salary END) AS avg_2023,
           MAX(CASE WHEN work_year=2024 THEN avg_salary END) AS avg_2024
    FROM Yearly GROUP BY experience_level, job_title
)
SELECT experience_level, job_title, avg_2023, avg_2024,
       100.0*(avg_2024-avg_2023)/NULLIF(avg_2023,0) AS increase_pct
FROM Pivoted
WHERE avg_2023 IS NOT NULL AND avg_2024 IS NOT NULL
ORDER BY experience_level, job_title;

-- Q19. Role-based access control demonstration by experience level.
-- Example: create a view for senior-level rows. Restrict database permissions separately.
CREATE OR ALTER VIEW dbo.SeniorWorkforceView AS
SELECT work_year, experience_level, employment_type, job_title, salary_in_usd,
       employee_residence, remote_ratio, company_location, company_size
FROM dbo.WorkforceData
WHERE experience_level='SE';
GO
-- Example permission statement (run only after creating a database user/role):
-- GRANT SELECT ON dbo.SeniorWorkforceView TO [SeniorAnalystRole];

-- Q20. Career/domain-switching insight framework.
-- SQL provides salary benchmarks by title and experience; recommendations need a client's
-- current role, skills, location and interests. This query returns benchmark alternatives
-- by experience level and employee residence rather than inventing a personal recommendation.
SELECT experience_level, employee_residence, job_title,
       AVG(CAST(salary_in_usd AS DECIMAL(18,2))) AS avg_salary_usd,
       COUNT(*) AS records
FROM dbo.WorkforceData
GROUP BY experience_level, employee_residence, job_title
HAVING COUNT(*) >= 5
ORDER BY experience_level, employee_residence, avg_salary_usd DESC;
