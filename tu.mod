package {
    mode dyn
}

mod asmer    { mode static }
mod linker   { mode static }
mod library  { mode static }
mod packages { mode static }
mod platform { mode static }
mod runtime  { mode static }

mod tests { mode mixed }
mod tests/pkgmode/dyndemo    { mode dyn }
mod tests/pkgmode/staticdemo { mode static }
