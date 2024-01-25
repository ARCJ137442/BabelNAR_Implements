# BabelNAR-Implements

[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)

该项目使用[语义化版本 2.0.0](https://semver.org/)进行版本号管理。

基于**抽象CIN接口库**[BabelNAR](https://github.com/ARCJ137442/BabelNAR.jl)的**具体CIN实现**

- 对接的两端
  - 前端：
  - 后端NARS实现（OpenNARS、ONA、NARS-Python、PyNARS、OpenJunars、Narjure、NARS-Swift……）
- 为其它使用Narsese的库提供数据结构表征、存取、互转支持

## 概念

相关概念可参考[BabelNAR.jl的相应部分](https://github.com/ARCJ137442/BabelNAR.jl?tab=readme-ov-file#%E6%A6%82%E5%BF%B5)

## 安装

作为一个**Julia包**，您只需：

1. 在安装`Pkg`包管理器的情况下，
2. 在REPL(`julia.exe`)运行如下代码：

```julia
using Pkg
Pkg.add(url="https://github.com/ARCJ137442/BabelNAR-Implements")
```

## 快速开始

### 配置可执行文件路径

要运行BabelNAR，首先需要在`scripts`目录下配置`CIN-paths.local.jl`

- 🎯其将被脚本用`include`函数引入，并作为字典类型`Dict{Symbol,String}`使用
- 📌为方便对接脚本代码，可使用上下文相关的**特殊变量**作为CIN名称
  - 📄具体类型
    - `TYPE_OPENNARS`: 对应CIN类型 **OpenNARS**
    - `TYPE_ONA`: 对应CIN类型 **ONA**
    - `TYPE_NARS_PYTHON`: 对应CIN类型 **NARS-Python**
    - `TYPE_OPEN_JUNARS`: 对应CIN类型 **OpenJunars**
    - `TYPE_PYNARS`: 对应CIN类型 **PyNARS**
  - 🔗参考链接：[native.jl#L46](https://github.com/ARCJ137442/BabelNAR_Implements/blob/e6b21d89c506baa7315ee2efeeb1fec92ef46ff9/src/CINConfig/native.jl#L46)

格式：

```julia
"【CIN类名】" => "【文件名】"
```

参考代码：

```julia
# CIN-paths.local.jl
# ! 文件的上下文由`console.jl`提供
# * 使用 `../` 表示所在目录的上一级目录

Dict([
    TYPE_OPENNARS => "../executables/opennars.jar"
    TYPE_ONA => "../executables/NAR.exe"
    TYPE_NARS_PYTHON => "../executables/main.exe"
    TYPE_OPEN_JUNARS => "../executables/OpenJunars-main"
    TYPE_PYNARS => "../executables/launch-pynars-console-plus.cmd"
])
```

### 启动终端

#### 运行聚合终端

要运行统一的聚合终端，可直接运行`scripts/console.jl`：

```bash
cd BabelNAR
julia scripts/console.jl
```

进入终端后，通过命令行输入选择相应CIN，即可进行交互。

#### 运行带Websocket服务端的聚合终端

要运行【带Websocket服务端】的聚合终端`scripts/console_WSServer.jl`

- 为使Websocket服务器能正常工作，需要Julia环境安装有 **SimpleWebsockets** 、 **JSON** 包

```bash
cd BabelNAR
julia scripts/console_WSServer.jl
```

当终端输出 `[ Info: Listening on: 【IP地址:端口】, thread id: 【XXX】` 时，BabelNAR Websocket服务器已成功启动

- 外部程序可与之连接并互传信息
  - 传入：向其发送NAVM指令（NAIR指令）
  - 传出：接收CIN运行输出（JSON）

其中，CIN运行输出为JSON格式，其内容用TypeScript定义如下：

```typescript
type WebNARSOutput = {
    /** 输出类型 */
    output_type: string
    /** 输出内容 */
    content: string
    /** 接口名称 */
    interface_name?: string // 【2024-01-25 17:38:44】目前只在PyNARS中用到
    /** 输出的操作及其参数 */
    output_operation?: NARSOperation // 只在`EXE`中出现
}

/** NARS操作 = [操作符（不带尖号"^"）, 操作参数...] */
type NARSOperation = [string, ...string[]]
```

## 代码规范 Notes

参考[BabelNAR.jl的相应部分](https://github.com/ARCJ137442/BabelNAR.jl?tab=readme-ov-file#%E4%BB%A3%E7%A0%81%E8%A7%84%E8%8C%83-notes)

## 参考

### CIN

- [OpenNARS (Java)](https://github.com/opennars/opennars)
- [ONA (C)](https://github.com/opennars/OpenNARS-for-Applications)
- [NARS-Python (Python)](https://github.com/ccrock4t/NARS-Python)
- [OpenJunars (Julia)](https://github.com/AIxer/OpenJunars)
- [PyNARS (Python)](https://github.com/bowen-xu/PyNARS)
<!-- - [Narjure (Clojure)](https://github.com/opennars/Narjure)
- [NARS-Swift (Swift)](https://github.com/maxeeem/NARS-Swift) -->

### 依赖

- [NAVM](https://github.com/ARCJ137442/NAVM.jl)
- [NAVM_Implements](https://github.com/ARCJ137442/NAVM_Implements)
- [BabelNAR](https://github.com/ARCJ137442/BabelNAR.jl)
