include("./heuristics.jl")

using Random

# test with: get_vertices_in_selected_paths(([2, [1,2]], [2, [3,4]]))
function get_vertices_in_selected_paths(selected_paths)
    if length(selected_paths) == 0
        return []
    end
    vertices = reduce(vcat, [i[2] for i in selected_paths])
    return vertices
end

# test with: get_vertices_not_in_selected_paths(([2, [1,2]], [2, [3,4]]), 10)
function get_vertices_not_in_selected_paths(n, selected_paths)
    all_vertices = [i for i in 1:n]
    vertices = get_vertices_in_selected_paths(selected_paths)
    diff = collect(setdiff(all_vertices, vertices))
    return diff
end

"""
test with:
n = 20
selected_paths = [[2, [1, 3]], [2, [2,4]], [2, [15, 11]], [2, [5, 10]]]
a = algorithm2_construction_method(n, selected_paths)
length(a[1])
"""
function algorithm2_construction_method(n, dist_matrix, selected_paths)
    if length(selected_paths) == 0
        tour = shuffle([i for i in 1:n])
        tour = random_insertion(tour, dist_matrix)
        indexes = [1 for i in 1:n]
        return tour, indexes
    end
    if length(selected_paths) == 1
        diff = get_vertices_not_in_selected_paths(n, selected_paths)
        diff = random_insertion(shuffle(diff), dist_matrix)
        tour = vcat(selected_paths[1][2], shuffle(diff))
        start_idx = length(selected_paths[1][2]) + 1
        indexes = [0 for i in 1:length(tour)]
        indexes = vcat(indexes, [1 for i in start_idx: n])
        return tour, indexes
    end
    num_paths = length(selected_paths)
    diff = get_vertices_not_in_selected_paths(n, selected_paths)
    partition_diff = nothing
    if num_paths - 1 <= 1
        partition_diff = [shuffle(diff)]
    else
        chunk_size = div(length(diff), num_paths - 1) + 1
        partition_diff = collect(Iterators.partition(shuffle(diff), chunk_size))
    end
    
    list_a = shuffle([selected_paths[i][2] for i in 1:length(selected_paths)])
    list_b = shuffle(partition_diff)
    tour = []
    indexes = []
    while length(list_a) != 0 && length(list_b) != 0
        if rand(1)[1] < 0.5
            path = pop!(list_a)
            l = length(path)
            tour = vcat(tour, path)
            push!(indexes, 1)
            indexes = vcat(indexes, [0 for i in 1:l-2])
            push!(indexes, 1)
            # start_idx = length(tour) + 1
            # end_idx = length(tour)
            # indexes = vcat(indexes, [start_idx, end_idx])
        else
            path = pop!(list_b)
            path = random_insertion(path, dist_matrix)
            l = length(path)
            tour = vcat(tour, path)
            indexes = vcat(indexes, [1 for i in 1:l])
            # start_idx = length(tour) + 1
            # end_idx = length(tour)
            # indexes = vcat(indexes, [i for i in start_idx:end_idx])
        end
    end
    while length(list_a) != 0
        path = pop!(list_a)
        l = length(path)
        tour = vcat(tour, path)
        push!(indexes, 1)
        indexes = vcat(indexes, [0 for i in 1:l-2])
        push!(indexes, 1)
    end
    while length(list_b) != 0
        path = pop!(list_b)
        path = random_insertion(path, dist_matrix)
        l = length(path)
        tour = vcat(tour, path)
        indexes = vcat(indexes, [1 for i in 1:l])
    end
#     println(num_paths)
#     for i in 1:num_paths - 1
#         tour = vcat(tour, selected_paths[i][2])
#         start_idx = length(tour) + 1
#         tour = vcat(tour, partition_diff[i])
#         end_idx = length(tour)
#         push!(indexes, [i for i in start_idx:end_idx])
#     end
#     tour = vcat(tour, last(selected_paths)[2])
    return tour, indexes
end

function algo2_final_tour(n, selected_paths, dist_matrix)
    right = get_vertices_not_in_selected_paths(n, selected_paths)
    left = reduce(vcat, [i[2] for i in selected_paths])
    comb = vcat(left, right)
    final_tour = two_opt(comb, dist_matrix)
    return final_tour
end

function algorithm2(n, dist_matrix, voters, limit_t)
    start_t = time()
    selected_paths = []

    best_length = 1e10
    best_tour = nothing
    best_selected_paths = nothing

    stuck = 0
    iters = 0

    logs = []
    path_memory = []
    tour_memory = []

    while true
        println("$iters, $best_length")
        if stuck == 10
            println("Got stuck. Restarting!")
            l_sel_path = length(selected_paths)
            println("Number of selected paths: $l_sel_path")
            selected_paths = sample(selected_paths, div(l_sel_path, 2))
            stuck = 0
        end

        # Check time elapsed and terminate if exceeded time limit.
        elapsed = time() - start_t
        if elapsed > limit_t
            break
        end

        tour = get_vertices_in_selected_paths(selected_paths)
        tour_l = length(tour)
        println("Tour length: $tour_l")
        if length(tour) == n
            break
        end
        
        tours_indexes_pairs = [algorithm2_construction_method(n, dist_matrix, selected_paths) for i in 1:voters]
        tours = map(x -> two_opt(x[1], dist_matrix, indexes=x[2]), tours_indexes_pairs)
        sets = map(x -> Set(get_bidirectional_arcs(x)), tours)
        intersecting_arcs = reduce(intersect, sets)
        selected_paths = global_dfs(intersecting_arcs)

        # Logging Trajectory
        log_tour = algo2_final_tour(n, selected_paths, dist_matrix)
        log_tour_length = get_tour_length(log_tour, dist_matrix)

        if log_tour_length >= best_length
            stuck += 1
        else
            best_length = min(best_length, log_tour_length)
            best_tour = tour
            best_selected_paths = selected_paths
        end        
        push!(logs, [elapsed, log_tour_length, best_length])
        

        if iters % 5 == 0
            push!(path_memory, selected_paths)
            push!(tour_memory, log_tour)
        end

        flush(stdout)
        iters += 1
    end
    final_tour = algo2_final_tour(n, best_selected_paths, dist_matrix)
    final_tour_length = get_tour_length(final_tour, dist_matrix)
    return final_tour, final_tour_length, logs, path_memory, tour_memory
end