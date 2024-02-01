include(raw"console$import.jl")

# * 扩展的实用函数库 * #

"扩展的input方法：支持直接输入整数类型"
function input(prompt::AbstractString, ::Type{N}, default::Union{Nothing,N}=nothing) where {N<:Number}
    local inp::String = input(prompt)
    # 输入后空值合并
    something(tryparse(N, inp), default)
end

"扩展的input方法：支持直接输入符号类型"
input(prompt::AbstractString, ::Type{Symbol})::Symbol = Symbol(input(prompt))
