using Plots
using Statistics

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

all_dice= [[1, x2,x3,x4,x5,x6]
       for x2 in 2:11
       for x3 in x2:11
       for x4 in x3:11
       for x5 in x4:11
       for x6 in x5:11]

#two_standard

#scatter(two_standard)

#test=Dict.. è un dizionario che contiene il test delle somme dei dadi modificati 
for d1 in all_dice, d2 in all_dice
       test= Dict{Int,Int}() #crea dizionario test
       for i in d1, j in d2 #inizilizza secondo ciclo for
           s = i+j # somma dei due dadi
           if haskey(test, s) #controllo se in test che inizializzo alla riga successiva è presente la somma calcolata
           test[s] +=1 #se è presente aggiugno una visualizzazione al dizionario
           else
           test[s] = 1 #se è la prima volta che lo vedo allora quel numero avrà un cumulativo di 1
        end
    end
           if test == two_standard #dopo aver effettuato tutta la distribuzione, controllo quali fra tutte le somme corrisponde a quella con two_standard
           println(d1," ",d2) #" " è lo spazio per una migliore lettura
           end
end

"""Nota: la soluzione contiene la sequenza 1 2 3 4 5 6 che ci aspettavamo. Invece le altre due sequenze sono una l'inverso dell'altra
in altre parole, una soluzione rappresente d1+d2 e l'altra d2+d1. Le distrubuzioni sono simmetriche e indistinguibili da quelle
dei dadi standard. 
"""
