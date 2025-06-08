# This contains code that was formerly a part of Julia. License is MIT: http://julialang.org/license

using Base.Order: Forward, Ordering, lt

# Binary min-heap percolate down.
function percolate_down!(by, xs::AbstractArray, i::Integer, x, o::Ordering)
    len = length(xs)
    @inbounds while (l = 2i) <= len
        r = 2i + 1
        j = r > len || lt(o, by(xs[l]), by(xs[r])) ? l : r
        xj = xs[j]
        lt(o, by(xj), by(x)) || break
        xs[i] = xj
        i = j
    end
    return @inbounds xs[i] = x
end

function heappop!(by, xs::AbstractArray, o::Ordering)
    x = @inbounds xs[1]
    y = pop!(xs)
    if !isempty(xs)
        percolate_down!(by, xs, 1, y, o)
    end
    return x
end

function heapreplace!(by, xs::Vector, x, o::Ordering)
    res = @inbounds xs[1]
    @inbounds xs[1] = x
    percolate_down!(by, xs, 1, x, o)
    return res
end

function heapify!(by, xs::AbstractArray, o::Ordering)
    for i in div(length(xs), 2):-1:1
        percolate_down!(by, xs, i, @inbounds(xs[i]), o)
    end
    return xs
end
