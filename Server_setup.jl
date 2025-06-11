using Genie
using Statistics
using ThreadsX
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
function asian_value(T, X0, K, r, s, m, max_time)
result = Float64[]
start_time = time()
while time() - start_time < max_time
append!(result,
ThreadsX.map(i -> payoff_asian_sample(T, X0, K, r, s, m),
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
Genie.config.run_as_server = true
Genie.Router.route("/", method=POST) do
message = Genie.Requests.jsonpayload()
return try
K = float(message["K"])
max_time = float(message["max_time"])
value = asian_value(1.0, 50.0, K, 0.05, 0.3, 200, max_time)
Genie.Renderer.Json.json((status="OK", value=value))
catch
Genie.Renderer.Json.json((status="ERROR", value=""))
end
end
Genie.Server.up()

using DataFrames

df = DataFrame(K=30:2:80, max_time=0.25)

df.data = map(df.K, df.max_time) do K, max_time
@show K
@time req = HTTP.post("http://127.0.0.1:8000",
["Content-Type" => "application/json"],
JSON3.write((;K, max_time)))
return JSON3.read(req.body)
end;

all(x -> x.status == "OK", df.data)

#esempi
#small_df = DataFrame(x=[(a=1, b=2), (a=3, b=4), (a=5, b=6)])
#transform(small_df, :x => identity => AsTable) #uguale a transform(small_df, :x => AsTable)

df2 = select(df, :K, :data => ByRow(x -> x.value) => AsTable)

using Plots

plot(plot(df2.K, df2.mv; legend=false,
xlabel="K", ylabel="expected value"),
plot(df2.K, df2.zero; legend=false,
xlabel="K", ylabel="probability of zero"))