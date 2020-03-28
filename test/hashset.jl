function test_membership(s::MinHash.HashSet, positives::Set, superset)
    mistakes = false
    for i in superset
        mistakes |= ((i in positives) ⊻ (i in s))
    end
    @test !mistakes
end

@testset "Instantiation" begin
    function test_hashset_length(s::MinHash.HashSet)
        @test s.mask + 1 == length(s.data)
        @test count_ones(length(s.data)) == 1
        return length(s.data)
    end

    for len in [1, 10, 16, 17, 100]
        @test test_hashset_length(MinHash.HashSet(len)) ≥ len
    end
end

@testset "Basic functionality" begin
    for len in [10, 100, 500, 5000]
        rnge = UInt(1):UInt(len)
        rf = Set(rand(rnge, div(len, 3)))
        s = MinHash.HashSet(len)
        for i in rf
            MinHash.unsafe_push!(s, i)
        end
        test_membership(s, rf, rnge)
        @test length(s) == length(rf)
    end
end

@testset "Repopulation" begin
    rnge = UInt(1):UInt(1000)
    integers = collect(Set(rand(rnge, 400)))
    keep = Set(integers[1:100])
    heap = heapify!(collect(keep), Base.Order.Reverse)
    s = MinHash.HashSet(1000)
    for i in integers
        MinHash.unsafe_push!(s, i)
    end
    MinHash.repopulate!(s, heap)
    test_membership(s, keep, integers)
    @test length(s) == length(keep)

    # Here, test the second if statement in push!
    s = MinHash.HashSet(1000)
    for i in UInt(1):UInt(500)
        MinHash.unsafe_push!(s, i)
    end
    heap = UInt[]
    for i in UInt(501):UInt(1000)
        heappush!(heap, i, Base.Order.Reverse)
        push!(s, i, heap)
    end
end

@testset "Pushing" begin
    s = MinHash.HashSet(50)
    heap = heapify!(rand(UInt, 25), Base.Order.Reverse)
    for i in 1:1000
        largest = pop!(heap)
        smaller = largest - 10
        heappush!(heap, smaller, Base.Order.Reverse)
        push!(s, smaller, heap)
    end
    @test all(i in s for i in heap)
end
