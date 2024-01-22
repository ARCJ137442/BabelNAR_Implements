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

### 可执行文件

运行CIN所需的所有**可执行文件**（需要用到的`.jar`、`.exe`等），都需放在与`src`同级的`executables`目录；

这个路径也可通过通过配置`test_console.jl`中的`paths`变量：

```julia
paths::Dict = Dict([
    "OpenNARS" => "opennars.jar" |> JER
    "ONA" => "NAR.exe" |> JER
    "Python" => "main.exe" |> JER
    "Junars" => raw"..\..\..\..\OpenJunars-main"
])
```

格式：

```julia
"【CIN类名】" => "【文件名】"
```

### 依赖路径问题

介于开发效率方面的需求，本Julia包如 [NAVM](https://github.com/ARCJ137442/NAVM.jl) 一样

### 快速启动

在有Julia环境的电脑上，可尝试运行源码中的`Implements/test/test_console.jl`：

```bash
cd BabelNAR
julia Implements/test/test_console.jl
```

或运行`Implements/test/test_console_WSServer.jl`

- 需要Julia环境安装有 **SimpleWebsockets** 、 **JSON** 包

```bash
cd BabelNAR
julia Implements/test/test_console_WSServer.jl
```

## 代码规范 Notes

参考[BabelNAR.jl的相应部分](https://github.com/ARCJ137442/BabelNAR.jl?tab=readme-ov-file#%E4%BB%A3%E7%A0%81%E8%A7%84%E8%8C%83-notes)

## 参考

### CIN

- [OpenNARS (Java)](https://github.com/opennars/opennars)
- [ONA (C)](https://github.com/opennars/OpenNARS-for-Applications)
- [NARS-Python (Python)](https://github.com/ccrock4t/NARS-Python)
- [OpenJunars (Julia)](https://github.com/AIxer/OpenJunars)
<!-- - [PyNARS (Python)](https://github.com/bowen-xu/PyNARS)
- [Narjure (Clojure)](https://github.com/opennars/Narjure)
- [NARS-Swift (Swift)](https://github.com/maxeeem/NARS-Swift) -->

### 依赖

- [JuNarsese](https://github.com/ARCJ137442/JuNarsese.jl)
- [JuNarsese-Parsers](https://github.com/ARCJ137442/JuNarseseParsers)
- [NAVM](https://github.com/ARCJ137442/NAVM.jl)
- [BabelNAR](https://github.com/ARCJ137442/BabelNAR.jl)
