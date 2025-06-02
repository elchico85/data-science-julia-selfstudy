import Downloads
using SHA
import ZipFile
using CSV
using DataFrames
using Graphs
using Statistics
using Plots
using Random

function ingest_to_df(archive::ZipFile.Reader, filename::AbstractString)
idx = only(findall(x -> x.name == filename, archive.files))
return CSV.read(read(archive.files[idx]), DataFrame)
end

git_zip = "git_web_ml.zip"

git_archive = ZipFile.Reader(git_zip)

edges_df = ingest_to_df(git_archive,
"git_web_ml/musae_git_edges.csv");

classes_df = ingest_to_df(git_archive,
"git_web_ml/musae_git_target.csv");

close(git_archive)

edges_df .+= 1
classes_df.id .+= 1

gh = SimpleGraph(nrow(classes_df))

for (srt, dst) in eachrow(edges_df)
add_edge!(gh, srt, dst)
end

classes_df.deg = degree(gh)

function deg_class(gh, class)
deg_ml = zeros(Int, length(class))
deg_web = zeros(Int, length(class))
for edge in edges(gh)
a, b = edge.src, edge.dst
if class[b] == 1
deg_ml[a] += 1
else
deg_web[a] += 1
end
if class[a] == 1
deg_ml[b] += 1
else
deg_web[b] += 1
end
end
return (deg_ml, deg_web)
end

classes_df.deg_ml, classes_df.deg_web =
deg_class(gh, classes_df.ml_target)

gdf = groupby(classes_df, :ml_target)

combine(gdf,
:deg_ml => mean => :mean_deg_ml,
:deg_web => mean => :mean_deg_web)

scatter(classes_df.deg_ml, classes_df.deg_web;
color=[x == 1 ? "black" : "yellow"
for x in classes_df.ml_target],
xlabel="degree ml", ylabel="degree web", labels=false)

agg_df = combine(groupby(classes_df, [:deg_ml, :deg_web]),
:ml_target => (x -> 1 - mean(x)) => :web_mean)

function gen_ticks(maxv)
max2 = round(Int, log2(maxv))
tick = [0; 2 .^ (0:max2)]
return (log1p.(tick), tick)
end

log1pjitter(x) = log1p(x) - 0.05 + rand() / 10

Random.seed!(1234);

scatter(log1pjitter.(agg_df.deg_ml),
log1pjitter.(agg_df.deg_web);
zcolor=agg_df.web_mean,
xlabel="degree ml", ylabel="degree web",
markersize=2,
markerstrokewidth=0.5,
markeralpha=0.8,
legend=:topleft, labels="fraction web",
xticks=gen_ticks(maximum(classes_df.deg_ml)),
yticks=gen_ticks(maximum(classes_df.deg_web)))

arrivato a 12.3.3