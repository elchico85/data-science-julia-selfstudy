function print_supertypes(T)
    # Print the supertype of T
    println(T)
    T== Any || print_supertypes(supertype(T))
    return nothing
end
