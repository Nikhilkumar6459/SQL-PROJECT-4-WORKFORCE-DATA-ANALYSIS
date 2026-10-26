# SQL Project 4: Workforce Data Analysis

## Project Description

This project focuses on workforce data analysis using Microsoft SQL Server (T-SQL) to explore salary trends, job roles, experience levels, employment types, company locations, company sizes, and remote-work patterns.

The project uses SQL queries to build a repeatable analytical framework for salary benchmarking, workforce planning, recruitment, employee retention, and career exploration. It covers 20 analysis tasks, including salary comparisons across job titles and countries, year-over-year salary growth, remote-work adoption, employment-type distribution, and role-based data access.

The analysis is designed to help transform structured workforce data into meaningful insights that can support business and HR decision-making.

## Project Objectives

- Analyze average salaries by job title, experience level, and location.
- Compare salary trends across different years.
- Identify countries with higher salary benchmarks for specific experience levels.
- Examine full-time and part-time employment patterns.
- Analyze fully remote work trends across years and experience levels.
- Identify company locations with significant large-company representation.
- Calculate salary growth percentages by job title and experience level.
- Demonstrate role-based access control using SQL views.
- Explore salary benchmarks to support career and domain-switching decisions.

## Dataset Overview

The project uses the following workforce dataset fields:

- `work_year`
- `experience_level`
- `employment_type`
- `job_title`
- `salary`
- `salary_currency`
- `salary_in_usd`
- `employee_residence`
- `remote_ratio`
- `company_location`
- `company_size`

### Key Data Categories

- **Experience Level:** EN (Entry-level), MI (Mid-level), SE (Senior-level), EX (Executive-level)
- **Employment Type:** FT (Full-time), PT (Part-time)
- **Remote Work:** 0 (Fully in-office), 100 (Fully remote), intermediate values (Hybrid)
- **Company Size:** S (Small), M (Medium), L (Large)

## SQL Concepts and Techniques Used

- Data filtering using `WHERE`
- Aggregation using `COUNT`, `SUM`, and `AVG`
- Grouping and filtering using `GROUP BY` and `HAVING`
- Common Table Expressions (CTEs)
- Conditional aggregation using `CASE`
- Salary comparisons and percentage-growth calculations
- Joins and cross joins
- Ranking functions such as `DENSE_RANK`
- Year-over-year salary analysis
