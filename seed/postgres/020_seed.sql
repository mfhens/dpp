-- sqlfluff:disable
-- 020_seed.sql

CREATE TEMP TABLE _seed(doc JSONB);

-- Client-side copy (psql meta-command). Works without superuser.
-- Using Lego Duck sample DPPs for demonstration
\copy _seed(doc) FROM '/docker-entrypoint-initdb.d/lego-duck-sample-dpps.ndjson'

INSERT INTO dpp (dpp_id, product_id, dpp_url)
SELECT
  doc->>'id' AS dpp_id,
  COALESCE(
    doc #>> '{product,model}',
    doc #>> '{product,serialNumber}',
    doc #>> '{product,batchOrLot}',
    doc #>> '{attributes,model}',
    doc #>> '{attributes,modelNumber}',
    doc->>'product_id',
    doc->>'id'
  ) AS product_id,
  concat('http://api:8000/dpp/', doc->>'id') AS dpp_url
FROM _seed
ON CONFLICT (dpp_id) DO NOTHING;

INSERT INTO dpp_version (dpp_id, version, payload)
SELECT doc->>'id', 1, doc
FROM _seed
ON CONFLICT (dpp_id, version) DO NOTHING;

DROP TABLE _seed;

