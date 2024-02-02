# MutableArgumentContracts.jl

Proof-of-concept for constructing a function signature that documents which arguments the function mutates, and forces the caller to acknowledge and document the same.

It is simply implemented using a wrapper type, `MutableArgument{T}`. The function is specified by prepending the function with `@!` and indicating which arguments are mutable by specifying the type as `::!` or `::!{T}` (for Any or T, respectively). The arguments are unwrapped but keep the same name with a hidden `let` block. Wrapping of an argument `x` at the call site is performed by `@!(x)`.

For example:

```
@! function foo!(x::!, y::!{T}, z) where {T}
    x .+= y .+= z
end
```

expands to

```
function foo!(x::MutableArgument, y::MutableArgument{<:T}, z) where {T}
    let x = x.obj, y = y.obj
        x .+= y .+= z
    end
end
```

and this function must be called by

```
a = [1, 2, 3];
b = [3, 2, 1];
foo!(@!(a), @!(b), 3)
```

Note that there is no mechanism to enforce proper usage. It is dependent on the function author to accurately specify which arguments can be mutated. The only intent is to ensure caller and callee
agree on and both document the mutable arguments.
