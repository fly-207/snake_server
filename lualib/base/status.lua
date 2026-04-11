---@module status
---状态管理模块
---提供对象状态的存储和管理功能
---支持状态值、状态时间和额外数据的存取

---创建状态对象实例
---@param ... any 构造参数
---@return CStatus 新创建的状态对象
function NewStatus(...)
    local o = CStatus:New(...)
    return o
end

---@class CStatus 状态管理类
---@field m_iStatus integer|nil 当前状态值
---@field m_iStatusTime integer|nil 状态设置时间(毫秒)
---@field m_mExtra table<string, any> 额外数据存储
CStatus = {}
CStatus.__index = CStatus

---创建状态对象实例
---@return CStatus 新创建的状态对象
function CStatus:New()
    local o = setmetatable({}, self)
    o.m_iStatus = nil
    o.m_iStatusTime = nil
    o.m_mExtra = {}
    return o
end

---释放状态对象资源
function CStatus:Release()
    release(self)
end

---设置状态
---@param iStatus integer 状态值
---@param iTime integer|nil 状态时间(毫秒)，默认为当前时间
function CStatus:Set(iStatus, iTime)
    if not iTime then
        iTime = get_msecond()
    end
    self.m_iStatus = iStatus
    self.m_iStatusTime = iTime
end

---获取状态
---@return integer|nil status 状态值
---@return integer|nil time 状态时间
function CStatus:Get()
    return self.m_iStatus, self.m_iStatusTime
end

---获取额外数据
---@param sKey string 数据键名
---@return any value 数据值
function CStatus:GetExtra(sKey)
    return self.m_mExtra[sKey]
end

---设置额外数据
---@param sKey string 数据键名
---@param rValue any 数据值
function CStatus:SetExtra(sKey, rValue)
    self.m_mExtra[sKey] = rValue
end
