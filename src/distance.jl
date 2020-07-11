"""
    intersectionlength(y::MinHashSketch, y::MinHashSketch)

Count number of hashes in both `x` and `y` more effectively than using ordinary
set operations.

# Examples

```julia-repl
julia> x = sketch(1:10000, 100); y = sketch(5000:15000, 100);

julia> intersectionlength(x, y)
49
```
"""
function intersectionlength(x::MinHashSketch, y::MinHashSketch)
    xi, yi = 1, 1
    n = 0
    @inbounds while (xi ≤ length(x.hashes)) & (yi ≤ length(y.hashes))
        xv, yv = x.hashes[xi], y.hashes[yi]
        n += xv == yv
        xi += xv ≤ yv
        yi += yv ≤ xv
    end
    return n
end

function init_counters(sketches::AbstractVector{MinHashSketch})
    heap = BinaryMinHeap{Tuple{UInt, Int}}()
    counts = counter(UInt)
    for (n, sketch) in enumerate(sketches)
        if !isempty(sketch.hashes)
            h = sketch.hashes[1]
            push!(heap, (h, n))
            inc!(counts, h)
        end
    end
    return heap, counts
end

function increment_matrix!(matrix::Matrix{<:Integer}, indices::Vector{<:Integer}, N::Integer)
    @inbounds for i in 1:N-1
        r = indices[i]
        for j in i+1:N
            c = indices[j]
            c_, r_ = minmax(c, r)
            matrix[r_, c_] += 1
        end
    end
end

# Pop smallest element from heap. If the source sketch have
# more hashes, updates counter and heap with new hash
function popheap!(heap, counts, sketches, indices)
    (smallest, sketchno) = pop!(heap)
    @inbounds hashes = sketches[sketchno].hashes
    @inbounds newindex = indices[sketchno] + 1
    @inbounds indices[sketchno] = newindex
    @inbounds if newindex ≤ length(hashes)
        h = hashes[newindex]

        # We can add a new value without fear that it will be popped
        # in the same round since the new value is guaranteed to be larger
        push!(heap, (h, sketchno))
        inc!(counts, h)
    end
    return (smallest, sketchno)
end

# This function scales better than O(N^2 * S), that's why it's so complicated
"""
    intersectionlength(v::AbstractVector{MinHashSketch})

Return a `length(v)` square `Matrix{Int}` where the `[i, j]` where `i > j`'th
cell contain the number of hashes in both `v[i]` and `v[j]`.

# Examples

```julia-repl
julia> v = [sketch((1:1000) .+ (300*i), 100) for i in 1:4];

julia> intersectionlength(v)
4×4 Array{Int64,2}:
  0   0   0  0
 64   0   0  0
 27  58   0  0
  8  34  73  0
```
"""
function intersectionlength(sketches::AbstractVector{MinHashSketch})
    heap, counts = init_counters(sketches)
    indices = fill(1, length(sketches))
    smallest_ids = Vector{Int}(undef, length(sketches))
    matrix = zeros(Int, (length(sketches), length(sketches)))
    @inbounds while !isempty(heap)
        # Get smallest value
        smallest, sketchno = popheap!(heap, counts, sketches, indices)
        smallest_ids[1] = sketchno
        # How many other values are equal to smallest value?
        N = counts[smallest]
        reset!(counts, smallest)
        # Increment overlaps for all that are equal
        if N > 1
            for i in 2:N
                smallest_ids[i] = popheap!(heap, counts, sketches, indices)[2]
            end
            increment_matrix!(matrix, smallest_ids, N)
        end
    end
    return matrix
end
