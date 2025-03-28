-- 交互通信模块
-- 用于处理服务之间的消息传递，支持发送消息、请求-响应模式
local skynet = require "skynet"
local extype = require "base.extype"
local rt_monitor = require "base.rt_monitor"

local M = {}

-- 是否开启消息合并模式
local bOpenMerge = false

local tinsert = table.insert

-- 消息类型定义
local SEND_TYPE = 1    -- 发送类型：单向消息
local REQUEST_TYPE = 2 -- 请求类型：需要响应的请求
local RESPONSE_TYPE = 3 -- 响应类型：对请求的响应

-- 存储回调函数和调试信息的表
local mNote = {}  -- 存储请求的回调函数
local mDebug = {} -- 存储请求的调试信息
local mQueue = {} -- 消息队列，用于消息合并模式
local iSessionIdx = 0 -- 会话ID计数器

-- 处理单条命令的核心函数
-- @param moduleLogic: 模块逻辑处理函数
-- @param mRecord: 消息记录
-- @param mData: 消息数据
local function HandleSingleCmd(moduleLogic, mRecord, mData)
    local iType = mRecord.type
    if iType == RESPONSE_TYPE then
        -- 处理响应消息
        local iNo = mRecord.session
        local f = mNote[iNo]
        local md = mDebug[iNo]
        if f then
            mNote[iNo] = nil
            if md then
                safe_call(function ()
                    rt_monitor.mo_call({"interactive", iType, md.module, md.cmd}, f, mRecord, mData)
                end)
            else
                safe_call(function ()
                    rt_monitor.mo_call({"interactive", iType, "None", "None"}, f, mRecord, mData)
                end)
            end
        end
        mDebug[iNo] = nil
    else
        -- 处理请求或发送消息
        local sModule = mRecord.module
        local sCmd = mRecord.cmd

        if sModule ~= "default" then
            if moduleLogic then
                safe_call(function ()
                    rt_monitor.mo_call({"interactive", iType, sModule, sCmd}, moduleLogic.Invoke, sModule, sCmd, mRecord, mData)
                end)
            end
        else
            -- 处理默认模块的命令
            local rr, br
            if sCmd == "ExecuteString" then
                -- 执行字符串命令
                local f, sErr = load(mData.cmd)
                if not f then
                    print(sErr)
                else
                    br, rr = safe_call(function ()
                        return rt_monitor.mo_call({"interactive", iType, sModule, sCmd}, f)
                    end)
                end
            end
            if iType == REQUEST_TYPE then
                M.Response(mRecord.source, mRecord.session, {data = rr})
            end
        end
    end
end

-- 初始化交互模块
-- @param bOpen: 是否开启消息合并模式
function M.Init(bOpen)
    if bOpen then
        bOpenMerge = true
    else
        bOpenMerge = false
    end
end

-- 将消息推入队列
-- @param sAddr: 目标地址
-- @param mArgs: 消息参数
-- @param mData: 消息数据
function M.PushQueue(sAddr, mArgs, mData)
    local iAddr = skynet.servicekey(sAddr)
    if iAddr then
        local m = mQueue[iAddr]
        if not m then
            m = {}
            mQueue[iAddr] = m
        end
        tinsert(m, {mArgs, mData})
    else
        print(string.format("lxldebug interactive PushQueue error %s", sAddr))
    end
end

-- 处理队列中的所有消息
function M.PopQueueAll()
    for k, v in pairs(mQueue) do
        skynet.send(k, "logic", v)
    end
    mQueue = {}
end

-- 获取新的会话ID
function M.GetSession()
    iSessionIdx = iSessionIdx + 1
    if iSessionIdx >= 100000000 then
        iSessionIdx = 1
    end
    return iSessionIdx
end

-- 发送单向消息
-- @param iAddr: 目标地址
-- @param sModule: 模块名
-- @param sCmd: 命令名
-- @param mData: 消息数据
function M.Send(iAddr, sModule, sCmd, mData)
    mData = mData or {}
    if bOpenMerge then
        M.PushQueue(iAddr, {source = MY_ADDR, module = sModule, cmd = sCmd, session = 0, type =SEND_TYPE}, mData)
    else
        skynet.send(iAddr, "logic", {source = MY_ADDR, module = sModule, cmd = sCmd, session = 0, type =SEND_TYPE}, mData)
    end
end

-- 发送请求消息
-- @param iAddr: 目标地址
-- @param sModule: 模块名
-- @param sCmd: 命令名
-- @param mData: 消息数据
-- @param fCallback: 回调函数
function M.Request(iAddr, sModule, sCmd, mData, fCallback)
    mData = mData or {}
    local iNo  = M.GetSession()
    mNote[iNo] = fCallback
    mDebug[iNo] = {
        time = get_time(),
        addr = iAddr,
        module = sModule,
        cmd = sCmd,
    }
    if bOpenMerge then
        M.PushQueue(iAddr, {source = MY_ADDR, module = sModule, cmd = sCmd, session = iNo, type = REQUEST_TYPE}, mData)
    else
        skynet.send(iAddr, "logic", {source = MY_ADDR, module = sModule, cmd = sCmd, session = iNo, type = REQUEST_TYPE}, mData)
    end
end

-- 发送响应消息
-- @param iAddr: 目标地址
-- @param iNo: 会话ID
-- @param mData: 响应数据
function M.Response(iAddr, iNo, mData)
    mData = mData or {}
    if bOpenMerge then
        M.PushQueue(iAddr, {source = MY_ADDR, session = iNo, type = RESPONSE_TYPE}, mData)
    else
        skynet.send(iAddr, "logic", {source = MY_ADDR, session = iNo, type = RESPONSE_TYPE}, mData)
    end
end

-- 初始化消息分发器
-- @param logiccmd: 逻辑处理函数
function M.Dispatch(logiccmd)
    -- 注册消息协议
    skynet.register_protocol {
        name = "logic",
        id = extype.LOGIC_TYPE,
        pack = skynet.pack,
        unpack = skynet.unpack,
    }

    if bOpenMerge then
        -- 消息合并模式下的消息处理
        skynet.dispatch("logic", function(session, address, lQueue)
            for _, oq in ipairs(lQueue) do
                local mRecord = oq[1]
                local mData = oq[2]
                HandleSingleCmd(logiccmd, mRecord, mData)
            end
        end)

        -- 定时处理队列中的消息
        local funcPopQueue
        funcPopQueue = function ()
            M.PopQueueAll()
            skynet.timeout(1, funcPopQueue)
        end
        funcPopQueue()
    else
        -- 普通模式下的消息处理
        skynet.dispatch("logic", function(session, address, mRecord, mData)
            HandleSingleCmd(logiccmd, mRecord, mData)
        end)
    end

    -- 会话超时检查
    local funcCheckSession
    funcCheckSession = function ()
        local iTime = get_time()
        local lDel = {}
        for k, v in pairs(mDebug) do
            local iDiff = iTime - v.time
            if iDiff >= 10 then
                print(string.format("warning: interactive check delay(%s sec) session:%d time:%d addr:%s module:%s cmd:%s",
                    iDiff, k, v.time, v.addr, v.module, v.cmd)
                )
            end
            if iDiff >= 300 then
                print(string.format("warning: interactive delete delay(%s sec) session:%d time:%d addr:%s module:%s cmd:%s",
                    iDiff, k, v.time, v.addr, v.module, v.cmd)
                )
                tinsert(lDel, k)
            end
        end
        for _, k in ipairs(lDel) do
            local v = mDebug[k]
            mNote[k] = nil
            mDebug[k] = nil
        end
        skynet.timeout(2*100, funcCheckSession)
    end
    funcCheckSession()
end

return M
