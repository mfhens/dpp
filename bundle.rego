package dpp

# ------------------------------------------------------------------
# PoC-friendly policy with a mode switch via data.dpp.mode:
#   "permissive" -> allow everything (default for your prototype)
#   "enforcing"  -> apply the rules below
# ------------------------------------------------------------------

default allow = false

# If mode is permissive, short-circuit to allow all.
allow {
  data.dpp.mode == "permissive"
}

# In enforcing mode, allow only when read/write rules pass.
allow {
  data.dpp.mode == "enforcing"
  allow_read
}

allow {
  data.dpp.mode == "enforcing"
  allow_write
}

# -----------------------
# Helpers
# -----------------------
is_get { input.method == "GET" }
is_write { input.method == "POST" or input.method == "PUT" or input.method == "PATCH" or input.method == "DELETE" }

path_is_dpp {
  count(input.path) > 0
  input.path[0] == "dpp"
}

has_scope(s) {
  some i
  input.user.scopes[i] == s
}

in_realm(r) {
  input.user.realm == r
}

# -----------------------
# Read rules
# -----------------------

# Public tier: allow GET on /dpp/* when access_tier is "public"
allow_read {
  is_get
  path_is_dpp
  input.access_tier == "public"
}

# B2B/privileged reads: allow GET for b2b realm or admin scope
allow_read {
  is_get
  path_is_dpp
  in_realm("b2b")
}

allow_read {
  is_get
  has_scope("role:admin")
}

allow_read {
  is_get
  has_scope("dpp:read")
}

# -----------------------
# Write rules
# -----------------------

# Admins can write anywhere
allow_write {
  is_write
  has_scope("role:admin")
}

# B2B writers need explicit write scope
allow_write {
  is_write
  path_is_dpp
  in_realm("b2b")
  has_scope("dpp:write")
}
