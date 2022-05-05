using Distributed
using Random
# using Distributed, SlurmClusterManager
using Dates

# addprocs(SlurmManager())

# hosts = []
# pids = []
# for i in workers()
# 	host, pid = fetch(@spawnat i (gethostname(), getpid()))
# 	push!(hosts, host)
# 	push!(pids, pid)
# end

# println("Distributed systems initialized")
# println(hosts)
# println(pids)

include("./utils.jl")
include("./visualize.jl")
@everywhere include("./algorithm1.jl")
# @everywhere include("./algorithm2.jl")
# algo1 and algo2 should take the same API.

ALGO1 = "ALGO1"
ALGO2 = "ALGO2"
LIN318 = "lin318"
D493 = "d493"
D657 = "d657"
VM1084 = "vm1084"

tsp_to_time_map = Dict(
	LIN318 => 235,
	D493 => 632,
	D657 => 3200,
	VM1084 => 3200
)

runs = 10

tsp_names = [LIN318, D493, D657, VM1084]
algos = [ALGO1]
runs_list = [i for i in 1:runs]

# Julia y u do dis and 1 index T_T
TASK_ID = parse(Int64, ARGS[1]) + 1
N_TASKS = parse(Int64, ARGS[2])
N_PROCS = nprocs() - 1
println("TASK_ID: $TASK_ID, N_TASKS: $N_TASKS")
println("NPROCS: $N_PROCS")

tups = vec(collect(Base.Iterators.product(tsp_names, runs_list, algos)))

# The shuffling is necessary as the default mapped tups if we don't shuffle
# will result in all the small jobs running on one node, which is not 
# what we want.
tups = shuffle(tups)
mapped_tups = map(x -> tups[x], collect(TASK_ID:N_TASKS:length(tups)))
println("Running the following jobs on this node:")
for tup in mapped_tups
	println(tup)
end

for tup in mapped_tups
	tsp_name, _, algo = tup
	limit_t = tsp_to_time_map[tsp_name]
	println("STARTING $TASK_ID: $tup with time limit $limit_t")

	rstring = uppercase(randstring(6))
	log_time = now()
	log_name = "$tsp_name-$algo-$log_time-$rstring"

	n, node_coords = tsp_instance_parser("tsp_instances/$tsp_name.tsp")
	dist_matrix = get_distance_matrix(node_coords)

	final_tour = nothing
	final_tour_length = nothing 
	logs = nothing 
	path_memory = nothing 
	tour_memory = nothing
	if algo == ALGO1
		final_tour, final_tour_length, logs, path_memory, tour_memory = algorithm1(n, dist_matrix, N_PROCS, limit_t)
	end
	save("results/runs/$log_name.jld", 
		Dict(
			"final_tour" => final_tour,
			"final_tour_length" => final_tour_length,
			"logs" => logs,
			"path_memory" => path_memory,
			"tour_memory" => tour_memory,
			"node_coords" => node_coords,
			"dist_matrix" => dist_matrix
		))
	println("ENDED $TASK_ID: $tup")
end


# algo = "algo1"
# log_file = open(log_name, "w")


# # n, node_coords = 10, rand(1:100,10,2)
# final_length = get_tour_length(final_tour, dist_matrix)
# println(final_length)
# draw_tours([final_tour], node_coords, output_path="results/plots/tour.png", close_tour=false)


