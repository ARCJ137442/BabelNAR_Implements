# 预先条件引入 # ! 不引入会导致无法使用符号
@isdefined(BabelNAR_Implements) || include(raw"console$common.jl")

# 引入其它配置 #
include(raw"console_NAVM$config.jl")
include(raw"console_ServerOutFormat$config.jl")

# * 覆盖@解析命令行参数：有关「是否启用详细输出」的配置
@soft_def arg_parse_settings = include(raw"console_MatriangleNAVMServer$arg_parse.jl")

# 覆盖配置 #
"覆盖：使用默认地址，但端口可配置（默认8765）"
function main_launch(consoleWS; arg_dict::ArgDict)

    # 先获取地址 | 包括输入
    local addresses = main_address(
        DEFAULT_HOST; # ! 使用默认主机地址
        arg_dict
    )

    # 决定「是否输出详细信息」
    if (
        arg_dict["debug"] ||
        !isempty(input("Debug mode (false)："))
    )
        ENV["JULIA_DEBUG"] = "all"
        # * 启用DEBUG模式
        @debug "DEBUG模式已启用！"
    end

    # 启动
    launch!(
        consoleWS;
        addresses...,
        # *【2024-01-22 23:19:51】使用0.1s的延迟，让CIN先将自身文本输出完，再打印提示词✅
        delay_between_input=0.1
    )
end

# 最终引入
include("console_WSServer.jl")
