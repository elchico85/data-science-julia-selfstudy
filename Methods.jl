#Creating methods for a function

fun(x) = println("unsupported type: ", x)

fun(x::Number) = println("A number was passed: ", x)

fun(x::Float64) = println("A float value: ", x)

# Avoiding method ambiguity, run this code then run bar(1,2) for results
bar(x,y) = println("no number passed: ", x, " ", y)

bar(x::Number, y) = println("A number was passed: ", x, " ", y)

bar(x, y::Number) = println("A number was passed: ", x, " ", y)

