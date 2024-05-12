use std
fn quick_sort(arr,cmper){
    if std.len(arr) < 1 return []
    first = arr[0]
    left = []
    right = []
    for i = 1 ; i < std.len(arr) ; i += 1 {
        if cmper(arr[i] , first)
            left[] = arr[i]
        else 
            right[] = arr[i]
    }

    left = quick_sort(left,cmper)
    right = quick_sort(right,cmper)

    left[] = first
    return _qsort_merge(left,right)
}

fn _qsort_merge(arr1,arr2){
    arr = []
    std.merge(arr,arr1)
    std.merge(arr,arr2)
    return arr
}
