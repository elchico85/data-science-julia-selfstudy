using DataFrames
using Serialization
using Plots
using BenchmarkTools


walk= deserialize("walk.bin")

# to matrix

#Matrix(walk)

# to named tuple

#Tables.columntable(walk)

function mysum(table)
s = 0
for v in table.x
s += v
end
end

df = DataFrame(x=1:1_000_000);

tab = Tables.columntable(df);

@code_warntype mysum(df)

