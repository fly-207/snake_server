---@module "public.version"
--- 版本配置模块
--- 定义服务器和客户端版本信息

--import module
local client_update_code = import("cs_common/code/src/clientupdatecode")

---@type string 服务器版本号
VERSION = "0"

---@type string 客户端应用版本号
APP_VERSION = "27"

---@type boolean 是否更新客户端资源
CLIENT_UPDATE_RES = false

---@type integer 异或加密密钥
XOR_KEY = 0xe07aea3911363aa9

--- 客户端更新码(每周清空)
---@type integer
CLIENT_UPDATE_CODE  = client_update_code.CLIENT_UPDATE_CODE
