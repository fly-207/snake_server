-- 导入skynet模块
local skynet = require "skynet"

-- 导入math模块，优化性能，避免每次调用都进行查找
local mmin = math.min
local mmax = math.max

-- 定义模块M
local M = {}

-- 预分配池的初始大小
local iPre = 50
-- 池中对象的最大缓存数量
local iMaxCache = 5000000
-- 触发收集操作的最大对象数量
local iMaxCollect = 500000
-- 收集操作的间隔时间（毫秒）
local iCollectTime = 50*60*100
-- 收集操作的计数器
local iCollectNo = 0

-- 对象池
local lPool = {}
-- 已经分配的对象计数
local iApplyPop = 0

-- 定时器函数，用于定期执行收集操作
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

-- 从池中获取一个对象
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

-- 将对象返回到池中
function M.Push(t)
    local i = #lPool
    if i < iMaxCache then
        lPool[i+1] = t
    end
end

-- 执行垃圾收集，移除池中部分对象
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

-- 清空池中所有对象
function M.Clear()
    local i = #lPool
    for ii = i, 1, -1 do
        lPool[ii] = nil
    end
    -- 返回清空前的池大小
    return i
end

-- 初始化模块，启动定时收集任务
function M.Init()
    ResetCollect()
end

-- 设置预分配的对象数量
function M.SetPre(i)
    iPre = mmax(i, 0)
end

-- 设置池中对象的最大缓存数量
function M.SetMaxCache(i)
    iMaxCache = mmax(i, 0)
end

-- 设置触发收集操作的最大对象数量
function M.SetMaxCollect(i)
    iMaxCollect = mmax(i, 0)
end

-- 设置收集操作的间隔时间
function M.SetCollectTime(i)
    iCollectTime = mmax(i, 1)
    ResetCollect()
end

-- 返回模块M
return M