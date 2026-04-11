
---@module memcmp
---内存快照对比模块，用于检测内存泄漏和跟踪对象分配
---提供内存快照、差异对比、对象跟踪等功能

local skynet = require "skynet"
local snapshot = require "snapshot"

---@class MemorySnapshot 内存快照字典，key为对象地址，value为对象描述
---@field [string] string 对象地址到描述的映射

---@class TrackInfo 跟踪统计信息
---@field [1] string 调用栈信息
---@field [2] integer 出现次数

---@class memcmp 内存对比模块
---@field current fun(): MemorySnapshot 获取当前内存快照
---@field shot fun() 拍摄内存快照
---@field diff fun(): MemorySnapshot|nil 获取两次快照的差异
---@field track fun(obj: any) 跟踪对象的分配位置
---@field showtrack fun(): TrackInfo[] 显示跟踪的对象统计
---@field printjemalloc fun() 打印jemalloc内存信息
local M = {}

---@type table[] 内存快照列表，最多保存2个快照用于对比
local lmem = {}

---@type table<any, string> 弱引用表，记录对象到调用栈的映射
local mtrack = setmetatable({}, {__mode="kv"})

---获取当前内存快照
---@return MemorySnapshot snapshot 当前内存中所有对象的快照
function M.current()
    local s = snapshot()
    ---@type MemorySnapshot
    local m = {}
    for k, v in pairs(s) do
        m[tostring(k)] = tostring(v)
    end
    return m
end

---拍摄内存快照，保存到内部列表中
---最多保存2个快照，新快照会替换旧快照
function M.shot()
    local iLen = #lmem
    if iLen == 0 then
        lmem[1] = snapshot()
    elseif iLen == 1 then
        lmem[2] = snapshot()
    else
        lmem[1] = lmem[2]
        lmem[2] = snapshot()
    end
end

---获取两次快照之间的差异（新增的对象）
---@return MemorySnapshot|nil diff 新增对象的快照，如果快照不足2个则返回nil
function M.diff()
    local iLen = #lmem
    if iLen < 2 then
        return
    end

    local m = {}

    local s1 = lmem[1]
    local s2 = lmem[2]

    for k, v in pairs(s2) do
        if s1[k] == nil then
            m[tostring(k)] = tostring(v)
        end
    end

    return m
end

---跟踪对象的分配位置
---仅在 is_auto_track_baseobject() 返回 true 时生效
---@param obj any 要跟踪的对象
function M.track(obj)
    if is_auto_track_baseobject() then
        local key = debug.traceback()
        mtrack[obj] = key
    end
end

---显示跟踪的对象统计信息
---会先触发垃圾回收，然后统计各调用栈的对象数量
---@return TrackInfo[] list 按对象数量降序排列的统计列表
function M.showtrack()
    collectgarbage("collect")
    local m = {}
    for k, v in pairs(mtrack) do
        if not m[v] then
            m[v] = 0
        end
        m[v] = m[v] + 1
    end

    local l = {}
    for k, v in pairs(m) do
        table.insert(l, {k, v})
    end
    table.sort(l, function (a, b)
        return a[2] > b[2]
    end)

    return l
end

---打印 jemalloc 内存分配器的详细信息
---用于诊断内存使用情况
function M.printjemalloc()
    local memory = require "memory"
    memory.dumpinfo()
end

return M
