use netio.sys
use netio.event
use netio.sys.unix

UNASSOCIATED<i64> = 0

mem IoSource {
    IoSourceState state
    u64*          inner
    SelectorId    selector_id
}

mem SelectorId {
    u64 id
}

const IoSource::new(io<u64*>) IoSource {
    return new IoSource {
        inner: io,
    }
}

IoSource::do_io(f<i64*>) {
    return this.state.do_io(f,this.inner)
}

IoSource::into_inner() {
    return this.inner
}

IoSource::register(registry<Registry>, token<u64>, interests<Interest>) i64 {
    if this.selector_id.associate(registry) != true {
        return false
    }

    return registry.selector()
        .register(this.inner.as_raw_fd(), token, interests)
}

IoSource::reregister(
    registry<Registry>,
    token<u64>,
    interests<Interest>
) i64 {
    if this.selector_id.check_association(registry) == false {
        runtime.warn(*"check_association failed")
    }
    return registry
            .selector()
            .reregister(
                this.inner.as_raw_fd(), 
                token, 
                interests
            )
}
IoSource::deregister(registry<Registry>) i64 {
    if this.selector_id.remove_association(registry) == false 
        runtime.warn(*"remove association failed")
    return registry.selector()
            .deregister(
                //TODO:
                this.inner.as_raw_fd()
            )
}

mem SelectorId {
    atomic.AtomicUsize id
}

const SelectorId::new() SelectorId {
    return new SelectorId {
        id: atomic.AtomicUsize{
            addr: 0
        },
    }
}

SelectorId::associate(registry<Registry>) u64 {
    registry_id<i64> = registry.selector().id()

    previous_id = this.id.swap(registry_id)

    if previous_id == 0 {
        return true
    } else {
        runtime.error(*
            "I/O source already registered with a `Registry`"
        )
    }
}

SelectorId::check_association(registry<Registry>) i64 {
    registry_id<i64> = registry.selector().id()
    id<u64> = this.id.load()

    if id == registry_id {
        return true
    } else if id == 0 {
        runtime.error(
            *"I/O source not registered with `Registry`",
        )
    } else {
        runtime.error(
            *"I/O source already registered with a different `Registry`"
        )
    }
}

SelectorId::remove_association(registry<Registry>) i64 {
    registry_id<u64> = registry.selector().id()
    previous_id<u64> = this.id.swap(UNASSOCIATED)

    if previous_id == registry_id {
        return true
    } else {
        runtime.error(*
            "I/O source not registered with `Registry`"
        )
    }
}

SelectorId::clone() SelectorId {
    return SelectorId {
        id: AtomicUsize {
            addr: this.id.load()
        }
    }
}
