using Random
using Plots

Random.seed!(6);


function sim_step(current)
    dx, dy = rand(((1,0), (-1,0), (0,1), (0,-1)))
return (x=current.x + dx, y=current.y + dy)
end

walk = DataFrame(x=0,y=0);

for _ in 1:10
    current = walk[end,:]
    push!(walk, sim_step(current))
end

plot(walk.x, walk.y;
legend=false,
series_annotations=1:11,
xticks=range(extrema(walk.x)...),
yticks=range(extrema(walk.y)...))

 #[i for i in 1:0.5:5]

 