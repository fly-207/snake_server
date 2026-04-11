---@module extype
---扩展消息类型定义模块
---定义 skynet 自定义协议的类型ID

---@class extype 消息类型常量
---@field ZINC_CLIENT integer 客户端消息类型，值为13
---@field ZINC_CLIENT_MERGE integer 客户端合并消息类型，值为14
---@field ZINC integer Zinc协议类型，值为3
---@field LOGIC_TYPE integer 逻辑消息类型，值为100
---@field ROUTER_TYPE integer 路由消息类型，值为101
local M = {}

M.ZINC_CLIENT = 13
M.ZINC_CLIENT_MERGE = 14
M.ZINC = 3

M.LOGIC_TYPE = 100
M.ROUTER_TYPE = 101

return M
