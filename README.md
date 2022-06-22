# HackRecursion

A simple package to help inference on (self) recursion function.

## Usage
This package provides `HackRecursion.@reduce` to mark a recursion function as reduced, i.e. at least one argument (or the callable object itself) shrinks during recursion. The shrinking argument should be wrapped with a `[]`.

A simple example:
1. Define `f` without `@reduce`
```julia
julia> f(x, y::NTuple{N,Any}, ::Val{N}) where {N} = x, y
f (generic function with 1 method)

julia> f(::Tuple{}, y, ::Val) = (), y
f (generic function with 2 methods)

julia> f(x, y, val::Val) = f(Base.tail(x), (y..., x[1]), val)
f (generic function with 3 methods)
```

2. Test inferability
```julia
julia> Base.return_types(f, Base.typesof((1,2,3,4,5,6), (), Val(2)))
1-element Vector{Any}:
 Tuple{NTuple{4, Int64}, Tuple{Int64, Int64}}

julia> Base.return_types(f, Base.typesof((1,2,3,4,5,6), (), Val(3)))
1-element Vector{Any}:
 Union{Tuple{Tuple{Int64, Int64, Int64}, Tuple{Int64, Int64, Int64}}, Tuple{Union{Tuple{}, Tuple{Int64}, Tuple{Int64, Int64}}, Tuple{Vararg{Int64}}}}
```
As shown above, we touch the inference limitation with `Val(3)`

3. Redefine `f` with `@reduce`
```julia
julia> using HackRecursion

julia> HackRecursion.@reduce f([x], y, val::Val) = f(Base.tail(x), (y..., x[1]), val) # Here, `[x]` marks the first argument as reduced.
f (generic function with 3 methods)

julia> Base.return_types(f, Base.typesof((1,2,3,4,5,6), (), Val(3)))
1-element Vector{Any}:
 Tuple{Tuple{Int64, Int64, Int64}, Tuple{Int64, Int64, Int64}}

julia> Base.return_types(f, Base.typesof((1,2,3,4,5,6), (), Val(4)))
1-element Vector{Any}:
 Tuple{Tuple{Int64, Int64}, NTuple{4, Int64}}
```

## Limitation
1. Multiple `[]`s require the marked the arguments reducing at the same time.
2. `kwargs` and `Vararg` are not supported.
