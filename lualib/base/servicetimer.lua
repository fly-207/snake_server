-- 定时器服务模块
-- 提供基于 skynet 的定时器功能，支持添加、删除定时回调
local skynet = require "skynet"
local ltimer = require "ltimer"
local rt_monitor = require "base.rt_monitor"

local M = {}
local iTestOverflow = 0  -- 用于测试时间溢出的变量

local tremove = table.remove
local tinsert = table.insert
local mmax = math.max
local mfloor = math.floor

local oTimerMgr  -- 全局定时器管理器实例

-- 调试用的堆栈跟踪函数
local function Trace(sMsg)
    print(debug.traceback(sMsg))
end

-- 定时器驱动函数，每0.01秒执行一次
local DriverFunc
DriverFunc = function ()
    if not oTimerMgr.m_bExecute then
        oTimerMgr:FlushNow()
        oTimerMgr.m_bExecute = true
        oTimerMgr.m_oCobj:ltimer_update(oTimerMgr:GetTime(), oTimerMgr.m_lCbHandles)
        oTimerMgr:ProxyFunc()
        oTimerMgr.m_bExecute = false
        skynet.timeout(1, DriverFunc)
    end
end

-- 单个定时器类
local CTimer = {}
CTimer.__index = CTimer

-- 创建新的定时器实例
function CTimer:New()
    local o = setmetatable({}, self)
    o.m_mName2Id = {}  -- 存储定时器名称到ID的映射
    return o
end

-- 释放定时器资源
function CTimer:Release()
    for k, v in pairs(self.m_mName2Id) do
        oTimerMgr:DelCallback(v)
    end
    self.m_mName2Id = {}

    release(self)
end

-- 添加定时回调
-- @param sKey: 定时器标识名
-- @param iDelay: 延迟时间(毫秒)
-- @param func: 回调函数
function CTimer:AddCallback(sKey, iDelay, func)
    assert(iDelay>0,string.format("CTimer AddCallback delay error too small %s %s", sKey, iDelay))
    iDelay = mmax(1, mfloor(iDelay/10))
    assert(iDelay<2^32, string.format("CTimer AddCallback delay error too huge %s %s", sKey, iDelay))
    assert(func, string.format("CTimer AddCallback func error , func is nil %s %s", sKey, iDelay))
    local iOldId = self.m_mName2Id[sKey]
    if iOldId and not oTimerMgr:GetCallback(iOldId) then
        self.m_mName2Id[sKey] = nil
        iOldId = nil
    end

    local mName2Id = self.m_mName2Id
    local f
    f = function ()
        local id = mName2Id[sKey]
        if not id then
            return
        end
        mName2Id[sKey] = nil

        rt_monitor.mo_call({"servicetimer", sKey}, func)
    end

    local iNewId = oTimerMgr:AddCallback(iDelay, f)
    self.m_mName2Id[sKey] = iNewId
    if iOldId then
        print(string.format("[WARNING] CTimer AddCallback repeated %s %d %d %s", sKey, iOldId, iNewId,debug.traceback()))
    end
end

-- 删除定时回调
function CTimer:DelCallback(sKey)
    local id = self.m_mName2Id[sKey]
    if id then
        self.m_mName2Id[sKey] = nil
        oTimerMgr:DelCallback(id)
    end
end

-- 获取定时回调
function CTimer:GetCallback(sKey)
    local id = self.m_mName2Id[sKey]
    if not id then
        return nil
    end
    return oTimerMgr:GetCallback(id)
end

-- 定时器管理器类
local CTimerMgr = {}
CTimerMgr.__index = CTimerMgr

-- 创建新的定时器管理器实例
function CTimerMgr:New()
    local o = setmetatable({}, self)

    o.m_lCbHandles = {}      -- 回调句柄列表
    o.m_iCbDispatchId = 0    -- 回调分发ID
    o.m_bExecute = false     -- 执行状态标志
    o.m_mCbUsedId = {}       -- 已使用的回调ID映射
    o.m_lCbReUseId = {}      -- 可重用的回调ID列表

    o:FlushStart()
    o:FlushNow()
    o.m_oCobj = ltimer.ltimer_create(o:GetTime())

    return o
end

-- 释放定时器管理器资源
function CTimerMgr:Release()
    release(self)
end

-- 初始化定时器管理器
function CTimerMgr:Init()
    skynet.timeout(1, DriverFunc)
end

-- 刷新服务启动时间
function CTimerMgr:FlushStart()
    self.m_iServiceStartTime = skynet.starttime()
end

-- 刷新当前时间
function CTimerMgr:FlushNow()
    self.m_iServiceNow = skynet.now()
end

-- 获取服务时间
function CTimerMgr:GetTime()
    return self.m_iServiceStartTime*100+self.m_iServiceNow+iTestOverflow
end

-- 获取当前时间
function CTimerMgr:GetNow()
    return self.m_iServiceNow
end

-- 获取服务启动时间
function CTimerMgr:GetStartTime()
    return self.m_iServiceStartTime
end

-- 创建新的定时器
function CTimerMgr:NewTimer()
    return CTimer:New()
end

-- 获取新的回调分发ID
function CTimerMgr:GetCbDispatchId()
    local l = self.m_lCbReUseId
    local id = tremove(l, #l)
    if id then
        return id
    end
    self.m_iCbDispatchId = self.m_iCbDispatchId + 1
    return self.m_iCbDispatchId
end

-- 添加回调
function CTimerMgr:AddCallback(iDelay, func)
    local iCbId = self:GetCbDispatchId()
    self.m_mCbUsedId[iCbId] = func
    self.m_oCobj:ltimer_add_time(iCbId, iDelay)
    return iCbId
end

-- 删除回调
function CTimerMgr:DelCallback(iCbId)
    self.m_mCbUsedId[iCbId] = nil
end

-- 获取回调函数
function CTimerMgr:GetCallback(iCbId)
    return self.m_mCbUsedId[iCbId]
end

-- 执行所有待处理的回调函数
function CTimerMgr:ProxyFunc()
    for _, v in ipairs(self.m_lCbHandles) do
        tinsert(self.m_lCbReUseId, v)
        local f = self.m_mCbUsedId[v]
        if f then
            self.m_mCbUsedId[v] = nil
            xpcall(f, Trace)
        end
    end
    list_clear(self.m_lCbHandles)
end

-- 模块初始化函数
function M.Init()
    if not oTimerMgr then
        oTimerMgr = CTimerMgr:New()
        oTimerMgr:Init()
    end
end

-- 创建新的定时器
function M.NewTimer()
    return oTimerMgr:NewTimer()
end

-- 添加定时回调
function M.AddCallback(iDelay, func)
    assert(iDelay>0, string.format("servicetimer AddCallback delay error too small %s", iDelay))
    iDelay = mmax(1, mfloor(iDelay/10))
    assert(iDelay<2^32, string.format("servicetimer AddCallback delay error too huge %s", iDelay))
    return oTimerMgr:AddCallback(iDelay, func)
end

-- 删除定时回调
function M.DelCallback(iCbId)
    oTimerMgr:DelCallback(iCbId)
end

-- 设置测试用的时间溢出值
function M.TestOverflow(i)
    iTestOverflow = i
end

-- 获取服务时间
function M.ServiceTime()
    return oTimerMgr:GetTime()
end

-- 获取当前时间
function M.ServiceNow()
    return oTimerMgr:GetNow()
end

-- 获取服务启动时间
function M.ServiceStartTime()
    return oTimerMgr:GetStartTime()
end

return M
