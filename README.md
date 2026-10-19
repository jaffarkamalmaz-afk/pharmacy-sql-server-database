# pharmacy-sql-server-database

Advanced SQL Programming assignment (SVU, BAIT): a relational database for "Sihhatak" pharmacy and medical supplies company, built on Microsoft SQL Server (T-SQL).

## Contents
- `SihhatakDB_solution.sql`: database creation, tables, constraints, indexes, sample data, and five queries.

## Schema
Customers, Categories, Products, Orders, OrderDetails (see the ERD in the assignment).

## Concepts covered
- Data and log file configuration
- Primary keys, foreign keys, CHECK, DEFAULT, UNIQUE constraints
- Computed column (`LineTotal`)
- Non-clustered indexes on join columns
- JOIN, LEFT JOIN, GROUP BY / HAVING, subqueries

## Run
Create `C:\SQLData` (or edit the paths), then run the script in SQL Server Management Studio.
