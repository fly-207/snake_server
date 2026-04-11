
---@module "base.servicesave"
--- 服务保存模块
--- 提供自动保存对象数据到数据库的功能，支持合并保存和递归保存

local skynet = require "skynet"
local servicetime = require "base.servicetimer"

---@class ServiceSaveModule 服务保存模块
---@field Init fun() 初始化
---@field NewSaveObj fun(f: function, i?: integer): integer 创建新的保存对象
---@field SaveAll fun() 保存所有对象
---@field AddSaveMerge fun(id1: integer, id2: integer) 添加保存合并关系
---@field DelSaveObj fun(id: integer) 删除保存对象
---@field DoSaveObj fun(id: integer) 立即保存对象
local M = {}

---@type CSaveObjMgr? 全局的保存对象管理器
local oSaveObjMgr

--- 调试用的堆栈跟踪函数
---@param sMsg string 消息
local function Trace(sMsg)
    print(debug.traceback(sMsg))
end


---@class CSaveObj 可保存对象类
---@field m_oTimer CTimer 定时器对象
---@field m_iSaveId integer 保存ID
---@field m_iSaveTime integer 保存间隔时间(ms)
---@field m_funcSave function 保存回调函数
---@field m_mMerge table<integer, boolean> 合并保存的ID映射
local CSaveObj = {}
CSaveObj.__index = CSaveObj

--- 创建新的可保存对象
---@param id integer 保存ID
---@param f function 保存回调函数
---@param i? integer 保存间隔时间(ms)
---@return CSaveObj
function CSaveObj:New(id, f, i)
    local o = setmetatable({}, self)
    o.m_oTimer = servicetime.NewTimer()
    o.m_iSaveId = id
    o.m_iSaveTime = math.min(20*60*1000, math.max(1*60*1000, i or 5*60*1000))
    o.m_funcSave = f
    o.m_mMerge = {}
    return o
end

--- 释放可保存对象资源
function CSaveObj:Release()
    self.m_oTimer:Release()

    release(self)
end

--- 添加定时回调
---@param sKey string 回调标识
---@param iDelay integer 延迟时间(ms)
---@param func function 回调函数
function CSaveObj:AddTimeCb(sKey, iDelay, func)
    self.m_oTimer:AddCallback(sKey, iDelay, func)
end

--- 删除定时回调
---@param sKey string 回调标识
function CSaveObj:DelTimeCb(sKey)
    self.m_oTimer:DelCallback(sKey)
end

--- 初始化可保存对象
function CSaveObj:Init()
    self:PrepareSaveDb()
end

--- 准备保存到数据库的定时任务
function CSaveObj:PrepareSaveDb()
    self:DelTimeCb("DoSaveObj")
    self:AddTimeCb("DoSaveObj", self.m_iSaveTime, function ()
        oSaveObjMgr:DoSaveObj(self:GetSaveId())
    end)
end

--- 获取保存ID
---@return integer 保存ID
function CSaveObj:GetSaveId()
    return self.m_iSaveId
end

--- 执行保存操作
function CSaveObj:DoSave()
    xpcall(self.m_funcSave, Trace)
    self:PrepareSaveDb()
end

--- 获取合并保存映射表
---@return table<integer, boolean> 合并映射表
function CSaveObj:GetMergeMap()
    return self.m_mMerge
end

--- 清空合并保存映射表
function CSaveObj:ClearMergeMap()
    self.m_mMerge = {}
end

--- 添加合并保存关系
---@param id integer 要合并的对象ID
function CSaveObj:AddMerge(id)
    self.m_mMerge[id] = true
end

--- 删除合并保存关系
---@param id integer 要删除的对象ID
function CSaveObj:DelMerge(id)
    self.m_mMerge[id] = nil
end


---@class CSaveObjMgr 保存对象管理器类
---@field m_mAllSave table<integer, CSaveObj> 所有保存对象映射
---@field m_iSaveDispatchId integer 保存分发ID生成器
---@field m_mProtectedRepeated table<integer, boolean> 防重复保存标记
---@field m_iSavingCnt integer 正在保存的数量
local CSaveObjMgr = {}
CSaveObjMgr.__index = CSaveObjMgr

--- 创建新的保存对象管理器
---@return CSaveObjMgr
function CSaveObjMgr:New()
    local o = setmetatable({}, self)
    o.m_mAllSave = {}
    o.m_iSaveDispatchId = 0
    o.m_mProtectedRepeated = {}
    o.m_iSavingCnt = 0
    return o
end

--- 释放保存对象管理器资源
function CSaveObjMgr:Release()
    for _, v in pairs(self.m_mAllSave) do
        v:Release()
    end
    self.m_mAllSave = {}
    release(self)
end

--- 初始化保存对象管理器
function CSaveObjMgr:Init()
end

--- 获取新的保存分发ID
---@return integer 保存分发ID
function CSaveObjMgr:GetSaveDispatchId()
    self.m_iSaveDispatchId = self.m_iSaveDispatchId + 1
    return self.m_iSaveDispatchId
end

--- 创建新的保存对象
---@param f function 保存回调函数
---@param i? integer 保存间隔时间(ms)
---@return integer 保存对象ID
function CSaveObjMgr:NewSaveObj(f, i)
    local id = self:GetSaveDispatchId()
    local o = CSaveObj:New(id, f, i)
    o:Init()
    self.m_mAllSave[id] = o
    return id
end

--- 获取保存对象
---@param id integer 保存对象ID
---@return CSaveObj? 保存对象
function CSaveObjMgr:GetSaveObj(id)
    return self.m_mAllSave[id]
end

--- 执行保存对象
---@param id integer 保存对象ID
function CSaveObjMgr:DoSaveObj(id)
    local o = self.m_mAllSave[id]
    if o then
        self:_RecuSave(o)
    end
end

--- 递归保存对象(内部方法)
---@param obj CSaveObj 要保存的对象
function CSaveObjMgr:_RecuSave(obj)
    if self.m_mProtectedRepeated[obj:GetSaveId()] then
        return
    end
    self.m_mProtectedRepeated[obj:GetSaveId()] = true
    self.m_iSavingCnt = self.m_iSavingCnt + 1

    local lMerge = table_key_list(obj:GetMergeMap())
    obj:DoSave()

    for _, k in ipairs(lMerge) do
        local o = self:GetSaveObj(k)
        if o then
            self:DelSaveMerge(obj:GetSaveId(), k)
            self:_RecuSave(o)
        end
    end

    self.m_iSavingCnt = self.m_iSavingCnt - 1
    if self.m_iSavingCnt <= 0 then
        self.m_mProtectedRepeated = {}
    end
end

--- 删除保存对象
---@param id integer 保存对象ID
function CSaveObjMgr:DelSaveObj(id)
    local o = self.m_mAllSave[id]
    if o then
        o:Release()
        self.m_mAllSave[id] = nil
    end
end

--- 添加保存合并关系
---@param id1 integer 保存对象ID1
---@param id2 integer 保存对象ID2
function CSaveObjMgr:AddSaveMerge(id1, id2)
    local o1 = self:GetSaveObj(id1)
    local o2 = self:GetSaveObj(id2)
    if o1 and o2 then
        o1:AddMerge(id2)
        o2:AddMerge(id1)
    end
end

--- 删除保存合并关系
---@param id1 integer 保存对象ID1
---@param id2 integer 保存对象ID2
function CSaveObjMgr:DelSaveMerge(id1, id2)
    local o1 = self:GetSaveObj(id1)
    local o2 = self:GetSaveObj(id2)
    if o1 then
        o1:DelMerge(id2)
    end
    if o2 then
        o2:DelMerge(id1)
    end
end

--- 保存所有对象
function CSaveObjMgr:SaveAll()
    for _, v in pairs(self.m_mAllSave) do
        self:_RecuSave(v)
    end
end


--- 初始化服务保存模块
function M.Init()
    if not oSaveObjMgr then
        oSaveObjMgr = CSaveObjMgr:New()
        oSaveObjMgr:Init()
    end
end

--- 创建新的保存对象
---@param ... any 参数(f: function, i?: integer)
---@return integer 保存对象ID
function M.NewSaveObj(...)
    return oSaveObjMgr:NewSaveObj(...)
end

--- 保存所有对象
function M.SaveAll()
    return oSaveObjMgr:SaveAll()
end

--- 添加保存合并关系
---@param ... any 参数(id1: integer, id2: integer)
function M.AddSaveMerge(...)
    return oSaveObjMgr:AddSaveMerge(...)
end

--- 删除保存对象
---@param ... any 参数(id: integer)
function M.DelSaveObj(...)
    return oSaveObjMgr:DelSaveObj(...)
end

--- 立即保存对象
---@param ... any 参数(id: integer)
function M.DoSaveObj(...)
    return oSaveObjMgr:DoSaveObj(...)
end


return M
