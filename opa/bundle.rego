package dpp

# ------------------------------------------------------------------
# PoC-friendly policy with a mode switch via data.dpp.mode:
#   "permissive" -> allow everything (default for your prototype)
#   "enforcing"  -> apply the rules below
# ------------------------------------------------------------------

default allow = false

# If mode is permissive, short-circuit to allow all.
allow if {
  data.dpp.mode == "permissive"
}

# In enforcing mode, allow only when read/write rules pass.
allow if {
  data.dpp.mode == "enforcing"
  allow_read
}

allow if {
  data.dpp.mode == "enforcing"
  allow_write
}

# -----------------------
# Helpers
# -----------------------
is_get if { input.method == "GET" }
is_write if {
  input.method == "POST"
}
is_write if {
  input.method == "PUT"
}
is_write if {
  input.method == "PATCH"
}
is_write if {
  input.method == "DELETE"
}

path_is_dpp if {
  count(input.path) > 0
  input.path[0] == "dpp"
}

has_scope(s) if {
  some i
  input.user.scopes[i] == s
}

in_realm(r) if {
  input.user.realm == r
}

# -----------------------
# Read rules
# -----------------------

# Public tier: allow GET on /dpp/* when access_tier is "public"
allow_read if {
  is_get
  path_is_dpp
  input.access_tier == "public"
}

# B2B/privileged reads: allow GET for b2b realm or admin scope
allow_read if {
  is_get
  path_is_dpp
  in_realm("b2b")
}

allow_read if {
  is_get
  has_scope("role:admin")
}

allow_read if {
  is_get
  has_scope("dpp:read")
}

# -----------------------
# Write rules
# -----------------------

# Admins can write anywhere
allow_write if {
  is_write
  has_scope("role:admin")
}

# B2B writers need explicit write scope
allow_write if {
  is_write
  path_is_dpp
  in_realm("b2b")
  has_scope("dpp:write")
}
