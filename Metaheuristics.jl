using Metaheuristics

f(x) = 10length(x) + sum( x.^2 - 10cos.(2π*x)  )

D = 10
bounds = boxconstraints(lb = -5ones(D), ub = 5ones(D))
result = optimize(f, bounds)


