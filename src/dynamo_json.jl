#                _       _ _
#  ___  ___ _ __(_) __ _| (_)_______
# / __|/ _ \ '__| |/ _` | | |_  / _ \
# \__ \  __/ |  | | (_| | | |/ /  __/
# |___/\___|_|  |_|\__,_|_|_/___\___|

const null_attr = Dict{AbstractString, Any}("NULL" => true)

# general objects
function attribute_value(x)
    r = Dict{String, Any}()
    for e=fieldnames(x)
        r[string(e)] = null_or_val(getfield(x,e))
    end
    Dict{String, Any}("M" => r)
end

# TODO -- binary?
attribute_value(x :: Bool) = Dict{AbstractString, Any}("BOOL" => x)
attribute_value(x :: Real) = Dict{AbstractString, Any}("N" => string(x))
attribute_value(x :: AbstractString) = Dict{AbstractString, Any}("S" => x)

attribute_value(x :: Array) =
    Dict{AbstractString, Any}("L" => [attribute_value(e) for e=x])
attribute_value{T <: Real}(x :: Set{T}) =
    Dict{AbstractString, Any}("NS" => [string(e) for e=x])
attribute_value{T <: AbstractString}(x :: Set{T}) =
    Dict{AbstractString, Any}("SS" => [e for e=x])
# TODO -- n-dimensional arrays

function attribute_value(x :: Dict)
    dict = Dict{String, Any}()
    for (k,v)=x
        dict[string(k)] = null_or_val(v)
    end
    Dict{String, Any}("M" => dict)
end

null_or_val(x) = x == nothing ? null_attr : attribute_value(x)


#      _                     _       _ _
#   __| | ___  ___  ___ _ __(_) __ _| (_)_______
#  / _` |/ _ \/ __|/ _ \ '__| |/ _` | | |_  / _ \
# | (_| |  __/\__ \  __/ |  | | (_| | | |/ /  __/
#  \__,_|\___||___/\___|_|  |_|\__,_|_|_/___\___|

bool_val(val :: Bool) = val
function bool_val(val :: AbstractString)
    if lowercase(val) == "false"
        return false
    elseif lowercase(val) == "true"
        return true
    else
        error("Received non-boolean value for boolean typed data: $val")
    end
end

real_val(val :: Real) = val
real_val(val :: AbstractString) = parse(Float64, val)

function value_from_attributes(hash :: Dict)

    ks = keys(hash)
    if length(ks) != 1
        error("multiple type keys provided in DynamoDB typed JSON value")
    end

    ty = first(ks)
    val = hash[ty]

    if ty == "NULL"     ; return nothing
    elseif ty == "BOOL" ; return bool_val(val)
    elseif ty == "N"    ; return real_val(val)
    elseif ty == "S"    ; return val
    elseif ty == "L"    ; return [value_from_attributes(e) for e in val]
    elseif ty == "NS"   ; return Set{Real}([float(e) for e in val])
    elseif ty == "SS"   ; return Set{AbstractString}(val)
    elseif ty == "M"
        m = Dict{AbstractString, Any}()
        for (k, v)=val
            m[string(k)] = value_from_attributes(v)
        end
        return m
    else
        error("Unknown datatype value in DynamoDB typed JSON value: $ty")
    end
end

function value_from_attributes(ty :: Type, typed_json :: Dict)

    vals = value_from_attributes(Dict("M" => typed_json))

    if ty <: Dict
      return vals
    else
      init_vals = [vals[string(e)] for e=fieldnames(ty)]
      return ty(init_vals...)
    end

end
