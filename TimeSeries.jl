using HTTP
using JSON3
using Dates

#query = "https://api.nbp.pl/api/exchangerates/rates/a/usd/" *
#"2020-06-01/?format=json"

#response = HTTP.get(query)

query = "https://api.nbp.pl/api/exchangerates/rates/a/usd/" *
"2020-06-01/?format=json"


try
response = HTTP.get(query)
json = JSON3.read(response.body)
only(json.rates).mid
catch e
if e isa HTTP.ExceptionRequest.StatusError
missing
else
rethrow(e)
end
end

dates=Date.(2020, 6, 1:30)

function get_rate(date::Date)
query = "https://api.nbp.pl/api/exchangerates/rates/" *
"a/usd/$date/?format=json"
try
response = HTTP.get(query)
json = JSON3.read(response.body)
return only(json.rates).mid
catch e
if e isa HTTP.ExceptionRequest.StatusError
return missing
else
rethrow(e)
end
end
end

