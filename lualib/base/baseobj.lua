---@module baseobj
---基础对象模块，提供游戏对象的基类实现
---包含定时器、事件系统、自动保存等基础功能

local servicetime = require "base.servicetimer"
local servicesave = require "base.servicesave"
local memcmp = require "base.memcmp"
local tbpool = require "base.tbpool"

local basedefines = import(lualib_path("base.basedefines"))

---创建事件控制器实例
---@param ... any 构造参数
---@return CEventCtrl 事件控制器实例
function NewEventCtrl(...)
    return CEventCtrl:New(...)
end

---@class CBaseObject 基础对象类，所有游戏对象的基类
---@field m_oTimer CTimer|nil 定时器实例
---@field m_oEventCtrl CEventCtrl|nil 事件控制器实例
---@field m_iSaveId integer|nil 保存任务ID
CBaseObject = {}
CBaseObject.__index = CBaseObject

---创建基础对象实例
---@return CBaseObject 新创建的基础对象
function CBaseObject:New()
    local o = setmetatable(tbpool.Pop(), self)
    --local o = setmetatable({}, self)
    o.m_oTimer = nil
    o.m_oEventCtrl = nil
    o.m_iSaveId = nil
    --lxldebug for mem leak
    memcmp.track(o)
    return o
end

---释放基础对象资源
---清理定时器、事件控制器和保存任务
function CBaseObject:Release()
    if self.m_oTimer then
        self.m_oTimer:Release()
        self.m_oTimer = nil
    end
    if self.m_oEventCtrl then
        self.m_oEventCtrl:Release()
        self.m_oEventCtrl = nil
    end
    if self.m_iSaveId then
        self:CancelSave()
    end

    release(self)
    tbpool.Push(self)
end

---添加定时回调
---@param sKey string 定时器唯一标识
---@param iDelay integer 延迟时间(毫秒)
---@param func function 回调函数
function CBaseObject:AddTimeCb(sKey, iDelay, func)
    if not self.m_oTimer then
        self.m_oTimer = servicetime.NewTimer()
    end
    self.m_oTimer:AddCallback(sKey, iDelay, func)
end

---删除定时回调
---@param sKey string 定时器唯一标识
function CBaseObject:DelTimeCb(sKey)
    if self.m_oTimer then
        self.m_oTimer:DelCallback(sKey)
    end
end

---获取定时回调
---@param sKey string 定时器唯一标识
---@return function|nil callback 回调函数，不存在则返回nil
function CBaseObject:GetTimeCb(sKey)
    if self.m_oTimer then
        return self.m_oTimer:GetCallback(sKey)
    end
end

---添加事件监听
---@param obj any 监听者对象
---@param iType integer 事件类型
---@param func function 事件处理函数
function CBaseObject:AddEvent(obj, iType, func)
    if not self.m_oEventCtrl then
        self.m_oEventCtrl = CEventCtrl:New()
    end
    self.m_oEventCtrl:AddEvent(obj, iType, func)
end

---删除事件监听
---@param obj any 监听者对象
---@param iType integer 事件类型
function CBaseObject:DelEvent(obj, iType)
    if self.m_oEventCtrl then
        self.m_oEventCtrl:DelEvent(obj, iType)
    end
end

---触发事件
---@param iType integer 事件类型
---@param mData table|nil 事件数据
function CBaseObject:TriggerEvent(iType, mData)
    if self.m_oEventCtrl then
        self.m_oEventCtrl:TriggerEvent(iType, mData)
    end
end

---申请自动保存
---@param f function 保存回调函数
---@param iTime integer|nil 保存间隔时间(毫秒)
function CBaseObject:ApplySave(f, iTime)
    assert(not self.m_iSaveId, "ApplySave fail")
    self.m_iSaveId = servicesave.NewSaveObj(f, iTime)
end

---获取保存任务ID
---@return integer|nil saveId 保存任务ID
function CBaseObject:GetSaveId()
    return self.m_iSaveId
end

---取消自动保存
function CBaseObject:CancelSave()
    assert(self.m_iSaveId, "CancelSave fail")
    servicesave.DelSaveObj(self.m_iSaveId)
    self.m_iSaveId = nil
end

---立即执行保存
function CBaseObject:DoSave()
    assert(self.m_iSaveId, "DoSave fail")
    servicesave.DoSaveObj(self.m_iSaveId)
end

---添加保存合并，将另一个对象的保存合并到当前对象
---@param obj CBaseObject 要合并的对象
function CBaseObject:AddSaveMerge(obj)
    assert(self.m_iSaveId and obj:GetSaveId(), "AddSaveMerge fail")
    if self.m_iSaveId ~= obj:GetSaveId() then
        servicesave.AddSaveMerge(self.m_iSaveId, obj:GetSaveId())
    end
end


---@class CEventCtrl 事件控制器类，管理事件的注册和触发
---@field m_mHandler table<integer, table<string, function>> 事件处理器映射 {eventType: {objKey: handler}}
CEventCtrl = {}
CEventCtrl.__index = CEventCtrl

---创建事件控制器实例
---@return CEventCtrl 新创建的事件控制器
function CEventCtrl:New()
    local o = setmetatable({}, self)
    o.m_mHandler = {}
    return o
end

---释放事件控制器资源
function CEventCtrl:Release()
    release(self)
end

---添加事件监听
---@param obj any 监听者对象，用于生成唯一标识
---@param iType integer 事件类型
---@param func function 事件处理函数
function CEventCtrl:AddEvent(obj, iType, func)
    local sKey = tostring(obj)
    if not self.m_mHandler[iType] then
        self.m_mHandler[iType] = {}
    end
    self.m_mHandler[iType][sKey] = func
end

---删除事件监听
---@param obj any 监听者对象
---@param iType integer 事件类型
function CEventCtrl:DelEvent(obj, iType)
    local sKey = tostring(obj)
    if self.m_mHandler[iType] then
        self.m_mHandler[iType][sKey] = nil
    end
end

---触发事件，调用所有注册的处理函数
---@param iType integer 事件类型
---@param mData table|nil 事件数据
function CEventCtrl:TriggerEvent(iType, mData)
    local m = self.m_mHandler[iType]
    if m then
        for k, func in pairs(m) do
            safe_call(func, iType, mData)
        end
    end
end
