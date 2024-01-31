module MutableArgumentContracts

export @!, MutableArgument

struct MutableArgument{T}
    obj::T
end

"""
    @!

Create a function signature that enforces self-documentation of which arguments may
be mutated by the function via dispatching.

Declare a mutating function that specifies that arguments `x` and `y` may be mutated:
```jldoctest
julia> @! function foo!(x::!, y::!{T}, z) where T # Equivalent to foo!(x, y::T, z) where T
    x .+= y .+ z
end;

julia> a = [1, 2, 3];

julia> b = [3, 2, 1];

julia> foo!(@!(a), @!(b), 3); # Call a mutating function

julia> a
3-element Vector{Int64}:
 7
 7
 7
```
"""
macro !(obj)
    if obj isa Expr && obj.head === :function
        funcheader = obj.args[1]
        funcbody = obj.args[2]
        if funcheader.head === :where
            funcsig = funcheader.args[1]
        else
            funcsig = funcheader
        end
        # unwrap mutables in function signature
        funcargs = funcsig.args[2:end]
        mutableargs = Symbol[]
        for a ∈ funcargs
            a isa Expr && a.head == :(::) || continue
            if a.args[2] === :!
                a.args[2] = :MutableArgument
                push!(mutableargs, a.args[1])
            elseif a.args[2] isa Expr && a.args[2].head === :curly
                a.args[2].args[1] === :! || continue
                a.args[2].args[1] = :MutableArgument
                push!(mutableargs, a.args[1])
            end
        end
        if funcbody.head === :block
            blockargs = funcbody.args
            letblock = :(let; end)
            unwrappedargs = letblock.args[1].args
            for muta ∈ mutableargs
                push!(unwrappedargs, :($muta = $muta.obj))
            end
            letblock.args[2] = :(begin; end)
            letblock.args[2].args = blockargs
            funcbody.args = [letblock]
        else
            error("Non-block function body?")
        end
        return esc(obj)
    else
        # wrap parameter
        return esc(:(MutableArgument($obj)))
    end
end

#=


=#





end
