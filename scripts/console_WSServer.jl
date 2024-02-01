#= 📝Julia加载依赖的方法
# ! Julia在父模块引入「本地子模块」时，
# ! 需要**本地子模块的Git存储库完成了提交**才会开始编译本地子模块**更改后的版本**
=#

# 预先条件引入 # ! 不引入会导致无法使用符号
@defined_or BabelNAR_Implements include(raw"console$common.jl")

"（统一的）消息接收钩子"
function on_message(consoleWS, connection, message)
    "转换后的字符串" # ! 可能「一输入多输出」
    local inputs::Vector{String} = main_received_convert(consoleWS, message)
    # 处理：通过「转译函数」后放入CIN，视作为「CIN自身的输入」 # ! 只有非空字符串才会输入进CIN
    isempty(inputs) || for input in inputs
        put!(consoleWS.console.program, input)
    end
end

"（统一的）连接关闭钩子"
function on_close(consoleWS, connection, reason)
    # 获取退出码以及描述
    code, description = reason
    if code == 1000
        @info "Websocket连接正常关闭✓"
    elseif contains(description, " ping ")
        @warn "连接疑似掉线：$(description)（退出码：$(code)）"
    else
        @warn "Websocket连接异常关闭！退出码：$code" description
    end
    # 通知条件（以便让程序执行完）
    # notify(consoleWS.ended) # ! 暂时不使用
end

"（统一的）连接错误钩子"
function on_error(consoleWS, connection, err)
    # 通知条件（以便让程序执行完）
    # notify(ended, err, error=true)
end

"启动Websocket服务器"
function launchWSServer(consoleWS::NARSConsoleWithServer, host::String, port::Int)

    # 检查「Websocket服务器」是否已初始化
    @assert !isnothing(consoleWS.server)
    # local ended = Condition()

    # 预备侦听
    listen(consoleWS.server, :client) do connection

        # Julia自带侦听提示
        @info "Websocket连接已建立。"
        @debug "" connection
        push!(consoleWS.connections, connection)

        listen(connection, :message) do message
            on_message(consoleWS, connection, message)
        end

        listen(connection, :close) do reason
            on_close(consoleWS, connection, reason)
            # notify(ended)
        end

    end

    # 错误通知
    listen(consoleWS.server, :connectError) do err
        on_error(consoleWS, connection, err)
    end

    # @show server

    @async serve(consoleWS.server, port, host)
    # wait(ended) # ! 实际上可以直接异步
end

# ! 依赖：Websocket包SimpleWebsockets ! #
try
    using SimpleWebsockets: WebsocketServer, Condition, listen, notify, serve, send
catch e
    @warn "BabelNAR: 包「SimpleWebsockets」未能成功导入，WebSocket服务将无法使用！"
end

# ! 统一规范：使用JSON「对象数组」的方式传递数据 ! #
try
    using JSON: json
catch err
    @warn "BabelNAR: 包「JSON」未能成功导入，WebSocket服务将无法使用！" err
end

# * 配置服务器地址信息
@soft_def function main_address(
    host::Union{AbstractString,Nothing}=nothing,
    port::Union{Int,Nothing}=nothing;
    default_host::String="127.0.0.1",
    default_port::Int=8765
)::NamedTuple{(:host, :port),Tuple{String,Int}}
    # 获取默认值

    if isnothing(host)
        local hostI = input("Host ($default_host): ")
        host = !isempty(hostI) ? hostI : default_host
    end

    if isnothing(port)
        local portI = tryparse(Int, input("Port ($default_port): "))
        port = something(portI, default_port)
    end

    # 返回
    return (
        host=host,
        port=port
    )
end

# * 转换服务器收到的消息，用于*输入CIN*
@soft_def main_received_convert(::NARSConsoleWithServer, message::String) = (
    message
) # ! 默认为恒等函数，后续用于NAVM转译

"覆盖：生成「带Websocket服务器」的NARS终端"
function main_console(type::CINType, path::String, CIN_configs)::NARSConsoleWithServer
    # 先定义一个临时函数，将其引用添加进服务器定义——然后添加「正式使用」的方法
    _temp_input_interpreter(x::Nothing) = x

    local server = NARSConsoleWithServer(
        # 先内置一个终端 #
        NARSConsole(
            type,
            CIN_configs[type],
            path;
            input_prompt="BabelNAR.$type> ",
            input_interpreter=_temp_input_interpreter # ! 与「来源网络」的一致
        );
        # 然后配置可选参数 #
        # 服务器
        server=WebsocketServer(),
        # 连接默认就是空
        connections=[],
        # 启动服务器
        server_launcher=launchWSServer,
        # 转译输出
        output_interpreter=(line::String) -> main_output_interpret(
            Val(Symbol(type)),
            CIN_configs[type],
            line
        ),
        # 发送数据 to 客户端
        server_send=(consoleWS::NARSConsoleWithServer, datas::Vector{NamedTuple}) -> begin
            # 只用封装一次JSON
            local text::String = json(datas)
            for output in datas
                print_NARSOutput(output)
            end
            # * 遍历所有连接，广播之
            for connection in consoleWS.connections
                send(connection, text)
            end
        end
    )
    # 定义方法
    _temp_input_interpreter(input::String) = main_received_convert(server, input)
    return server
end


"覆盖：可选启动服务器"
main_launch(consoleWS) = launch!(
    consoleWS;
    main_address()...,
    # *【2024-01-22 23:19:51】使用0.1s的延迟，让CIN先将自身文本输出完，再打印提示词✅
    delay_between_input=0.1
)

# 最终引入
include("console.jl")
