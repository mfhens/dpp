-- 020_seed.sql

-- 1) Stage NDJSON as raw documents
CREATE TEMP TABLE _seed(doc JSONB);

-- Server-side COPY reads a file from inside the container.
-- In the Postgres image, /docker-entrypoint-initdb.d is readable at init time.
COPY _seed(doc) FROM '/docker-entrypoint-initdb.d/testdata.ndjson';

-- 2) Insert headers (idempotent)
INSERT INTO dpp (dpp_id, product_id, dpp_url)
SELECT
  doc->>'id' AS dpp_id,
  COALESCE(
    doc #>> '{attributes,model}',
    doc #>> '{attributes,modelNumber}',
    doc->>'product_id',
    doc->>'id'
  ) AS product_id,
  concat('http://api:8080/dpp/', doc->>'id') AS dpp_url
FROM _seed
ON CONFLICT (dpp_id) DO NOTHING;

-- 3) Insert first version (append-only, idempotent)
INSERT INTO dpp_version (dpp_id, version, payload)
SELECT
  doc->>'id' AS dpp_id,
  1          AS version,
  doc        AS payload
FROM _seed
ON CONFLICT (dpp_id, version) DO NOTHING;

-- 4) Cleanup temp
DROP TABLE _seed;
