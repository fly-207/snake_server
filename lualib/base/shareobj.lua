---@module shareobj
---共享对象模块
---提供基于 skynet stm (软件事务内存) 的跨服务数据共享功能
---包含写入器 (Writer) 和读取器 (Reader) 两个类

local skynet = require "skynet"
local stm = require "stm"

local mypack = skynet.pack
local myunpack = skynet.unpack

---@class CShareWriter 共享数据写入器，用于创建和更新共享数据
---@field m_oStm userdata STM对象
---@field m_bIsDirty boolean 是否有待更新的数据
CShareWriter = {}
CShareWriter.__index = CShareWriter

---创建共享写入器实例
---@return CShareWriter 新创建的写入器
function CShareWriter:New()
    local o = setmetatable({}, self)
    o.m_oStm = nil
    return o
end

---初始化写入器，创建STM对象
function CShareWriter:Init()
    self.m_oStm = stm.new(mypack(self:Pack()))
end

---释放写入器资源
function CShareWriter:Release()
    self.m_oStm = nil
end

---打包数据，子类需要重写此方法
---@return any data 要共享的数据
function CShareWriter:Pack()
end

---生成读取器副本
---@return userdata copy STM副本，用于创建读取器
function CShareWriter:GenReaderCopy()
    assert(self.m_oStm, "CShareWriter GenReaderCopy fail")
    return stm.copy(self.m_oStm)
end

---更新共享数据
function CShareWriter:Update()
    assert(self.m_oStm, "CShareWriter Update fail")
    self.m_oStm(mypack(self:Pack()))
end

---标记数据需要更新
function CShareWriter:PrepareUpdate()
    self.m_bIsDirty = true
end

---检查是否有待更新的数据
---@return boolean isDirty 是否需要更新
function CShareWriter:IsUpdate()
    return self.m_bIsDirty
end

---检查并执行更新
function CShareWriter:CheckUpdate()
    if not self.m_bIsDirty then
        return
    end
    self.m_bIsDirty = false
    self:Update()
end

---@class CShareReader 共享数据读取器，用于读取共享数据
---@field m_oStmShadow userdata STM影子副本
CShareReader = {}
CShareReader.__index = CShareReader

---创建共享读取器实例
---@return CShareReader 新创建的读取器
function CShareReader:New()
    local o = setmetatable({}, self)
    o.m_oStmShadow = nil
    return o
end

---初始化读取器
---@param o userdata STM副本对象
function CShareReader:Init(o)
    self.m_oStmShadow = stm.newcopy(o)
    self:Update()
end

---释放读取器资源
function CShareReader:Release()
    self.m_oStmShadow = nil
end

---更新读取器，获取最新数据
function CShareReader:Update()
    assert(self.m_oStmShadow, "CShareReader Update fail")
    local b, m = self.m_oStmShadow(myunpack)
    if b then
        self:Unpack(m)
    end
end

---解包数据，子类需要重写此方法
---@param m any 解包后的数据
function CShareReader:Unpack(m)
end
