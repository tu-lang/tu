// Macro thin wrappers.

use runtime
use asyncio.macros as macros

fn join2(a<runtime.Future>, b<runtime.Future>) runtime.Future {
    return macros.join2(a, b)
}

fn select2(a<runtime.Future>, b<runtime.Future>) runtime.Future {
    return macros.select2(a, b)
}
