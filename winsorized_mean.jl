function winsorized_mean(x::AbstractVector, k::Integer)
k >= 0 || throw(ArgumentError("k must be non-negative"))
length(x) > 2 * k || throw(ArgumentError("k is too large"))
y = sort!(collect(x))
for i in 1:k
y[i] = y[k + 1]
y[end - i + 1] = y[end - k]
end
return sum(y) / length(y)
end