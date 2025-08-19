-- 002_views.sql
CREATE OR REPLACE VIEW dpp_latest AS
SELECT DISTINCT ON (v.dpp_id)
    v.dpp_id,
    v.version,
    v.valid_from,
    v.payload
FROM dpp_version v
ORDER BY v.dpp_id, v.version DESC;
