-- Initialize Rinoimob database
-- This script creates the base schema structure

CREATE SCHEMA IF NOT EXISTS public;

-- Grant privileges to postgres user
GRANT ALL PRIVILEGES ON SCHEMA public TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;

COMMENT ON SCHEMA public IS 'Standard public schema for Rinoimob application';
