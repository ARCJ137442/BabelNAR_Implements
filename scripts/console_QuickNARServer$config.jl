# 预先条件引入 # ! 不引入会导致无法使用符号
@isdefined(BabelNAR_Implements) || include(raw"console$common.jl")

"覆盖：默认OpenNARS"
main_type(::CINType)::CINType = TYPE_OPENNARS

"覆盖：使用默认地址"
main_address() = (
    host="127.0.0.1",
    port=8765
)