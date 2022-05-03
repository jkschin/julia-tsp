using Combinatorics

function get_node_after(tour, index)
    if index == length(tour)
        return 1
    else
        return index + 1
    end
end

function get_node_before(tour, index)
    if index == 1
        return length(tour)
    else
        return index - 1
    end
end

function two_opt_change(pair, tour, dist_matrix)
    b, c = pair
    rev = true
    # Handles edge case of swapping the ends
    if b == 1 && c == length(tour)
        d = get_node_before(tour, c)
        a = get_node_after(tour, b)
        rev = false
    else
        a = get_node_before(tour, b)
        d = get_node_after(tour, c)
    end
    a, b, c, d = map((x) -> tour[x], [a, b, c, d])
    cur_dist = dist_matrix[a, b] + dist_matrix[c, d]
    new_dist = dist_matrix[a, c] + dist_matrix[b, d]
    dist_changed = new_dist - cur_dist
    return dist_changed, rev
end

function swap(tour, a, b, rev)
    tour[a], tour[b] = tour[b], tour[a]
    if rev
        tour = reverse(tour, a+1, b-1)
    end 
    return tour
end

# A list of indexes where the swaps are allowed.
# For example, [1, 3, 5, 7], means that swaps between [1, 3], [1, 5], etc. are all allowed.
function two_opt(tour, dist_matrix; indexes=nothing)
    n = length(tour)
    pairs = nothing
    if indexes == nothing
        pairs = collect(combinations(1:n,2))
    end
    while true
        if indexes != nothing
            swappable_vertices = findall(==(1), indexes)
            pairs = collect(combinations(swappable_vertices,2))
        end
        # pairs = collect(combinations(swappable_vertices,2))
        # changes = SharedArray{Float64}(length(pairs))
        # # We parallelized this here.
        # @sync @distributed for i = 1:length(pairs)
        #     changes[i] = two_opt_change(pairs[i], tour, dist_matrix)
        # end
        changes = map((x) -> two_opt_change(x, tour, dist_matrix), pairs)
        # println(changes)
        # println(tour)
        idx = argmin([i[1] for i in changes])
        best_change, rev = changes[idx]
        # println(changes[idx])
        if best_change >= 0
            break
        else
            a, b = pairs[idx]
            # println(a, b, tour)
            tour = swap(tour, a, b, rev)
            if indexes != nothing
                indexes = swap(indexes, a, b, rev)
            end
            # println(a, b, tour)
        end
    end
    return tour
end

two_opt_wrapper(f, dist_matrix) = x->f(x, dist_matrix)