// Fixture project manifest: nested mod overrides, longest prefix wins.
package {
    mode dyn
}

mod a   { mode static }
mod a/b { mode dyn }
