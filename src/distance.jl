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
