"用于快速启动交互式CIN控制台（带有可选的Websocket服务器）"

#=
# !📝同名异包问题：直接导入≠间接导入 ! #
    ! 当在「加载路径」添加了太多「本地值」时，可能会把「依赖中的本地包」和「加载路径上的本地包」一同引入
    * 这样的引入会导致「看似都是同一个包（这里是BabelNAR），
      * 但实际上『从本地直接引入的一级包』和『从本地其它包二级引入的同名包』不一样」的场景
    * 本文件的例子就是：从`LOAD_PATH`和`BabelNAR_Implements`分别引入了俩`BabelNAR`，一个「纯本地」一个「纯本地被引入」
    * 📌没意识到的就是：这俩包 居 然 是 不 一 样 的
    ! 于是就会发生冲突——或者，「奇怪的不相等」
    * 比如「同样都是一个位置的同名结构」，两个「NARSType」死活不相等
    * ——就是因为「一级本地包中的 NARSType」与「二级本地包中的 NARSType」不一致
    * 然后导致了「缺方法」的假象
        * 一个「一级本地类A1」配一个「二级本地类B2」想混合着进函数f，
        * 结果`f(a::A1, b::B1)`和`f(a::A2, b::B2)`都匹配不上
    * 于是根子上就是「看起来`BabelNAR.CIN.NARSType`和`NARSType`是一致的，但实际上不同的是`BabelNAR`和`BabelNAR_Implements.BabelNAR`」的情况
    * 记录时间：【2023-11-02 01:36:43】
=#

# 条件引入
@isdefined(BabelNAR_Implements) || include(raw"console$common.jl")

# * 所有CIN配置：程序类型、启动命令、转译函数……
CIN_CONFIGS::CINConfigDict = NATIVE_CIN_CONFIGS
# 合并可选的「附加配置」
ispath("CINConfig_extra.local.jl") && merge!(
    CIN_CONFIGS,
    include("CINConfig_extra.local.jl")
)

# * 获取可执行文件路径配置
CIN_PATHS::CINPaths = let
    dict::Dict = include("CIN-paths.local.jl")
    #= # * 以下为示例内容（最后更新于2024-01-22 22:32:43 @ Windows 10）
    # ! 文件的上下文由`console.jl`提供
    # 获取文件所在目录的上一级目录（包根目录）
    # EXECUTABLE_ROOT = joinpath(dirname(dirname(@__DIR__)), "executables")
    "函数式计算相对路径：生成一个「文件名 -> 完整路径」的函数"
    join_root(n::Integer, bases::Vararg{AbstractString}; root=@__DIR__) = (
        n == 0
            ? name -> joinpath(root, bases..., name)
            # 惰性递归求值（只有在传递参数的时候，才真正开始求函数）
            : name -> join_root(n-1, bases...; root=dirname(root))(name)
    )

    Dict([
        TYPE_OPENNARS => "opennars.jar" |> join_root(2, "executables")
        TYPE_ONA => "NAR.exe" |> join_root(3, "NAR", "OpenNARS-for-Applications")
        TYPE_NARS_PYTHON => "main.exe" |> join_root(2, "executables")
        TYPE_OPEN_JUNARS => "" |> join_root(3, "NAR", "OpenJunars")
        TYPE_PYNARS => "launch-pynars-console-plus.cmd" |> join_root(2, "executables")
    ])
    =#

    # 规整化路径：名 => (CIN模式 => 完整路径)
    CINPaths(
        (
            mode_path isa Pair
            ? string(name) => (Symbol(first(mode_path)) => string(last(mode_path)))
            : string(name) => (Symbol(name) => string(mode_path))
        )
        for (name, mode_path) in dict
    )
end

# 检查路径合法性
for (name, (mode, path)) in CIN_PATHS
    @assert ispath(path) "CIN路径不合法：$path"
end

"根据类型获取可执行文件路径 | 字典结构：`名称 => (CIN类型 => 路径)`"
main_CIN_path(name::String)::CINName = last(CIN_PATHS[name])

"根据类型获取可执行文件路径 | 字典结构：`名称 => (CIN类型 => 路径)`"
main_CIN_type(name::String)::CINType = first(CIN_PATHS[name])

"""
用于从各种不完整输入中灵活锁定CIN名称
"""
function match_CIN_name(name_to_index::AbstractString, CIN_paths::CINPaths)::Union{String,Nothing}

    "用于对比的字符串" # ! 全部转换成小写字母（忽略大小写）
    local name_str_comp = lowercase(name_to_index)
    "用于对比的配置键"
    local type2_comp::CINName

    # * 合法⇒返回 | 优先级：相等⇒前缀⇒后缀⇒被包含⇒包含（原有，输入）
    for condition_f in [isequal, startswith, endswith, occursin, contains]
        # * 层层条件过滤
        for type2::CINName in keys(CIN_paths)

            type2_str_comp = lowercase(type2)
            # 最后返回的还是「名称」而非「对比用的字符串」
            condition_f(type2_str_comp, name_str_comp) && return type2
        end
    end

    # 默认返回空
    return nothing
end

"""
用于获取用户输入的「NARS类型」
- 逻辑：不断判断「是否有效」
    - 有效⇒返回
    - 无效⇒要求再次输入
- 字典类型 Dict{名称::String,Pair{CIN类型::CINType,路径::String}}
    - 结构：`名称 => (CIN类型 => 路径)`
"""
function get_valid_NARS_name_from_input(
    CIN_paths::CINPaths;
    default_name::CINName,
    input_prompt::String="NARS Type [$(join(keys(CIN_paths), '|'))] ($default_name): "
)::CINName

    "与输入匹配的字符串 | 可能为空"
    local name_matched::Union{CINName,Nothing}

    while true
        name_matched = match_CIN_name(
            input(input_prompt, default_name),
            CIN_paths
        )

        # * 非空⇒返回
        isnothing(name_matched) || return name_matched

        # * 非法⇒警告⇒重试
        printstyled("Invalid Type $(name_str_index)!\n"; color=:red)
    end

    # ! 永远不会运行到这里
end

# * CIN输出相关 * #

# * 转译CIN输出，生成「具名元组」数据（后续编码成JSON，用于输出）
@soft_def function main_output_interpret(::Val, CIN_config::CINConfig, line::String)
    # * 现在使用NAVM进行解析
    return CIN_config.output_interpret(line)
    # ! ↓ 弃用代码
    #= local objects::Vector{NamedTuple} = NamedTuple[]

    local head = findfirst(r"^\w+:", line) # EXE: XXXX # ! 只截取「开头纯英文，末尾为『:』」的内容

    isnothing(head) || begin
        push!(objects, (
            interface_name="BabelNAR@$(nars_type)",
            output_type=line[head][begin:end-1],
            content=line[last(head)+1:end]
        ))
    end

    return objects =#
end

"""
用于高亮「输出颜色」的字典
"""
const output_color_dict = Dict([
    NARSOutputType.IN => :light_white
    NARSOutputType.OUT => :light_white
    NARSOutputType.EXE => :light_cyan
    NARSOutputType.ANTICIPATE => :light_yellow
    NARSOutputType.ANSWER => :light_green
    NARSOutputType.ACHIEVED => :light_green
    NARSOutputType.INFO => :white
    NARSOutputType.COMMENT => :white
    NARSOutputType.ERROR => :light_red
    NARSOutputType.OTHER => :light_black # * 未识别的信息
    # ! ↓这俩是OpenNARS附加的
    "CONFIRM" => :light_blue
    "DISAPPOINT" => :light_magenta
])

"""
用于分派「颜色反转」的集合
"""
const output_reverse_color_dict = Set([
    NARSOutputType.EXE
    NARSOutputType.ANSWER
    NARSOutputType.ACHIEVED
])

"""
根据JSON输出打印信息
- 要求output具有`output_type`、`content`两个字段
"""
print_NARSOutput(output) = printstyled(
    "[$(output.output_type)] $(output.content)\n";
    # 样式
    color=get(output_color_dict, output.output_type, :default),
    reverse=output.output_type in output_reverse_color_dict,
    bold=true, # 所有都加粗，以便和「程序自身输出」对比
)

# * 主函数 * #

# * 基于 ArgParse.jl 的参数解析表 | 从外部引入一个匿名函数
@soft_def arg_parse_settings = include(raw"console$arg_parse.jl")

# * 解析命令行参数
@soft_def function cmdline_args_dict(ARGS)::ArgDict

    @isdefined(ArgParse) || return ArgDict()

    return parse_args(ARGS, arg_parse_settings())
end

# * 获取NARS类型
@soft_def function main_CIN_name(default_name::CINName, CIN_paths::CINPaths; arg_dict::ArgDict)::CINName

    global not_VSCode_running

    # * 命令行参数中已指定⇒使用命令行参数值做匹配
    isnothing(arg_dict["type"]) || return @show match_CIN_name(arg_dict["type"], CIN_paths)

    # * 在VSCode中运行⇒返回默认值
    not_VSCode_running || return default_name

    # * 默认情况：请求输入
    return get_valid_NARS_name_from_input(
        CIN_paths;
        default_name
    )
end

# * 生成NARS终端
@soft_def main_console(name::CINName, type::CINType, path::String, CIN_configs; arg_dict::ArgDict) = NARSConsole(
    type,
    CIN_configs[type],
    path;
    input_prompt="BabelNAR.$name> ",
    on_out=(line::String) -> begin
        local outputs = main_output_interpret(
            Val(Symbol(type)),
            CIN_configs[type],
            line
        )
        for output in outputs
            print_NARSOutput(output)
        end
    end
)

# * 启动！
@soft_def main_launch(console; arg_dict::ArgDict) = launch!(
    console,
    ( # 可选的「服务器」
        (@isdefined(IP) && @isdefined(PORT)) ?
        (IP, PORT) : tuple()
    )...,
    # *【2024-01-22 23:19:51】使用0.1s的延迟，让CIN先将自身文本输出完，再打印提示词✅
    delay_between_input=0.1
)

"常量「默认类型」"
const DEFAULT_NAME = string(TYPE_OPENNARS)

"""
主函数（不建议覆盖）
"""
function main(ARGS::Vector{String}=[])

    "<================BabelNAR Console================>" |> println

    global not_VSCode_running

    # 获取命令行参数
    local arg_dict = cmdline_args_dict(ARGS)

    # 获取NARS名称
    local name::String = main_CIN_name(DEFAULT_NAME, CIN_PATHS; arg_dict) # ! 默认为OpenNARS

    # 根据名称获取CIN类型
    local type::CINType = main_CIN_type(name)

    # 根据名称获取可执行文件路径
    local path::String = main_CIN_path(name)

    # 生成NARS终端 | 不再负责获取类型、可执行文件路径
    local console = main_console(name, type, path, CIN_CONFIGS; arg_dict) # ! 类型无需固定

    # 启动NARS终端
    not_VSCode_running && @debug console # VSCode（CodeRunner）运行⇒打印
    main_launch(console; arg_dict) # 无论如何都会启动 # * 用于应对「在VSCode启动服务器相对不需要用户输入」的情况
end

# * 现在可以通过「预先定义main函数」实现可选的「函数替换」
main(ARGS)

@info "It is done."
