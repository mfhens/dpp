-- 001_schema.sql
CREATE TABLE IF NOT EXISTS dpp (
  dpp_id      VARCHAR(512)  PRIMARY KEY,
  product_id  VARCHAR(255),
  dpp_url     VARCHAR(1024) UNIQUE,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Matches: Index("ix_dpp_product_id_created", "product_id", "created_at")
CREATE INDEX IF NOT EXISTS ix_dpp_product_id_created ON dpp (product_id, created_at);

CREATE TABLE IF NOT EXISTS dpp_version (
  dpp_id     VARCHAR(512) REFERENCES dpp(dpp_id) ON DELETE CASCADE,
  version    INTEGER     NOT NULL,
  valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
  payload    JSONB       NOT NULL,
  CONSTRAINT pk_dpp_version PRIMARY KEY (dpp_id, version),
  CONSTRAINT uq_dpp_version_id_ver UNIQUE (dpp_id, version)
);
