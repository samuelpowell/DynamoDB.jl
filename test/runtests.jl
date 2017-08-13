using AWSCore
using DynamoDB
using JSON
using Base.Test

mutable struct Foo
    a
    b
end

# tests on component functions
include("dynamo_json.jl")
include("dynamo_dsl.jl")
include("dynamo.jl")
include("dynamo_row_ops.jl")

# live tests
include("integration_tests.jl")
