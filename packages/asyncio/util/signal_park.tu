// Monotonic count of signalfd deliveries applied by the signal driver.
// RecvFut polls this (same util package both sides) because cross-pkg
// EventInfo.fired_count / u64 bridges are unreliable under current codegen.

SIGNAL_DELIVERIES<u64> = 0

fn signal_deliveries_bump() {
    SIGNAL_DELIVERIES = SIGNAL_DELIVERIES + 1
}

fn signal_deliveries_get() u64 {
    return SIGNAL_DELIVERIES
}
