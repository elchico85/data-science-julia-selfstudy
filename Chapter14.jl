using CSV
using DataFrames
using CategoricalArrays
using DataFramesMeta
using Dates
using Distributions
import Downloads
using FreqTables
using GLM
using Plots
using Random
using ROCAnalysis
using SHA
using Statistics
import ZipFile
using BenchmarkTools
using ThreadsX
using Genie

Random.seed!(1234);

X0, T, s, r, m = 1.0, 2.0, 0.2, 0.1, 4

gbm = DataFrame(X=X0, t=0.0)

for i in 1:m
Z = randn()
log_return = (r - s^2/2) * T/m + s * sqrt(T/m) * Z
next_X = gbm.X[end] * exp(log_return)
next_t = gbm.t[end] + T/m
push!(gbm, (next_X, next_t))
end

# Function to calculate the payoff of an Asian option using a sample path
# of the geometric Brownian motion (GBM) model.
function payoff_asian_sample(T, X0, K, r, s, m)::Float64
X = X0
sumX = X
d = T / m
for i in 1:m
X *= exp((r - s^2 / 2) * d + s * sqrt(d) * randn())
sumX += X
end
Y = sumX / (m + 1)
return exp(-r * T) * max(Y - K, 0)
end

# Function to calculate the Asian option value using Monte Carlo simulation
# with a time limit for execution

    asian_value(T, X0, K, r, s, m, max_time)
function asian_value(T, X0, K, r, s, m, max_time)
result = Float64[]
start_time = time()
while time() - start_time < max_time
append!(result, ThreadsX.map(i -> payoff_asian_sample(T, X0, K,
r, s, m),
1:10_000))
end
n = length(result)
mv = mean(result)
sdv = std(result)
lo95 = mv - 1.96 * sdv / sqrt(n)
hi95 = mv + 1.96 * sdv / sqrt(n)
zero = mean(==(0), result)
return (; n, mv, lo95, hi95, zero)
end

Genie.Renderer.Json.json((firstname="Valerio", lastname="Parra"))
