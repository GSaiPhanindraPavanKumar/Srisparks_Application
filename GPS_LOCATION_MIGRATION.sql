-- GPS Location Enhancement Migration
-- This migration adds GPS coordinates to customers and work tables
-- for the location verification feature

-- ========================================
-- 1. Add GPS coordinates to customers table
-- ========================================

-- Add latitude and longitude columns to customers table
ALTER TABLE customers 
ADD COLUMN latitude DECIMAL(10,8),
ADD COLUMN longitude DECIMAL(11,8);

-- Add comment for clarity
COMMENT ON COLUMN customers.latitude IS 'Customer location latitude for GPS verification';
COMMENT ON COLUMN customers.longitude IS 'Customer location longitude for GPS verification';

-- ========================================
-- 2. Add location tracking to work table
-- ========================================

-- Add location tracking columns to work table
ALTER TABLE work 
ADD COLUMN start_location_latitude DECIMAL(10,8),
ADD COLUMN start_location_longitude DECIMAL(11,8),
ADD COLUMN complete_location_latitude DECIMAL(10,8),
ADD COLUMN complete_location_longitude DECIMAL(11,8),
ADD COLUMN completion_response TEXT;

-- Add comments for clarity
COMMENT ON COLUMN work.start_location_latitude IS 'Employee GPS latitude when work was started';
COMMENT ON COLUMN work.start_location_longitude IS 'Employee GPS longitude when work was started';
COMMENT ON COLUMN work.complete_location_latitude IS 'Employee GPS latitude when work was completed';
COMMENT ON COLUMN work.complete_location_longitude IS 'Employee GPS longitude when work was completed';
COMMENT ON COLUMN work.completion_response IS 'Employee written response describing completed work';

-- ========================================
-- 3. Add indexes for performance
-- ========================================

-- Add indexes for location-based queries
CREATE INDEX idx_customers_location ON customers(latitude, longitude);
CREATE INDEX idx_work_start_location ON work(start_location_latitude, start_location_longitude);
CREATE INDEX idx_work_complete_location ON work(complete_location_latitude, complete_location_longitude);

-- ========================================
-- 4. Sample data insertion
-- ========================================

-- Example: Add customer1 with the provided GPS coordinates
-- First, get an existing office_id (replace with actual office_id)
-- You can find office_id by running: SELECT id FROM offices LIMIT 1;

-- Insert customer1 with GPS coordinates (16.746794, 81.7022911)
INSERT INTO customers (
    name, 
    email, 
    phone_number, 
    address, 
    city, 
    state, 
    country, 
    company_name, 
    latitude, 
    longitude, 
    office_id, 
    is_active
) VALUES (
    'Customer 1',
    'customer1@example.com',
    '+91-1234567890',
    'Sample Address, Street 1',
    'Sample City',
    'Sample State',
    'India',
    'Customer 1 Company',
    16.746794,
    81.7022911,
    '550e8400-e29b-41d4-a716-446655440000', -- Replace with actual office_id
    true
);

-- ========================================
-- 5. Utility functions for location
-- ========================================

-- Function to calculate distance between two GPS coordinates (in meters)
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 DECIMAL(10,8),
    lon1 DECIMAL(11,8),
    lat2 DECIMAL(10,8),
    lon2 DECIMAL(11,8)
) RETURNS DECIMAL(10,2) AS $$
DECLARE
    R DECIMAL := 6371000; -- Earth's radius in meters
    phi1 DECIMAL;
    phi2 DECIMAL;
    delta_phi DECIMAL;
    delta_lambda DECIMAL;
    a DECIMAL;
    c DECIMAL;
    distance DECIMAL;
BEGIN
    -- Convert degrees to radians
    phi1 := radians(lat1);
    phi2 := radians(lat2);
    delta_phi := radians(lat2 - lat1);
    delta_lambda := radians(lon2 - lon1);
    
    -- Haversine formula
    a := sin(delta_phi/2) * sin(delta_phi/2) + 
         cos(phi1) * cos(phi2) * sin(delta_lambda/2) * sin(delta_lambda/2);
    c := 2 * atan2(sqrt(a), sqrt(1-a));
    distance := R * c;
    
    RETURN distance;
END;
$$ LANGUAGE plpgsql;

-- Function to check if work location is valid (within 50 meters of customer)
CREATE OR REPLACE FUNCTION is_work_location_valid(
    customer_lat DECIMAL(10,8),
    customer_lon DECIMAL(11,8),
    work_lat DECIMAL(10,8),
    work_lon DECIMAL(11,8),
    max_distance_meters DECIMAL DEFAULT 50
) RETURNS BOOLEAN AS $$
DECLARE
    distance DECIMAL;
BEGIN
    -- If customer has no location, always valid
    IF customer_lat IS NULL OR customer_lon IS NULL THEN
        RETURN TRUE;
    END IF;
    
    -- If work location is missing, invalid
    IF work_lat IS NULL OR work_lon IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Calculate distance and check if within limit
    distance := calculate_distance(customer_lat, customer_lon, work_lat, work_lon);
    RETURN distance <= max_distance_meters;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 6. Sample queries for testing
-- ========================================

-- Query to find customers with GPS coordinates
SELECT 
    name,
    latitude,
    longitude,
    CASE 
        WHEN latitude IS NOT NULL AND longitude IS NOT NULL 
        THEN 'GPS Enabled'
        ELSE 'No GPS'
    END AS gps_status
FROM customers
ORDER BY name;

-- Query to find work with location verification
SELECT 
    w.title,
    c.name AS customer_name,
    c.latitude AS customer_lat,
    c.longitude AS customer_lon,
    w.start_location_latitude,
    w.start_location_longitude,
    w.complete_location_latitude,
    w.complete_location_longitude,
    CASE 
        WHEN w.start_location_latitude IS NOT NULL 
        THEN calculate_distance(c.latitude, c.longitude, w.start_location_latitude, w.start_location_longitude)
        ELSE NULL
    END AS start_distance_meters,
    CASE 
        WHEN w.complete_location_latitude IS NOT NULL 
        THEN calculate_distance(c.latitude, c.longitude, w.complete_location_latitude, w.complete_location_longitude)
        ELSE NULL
    END AS complete_distance_meters
FROM work w
JOIN customers c ON w.customer_id = c.id
WHERE w.status IN ('completed', 'verified')
ORDER BY w.created_at DESC;

-- Query to find work that was completed outside the 50-meter radius
SELECT 
    w.title,
    c.name AS customer_name,
    calculate_distance(c.latitude, c.longitude, w.complete_location_latitude, w.complete_location_longitude) AS distance_meters
FROM work w
JOIN customers c ON w.customer_id = c.id
WHERE w.complete_location_latitude IS NOT NULL
AND c.latitude IS NOT NULL
AND calculate_distance(c.latitude, c.longitude, w.complete_location_latitude, w.complete_location_longitude) > 50
ORDER BY distance_meters DESC;

-- ========================================
-- 7. Commands to execute in Supabase
-- ========================================

/*
To implement this in your Supabase project:

1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Run the migration SQL above (sections 1-3)
4. Update the office_id in the INSERT statement (section 4) with your actual office_id
5. Run the customer insertion query
6. Optionally, run the utility functions (section 5) for advanced location queries

To find your office_id:
SELECT id, name FROM offices;

To verify the customer was inserted:
SELECT name, latitude, longitude FROM customers WHERE name = 'Customer 1';
*/
