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
@isdefined(BabelNAR_Implements) || include(raw"console$import.jl")

"""
用于获取用户输入的「NARS类型」
- 逻辑：不断判断
"""
function get_valid_NARS_type_from_input(
    valid_types;
    default_type::CINType,
    input_prompt::String)::CINType

    local inp::String, type::CINType

    while true
        inp = input(input_prompt)
        # 输入后空值合并
        "输入的字符串"
        local type_str = string(
            isempty(inp) ? (default_type) :
            CINType(inp)
        )
        "用于对比的字符串" # ! 全部转换成小写字母（忽略大小写）
        local type_str_comp = lowercase(type_str)
        local type2_comp::String
        # * 合法⇒返回
        for type2 in valid_types
            type2_str_comp = lowercase(string(type2))
            # * 条件优先级：相等⇒前缀⇒后缀
            (type_str_comp === type2_str_comp || # 相等
             startswith(type2_str_comp, type_str_comp) ||# 前缀也算合法
             endswith(type2_str_comp, type_str_comp)
            ) && return type2 # 最后返回的还是「类型」而非「对比用的字符串」
        end
        # * 非法⇒警告⇒重试
        printstyled("Invalid Type $(type_str)!\n"; color=:red)
    end

    # ! 永远不会运行到这里
end

begin # * 可执行文件路径
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
    paths::Dict = include("CIN-paths.local.jl")
end


# * 主函数 * #
# * 获取NARS类型
@isdefined(main_type) || (main_type(default_type::CINType)::CINType = begin
    global not_VSCode_running

    @isdefined(FORCED_TYPE) ? FORCED_TYPE :
    not_VSCode_running ? get_valid_NARS_type_from_input(
        keys(NATIVE_CIN_CONFIGS);
        default_type,
        input_prompt="NARS Type [$(join(keys(NATIVE_CIN_CONFIGS)|>collect, '|'))] ($default_type): "
    ) :
    TYPE_OPENNARS
end)
# * 根据类型获取可执行文件路径
@isdefined(main_path) || (main_path(type::CINType)::String = paths[type])
# * 生成NARS终端
@isdefined(main_console) || (main_console(type::CINType, path, CIN_configs) = NARSConsole(
    type,
    CIN_configs[type],
    path;
    input_prompt="BabelNAR.$type> "
))
# * 启动
@isdefined(main_launch) || (main_launch(console) = launch!(
    console,
    ( # 可选的「服务器」
        (@isdefined IP) && (@isdefined PORT) ?
        (IP, PORT) : tuple()
    )...,
    # *【2024-01-22 23:19:51】使用0.1s的延迟，让CIN先将自身文本输出完，再打印提示词✅
    delay_between_input=0.1
))
# * 主函数
@isdefined(main) || function main()

    "<================BabelNAR Console================>" |> println

    global not_VSCode_running

    # 获取NARS类型
    local type::CINType = main_type(TYPE_OPENNARS)

    # 根据类型获取可执行文件路径
    local path::String = main_path(type)

    # 生成NARS终端
    local console = main_console(type, path, NATIVE_CIN_CONFIGS) # ! 类型无需固定

    # 启动NARS终端
    not_VSCode_running && @debug console # VSCode（CodeRunner）运行⇒打印
    main_launch(console) # 无论如何都会启动 # * 用于应对「在VSCode启动服务器相对不需要用户输入」的情况
end

# * 现在可以通过「预先定义main函数」实现可选的「函数替换」
main()

@info "It is done."
