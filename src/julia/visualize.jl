ENV["GKSwstype"]="100"
using Plots; 

function draw_arcs(arcs, node_coords; output_path="results/plots/arcs.png")
    plot()
    for arc in arcs
        coords = collect(map(x -> node_coords[x, :], arc))
        coords = reduce(vcat,transpose.(coords))
        plot!(coords[:, 1], coords[:, 2]; marker=(:circle, 1), legend=false, color=1)
    end
    plot!()
    savefig(output_path)
end

function draw_tour(tour, node_coords, close_tour)
    a = map((x) -> node_coords[x, :], tour)
    if close_tour
        push!(a, a[1])
    end
    a = transpose(reduce(hcat,a))
    println(tour)
    plot!(a[:, 1], a[:, 2]; marker=(:circle, 1), legend=false)
end

function draw_tours(tours, node_coords; output_path="results/plots/tour.png", close_tour=false)
    plot()
    for tour in tours
        draw_tour(tour, node_coords, close_tour)
    end
    savefig(output_path)
end