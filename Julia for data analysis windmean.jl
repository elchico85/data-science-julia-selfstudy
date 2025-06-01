function windsorized_mean(x, k)
    y = sort(x)
    for i in 1:k
        y[i] = y[k + 1]
        y[end - i + 1] = y[end - k]
    end
    s=0
    for v in y
        s += v
    end
    return s / length(y)
end
