# * 覆盖@解析命令行参数：有关「是否启用详细输出」的配置
let # 使用`let`保证临时上下文
    # * 引入原先的匿名函数，并进行追加
    local old = include(raw"console_WSServer$arg_parse.jl")
    # 返回新的匿名函数
    () -> begin
        # * 使用原先的构造函数
        local settings::ArgParseSettings = old()

        # * 追加新参数
        @add_arg_table! settings begin
            "--debug", "-d"
            help = "是否启用debug模式"
            action = :store_true # 参考: https://carlobaldassi.github.io/ArgParse.jl/stable/arg_table/#Available-actions-and-nargs-values
        end

        return settings
    end
end
