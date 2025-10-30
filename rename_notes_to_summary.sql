-- Migration: Rename 'notes' column to 'summary' in attendance table
-- Date: October 30, 2025
-- Description: Rename the notes column to summary for better clarity

-- Step 1: Rename the column from 'notes' to 'summary'
ALTER TABLE attendance 
RENAME COLUMN notes TO summary;

-- Step 2: Verify the change
-- Run this query to confirm the column has been renamed:
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'attendance' AND column_name = 'summary';

-- Note: This migration will not lose any data. All existing data in the 'notes' 
-- column will be preserved under the new 'summary' column name.
