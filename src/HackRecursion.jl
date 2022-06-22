module HackRecursion
using MacroTools
using Core.Compiler: type_more_complex
using Core: svec

function get_method_type(spex)
    name, args = spex[:name], spex[:args]
    param = Dict{Symbol,Any}()
    for ex in spex[:whereparams]
        if isexpr(ex, :<:)
            param[ex.args[1]] = ex.args[2]
        else
            param[ex::Symbol] = :Any
        end
    end
    MT = if name isa Symbol
        :(Tuple{typeof($name)})
    elseif isexpr(name, :(::))
        T = last(name.args)
        :(Tuple{$(get(param, T, T))})
    end
    issplat = false
    for ex in args
        issplat && throw(ArgumentError("Invalid method definition"))
        if ex isa Symbol
            push!(MT.args, :Any)
        else
            T = splitarg(ex)[2]
            if isexpr(T, :curly) && T.args[1] == :Vararg
                ET = get(param, T.args[2], T.args[2])
                if length(T.args) === 3 && !haskey(param, T.args[3])
                    push!(MT.args, :(Vararg{$ET,$(T.args[3])}))
                else
                    push!(MT.args, :(Vararg{$ET}))
                end
                issplat = true
            else
                push!(MT.args, get(param, T, T))
            end
        end
    end
    return MT, issplat
end

function handle_splat(ex)
    name, type, splat, default = MacroTools.splitarg(ex)
    if splat && default === nothing
        MacroTools.combinearg(name, :(Vararg{$type}), false, nothing)
    else
        MacroTools.combinearg(name, type, splat, default)
    end
end

gen_sig(sig, id, splat = false) = if splat
    quote
        let sig = $sig
            for _ = 1:$(id[end] - 1)
                sig = Base.tuple_type_tail(sig)
            end
            tuple($((:(fieldtype($sig, $i)) for i in id[1:end-1])...), sig)
        end
    end
else
    :(tuple($((:(fieldtype($sig, $i)) for i in id)...)))
end

"""
    @reduce f(x, [y]) = g((x..., y[1]), Base.tail(y))
    f(x, ::Tuple{}) = x, ()
"""
macro reduce(ex)
    lex = MacroTools.longdef(ex)
    spex = MacroTools.splitdef(lex)
    isempty(spex[:kwargs]) || throw(ArgumentError("kwargs function is not supported!"))
    reduced = Int[]
    if isexpr(spex[:name], :vect)
        spex[:name] = only(spex[:name].args)
        push!(reduced, 1)
    end
    args = spex[:args]::Vector{Any}
    for i in eachindex(args)
        if isexpr(args[i], :vect)
            args[i] = only(args[i].args)
            push!(reduced, i + 1)
        end
    end
    args[end] = handle_splat(args[end])
    isempty(reduced) && throw(ArgumentError("Reduced argument list is empty!"))
    MT, issplat = get_method_type(spex)
    issplat && throw(ArgumentError("Vararg is not supported!"))
    return quote
        local f = $(esc(MacroTools.combinedef(spex)))
        which($(esc(MT))).recursion_relation = 
            function(_, _, parent_sig, new_sig)
                par = $(gen_sig(:parent_sig, reduced))
                new = $(gen_sig(:new_sig, reduced))
                for (n, p) in zip(new, par)
                    type_more_complex(n, p, svec(p), 1, 3, 1) || return false
                end
                return true
            end
        f
    end
end

end
