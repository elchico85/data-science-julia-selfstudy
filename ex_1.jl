using Debugger
# Esempio di codice Julia con Debugger
function calcola_area(base::Float64, altezza::Float64)
    risultato = 0.5 * base * altezza
    println("Dentro calcola_area: risultato = ", risultato)
    return risultato
end

function programma_principale()
    b = 10.0
    h = 5.0
    println("Dentro programma_principale, prima della chiamata.")
    area_triangolo = calcola_area(b, h)
    println("Dentro programma_principale, dopo la chiamata: area = ", area_triangolo)
end

programma_principale()
Debugger.@run programma_principale()
println("Finito.")