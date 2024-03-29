ROOT_PATH = contains(@__DIR__, "scripts") ? dirname(@__DIR__) : @__DIR__
@assert ispath(joinpath(ROOT_PATH), "scripts") # 确保是项目根目录
push!(LOAD_PATH, ROOT_PATH) # 当前项目根目录
push!(LOAD_PATH, dirname(ROOT_PATH)) # 更上层根目录
push!(LOAD_PATH, joinpath(dirname(ROOT_PATH), "BabelNAR.jl")) # BabelNAR包目录

"检测是否在VSCode中（使用CodeRunner）执行"
not_VSCode_running::Bool = "scripts" ⊆ pwd() && contains(@__FILE__, "temp") # tempCodeRunnerFile.julia

# ! 避免「同名异包问题」最好的方式：只从「间接导入的包」里导入「直接导入的包」
using BabelNAR_Implements
@debug names(BabelNAR_Implements)
using BabelNAR_Implements.BabelNAR # * ←这里就是「直接导入的包」
import BabelNAR_Implements.BabelNAR: CINConfigDict
@debug names(BabelNAR)
import BabelNAR.Utils: input, _INTERNAL_MODULE_SEARCH_DICT # ! ←这个用于注入Junars

# 引入OpenJunars # ! 但这是本地目录，所以在别的地方需要稍加修改
try
    push!(LOAD_PATH, "../../../OpenJunars-main")
    import DataStructures
    import Junars
    @debug names(Junars) names(DataStructures)
    # 注入 # * Symbol(模块)=模块名（符号）
    for m in [Junars, DataStructures]
        _INTERNAL_MODULE_SEARCH_DICT[Symbol(m)] = m
    end
catch e
    @warn "无法加载OpenJunars主模块`Junars`！" e
    @debug showerror(stderr, e, stacktrace(Base.catch_backtrace()))
end

# !【2023-11-02 01:30:04】新增的「检验函数」，专门在「导入的包不一致」的时候予以提醒
if BabelNAR_Implements.BabelNAR !== BabelNAR
    error("报警：俩包不一致！")
end

# * 尝试导入「命令行参数解析」相关库
try
    using ArgParse
catch
    @warn "ArgParse.jl 未成功导入，无法解析命令行参数。"
end
