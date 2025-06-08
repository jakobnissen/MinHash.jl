# This contains code that was formerly a part of Julia. License is MIT: http://julialang.org/license

using Base.Order: Forward, Ordering, lt

# Binary min-heap percolate down.
function percolate_down!(xs::AbstractArray, i::Integer, x, o::Ordering)
    len = length(xs)
    @inbounds while (l = 2i) <= len
        r = 2i + 1
        j = r > len || lt(o, xs[l], xs[r]) ? l : r
        lt(o, xs[j], x) || break
        xs[i] = xs[j]
        i = j
    end
    return @inbounds xs[i] = x
end

# Binary min-heap percolate up.
function percolate_up!(xs::AbstractArray, i::Integer, x, o::Ordering)
    @inbounds while (j = div(i, 2)) >= 1
        lt(o, x, xs[j]) || break
        xs[i] = xs[j]
        i = j
    end
    return @inbounds xs[i] = x
end

function heappop!(xs::AbstractArray)
    x = @inbounds xs[1]
    y = pop!(xs)
    if !isempty(xs)
        percolate_down!(xs, 1, y, Forward)
    end
    return x
end

function heapreplace!(xs::Vector, x, o::Ordering)
    res = @inbounds xs[1]
    @inbounds xs[1] = x
    percolate_down!(xs, 1, x, o)
    return res
end

function heapify!(xs::AbstractArray, o::Ordering)
    for i in div(length(xs), 2):-1:1
        percolate_down!(xs, i, @inbounds(xs[i]), o)
    end
    return xs
end
