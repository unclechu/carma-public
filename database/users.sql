CREATE ROLE carma_search PASSWORD 'pass' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
CREATE ROLE carma_db_sync PASSWORD 'pass' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
CREATE ROLE carma_action_assignment PASSWORD 'pass' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
CREATE ROLE carma_geo PASSWORD 'pass' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;

CREATE ROLE reportgen PASSWORD 'pass' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
CREATE ROLE analyst PASSWORD 'pass' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
