# 引入配置
include(raw"console_NAVM$config.jl")
include(raw"console_ServerOutFormat$config.jl")

# 最终引入
include("console_WSServer.jl")
