---@module baserecycle
---对象回收模块
---提供延迟释放和批量回收对象的机制
---支持回收失败的记录和重试

local skynet = require "skynet"

---@type table<any, boolean> 等待回收的对象
local recycle_wait = {}
---@type table<any, string> 回收失败的对象及错误信息
local recycle_fail = {}

---@class baserecycle 对象回收模块
local M = {}

---立即释放对象
---@param obj table 要释放的对象，必须有 Release 方法
function M.now_release(obj)
    assert(obj.Release, "baserecycle now_release fail")
    local br, rr = safe_call(obj.Release, obj)
    if not br then
        recycle_fail[obj] = rr
    end
end

---延迟释放对象
---@param obj table 要延迟释放的对象，必须有 Release 方法
function M.wait_release(obj)
    assert(obj.Release, "baserecycle wait_release fail")
    recycle_wait[obj] = true
end

---执行批量回收
---递归处理所有等待回收的对象，最多递归10层
function M.recycle()
    local limit = 0
    local repeated = {}

    local m = M.getwait()
    while table_count(m) > 0 do
        limit = limit + 1
        recycle_wait = {}

        for v, _ in pairs(m) do
            if not repeated[v] then
                repeated[v] = true
                local br, rr = safe_call(v.Release, v)
                if not br then
                    recycle_fail[v] = rr
                end
            end
        end

        if limit >= 10 then
            print(string.format("warning: recycle deep limit:%d", limit))
            break
        end
        m = M.getwait()
    end
end

---获取等待回收的对象列表
---@return table<any, boolean> wait 等待回收的对象表
function M.getwait()
    local m = {}
    for k, v in pairs(recycle_wait) do
        m[k] = v
    end
    return m
end

---获取回收失败的对象列表
---@return table<any, string> fail 回收失败的对象及错误信息
function M.getfail()
    local m = {}
    for k, v in pairs(recycle_fail) do
        m[k] = v
    end
    return m
end

---清理回收失败的对象
---@param force boolean|nil 是否强制清空失败列表
function M.cleanfail(force)
    local m = M.getfail()
    for v, _ in pairs(m) do
        local br, rr = safe_call(v.Release, v)
        if not br then
            recycle_fail[v] = rr
        else
            recycle_fail[v] = nil
        end
    end

    if force then
        recycle_fail = {}
    end
end

return M
