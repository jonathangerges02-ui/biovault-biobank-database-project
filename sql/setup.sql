-- One-command setup for psql.
\set ON_ERROR_STOP on
\ir create_tables.sql
\ir triggers_procedures.sql
\ir load_data.sql
\ir views.sql

SELECT 'BioVault setup completed successfully.' AS status;
