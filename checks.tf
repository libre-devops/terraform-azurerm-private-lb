# Post-plan sanity checks: informational (warn), they never fail an apply.

check "has_lbs" {
  assert {
    condition     = length(var.lbs) > 0
    error_message = "No load balancers are defined: the module call creates nothing."
  }
}

# A load-balancing rule without a health probe keeps sending traffic to dead backends. Probes are
# free; wire one up (probe_key or probe_id) for every rule.
check "rules_have_probes" {
  assert {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for r in values(lb.rules) : r.probe_key != null || r.probe_id != null
      ]
    ]))
    error_message = "At least one load-balancing rule has no health probe, so unhealthy backends keep receiving traffic."
  }
}
