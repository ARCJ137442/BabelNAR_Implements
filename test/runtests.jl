# * 导入自身源码文件
push!(LOAD_PATH, "../", "../src/")

# 导入依赖

println('='^16 * "Test of BabelNAR_Implements" * '='^16)

using BabelNAR_Implements

# @info NAVM names(NAVM)
@info BabelNAR_Implements names(BabelNAR_Implements)
