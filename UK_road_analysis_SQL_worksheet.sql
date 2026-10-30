CREATE DATABASE IF NOT EXISTS uk_road_safety_2025;

USE uk_road_safety_2025;

show databases;
select database();

Create table if not exists collisionn_import_tests (
	join_ref VARCHAR(20) not null primary key,
    collision_year int,
    collision_severity INT,
    number_of_vehicles INT,
    number_of_casualties int,
    speed_limit int
    );
    
-- Exporting the collision data from Python
-- display all column and all row 

Select *
from collisionn_import_tests;

-- display all column and all row 
SELECT COUNT(*) AS total_collisions
FROM collisionn_import_tests;

-- exploring the data that we just now imported

-- diaplay the total number of rows as per severity
SELECT
    collision_severity,
    COUNT(*) AS collision_count
FROM collisionn_import_tests
GROUP BY collision_severity
ORDER BY collision_severity;

-- View the first 10 records
SELECT *
FROM collisionn_import_tests
LIMIT 10;

-- Count all rows
SELECT COUNT(*)
FROM collisionn_import_tests;

-- Display specific columns
SELECT
    join_ref,
    collision_severity,
    speed_limit
FROM collisionn_import_tests
LIMIT 10;

-- Validation 
USE uk_road_safety_2025;

SELECT 'Collisions' AS dataset, COUNT(*) AS records
FROM collisions_2025

UNION ALL

SELECT 'Vehicles', COUNT(*)
FROM vehicles_2025

UNION ALL

SELECT 'Casualties', COUNT(*)
FROM casualties_2025;

-- Analytical Queries

USE uk_road_safety_2025;

SELECT
    speed_limit,
    COUNT(*) AS total_collisions,
    SUM(
        CASE
            WHEN collision_severity IN (1, 2)
            THEN 1
            ELSE 0
        END
    ) AS ksi_collisions,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN collision_severity IN (1, 2)
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS ksi_percentage
FROM collisions_2025
GROUP BY speed_limit
ORDER BY speed_limit;

-- Joining Multiple Tables

-- (a) vehicles by collision severity
SELECT
    c.collision_severity,
    COUNT(v.vehicle_reference) AS total_vehicles
FROM collisions_2025 AS c
INNER JOIN vehicles_2025 AS v
    ON c.join_ref = v.join_ref
GROUP BY c.collision_severity
ORDER BY c.collision_severity;

-- (b) casualties by collision severity
SELECT
    c.collision_severity,
    COUNT(ca.casualty_reference) AS total_casualty
FROM collisions_2025 AS c
INNER JOIN casualties_2025 AS ca
    ON c.join_ref = ca.join_ref
GROUP BY c.collision_severity
ORDER BY c.collision_severity;

-- CTEs AND Window Functions

WITH road_class_summary AS (
    SELECT
        first_road_class,
        COUNT(*) AS total_collisions,
        SUM(
            CASE
                WHEN collision_severity IN (1, 2)
                THEN 1
                ELSE 0
            END
        ) AS ksi_collisions
    FROM collisions_2025
    GROUP BY first_road_class
)

SELECT
    first_road_class,
    total_collisions,
    ksi_collisions,
    ROUND(
        100.0 * ksi_collisions
        / NULLIF(total_collisions, 0),
        2
    ) AS ksi_percentage
FROM road_class_summary
ORDER BY ksi_percentage DESC;

-- with window function
WITH road_class_summary AS (
    SELECT
        first_road_class,
        COUNT(*) AS total_collisions,
        SUM(
            CASE
                WHEN collision_severity IN (1, 2)
                THEN 1
                ELSE 0
            END
        ) AS ksi_collisions
    FROM collisions_2025
    GROUP BY first_road_class
),

road_class_percentage AS (
    SELECT
        first_road_class,
        total_collisions,
        ksi_collisions,
        ROUND(
            100.0 * ksi_collisions /
            NULLIF(total_collisions, 0),
            2
        ) AS ksi_percentage
    FROM road_class_summary
)

SELECT
    first_road_class,
    total_collisions,
    ksi_collisions,
    ksi_percentage,

    RANK() OVER (
        ORDER BY ksi_percentage DESC
    ) AS ksi_rank,

    DENSE_RANK() OVER (
        ORDER BY ksi_percentage DESC
    ) AS dense_ksi_rank,

    ROW_NUMBER() OVER (
        ORDER BY ksi_percentage DESC, first_road_class
    ) AS row_number_rank

FROM road_class_percentage
ORDER BY ksi_percentage DESC, first_road_class;

-- — Creating Reporting Views

-- (i) Create a speed-limit reporting view
USE uk_road_safety_2025;

CREATE OR REPLACE VIEW vw_speed_limit_analysis AS
SELECT
    speed_limit,
    COUNT(*) AS total_collisions,
    SUM(
        CASE
            WHEN collision_severity IN (1, 2) THEN 1
            ELSE 0
        END
    ) AS ksi_collisions,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN collision_severity IN (1, 2) THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS ksi_percentage
FROM collisions_2025
GROUP BY speed_limit;

-- Testing it 
SELECT *
FROM vw_speed_limit_analysis
ORDER BY speed_limit;

-- (ii) Create a collision severity view
CREATE OR REPLACE VIEW vw_collision_severity AS
SELECT
    collision_severity,
    CASE collision_severity
        WHEN 1 THEN 'Fatal'
        WHEN 2 THEN 'Serious'
        WHEN 3 THEN 'Slight'
        ELSE 'Unknown'
    END AS severity_label,
    COUNT(*) AS total_collisions
FROM collisions_2025
GROUP BY collision_severity;

-- Testing it 
SELECT *
FROM vw_collision_severity
ORDER BY collision_severity;



    
