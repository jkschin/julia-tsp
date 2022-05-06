using Distances

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

function get_arcs(tour)
    arcs = [(tour[i], tour[i+1]) for i in 1:length(tour)-1]
    return arcs
end

"""
returns 2x the number of arcs. (1, 2) becomes (1, 2) and (2, 1)
"""
function get_bidirectional_arcs(tour)
    arcs = get_arcs(tour)
    arcs_rev = map(x -> reverse(x), arcs)
    return vcat(arcs, arcs_rev)
end

"""
(1, 2) and (2, 1) will get deduped in (1, 2)
"""
function dedupe_arcs(arcs)
    return Set([sort(collect(i)) for i in arcs])
end

function tsp_instance_parser(filename)
    f = open(filename, "r")
    headers = []
    node_coords = []
    for i in 1:5
        d = split(readline(f), ": ")[2]
        push!(headers, d)
    end
    readline(f)

    while !eof(f)
        b = readline(f)
        if b == "EOF"
            continue
        end
        b = split(b, " ")
        b = [parse(Float64, x) for x in b]
        popfirst!(b)
        push!(node_coords, b)
    end
    n = parse(Int, headers[4])
    node_coords = Matrix(transpose(reduce(hcat,node_coords)))
    return n, node_coords
end

function get_adj_list(arcs)
    function add!(d, node_a, node_b)
        if !haskey(d, node_a)
            d[node_a] = [node_b]
        else
            push!(d[node_a], node_b)
        end
    end
    adj_list = Dict()
    for arc in arcs
        node_a, node_b = arc
        add!(adj_list, node_a, node_b)
        add!(adj_list, node_b, node_a)
    end
    return adj_list
end

function dfs!(adj_list, node, unvisited)
    tour = []
    frontier = [node]
    leaf = -1
    while length(frontier) != 0
        cur_node = pop!(frontier)
        delete!(unvisited, cur_node)
        push!(tour, cur_node)

        count = 0
        neighbors = adj_list[cur_node]
        for neighbor in neighbors
            if in(neighbor, unvisited)
                push!(frontier, neighbor)
                count += 1
            end
        end
        if count == 0
            leaf = cur_node
        end
    end    
    return (length(tour), tour, leaf)
end

"""
1. Takes a set of arcs.
2. Builds an adjacency list from those arcs.
3. Does a global DFS.
4. Intermediate results include all paths and corresponding leaf nodes.
"""
function global_dfs(arcs)
    deduped_arcs = dedupe_arcs(arcs)
    adj_list = get_adj_list(deduped_arcs)
    unvisited = Set(keys(adj_list))
    results = []
    while length(unvisited) != 0
        node = rand(unvisited)
        l_tour, tour, leaf_node = dfs!(adj_list, node, unvisited)
        result = dfs!(adj_list, leaf_node, Set(tour))
        push!(results, result)
    end
    return results
end

function get_longest_path(results)
    lengths = [i[1] for i in results]
    idx = argmax(lengths)
    selected_sequence = results[idx]
    return selected_sequence
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

"""
tour and selected paths are distinct sets. The union of both gives all 
vertices in the graph.
"""
function get_tour_from_tour_and_selected_paths(tour, selected_paths, dist_matrix)
    tour = two_opt(tour, dist_matrix)
    final_tour = reduce(vcat, [i[2] for i in selected_paths])
    final_tour = vcat(tour, final_tour)
    final_tour = two_opt(final_tour, dist_matrix)  
    return final_tour
end

function log_message(file, message)
    println("logger: $message")
    write(file, "$message\n")
    flush(file)
end
