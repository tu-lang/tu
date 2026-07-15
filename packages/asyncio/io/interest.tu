 // Interest helpers live on netio; this file kept to preserve package layout.
 // asyncio.io short-name clashes with library/io — avoid `use netio` here so
 // package-level init does not pull foreign constants into this package's
 // static table.
