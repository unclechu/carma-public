CREATE TABLE "CheckType"
  ( id    SERIAL PRIMARY KEY
  , label text UNIQUE NOT NULL
  , synonyms text[]
  );

GRANT ALL ON "CheckType" TO carma_db_sync;
GRANT ALL ON "CheckType_id_seq" TO carma_db_sync;

COPY "CheckType" (id, label) FROM stdin;
1	Масляный сервис
2	Интервальный сервис
3	Инспекционный сервис
\.

SELECT setval(pg_get_serial_sequence('"CheckType"', 'id'), max(id)) from "CheckType";
