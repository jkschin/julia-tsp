using Plots
using SharedArrays
using StaticArrays
using Distances
using Combinatorics
using Random
using BenchmarkTools

function draw_tour(tour, node_coords)
    a = map((x) -> node_coords[x, :], tour)
    push!(a, a[1])
    a = transpose(reduce(hcat,a))
    plot(a[:, 1], a[:, 2]; marker=(:circle, 1), legend=false)
end

function get_distance_matrix(node_coords)
    n = size(node_coords)[1]
    dist_matrix = rand([0.0], n, n)
    for i in 1:n
        for j in i+1:n
            a, b = node_coords[i, :], node_coords[j, :]
            dist_matrix[i, j] = euclidean(a, b)
            dist_matrix[j, i] = euclidean(a, b)
        end
    end
    return dist_matrix
end

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

function get_tour_length(tour, dist_matrix)
    total = 0
    for i in 1:(length(tour) - 1)
        node_a, node_b = tour[i], tour[i+1]
        total += dist_matrix[node_a, node_b]
    end
    node_a, node_b = tour[1], tour[length(tour)]
    total += dist_matrix[node_a, node_b]
    return total
end
    
function two_opt_change(pair, tour, dist_matrix)
    b, c = pair
    # Handles edge case of swapping the ends
    if b == 1 && c == length(tour)
        return 0
    end
    a = get_node_before(tour, b)
    d = get_node_after(tour, c)
    a, b, c, d = map((x) -> tour[x], [a, b, c, d])
    cur_dist = dist_matrix[a, b] + dist_matrix[c, d]
    new_dist = dist_matrix[a, c] + dist_matrix[b, d]
    dist_changed = new_dist - cur_dist
    return dist_changed
end


"""
Swaps and reverses a tour. This is used only in 2-OPT.
"""
function swap_and_reverse(tour, a, b)
    tour[a], tour[b] = tour[b], tour[a]
    tour = reverse(tour, a+1, b-1)
end

"""
The TSP 2-OPT operator.
"""
function two_opt(tour, dist_matrix)
    n = length(tour)
    pairs = collect(combinations(1:n,2))
    while true
        # # Feels like this isn't necessary
        # changes = SharedArray{Float64}(length(pairs))
        # # We parallelized this here.
        # for i = 1:length(pairs)
        #     changes[i] = two_opt_change(pairs[i], tour, dist_matrix)
        # end
        changes = map((x) -> two_opt_change(x, tour, dist_matrix), pairs)
        best_change, idx = findmin(changes)
        if best_change >= 0
            break
        else
            a, b = pairs[idx]
            tour = swap_and_reverse(tour, a, b)
        end
    end
    return tour
end

function simulated_annealing(tour, dist_matrix)
    k_max = 1e8
    for k in 1:k_max
        temp = k_max/(k + 1)
        pair = rand(1:length(tour), 2)
        dist_change = two_opt_change(pair, tour, dist_matrix)
        accept = false
        if dist_change < 0
            accept = true
        elseif exp(-dist_change / temp) >= rand()
            accept = true
        end
        if accept
            a, b = pair
            tour = swap_and_reverse(tour, a, b)
        end
    end
    return tour
end

# function swap_heuristic(tour)


two_opt_wrapper(f, dist_matrix) = x->f(x, dist_matrix)

# Construction heuristics are here. In reality though, it can be seen as trimming and then adding.
"""
Returns arc-distance pairs as a dictionary for greedy heuristic.
"""
function greedy_heuristic(n, dist_matrix)
    # Step 1: Build dictionary of edges and distances
    arc_labels = []
    arc_values = []
    for i in 1:n
        for j in i:n
            if i == j
                continue
            else
                push!(arc_labels, (i, j))
                push!(arc_values, dist_matrix[i, j])
            end
        end
    end
    dictionary = Dict(zip(arc_labels, arc_values))
    dictionary = sort(collect(dictionary), by=x->x[2])
    return dictionary
end

"""
Small test case
arc = (4, 5)
adj_list = Dict(
    1 => [2, 4],
    2 => [1, 3],
    3 => [2],
    4 => [1]
    )
check_cycle(arc, adj_list) -> should return false
"""
function check_cycle(arc, adj_list, n)
    # Pick any node as the start node.
    start_node = arc[1]
    tour = [start_node]
    visited = Set([start_node])
    while true
        neighbors = adj_list[last(tour)]
        pushed = false
        for neighbor in neighbors
            if !in(neighbor, visited)
                push!(tour, neighbor)
                push!(visited, neighbor)
                pushed = true

            end
        end
        if pushed
            continue
        else
            break
        end
    end
    if Set(arc) == Set([tour[1], last(tour)]) && length(tour) < n
        return true, tour
    else
        return false, tour
    end
end


function greedy_tour(arc_distance_pairs)
    adj_list = Dict([(i, []) for i in 1:n])
    for arc_distance_pair in arc_distance_pairs
        arc, distance = arc_distance_pair
        node_i, node_j = arc

        # Check if adding this arc causes a cycle
        cycle_present, cur_tour = check_cycle(arc, adj_list, n)
        if length(cur_tour) == n
            node_i = tour[1]
            node_j = last(tour)
            push!(adj_list[node_i], node_j)
            push!(adj_list[node_j], node_i)
            return cur_tour
            break 
        end
        if cycle_present
            continue
        end

        # Check if adding this arc violates 2 arc constraint.
        if length(adj_list[node_i]) == 2 || length(adj_list[node_j]) == 2
            continue
        end
        push!(adj_list[node_i], node_j)
        push!(adj_list[node_j], node_i)
    end
end