// asyncio.wrapper: dynamic class facade over the mem asyncio engine.
// Public API is camelCase. Class shells live in asyncio.wrapper.types;
// this package exposes sync leaf-future factories + blockOn/spawn.
// Leaf name is "wrapper" (not "wrap") to avoid library/string/wrap.tu.
