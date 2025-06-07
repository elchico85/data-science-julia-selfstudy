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

