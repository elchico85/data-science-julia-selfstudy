using LinearAlgebra
using Plots

# Definiamo la matrice A
A = [2 1;
     1 2]

# Calcoliamo autovalori e autovettori
E = eigen(A)

λ = E.values         # autovalori
V = E.vectors        # colonne = autovettori

println("Autovalori: ", λ)
println("Autovettori (colonne): \n", V)

# Visualizziamo la trasformazione
plot(title="Autovettori e trasformazione A*v", size=(600, 600), legend=:bottomright, aspect_ratio=1)
xlims!(-3, 3)
ylims!(-3, 3)

# Griglia di vettori nel piano
for θ in 0:π/8:2π
    v = [cos(θ), sin(θ)]
    Av = A * v

    # Disegniamo il vettore originale e trasformato
    quiver!([0.0], [0.0], quiver=([v[1]], [v[2]]), color=:gray, lw=1, label=false)
    quiver!([0.0], [0.0], quiver=([Av[1]], [Av[2]]), color=:blue, lw=1, label=false)
end

# Disegniamo gli autovettori e le loro immagini
colors = [:red, :green]
for i in 1:2
    v = V[:, i]
    Av = A * v
    λi = λ[i]

    quiver!([0.0], [0.0], quiver=([v[1]], [v[2]]), color=colors[i], lw=3, label="v$i")
    quiver!([0.0], [0.0], quiver=([Av[1]], [Av[2]]), color=colors[i], linestyle=:dash, lw=3, label="λ$i * v$i")
end

display(plot!)
