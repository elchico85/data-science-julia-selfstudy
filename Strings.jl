using FreqTables
using Plots
using InlineStrings
#Retrieve data
movies = readlines("movies.dat")
movie1 = first(movies)
movie1_parts= split(movie1, "::")

# Extract the title and year with regular expressions
rx= r"(.+) \((\d{4})\)$"

function parseline(line::AbstractString)
    parts = split(line, "::") #splitta il la stringa "line" in base al delimitatore "::"
    m=match(rx, parts[2]) #applica la regex al secondo elemento della lista
    return (id=parts[1], #ritorna una tupla nominata con i campi id
            name=m[1],             #ritorna il nome parsato dalla regex
            year=parse(Int,m[2]),  #ritorna l'anno parsato dalla regex
            genres=split(parts[3], "|")) # prende il terzo elemento e lo splitta ancora in base al delimitatore "|"
end

records=parseline.(movies) #applica la funzione parseline a tutti gli elementi della lista movies

genres=String[]

for record in records
    append!(genres, record.genres) #aggiunge alla lista genres i generi di ogni film
end

genres;

table= freqtable(genres) #crea una tabella di frequenza dei generi

sort!(table)

years= [record.year for record in records] #comprehension

has_drama = ["Drama" in record.genres for record in records] #comprehension

drama_prop= proptable(years, has_drama;margins=1)

