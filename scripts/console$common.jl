include(raw"console$import.jl")

"统一的「CIN路径配置」类型"
const CINPaths = Dict{String,Pair{CINType,String}}

"统一的「CIN配置名称」类型"
const CINName = String

"统一的「命令行参数字典」类型"
const ArgDict = Dict{String,Any}

# * 扩展的实用函数库 * #

"从表达式中获取形如「f(x) = 2x」的定义名称`:f`（兼容普通赋值、函数`function`的定义方式）"
function get_expr_definition_name(expr::Union{Symbol,Expr})::Symbol
    local result::Union{Symbol,Expr} = expr
    # 不断取参数中的第一个参数，直到为 Symbol 为止
    while !(result isa Symbol)
        result = result.args[begin]
    end
    # 返回符号
    return result
end

"宏：未定义符号时执行代码"
macro_defined_or(symbol, or) = :(
    @isdefined($symbol)
    ? $symbol
    : $or
) |> esc

"宏：软定义符号（只有在「符号未定义」时定义变量）"
macro_soft_define(expr_def) = macro_defined_or(
    # 要么「定义名」未定义
    get_expr_definition_name(expr_def),
    # 要么执行定义
    expr_def
)

"未定义符号时执行 完整宏"
macro defined_or(symbol, expr_def)
    macro_defined_or(symbol, expr_def)
end

"软定义符号 完整宏"
macro soft_define(expr_def)
    macro_soft_define(expr_def)
end

"软定义符号 宏简写"
macro soft_def(expr_def)
    macro_soft_define(expr_def)
end

#= let a = 2, f(x) = 2x # 测试代码
    @soft_define a = 3 # 软定义会失败
    @assert a == 2 # 仍然是原先的值
    @soft_define f(x) = x # 软定义会失败
    @assert f(1) == 2 # 仍然是原先的值
    @assert (@defined_or a 3) == 2 # 已经有a了，那就取a的值
    # @assert (@defined_or f(1) x) == 2
end =#

# 尝试补充默认input方法
@soft_def function input(prompt::String)
    print(prompt)
    return readline()
end

"扩展的input方法：支持自带默认值"
function input(prompt::String, default)
    print(prompt)
    local inp = readline()
    return isempty(inp) ? default : inp
end

"扩展的input方法：支持直接输入整数类型"
function input(prompt::AbstractString, ::Type{N}, default=nothing) where {N<:Number}
    local inp::String = input(prompt)
    # 输入后空值合并
    something(tryparse(N, inp), default)
end

"扩展的input方法：支持直接输入符号类型"
function input(prompt::AbstractString, ::Type{Symbol}, default=nothing)
    local inp = input(prompt)
    return (
        isempty(inp) ?
        default :
        Symbol(inp)
    )
end

#= input("num? (123): ", Int, 123)
input("num? (123): ", Int, 123)
input("type? (nothing): ", Symbol, nothing)
input("type? (nothing): ", Symbol, nothing) =#

"复刻[something](@ref)、[coalesce](@ref)函数，返回非空的第一个值"
function nonempty end

nonempty() = throw(ArgumentError("No value arguments present"))
nonempty(x) = x
nonempty(x, default) = isempty(x) ? default : x
nonempty(x, args...) = isempty(x) ? nonempty(args...) : x

"复刻惰性求值的[@something](@ref)宏"
macro nonempty(args...)
    expr = ""
    for arg in reverse(args)
        expr = :(val = $(esc(arg)); isempty(val) ? ($expr) : val)
    end
    nonempty = GlobalRef(Main, :nonempty)
    return :($nonempty($expr))
end
