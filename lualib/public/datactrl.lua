---@module "public.datactrl"
--- 数据控制器基类
--- 提供数据加载、保存、脏标记等通用功能

--import module
local skynet = require "skynet"

---@class CDataCtrl 数据控制器基类
---@field m_mInfo table 配置信息
---@field m_mData table 数据存储
---@field m_bIsDirty boolean 是否有未保存的改动
---@field m_bLoaded boolean 是否已加载
---@field m_bLoadedSuccess boolean 是否加载成功
---@field m_lWaitingFunc function[] 等待加载完成的回调函数列表
CDataCtrl = {}
CDataCtrl.__index = CDataCtrl
inherit(CDataCtrl, logic_base_cls())

--- 创建数据控制器实例
---@param mInfo? table 初始配置信息
---@return CDataCtrl
function CDataCtrl:New(mInfo)
    local o = super(CDataCtrl).New(self)

    o.m_mInfo = mInfo
    o.m_mData = nil
    o.m_bIsDirty = false

    o.m_bLoaded = false
    o.m_bLoadedSuccess = false
    o.m_lWaitingFunc = {}

    return o
end

function CDataCtrl:Release()
    self.m_mInfo = nil
    self.m_mData = nil
    super(CDataCtrl).Release(self)
end

function CDataCtrl:SetInfo(k, v)
    if not self.m_mInfo then
        self.m_mInfo = {}
    end
    self.m_mInfo[k] = v
end

function CDataCtrl:GetInfo(k, rDefault)
    if not self.m_mInfo then
        self.m_mInfo = {}
    end
    return self.m_mInfo[k] or rDefault
end

function CDataCtrl:SetData(k, v)
    if not self.m_mData then
        self.m_mData = {}
    end
    self.m_mData[k] = v
    self:Dirty()
end

function CDataCtrl:GetData(k, rDefault)
    if not self.m_mData then
        self.m_mData = {}
    end
    return self.m_mData[k] or rDefault
end

function CDataCtrl:Load(m)
end

function CDataCtrl:Save()
end

function CDataCtrl:IsDirty()
    return self.m_bIsDirty
end

function CDataCtrl:Dirty()
    self.m_bIsDirty = true
end

function CDataCtrl:UnDirty()
    self.m_bIsDirty = false
end

function CDataCtrl:LoadDb()
end

function CDataCtrl:SaveDb()
end

function CDataCtrl:IsLoaded()
    return self.m_bLoaded
end

function CDataCtrl:SetLoaded()
    self.m_bLoaded = true
end

function CDataCtrl:IsLoadedSuccess()
    return self.m_bLoadedSuccess
end

function CDataCtrl:SetLoadedSuccess()
    self.m_bLoadedSuccess = true
end

function CDataCtrl:OnLoaded()
    self:SetLoaded()
    self:SetLoadedSuccess()
    self:ConfigSaveFunc()
    self:AfterLoad()
    self:LoadedExec()
end

function CDataCtrl:OnLoadedFail()
    self:SetLoaded()
    self:LoadedExec()
end

function CDataCtrl:ConfigSaveFunc()
end

function CDataCtrl:AfterLoad()
end

function CDataCtrl:WaitLoaded(func)
    if not self:IsLoaded() then
        table.insert(self.m_lWaitingFunc, func)
    else
        if self:IsLoadedSuccess() then
            safe_call(func, self)
        else
            safe_call(func, nil)
        end
    end
end

function CDataCtrl:LoadedExec()
    local lFuncs = self.m_lWaitingFunc
    self.m_lWaitingFunc = {}
    for _, func in ipairs(lFuncs) do
        if self:IsLoadedSuccess() then
            safe_call(func, self)
        else
            safe_call(func, nil)
        end
    end
end

