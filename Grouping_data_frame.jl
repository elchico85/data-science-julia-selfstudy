using CSV
using DataFrames

raw_data = """
city,date,rainfall
Olecko,2020-11-16,2.9
Olecko,2020-11-17,4.1
Olecko,2020-11-19,4.3
Olecko,2020-11-20,2.0
Olecko,2020-11-21,0.6
Olecko,2020-11-22,1.0
Ełk,2020-11-16,3.9
Ełk,2020-11-19,1.2
Ełk,2020-11-20,2.0
Ełk,2020-11-22,2.0
""";

rainfall_df = CSV.read(IOBuffer(raw_data), DataFrame)
gdf_city = groupby(rainfall_df, "city")

gdf_city_date = groupby(rainfall_df, Not("rainfall"))