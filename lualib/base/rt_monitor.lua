---@module "base.rt_monitor"
--- 运行时监控模块
--- 用于监控函数执行时间和内存使用

local skynet = require "skynet"
local measure = require "measure"
local mem_rt_monitor = require "base.mem_rt_monitor"

---@class RtMonitorModule 运行时监控模块
---@field mo_call fun(key: any[], func: function, ...): any, any, any 监控函数调用
---@field change_monitor fun(bFlag: boolean) 切换监控状态
---@field is_open_monitor fun(): boolean 检查监控是否开启
local M = {}

---@type boolean 是否开启监控
local bOpenMonitor = false

--- 监控函数调用，考虑效率最多返回3个值
---@param key any[] 监控标识键
---@param func function 要执行的函数
---@param ... any 函数参数
---@return any a 返回值1
---@return any b 返回值2
---@return any c 返回值3
function M.mo_call(key, func, ...)
    if not M.is_open_monitor() then
        local a, b, c = func(...)
        return a, b, c
    else
        local itt = measure.timestamp_us()
        local c1
        if mem_rt_monitor.IsOpen() then
            c1 = collectgarbage("count")
        end
        local a, b, c = func(...)
        skynet.send(".rt_monitor", "lua", "Record", measure.timestamp_us() - itt, key, MY_SERVICE_NAME)
        if mem_rt_monitor.IsOpen() and c1 then
            mem_rt_monitor.Record(key,c1)
        end
        return a, b, c
    end
end

--- 切换监控状态
---@param bFlag boolean 是否开启
function M.change_monitor(bFlag)
    bOpenMonitor = bFlag
end

--- 检查监控是否开启
---@return boolean 是否开启
function M.is_open_monitor()
    return bOpenMonitor
end

return M
