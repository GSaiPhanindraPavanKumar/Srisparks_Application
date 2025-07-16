-- Create Test Users for Srisparks App
-- Run this script in your Supabase SQL Editor to create test users

-- First, let's check if we have any users
SELECT COUNT(*) as user_count FROM users;

-- ACTUAL USER PROFILES (Already created)
-- These users have been created in both Authentication and users table

-- Current authenticated user profile (for saiphanindra2004@gmail.com)
INSERT INTO users (id, email, full_name, role, office_id, status) VALUES
('4df6e08f-19f8-4b9d-a317-7c55952f6cfb', 'saiphanindra2004@gmail.com', 'System Administrator', 'director', '550e8400-e29b-41d4-a716-446655440000', 'active')
ON CONFLICT (id) DO NOTHING;

-- Director User Profile
INSERT INTO users (id, email, full_name, role, office_id, status) VALUES
('9d186cb9-2510-4da7-a411-1f9f561064df', 'director@srisparks.in', 'Director', 'director', '550e8400-e29b-41d4-a716-446655440000', 'active')
ON CONFLICT (id) DO NOTHING;

-- Manager User Profile
INSERT INTO users (id, email, full_name, role, office_id, reporting_to_id, status) VALUES
('5ce62644-820f-42c3-b1a5-26349fdca447', 'manager@srisparks.in', 'Manager', 'manager', '550e8400-e29b-41d4-a716-446655440000', '9d186cb9-2510-4da7-a411-1f9f561064df', 'active')
ON CONFLICT (id) DO NOTHING;

-- Employee User Profile
INSERT INTO users (id, email, full_name, role, office_id, reporting_to_id, status) VALUES
('ce596f6c-9ea0-4252-b840-2fe58f52f5ce', 'employee@srisparks.in', 'Employee', 'employee', '550e8400-e29b-41d4-a716-446655440000', '5ce62644-820f-42c3-b1a5-26349fdca447', 'active')
ON CONFLICT (id) DO NOTHING;

-- Lead User Profile (Employee with is_lead = true)
INSERT INTO users (id, email, full_name, role, office_id, reporting_to_id, is_lead, status) VALUES
('0ad2ebe6-00e9-483f-ad38-37d6de21f577', 'lead@srisparks.in', 'Lead', 'employee', '550e8400-e29b-41d4-a716-446655440000', '5ce62644-820f-42c3-b1a5-26349fdca447', true, 'active')
ON CONFLICT (id) DO NOTHING;

-- Check if office exists
SELECT * FROM offices WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- If office doesn't exist, create it
INSERT INTO offices (id, name, address, city, state, country) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'Main Office', '123 Business St', 'New York', 'NY', 'USA')
ON CONFLICT (id) DO NOTHING;

-- Check current users
SELECT id, email, full_name, role, is_lead, status FROM users;

-- Debug: Check if we have the authenticated user profile
SELECT id, email, full_name, role, is_lead, status 
FROM users 
WHERE id = '4df6e08f-19f8-4b9d-a317-7c55952f6cfb';

-- Debug: Check all users in users table
SELECT 'users_table' as source, id, email, full_name, role, is_lead, status FROM users
ORDER BY created_at DESC;
