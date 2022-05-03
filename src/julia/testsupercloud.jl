using Distributed, SlurmClusterManager

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

@everywhere include("./tsp.jl")

runs = 1000
n = 300
node_coords = rand(0:10000, n, 2)
dist_matrix = get_distance_matrix(node_coords)
tour = [i for i in 1:n]
tours = [shuffle(tour) for i in 1:runs]

function test1()
    println("Started")
    println("Current: ", get_tour_length(tour, dist_matrix))
    # res = Vector{Vector}(undef, runs)
    # @sync @distributed for i = 1:runs
    #     println(i)
    #     res[i] = two_opt(tours[i], dist_matrix)
    # end
    res = pmap(two_opt_wrapper(two_opt, dist_matrix), tours)
    res = map((x) -> get_tour_length(x, dist_matrix), res)
    print(res)
    println("Done")
end

println(@elapsed test1())