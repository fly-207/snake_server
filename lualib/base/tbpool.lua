---@module tbpool
---表对象池模块
---提供 table 对象的复用机制，减少内存分配和GC压力
---通过对象池预分配和回收 table，提高性能

local skynet = require "skynet"

local mmin = math.min
local mmax = math.max

---@class tbpool 表对象池模块
---@field Pop fun(): table 从池中获取一个空表
---@field Push fun(t: table) 将表归还到池中
---@field Collect fun() 执行垃圾收集，清理多余的表
---@field Clear fun(): integer 清空池中所有表，返回清空数量
---@field Init fun() 初始化模块，启动定时收集
---@field SetPre fun(i: integer) 设置预分配数量
---@field SetMaxCache fun(i: integer) 设置最大缓存数量
---@field SetMaxCollect fun(i: integer) 设置触发收集的阈值
---@field SetCollectTime fun(i: integer) 设置收集间隔时间
local M = {}

---@type integer 预分配池的初始大小
local iPre = 50
---@type integer 池中对象的最大缓存数量
local iMaxCache = 5000000
---@type integer 触发收集操作的最大对象数量
local iMaxCollect = 500000
---@type integer 收集操作的间隔时间（毫秒）
local iCollectTime = 50*60*100
---@type integer 收集操作的计数器
local iCollectNo = 0

---@type table[] 对象池列表
local lPool = {}
---@type integer 已经分配的对象计数
local iApplyPop = 0

---重置定时收集任务
---启动或重启定时收集循环
local function ResetCollect()
    iCollectNo = iCollectNo + 1
    local iStartNo = iCollectNo
    local f
    f = function ()
        if iCollectNo == iStartNo then
            M.Collect()
            skynet.timeout(iCollectTime, f)
        end
    end
    f()
end

---从池中获取一个空表
---如果池为空，会预分配一批新表
---@return table t 一个清空的表对象
function M.Pop()
    local i = #lPool
    local t = lPool[i]

    if t then
        lPool[i] = nil
    else
        t = {}
        local j = mmin(iPre, iMaxCache)
        for ii = 1, j do
            lPool[ii] = {}
        end
    end

    -- 移除对象的元数据，避免残留旧的元表影响
    setmetatable(t, nil)
    -- 清空对象的所有字段
    for k, _ in pairs(t) do
        t[k] = nil
    end
    -- 更新已分配对象计数
    iApplyPop = iApplyPop + 1

    return t
end

---将表归还到池中
---如果池已满则丢弃
---@param t table 要归还的表对象
function M.Push(t)
    local i = #lPool
    if i < iMaxCache then
        lPool[i+1] = t
    end
end

---执行垃圾收集
---移除池中多余的表，保留最近一次分配数量的两倍
function M.Collect()
    local i = 2*iApplyPop
    local j = #lPool
    if i < j then
        for ii = j, i+1, -1 do
            lPool[ii] = nil
        end
    end
    -- 重置已分配对象计数
    iApplyPop = 0
end

---清空池中所有表
---@return integer count 清空前的池大小
function M.Clear()
    local i = #lPool
    for ii = i, 1, -1 do
        lPool[ii] = nil
    end
    -- 返回清空前的池大小
    return i
end

---初始化模块
---启动定时收集任务
function M.Init()
    ResetCollect()
end

---设置预分配的表数量
---@param i integer 预分配数量
function M.SetPre(i)
    iPre = mmax(i, 0)
end

---设置池中表的最大缓存数量
---@param i integer 最大缓存数量
function M.SetMaxCache(i)
    iMaxCache = mmax(i, 0)
end

---设置触发收集操作的最大对象数量
---@param i integer 触发阈值
function M.SetMaxCollect(i)
    iMaxCollect = mmax(i, 0)
end

---设置收集操作的间隔时间
---@param i integer 间隔时间(毫秒)
function M.SetCollectTime(i)
    iCollectTime = mmax(i, 1)
    ResetCollect()
end

return M