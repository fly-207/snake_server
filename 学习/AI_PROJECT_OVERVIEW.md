# Snake Server 项目说明（面向 AI 快速理解）

> 本文档用于让 AI 或新同学在最短时间内理解项目结构与启动方式。
> 代码基于 **Skynet 1.0**，并在仓库内 `skynet/` 目录做了定制。

## 1. 项目定位

- 项目类型：Lua + C 混合开发的游戏服务端。
- 框架基座：Skynet（仓库内源码）。
- 业务主体：`service/` 下的大量服务模块。
- 构建产物：`build/` 下的 `skynet` 可执行文件和各类 `.so` 动态库。

## 2. 顶层目录职责速览

- `clib/`：C 库源码目录。
  - 包含 `rc4`、`xor`、`lua-protobuf`、`timingwheel`、`aoi/gaoi` 等。
  - 通过 `Makefile` 编译为 `build/clib/*.so`、`build/clualib/*.so`、`build/cservice/*.so`。
- `config/`：Skynet 启动配置目录。
  - 包含 `bs_config.lua`、`cs_config.lua`、`gs_config.lua`、`ks_config.lua`。
  - 配置线程数、入口 `start`、服务搜索路径、Lua/C 模块路径、PB 文件路径等。
- `lualib/`：基础 Lua 库与公共能力。
  - `base/` 常放基础机制；`public/` 常放跨业务公共模块。
- `service/`：核心业务服务目录（最重要）。
  - `*_launcher.lua` 为启动入口服务。
  - 各子目录承载具体业务逻辑（登录、聊天、世界、排行、支付、场景等）。
- `skynet/`：Skynet 开源库目录（有定制）。
  - 版本基线见 `skynet/HISTORY.md`，当前可见为 **v1.0.0**。
- `cs_common/`：跨服/跨层共享数据目录（当前观察）。
  - 已确认包含 `proto/`，另有 `code/`、`data/`。
  - 常见用途是协议、映射和共享定义。
- `daobiao/`：数据表与导表工具目录。
  - 包含 xls 转 lua、打包、校验等脚本和导表产物。
- `shell/`：运维与开发脚本目录。
  - 启停、检查、生成配置、清理日志、数据脚本等。
- `tools/`：项目工具目录（辅助脚本或工具集合）。
- `doc/`：历史文档（Word/XMind 等），**不作为当前技术说明主入口**。

## 3. Skynet 版本与定制说明

- 版本基线：`skynet/HISTORY.md` 顶部为 `v1.0.0 (2016-7-11)`。
- 结论：该项目并非新版本 skynet，属于 1.0 系列并包含本地修改。
- 实践建议：
  - 先按当前仓库编译运行，不要直接按新版 skynet 文档做升级式改造。
  - 与 skynet 行为不一致时，优先以仓库源码和本项目调用方式为准。

## 4. 构建与产物关系

`Makefile` 的核心流程：

1. 创建 `build/` 目录结构。
2. 编译 `skynet/`，产出：
   - `build/skynet`
   - `build/lua`、`build/luac`
   - 头文件到 `build/include/`
3. 编译业务 C 扩展：
   - `build/clib/librc4.so`、`libxor.so`、`libpbc.so`
   - `build/cservice/zinc_gate.so`
   - `build/clualib/protobuf.so`、`laoi.so`、`gaoi.so`、`ltimer.so` 等

## 5. 启动配置关键点（以 cs/gs 为例）

`config/cs_config.lua` 与 `config/gs_config.lua` 关键字段：

- `start`：分别是 `cs_launcher` / `gs_launcher`。
- `server_key`：环境标识（如 `dev_cs`、`dev_gs10001`）。
- `proto_file`：`cs_common/proto/proto.pb`。
- `proto_define`：`cs_common/proto/netdefines.lua`。
- `luaservice`：服务脚本检索路径（`service/` + `skynet/service/`）。
- `lua_path`：Lua 库检索路径（`lualib/` + `skynet/lualib/`）。
- `lua_cpath` / `cpath`：动态库路径（`build/clualib`、`build/cservice`）。
- `preload`：`lualib/base/preload.lua`（全局预加载逻辑入口）。

## 6. 服务启动链路（概念）

以 `./build/skynet ./config/gs_config.lua <flag>` 为例：

1. skynet 读取配置文件。
2. 按 `start = "gs_launcher"` 启动 `service/gs_launcher.lua`。
3. `gs_launcher` 内通过 `skynet.newservice` 拉起基础服务和业务服务。
4. 启动完成后，向 `dictator` 发 `AllServiceBooted` 通知。

`cs_launcher` 与 `gs_launcher` 都遵循类似模式，但拉起的服务集合不同。

## 7. 常用启停脚本

项目根目录常用脚本：

- `bs_run.sh` / `cs_run.sh` / `gs_run.sh`：单服启动。
- `bs_kill.sh` / `cs_kill.sh` / `gs_kill.sh`：单服停止。
- `all_start.sh`：按顺序启动 `bs -> cs -> gs`，最后执行 `open_gate.sh`。

脚本特征：

- 通过传入 `FLAG`（如 `dev_gs10001`）区分实例进程。
- 启动前会检查已有进程并备份旧日志。
- 最终使用 `nohup ./build/skynet ./config/*_config.lua $FLAG` 后台拉起。

## 8. 推荐阅读顺序（给 AI）

为快速理解业务，建议按以下顺序读取：

1. `config/gs_config.lua`、`config/cs_config.lua`
2. `service/gs_launcher.lua`、`service/cs_launcher.lua`
3. `lualib/base/preload.lua`
4. `lualib/public/serverdefines.lua`（端口、服务数量等关键常量）
5. `service/` 下目标业务目录（如 `login/`、`world/`、`scene/`）
6. 协议相关：`cs_common/proto/` + `daobiao/` 导表结果

## 9. AI 分析该仓库时的注意事项

- 这是“工程化老项目 + 大量历史脚本”，优先相信仓库内真实启动链路。
- 不要默认按最新 skynet API 推断行为，先看 `skynet/` 本地代码与调用。
- 遇到全局变量（如 `ROUTERS_SERVICE_COUNT`）时，先回溯 `preload` 与公共定义文件。
- 涉及协议字段和资源配置时，通常要联合 `cs_common/`、`daobiao/`、`lualib/public/` 一起看。

## 10. 一句话总结

这是一个基于 **Skynet v1.0.0（含本地定制）** 的 Lua/C 游戏服务端，`service/` 承担核心业务，`config/` 决定启动与加载路径，`clib/` + `build/` 提供底层动态库能力，`cs_common/` 与 `daobiao/` 负责协议和配置数据支撑。