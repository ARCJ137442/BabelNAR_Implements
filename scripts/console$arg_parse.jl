# * 基于 ArgParse.jl 的参数解析表 | 只在 ArgParse.jl 被启用时执行 | ?因引入问题，仍需不断覆盖
() -> begin
    local settings::ArgParseSettings = ArgParseSettings()

    @add_arg_table! settings begin
        "type"
        help = "要启动的CIN名称（在`CIN-paths.local.jl`中定义）"
        # required = true
        # default = 
    end

    return settings
end
