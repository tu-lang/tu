use os
use std
use string

// Cached KEY→value map; prefer env_get() for early calls (init order unsafe).
envs = {}

func init(){
	m = {}
	for (k, v : os.envs()) {
		arr = string.split(v, "=")
		if std.len(arr) < 2 {
			continue
		}
		// Rejoin value so KEY=a=b keeps "a=b".
		val = arr[1]
		i = 2
		while i < std.len(arr) {
			val += "=" + arr[i]
			i += 1
		}
		m[arr[0]] = val
	}
	envs = m
}
