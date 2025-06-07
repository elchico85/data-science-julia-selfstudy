using CSV
using DataFrames
using CategoricalArrays
using DataFramesMeta
using Dates
using Distributions
import Downloads
using FreqTables
using GLM
using Plots
using Random
using ROCAnalysis
using SHA
using Statistics
import ZipFile

function verify()
    sqrt(sum(1:8)) == @chain 1:8 begin 
        sum 
        sqrt 
    end
end


url_zip = "https://stacks.stanford.edu/file/druid:yg821jf8611/" *
"yg821jf8611_ky_owensboro_2020_04_01.csv.zip"; #URL of the file we want to fetch

local_zip = "owensboro.zip"; #Local file name to save the zip file

isfile(local_zip) || Downloads.download(url_zip, local_zip) #Download the file if it does not exist

open(sha256, local_zip) == [0x14, 0x3b, 0x7d, 0x74,
0xbc, 0x15, 0x74, 0xc5,
0xf8, 0x42, 0xe0, 0x3f,
0x8f, 0x08, 0x88, 0xd5,
0xe2, 0xa8, 0x13, 0x24,
0xfd, 0x4e, 0xab, 0xde,
0x02, 0x89, 0xdd, 0x74,
0x3c, 0xb3, 0x5d, 0x56] #Verify the SHA256 checksum of the downloaded file

archive = ZipFile.Reader(local_zip) #Open the zip file

owensboro = @chain archive begin
only(_.files)
read
CSV.read(DataFrame; missingstring="NA")
end; #Extracts the CSV file from the archive and loads it into a DataFrame; treats NA values as missing by using the @chain

close(archive) #Close the archive  

select!(owensboro, :date, :type, :arrest_made, :violation); #Select only the relevant columns from the DataFrame!!

""" Data Frame available functions: 
combine: Performs column transformations following operation specification
syntax, allowing for changing the number of rows in the source (typically, com-
bining multiple rows into one row—that is, aggregating them)

select: Performs column transformations following operation specification
syntax with the restriction that the result will have the same number of rows and
in the same order as the source

select!: The same as select, but updates the source in place

transform: The same as select, but always keeps all columns from the source

transform!: The same as transform, but updates the source in place

df = DataFrame(id=[1, 2, 1, 2], v=1:4)

combine(df, :v => sum => :somma) # esempio 1

transform(df, :v => sum => :sum) # esempio 2

combine(df, :v => sum => :somma, :id => sum => :somma2) # per COILS

Potrei raggruppare (groupby -split action) per id coil, (apply action, ..sum=>..) sommare i sommabili tipo lunghezza e diametro, e lasciare gli
altri invariati, e ricombinare (combine) il tutto in un nuovo DataFrame.


"""

agg_violation = @chain owensboro begin
select(:violation =>
ByRow(x -> strip.(split(x, ";"))) =>
:v)
flatten(:v)
select(:v =>
ByRow(x -> contains(x, "SPEEDING") ? "SPEEDING" : x) =>
:v)
groupby(:v)
combine(nrow => :count)
sort(:count, rev=true)
end # Count the number of occurrences of each violation type, flatting Speed violations into a single category.

#using DataFramesMeta

@chain owensboro begin
@rselect(:v=strip.(split(:violation, ";")))
flatten(:v)
@rselect(:v=contains(:v, "SPEEDING") ? "SPEEDING" : :v)
groupby(:v)
combine(nrow => :count)
sort(:count, rev=true)
end # The same as above, but using DataFramesMeta for a more concise syntax.

owensboro2 = select(owensboro,
:arrest_made => :arrest,
:date => ByRow(dayofweek) => :day,
:type,
[:violation =>
ByRow(x -> contains(x, agg_violation.v[i])) =>
"v$i" for i in 1:4])

weekdays = DataFrame(day=1:7,
dayname=categorical(dayname.(1:7);
ordered=true))

levels(weekdays.dayname)

levels!(weekdays.dayname, weekdays.dayname)

leftjoin!(owensboro2, weekdays; on=:day)

"""
freqtable(owensboro2, :dayname, :day) ---> matrice

@chain owensboro2 begin
groupby([:day, :dayname]; sort=true)
combine(nrow)
unstack(:dayname, :day, :nrow; fill=0)
end -----> stesso risultato di prima ma dataframe
"""

dropmissing!(owensboro2)
select!(owensboro2, Not(:day))

#preparing the data for modeling
Random.seed!(1234);
owensboro2.train = rand(Bernoulli(0.7), nrow(owensboro2));
train = subset(owensboro2, :train)
test = subset(owensboro2, :train => ByRow(!))

model = glm(@formula(arrest~dayname+type+v1+v2+v3+v4),
train, Binomial(), LogitLink())

train.predict = predict(model)
test.predict = predict(model, test)

test_groups = groupby(test, :arrest);

histogram(test_groups[(false,)].predict;
bins=10, normalize=:probability,
fillstyle= :/, label="false")

histogram!(test_groups[(true,)].predict;
bins=10, normalize=:probability,
fillalpha=0.5, label="true")

@chain test begin
@rselect(:predicted=:predict > 0.15, :observed=:arrest)
proptable(:predicted, :observed; margins=2)
end

test_roc = roc(test; score=:predict, target=:arrest)

plot(test_roc.pfa, test_roc.pmiss;
color="black", lw=3,
label="test (AUC=$(round(100*auc(test_roc), digits=2))%)",
xlabel="pfa", ylabel="pmiss")

train_roc = roc(train, score=:predict, target=:arrest)

plot!(train_roc.pfa, train_roc.pmiss;
color="gold", lw=3,
label="train (AUC=$(round(100*auc(train_roc), digits=2))%)")