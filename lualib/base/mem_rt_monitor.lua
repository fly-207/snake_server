---@module "base.mem_rt_monitor"
--- 实时内存监控模块
--- 用于跟踪函数调用的内存分配情况

local skynet = require "skynet"

---@class MemRtMonitorModule 实时内存监控模块
---@field Record fun(key: any[], iMem: number) 记录内存使用
---@field Start fun() 开始监控
---@field Stop fun() 停止监控
---@field IsOpen fun(): boolean 检查是否开启
local M = {}

---@type table 记录表
local mRecord = {}
---@type boolean 是否开启
local bOpen = false

--- 记录内存使用
---@param key any[] 监控标识键
---@param iMem number 内存使用量(KB)
function M.Record(key,iMem)
    local interactive = require "base.interactive"
    local c2 = collectgarbage("count")
    local i1 = iMem*1024
    local i2 =  c2*1024
    if i2-i1 > 1000  then
        local sKey = ConvertTblToStr(key)
        sKey = string.format("{%s}_%s",MY_SERVICE_NAME,sKey)
        if not mRecord[sKey] then
            mRecord[sKey] = {}
        end 
        local iSum = mRecord.sum or 0
        mRecord.sum = iSum + 1 
        local mKeyRecord = mRecord[sKey]
        local iCnt = mKeyRecord.count or 0
        mKeyRecord.count = iCnt + 1 
        local iTime = mKeyRecord.time or 0
        mKeyRecord.time = iTime + i2-i1
        mRecord[sKey] = mKeyRecord
        if mRecord.sum >= 200 then
            mRecord.sum = nil 
            interactive.Send(".mem_rt_monitor", "common", "AddRtMonitor",mRecord)
            mRecord = {}
        end 
    end 
end

--- 开始实时内存监控
function M.Start()
    if bOpen then
        M.Stop()
    end
    bOpen = true
end

--- 停止实时内存监控
function M.Stop()
    if not bOpen then
        return
    end
    bOpen = false
end

--- 检查实时内存监控是否开启
---@return boolean 是否开启
function M.IsOpen()
    if bOpen then
        return true
    end
    return false
end

return M  
