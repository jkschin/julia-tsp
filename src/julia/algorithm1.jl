include("./heuristics.jl")
include("./two_opt.jl")
include("./utils.jl")

using Random
using Distributed
using Dates



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
function algorithm1(n, dist_matrix, voters, logfile)
    start_t = time()
    selected_paths = []
    tour = [i for i in 1:n]
    best_length = 1e10
    while length(tour) >= 2
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
        log_tour = get_tour_from_tour_and_selected_paths(tour, selected_paths)
        log_tour_length = get_tour_length(log_tour, dist_matrix)
        best_length = min(best_length, log_tour_length)
        elapsed = time() - start_t
        log_message(logfile, "$elapsed, $log_tour_length, $best_length")
    end
    log_message(logfile, "completed")
    close(logfile)
    final_tour = reduce(vcat, [i[2] for i in selected_paths])
    final_tour = two_opt(final_tour, dist_matrix)    
    return final_tour
end
