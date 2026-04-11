---@module idpool
---ID池模块，提供可复用ID的分配和回收机制
---支持ID回收后的冷却时间，避免ID被立即重用

local skynet = require "skynet"

---@class CIDPool ID池类，管理可复用ID的分配和回收
---@field m_iAvailableTime integer ID可重用的冷却时间(秒)
---@field m_iBaseId integer 当前最大ID基数
---@field m_mCollect table<integer, integer> 已回收待复用的ID {id: collectTime}
---@field m_mProduct table<integer, integer> 可立即分配的ID {id: 1}
CIDPool = {}
CIDPool.__index = CIDPool

local floor = math.floor
local max = math.max
local tinsert = table.insert
local tremove = table.remove

---创建新的ID池实例
---@param t number ID可重用的冷却时间(秒)
---@param i number|nil 初始基础ID，默认为0
---@return CIDPool 新创建的ID池
function CIDPool:New(t, i)
    local o = setmetatable({}, self)
    o.m_iAvailableTime = floor(max(t, 0))
    o.m_iBaseId = floor(max(i or 0, 0))
    o.m_mCollect = {}
    o.m_mProduct = {}
    return o
end

---初始化ID池
function CIDPool:Init()
end

---释放ID池资源
function CIDPool:Release()
end

---修改ID可重用的冷却时间
---@param t number 新的冷却时间(秒)
function CIDPool:ChangeAvailableTime(t)
    self.m_iAvailableTime = floor(max(t, 0))
end

---将已过冷却期的ID从回收池移到可用池
---检查所有已回收的ID，将满足冷却时间的ID标记为可分配
function CIDPool:Produce()
    local iNowTime = get_time()
    local iAvailableTime = self.m_iAvailableTime
    local m = {}
    for k, v in pairs(self.m_mCollect) do
        if iNowTime - v >= iAvailableTime then
            m[k] = 1
        end
    end
    for k, _ in pairs(m) do
        self.m_mCollect[k] = nil
        self.m_mProduct[k] = 1
    end
end

---回收一个ID，进入冷却期
---@param id integer 要回收的ID
function CIDPool:Free(id)
    if id >= 0 and id <= self.m_iBaseId and not self.m_mCollect[id] and not self.m_mProduct[id] then
        self.m_mCollect[id] = get_time()
    else
        print(string.format("CIDPool Free error:%s", id))
    end
end

---获取一个可用的ID
---优先从可用池获取，如果没有则分配新ID
---@return integer id 分配的ID
function CIDPool:Gain()
    local m = self.m_mProduct
    local id = next(m)
    if id then
        m[id] = nil
        return id
    end
    self.m_iBaseId = self.m_iBaseId + 1
    return self.m_iBaseId
end
