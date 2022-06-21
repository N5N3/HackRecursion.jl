module HackRecursion
using MacroTools

function get_method_type(spex)
    name, args = spex[:name], spex[:args]
    param = Dict{Symbol,Any}()
    for ex in spex[:whereparams]
        if ispexpr(ex, :<:)
            param[ex.args[1]] = ex.args[2]
        else
            param[ex::Symbol] = :Any
        end
    end
    MT = if name isa Symbol
        :(Tuple{typeof($name)})
    elseif ispexpr(name, :(::))
        T = last(name.args)
        :(Tuple{$(get(param, T, T))})
    end
    for ex in args
        if ex isa Symbol
            push!(MT.args, :Any)
        else
            T = splitarg(ex)[2]
            push!(MT.args, get(param, T, T))
        end
    end
    return MT
end

"""
    @reduce f(x, [y]) = g((x..., y[1]), Base.tail(y))
    f(x, ::Tuple{}) = x, ()
"""
macro reduce(ex)
    lex = MacroTools.longdef(ex)
    spex = MacroTools.splitdef(lex)
    isempty(spex[:kwargs]) || throw(ArgumentError("kwargs function is not supported"))
    reduceid = nothing
    if isexpr(spex[:name], :vect)
        spex[:name] = only(spex[:name].args)
        reduceid = 1
    else
        args = spex[:args]
        for i in eachindex(args)
            if isexpr(args[i], :vect)
                args[i] = only(args[i].args)
                reduceid = i + 1
                break
            end
        end
    end
    reduceid === nothing && error("no reduce argument")
    return quote
        local f = $(esc(MacroTools.combinedef(spex)))
        Base.which($(esc(get_method_type(spex)))).recursion_relation = 
            function(method1, method2, parent_sig, new_sig)
                par = Tuple{fieldtype(parent_sig, $reduceid)}
                new = Tuple{fieldtype(new_sig, $reduceid)}
                Core.Compiler.type_more_complex(new, par, Core.svec(par), 1, 3, 1)
            end
        f
    end
end

end
