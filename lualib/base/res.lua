---@module res
---资源数据模块
---提供对共享资源数据的访问，使用 skynet sharedata 实现跨服务共享
---通过元表代理方式提供透明的资源数据访问

local skynet = require "skynet"
local sharedata = require "sharedata"

---@class res 资源数据模块，可通过索引访问共享的资源数据
---@field daobiao table 导表数据
---@field [string] any 其他资源数据
local M = {}

skynet.init(function()
    local box = sharedata.query("res")
    setmetatable(M, {__index = box})
end, "res")

return M
