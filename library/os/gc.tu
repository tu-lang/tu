
use runtime

fn gc()
{
    runtime.GC()
}

fn enablegc(){
    runtime.gc.enablegc = true
} 

fn disbalegc(){
    runtime.gc.enablegc = false
}