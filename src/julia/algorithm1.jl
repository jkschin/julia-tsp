include("./heuristics.jl")
include("./two_opt.jl")
include("./utils.jl")

using Random
using Distributed
using Dates
using JLD

"""
1. Initialize X number of random sequences.
2. Use the random insertion construction heuristic to build the random sequences into tours.
3. Use two_opt on all X instances.
4. Get intersecting arcs among all X instances.
5. Collect these arcs as a path. Store the path. Remove the relevant vertices from the tour.
6. Repeat 1 - 5, just that the tour now has removed vertices.
7. At the end of the algorithm, you get a set of paths. Concatenate them randomly and two_opt until you get the final tour.
8. This algorithm currently does a simple concatenate, but it is easy to think of an idea where the concatenation can be randomized.
"""
function algorithm1(n, dist_matrix, voters, limit_t)
    start_t = time()
    selected_paths = []
    tour = [i for i in 1:n]

    best_length = 1e10
    best_tour = nothing
    best_selected_paths = nothing

    stuck = 0
    iters = 0

    logs = []
    path_memory = []
    tour_memory = []

    while length(tour) >= 2
        println("$iters, $best_length")
        # If stuck, restart.
        if stuck == 10
            println("Got stuck. Restarting!")
            tour = [i for i in 1:n]
            selected_paths = []
            stuck = 0
        end

        # Check time elapsed and terminate if exceeded time limit.
        elapsed = time() - start_t
        if elapsed > limit_t
            break
        end

        _l = length(tour)
        tours = [shuffle(tour) for j in 1:voters]
        tours = map(x -> random_insertion(x, dist_matrix), tours)
        tours = pmap(two_opt_wrapper(two_opt, dist_matrix), tours)
        sets = map(x -> Set(get_bidirectional_arcs(x)), tours)
        intersecting_arcs = reduce(intersect, sets)
        paths = global_dfs(intersecting_arcs)
        if length(paths) != 0
            selected_path = get_longest_path(paths)
        else
            continue
            # selected_path = two_opt(tour, dist_matrix)
            # selected_path = (length(selected_path), two_opt(tour, dist_matrix))
        end

        push!(selected_paths, selected_path)
        tour = collect(setdiff(tour, Set(selected_path[2])))

        # Logging Trajectory
        log_tour = get_tour_from_tour_and_selected_paths(tour, selected_paths, dist_matrix)
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
    final_tour = get_tour_from_tour_and_selected_paths(best_tour, best_selected_paths, dist_matrix)
    final_tour_length = get_tour_length(final_tour, dist_matrix)
    return final_tour, final_tour_length, logs, path_memory, tour_memory
end
