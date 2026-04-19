# Snake Server — GitHub Copilot 上下文指令

> 本文件为 GitHub Copilot 提供仓库上下文，帮助 AI 在代码补全、注释生成、新服务创建等任务中生成符合本项目约定的代码。

## 项目简介

本项目是游戏「大话许仙」的服务端代码，基于 [Skynet](https://github.com/cloudwu/skynet) 框架构建。
- **Skynet**：轻量级 Actor 模型并发框架，每个服务是独立的 Lua 协程，服务间通过消息通信，不共享内存
- 主要语言：**Lua**（业务逻辑） + **C**（性能敏感扩展）
- 协议序列化：**sproto**（内部协议） + **protobuf**（客户端协议）
- 数据库：**MongoDB**（通过 `lualib/base/mongoop.lua` 封装访问）

---

## 服务器类型与启动

本项目有四种服务器进程，每种有独立的配置文件、启动脚本和 launcher：

| 类型 | 启动脚本 | Launcher | 配置文件 | 说明 |
|------|----------|----------|----------|------|
| **GS** (Game Server) | `gs_run.sh` | `service/gs_launcher.lua` | `config/gs_config.lua` | 游戏主逻辑服务器，玩家直连 |
| **CS** (Center Server) | `cs_run.sh` | `service/cs_launcher.lua` | `config/cs_config.lua` | 中心服务器，跨服/全局逻辑 |
| **BS** (Backend Server) | `bs_run.sh` | `service/bs_launcher.lua` | `config/bs_config.lua` | 后台管理服务器 |
| **KS** (Keep Server) | *(ks_run.sh)* | `service/ks_launcher.lua` | `config/ks_config.lua` | 保活/存档服务器 |

### 服务器标识规则

服务器通过 `server_key` 字段标识，格式为 `{cluster}_{type}{id}`，例如 `dev_gs10001`。
可通过以下全局函数（由 `lualib/base/preload.lua` 注入）判断当前服务器类型：
- `is_gs_server()` — 是否 GS
- `is_cs_server()` — 是否 CS
- `is_bs_server()` — 是否 BS
- `is_ks_server()` — 是否 KS
- `get_server_cluster()` — 获取集群标识（如 `dev`, `prod`）
- `get_server_type()` — 获取服务器类型字符串
- `get_server_id()` — 获取服务器ID（整数）
- `is_production_env()` — 是否生产环境

---

## 目录结构

```
snake_server/
├── service/                    # 所有 Skynet 服务（每个子目录是一个独立服务）
│   ├── gs_launcher.lua         # GS 启动入口，按顺序启动所有 GS 服务
│   ├── cs_launcher.lua         # CS 启动入口
│   ├── bs_launcher.lua         # BS 启动入口
│   ├── ks_launcher.lua         # KS 启动入口
│   ├── login/                  # 登录服务
│   ├── scene/                  # 场景服务（多实例）
│   ├── world/                  # 世界服务
│   ├── chat/                   # 聊天服务
│   ├── gamedb/                 # 数据库读写服务（多实例，GAMEDB_SERVICE_COUNT 个）
│   ├── logdb/                  # 日志数据库服务
│   ├── dictator/               # 独裁者服务（协调所有服务启动完成）
│   ├── router_c/               # 客户端路由服务
│   ├── router_s/               # 服务器间路由服务（多实例）
│   ├── datacenter/             # 数据中心服务（CS 专属，跨服数据共享）
│   ├── rank/                   # 排行榜服务
│   ├── pay/                    # 支付服务（多实例）
│   ├── loginverify/            # 登录验证服务（多实例）
│   ├── broadcast/              # 广播服务
│   ├── webrouter/              # Web HTTP 路由服务
│   ├── webhandler/             # Web HTTP 请求处理服务
│   ├── mem_monitor/            # 内存监控服务
│   ├── rt_monitor/             # 实时性能监控服务
│   └── ...                     # 其他服务
│
├── lualib/
│   ├── base/                   # 底层公共库（框架级，不含业务逻辑）
│   │   ├── preload.lua         # 每个服务启动时自动执行，注入全局变量和基础模块
│   │   ├── interactive.lua     # 服务间消息通信核心模块（Send/Request/Response）
│   │   ├── servicesave.lua     # 数据自动保存模块（定时保存到 MongoDB）
│   │   ├── servicetimer.lua    # 服务定时器模块
│   │   ├── net.lua             # 网络连接封装
│   │   ├── router.lua          # 路由逻辑封装
│   │   ├── mongoop.lua         # MongoDB 操作封装
│   │   ├── tableop.lua         # Table 工具函数扩展
│   │   ├── stringop.lua        # String 工具函数扩展
│   │   ├── timeop.lua          # 时间操作工具函数
│   │   ├── extend.lua          # Lua 基础类型扩展
│   │   ├── baseobj.lua         # 基础对象类（OOP 基类）
│   │   ├── reload.lua          # 热重载支持
│   │   └── ...
│   │
│   └── public/                 # 业务层公共库（含游戏业务逻辑）
│       ├── record.lua          # 日志记录模块（error/info/warning/debug + 数据库日志）
│       ├── serverdefines.lua   # 服务器端口、服务数量等全局配置常量
│       ├── gamedefines.lua     # 游戏业务常量定义（枚举值等）
│       ├── gamedb.lua          # gamedb 服务的客户端封装（供其他服务调用）
│       ├── serverinfo.lua      # 服务器信息管理
│       ├── serverdesc.lua      # 服务器描述信息
│       └── ...
│
├── config/                     # Skynet 配置文件（Lua 格式）
│   ├── gs_config.lua           # GS 配置
│   ├── cs_config.lua           # CS 配置
│   ├── bs_config.lua           # BS 配置
│   └── ks_config.lua           # KS 配置
│
├── clib/                       # C 扩展库源码
├── cs_common/                  # 客户端/服务端共用文件（proto 协议定义等）
│   └── proto/                  # protobuf 协议文件
├── daobiao/                    # 游戏数据表（策划导表，服务器读取）
├── gm/                         # GM 工具
├── skynet/                     # Skynet 子模块（不要修改）
├── tools/                      # 开发工具脚本
└── 学习/                       # 新人学习文档和架构说明
```

---

## 服务间通信规范

### 核心模块：`base.interactive`

所有服务间通信必须通过 `interactive` 模块，**禁止**直接使用 `skynet.send` / `skynet.call`（已有封装）。

```lua
local interactive = require "base.interactive"

-- 单向消息（不需要响应）
interactive.Send(".target_service", "模块名", "命令名", {数据})

-- 请求-响应（需要回调）
interactive.Request(".target_service", "模块名", "命令名", {数据}, function(mRecord, mData)
    -- 处理响应
end)

-- 响应一个 Request
interactive.Response(mRecord.source, mRecord.session, {响应数据})
```

服务地址使用 `.服务名` 格式（Skynet 命名服务）。

### 消息分发

每个服务在 `skynet.start()` 中调用 `interactive.Dispatch(moduleLogic)` 注册消息处理器。
`moduleLogic` 对象需实现 `Invoke(sModule, sCmd, mRecord, mData)` 方法来分发各模块的命令。

### 服务启动完成通知

所有服务启动完毕后，launcher 向 `.dictator` 发送 `AllServiceBooted` 通知：
```lua
interactive.Send(".dictator", "common", "AllServiceBooted", {type = "launcher"})
```

---

## 全局变量（由 `preload.lua` 注入）

每个服务启动时，`preload.lua` 会自动初始化以下全局变量：

| 变量 | 类型 | 说明 |
|------|------|------|
| `MY_ADDR` | integer | 当前服务的 Skynet 地址 |
| `MY_SERVER_KEY` | string | 服务器标识，如 `dev_gs10001` |
| `MY_SERVER_TYPE` | string | 服务器类型，如 `gs` |
| `MY_SERVER_ID` | integer | 服务器ID |
| `MY_SERVER_CLUSTER` | string | 集群标识，如 `dev` |
| `MY_SERVICE_NAME` | string | 当前服务名称 |
| `LOG_BASE_PATH` | string | 日志根目录 |

---

## 日志规范

统一使用 `public.record` 模块记录日志，**禁止**直接使用 `print` 或 `skynet.error`：

```lua
local record = require "public.record"

record.info("服务启动成功")          -- 普通信息
record.error("发生错误: %s", err)    -- 错误日志（支持 string.format 格式）
record.warning("警告: %s", msg)      -- 警告日志
record.debug("调试信息: %s", data)   -- 调试日志（仅开发环境）

-- 记录到 MongoDB（用于数据分析）
record.log_db("行为类型", "子类型", {数据表})
```

---

## 数据保存规范

使用 `base.servicesave` 模块实现数据自动定时保存：

```lua
local servicesave = require "base.servicesave"

-- 注册一个保存任务（每5分钟自动保存一次，范围1~20分钟）
local iSaveId = servicesave.NewSaveObj(function()
    -- 执行实际的数据库写入操作
    gamedb.save_player_data(player_data)
end, 5*60*1000)  -- 间隔毫秒数，可选，默认5分钟

-- 立即触发保存
servicesave.DoSaveObj(iSaveId)

-- 服务关闭时保存所有数据
servicesave.SaveAll()
```

---

## 新建服务步骤

创建一个新服务时，**必须**按以下步骤操作：

### 1. 创建服务目录和入口文件

新建 `service/<服务名>/init.lua`（Skynet 会自动查找 `service/<名称>/init.lua` 或 `service/<名称>.lua`）：

```lua
-------------------------------------------------------------------
-- @file    init.lua
-- @service &lt;服务名&gt;
-- @brief   &amp;lt;一句话描述该服务的职责&gt;
-- @server  gs/cs/bs  （运行在哪种服务器上）
--
-- 详细说明：
--   &amp;lt;该服务在整个架构中的角色&gt;
--   &amp;lt;与哪些服务交互，职责边界是什么&gt;
--
-- 依赖服务：
--   - .gamedb    : 数据库读写
--   - .dictator  : 启动协调
-------------------------------------------------------------------
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"

-- 引入业务逻辑模块（按需）
-- local logic = require "服务名.logic"

skynet.start(function()
    record.info("&amp;lt;服务名&gt; start")

    -- 注册服务名（使其可被 .服务名 寻址）
    skynet.register(".&amp;lt;服务名&gt;")

    -- 注册消息分发器
    interactive.Dispatch()

    record.info("&amp;lt;服务名&gt; ready")
end)
```

### 2. 在对应 Launcher 中注册

根据服务运行的服务器类型，在对应 launcher 的 `skynet.start()` 中添加：
```lua
skynet.newservice("&amp;lt;服务名&gt;")
-- 若需要多实例：
for iNo = 1, SERVICE_COUNT do
    skynet.newservice("&amp;lt;服务名&gt;", iNo)
end
```

### 3. 服务实例编号约定

多实例服务（如 `gamedb`, `scene`, `loginverify`）通过第一个参数接收编号：
```lua
-- 在 init.lua 中获取实例编号
local iNo = ...  -- 第一个启动参数
skynet.register(string.format(".服务名_%d", iNo))
```

---

## 注释规范

### Lua 文件头注释

```lua
-------------------------------------------------------------------
-- @file    文件名.lua
-- @brief   模块/服务的一句话描述
-- @author  （可选）
-- @date    （可选）
--
-- 详细说明：
--   详细描述该模块的用途、设计思路
--
-- 使用示例：
--   local mod = require "路径.模块名"
--   mod.DoSomething()
-------------------------------------------------------------------
```

### 函数注释（使用 LuaDoc / EmmyLua 风格）

```lua
--- 函数功能的一句话描述
-- 详细说明（可选，多行）
---@param paramName  type  参数说明
---@param paramName2 type? 可选参数说明（type后加?表示可选）
---@return type 返回值说明
local function MyFunction(paramName, paramName2)
end
```

### 类定义注释

```lua
---@class CMyClass 类的说明
---@field m_iField integer 字段说明
---@field m_sName string 名称
local CMyClass = {}
CMyClass.__index = CMyClass
```

---

## 端口配置速查（来自 `public.serverdefines`）

| 服务器 | GM控制台 | Dictator | Web | 网关/其他 |
|--------|----------|----------|-----|-----------|
| GS | 7001 | 7002 | 7003 | 7011,7012,27011~27013 |
| CS | 10001 | 10002 | 10003 | 二维码:10004~10009, 路由:10010~10013 |
| BS | 20001 | 20002 | 20003 | — |
| KS | 20011 | 20012 | 20013 | 27014~27016(dev) |

---

## 常用服务数量常量（来自 `public.serverdefines`）

```lua
SCENE_SERVICE_COUNT  = 15   -- 场景服务实例数
WAR_SERVICE_COUNT    = 15   -- 战斗服务实例数
GAMEDB_SERVICE_COUNT = 4    -- 数据库服务实例数
PAY_SERVICE_COUNT    = 4    -- 支付服务实例数
VERIFY_SERVICE_COUNT = 4    -- 登录验证服务实例数
ROUTERS_SERVICE_COUNT = 4   -- 路由服务实例数
PLAYER_SEND_COUNT    = 10   -- 玩家发送代理实例数
```

---

## Copilot 任务指引

### 为服务添加注释
> 对 `service/<名称>/` 目录下的所有 Lua 文件，添加文件头注释和函数注释，遵循上方注释规范，注释语言使用**中文**。

### 为公共库添加注释
> 对 `lualib/base/` 或 `lualib/public/` 下的指定文件，添加完整的 EmmyLua 风格注释，包括 `@module`、`@class`、`@field`、`@param`、`@return`。

### 创建新服务
> 按照「新建服务步骤」章节操作，创建 `service/<名称>/init.lua` 并在对应 launcher 中注册。注意：服务名要全小写，单词间用下划线连接。
