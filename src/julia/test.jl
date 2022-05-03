using Distributed, SlurmClusterManager
using Dates

addprocs(SlurmManager())

hosts = []
pids = []
for i in workers()
	host, pid = fetch(@spawnat i (gethostname(), getpid()))
	push!(hosts, host)
	push!(pids, pid)
end

println(hosts)
println(pids)

include("./utils.jl")
include("./visualize.jl")
@everywhere include("./algorithm1.jl")

tsp_name = "d493"
log_time = now()
algo = "algo1"
log_name = "$algo-$tsp_name-$log_time"
log_file = open(log_name, "w")

n, node_coords = tsp_instance_parser("tsp_instances/$tsp_name.tsp")
# n, node_coords = 10, rand(1:100,10,2)
dist_matrix = get_distance_matrix(node_coords)
tour = [i for i in 1:n]
final_tour = algorithm1(n, dist_matrix, 48, log_file)
final_length = get_tour_length(final_tour, dist_matrix)
println(final_length)
draw_tours([final_tour], node_coords, output_path="results/plots/tour.png", close_tour=false)

