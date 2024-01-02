# This contains code that was formerly a part of Julia. License is MIT: http://julialang.org/license

using Base.Order: Forward, Ordering, lt

# Binary min-heap percolate down.
function percolate_down!(xs::AbstractArray, i::Integer, x=xs[i], o::Ordering=Forward, len::Integer=length(xs))
    @inbounds while (l = 2i) <= len
        r = 2i + 1
        j = r > len || lt(o, xs[l], xs[r]) ? l : r
        lt(o, xs[j], x) || break
        xs[i] = xs[j]
        i = j
    end
    @inbounds xs[i] = x
end

percolate_down!(xs::AbstractArray, i::Integer, o::Ordering, len::Integer=length(xs)) = percolate_down!(xs, i, xs[i], o, len)

# Binary min-heap percolate up.
function percolate_up!(xs::AbstractArray, i::Integer, x=xs[i], o::Ordering=Forward)
    @inbounds while (j = div(i, 2)) >= 1
        lt(o, x, xs[j]) || break
        xs[i] = xs[j]
        i = j
    end
    @inbounds xs[i] = x
end

@inline percolate_up!(xs::AbstractArray, i::Integer, o::Ordering) = percolate_up!(xs, i, xs[i], o)

function heappop!(xs::AbstractArray)
    x = @inbounds xs[1]
    y = pop!(xs)
    if !isempty(xs)
        percolate_down!(xs, 1, y, Forward)
    end
    return x
end

@inline function heappush!(xs::AbstractArray, x)
    push!(xs, x)
    percolate_up!(xs, length(xs), Forward)
    return xs
end

function heapify!(xs::AbstractArray, o::Ordering=Forward)
    for i in div(length(xs), 2):-1:1
        percolate_down!(xs, i, o)
    end
    return xs
end