# * 覆盖@解析命令行参数：有关主机地址、端口的配置
let # 使用`let`保证临时上下文
    # * 引入原先的匿名函数，并进行追加
    local old = include(raw"console$arg_parse.jl")
    # 返回新的匿名函数
    () -> begin
        # * 使用原先的构造函数
        local settings::ArgParseSettings = old()

        # * 追加新参数
        @add_arg_table! settings begin
            "--host", "--ip", "-i"
            help = "要启动的WebSocket服务器主机地址"
            arg_type = String
            default = nothing # DEFAULT_HOST # ! 取消各自的默认值

            "--port", "-p"
            help = "要启动的WebSocket服务端口"
            arg_type = Int
            default = nothing # DEFAULT_PORT # ! 取消各自的默认值
        end

        return settings
    end
end
