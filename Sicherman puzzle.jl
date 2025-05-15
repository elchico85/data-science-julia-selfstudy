two_standard = Dict{Int, Int}()

for i in [1, 2, 3, 4, 5, 6]
    for j in [1, 2, 3, 4, 5, 6]
        s = i+j
        if haskey(two_standard, s)
            two_standard[s] += 1
        else
            two_standard[s] = 1
        end
    end
end

two_standard