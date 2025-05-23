using DataFrames
using Random # For generating mock data

# --- 1. Create a Mock 'coils' DataFrame ---
Random.seed!(123) # for reproducibility
n_rows = 100 # Let's use 100 for the example, but it scales to 9000
coatings = ["None", "Zinc", "PaintA", "PaintB"]
qualities = ["Prime", "Secondary", "Defective"]
steel_grades = ["S235", "S275", "S355"]

coils = DataFrame(
    id = 1:n_rows,
    coating = rand(coatings, n_rows),
    quality = rand(qualities, n_rows),
    thickness_mm = rand(0.5:0.1:5.0, n_rows),
    width_mm = rand(800:50:1500, n_rows),
    weight_kg = rand(1000:100:10000, n_rows),
    steel_grade = rand(steel_grades, n_rows)
)

println("Original DataFrame preview:")
println(first(coils, 5))
println("...\n")