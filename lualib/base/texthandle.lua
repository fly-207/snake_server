---@module texthandle
---文本命令处理模块
---提供基于 skynet text 协议的命令分发机制
---用于处理调试控制台等文本命令

local skynet = require "skynet"

---@class texthandle 文本命令处理模块
---@field Dispatch fun(textcmd: TextCmdHandler|nil) 初始化文本命令分发器
local M = {}

---@class TextCmdHandler 文本命令处理器接口
---@field Invoke fun(cmd: string, address: integer, id: integer, parm: string) 命令处理函数

---初始化文本命令分发器
---@param textcmd TextCmdHandler|nil 文本命令处理器，包含 Invoke 方法
function M.Dispatch(textcmd)
    skynet.register_protocol {
        name = "text",
        id = skynet.PTYPE_TEXT,
        pack = function (...)
            local n = select ("#" , ...)
            if n == 0 then
                return ""
            elseif n == 1 then
                return tostring(...)
            else
                return table.concat({...}," ")
            end
        end,
        unpack = skynet.tostring
    }

    skynet.dispatch("text", function (session, address, message)
        if textcmd then
            local id, cmd , parm = string.match(message, "(%d+) (%w+) ?(.*)")
            id = tonumber(id)
            textcmd.Invoke(cmd, address, id, parm)
        end
    end)
end

return M
