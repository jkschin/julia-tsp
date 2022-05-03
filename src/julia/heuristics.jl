# Construction heuristics. See: https://www.math.cmu.edu/~af1p/Teaching/OR2/Projects/P58/OR2_Paper.pdf for some good information too.

"""
########################################
########## GREEDY HEURISTIC ############
########################################
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
    
    arc_distance_pairs = dictionary
    
    # Step 2: Add arcs greedily and return tour.
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
    # This is added here just in case it does not terminate.
    return -1
end

"""
########################################
########## NEAREST NEIGHBOR ############
########################################
"""
function nearest_neighbor(n, dist_matrix)
    start_node = rand(1:n, 1)[1]
    tour = [start_node]
    visited = Set([start_node])
    while length(tour) < n
        cur_node = last(tour)
        neighbors_distance_pairs = Dict([(i, dist_matrix[cur_node, i]) for i in 1:n])
        neighbors_distance_pairs = sort(collect(neighbors_distance_pairs), by=x->x[2])
        for item in neighbors_distance_pairs
            neighbor, distance = item
            if !in(neighbor, visited) && neighbor != cur_node
                push!(tour, neighbor)
                push!(visited, neighbor)
                break
            end
        end
    end
    return tour
end

"""
########################################
########## RANDOM INSERTION ############
########################################
"""
function compute_insertion_delta(arc, node, dist_matrix)
    a, b = arc
    c = node
    increase = dist_matrix[a, c] + dist_matrix[c, b] - dist_matrix[a, b]
    return increase
end

function shortest_insertion(node, tour, dist_matrix)
    pairs = [(tour[i], tour[i+1]) for i in 1:length(tour)-1]
    insertion_deltas = map(x -> compute_insertion_delta(x, node, dist_matrix), pairs)
    idx = argmin(insertion_deltas)
    delta = insertion_deltas[idx]
    return idx, delta
end

# NOTE: this API is different from the others for now.
function random_insertion(nodes, dist_matrix)
    n = length(nodes)
    unvisited = shuffle(nodes)
    node_a = pop!(unvisited)
    node_b = pop!(unvisited)
    tour = [node_a, node_b]
    while length(tour) < n
        node_c = pop!(unvisited)
        idx, delta = shortest_insertion(node_c, tour, dist_matrix)
        tour = vcat(tour[1:idx], [node_c], tour[idx+1:length(tour)])
    end
    return tour
end

"""
########################################
########## CHEAPEST INSERTION ##########
########################################

Observe that cheapest insertion uses a lot of subroutines from random insertion.

"""
function cheapest_insertion(n, dist_matrix)
    unvisited = shuffle([i for i in 1:n])
    node_a = pop!(unvisited)
    node_b = pop!(unvisited)
    tour = [node_a, node_b]
    while length(tour) < n
        ins_idx_distance_pairs = map(x -> shortest_insertion(x, tour, dist_matrix), unvisited)
        shortest_distances = [i[2] for i in ins_idx_distance_pairs]
        node_idx = argmin(shortest_distances)
        ins_idx, _ = ins_idx_distance_pairs[node_idx]
        
        node_c = unvisited[node_idx]
        deleteat!(unvisited, node_idx)
        tour = vcat(tour[1:ins_idx], [node_c], tour[ins_idx+1:length(tour)])
    end
    return tour
end