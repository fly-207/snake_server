---@module "base.mem_monitor"
--- 内存监控模块
--- 用于跟踪每行代码的内存分配情况

local skynet = require "skynet"

---@class MemMonitorModule 内存监控模块
---@field Start fun() 开始监控
---@field Stop fun() 停止监控
local M = {}

---@type number 当前内存使用量
local iCurrMem = 0
---@type string 当前行名称
local sLineName = ""
---@type boolean 是否开启
local bOpen = false

--- 内存记录函数(钩子)
---@param sEvent string 事件类型
---@param iLineNo integer 行号
local function RecordFunc(sEvent, iLineNo)
    local iMemInc = collectgarbage("count") - iCurrMem
    if (iMemInc <= 1e-6) then
        iCurrMem = collectgarbage("count")
        return
    end
    skynet.send(".mem_monitor", "lua", "Record", iMemInc, sLineName)
    sLineName = string.format("{%s}%s_%s", MY_SERVICE_NAME, debug.getinfo(2, 'S').source, iLineNo)
    iCurrMem = collectgarbage("count")
end

--- 开始内存监控
function M.Start()
    if bOpen then
        M.Stop()
    end
    iCurrMem = collectgarbage("count")
    bOpen = true
    debug.sethook(RecordFunc, "l")
end

--- 停止内存监控
function M.Stop()
    if not bOpen then
        return
    end
    debug.sethook()
    iCurrMem = 0
    bOpen = false
end

return M
