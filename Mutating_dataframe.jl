import Downloads
using SHA
import ZipFile
using CSV
using DataFrames

function ingest_to_df(archive::ZipFile.Reader, filename::AbstractString)
idx = only(findall(x -> x.name == filename, archive.files))
return CSV.read(read(archive.files[idx]), DataFrame)
end

edges = edges_df = ingest_to_df(git_archive,
"git_web_ml/musae_git_edges.csv");

classes_df = ingest_to_df(git_archive,
"git_web_ml/musae_git_target.csv");

close(git_archive)