---@module "public.demisdk"
--- DemiSDK集成模块
--- 提供与Demi SDK交互的签名、支付ID生成等功能

-- import file

local md5 = require "md5"
local serverdefines = require "public.serverdefines"

local serverinfo = import(lualib_path("public.serverinfo"))

--- 创建DemiSdk实例
---@param bPay? boolean 是否支付模块
---@param iSeqBase? integer 序列号基数
---@return CDemiSdk
function NewDemiSdk(...)
    return CDemiSdk:New(...)
end

--- 创建支付ID生成器
---@param iSeqBase? integer 序列号基数
---@return CPayId
function NewPayId(...)
    return CPayId:New(...)
end

---@class CDemiSdk DemiSDK封装类
---@field m_iLastTimeStamp? integer 上次时间戳
---@field m_oPayId? CPayId 支付ID生成器
CDemiSdk = {}
CDemiSdk.__index = CDemiSdk

--- 创建DemiSdk实例
---@param bPay? boolean 是否启用支付
---@param iSeqBase? integer 序列号基数
---@return CDemiSdk
function CDemiSdk:New(bPay, iSeqBase)
    local o = setmetatable({}, self)
    o.m_iLastTimeStamp = nil
    if bPay then
        o.m_oPayId = NewPayId(iSeqBase)
    end
    return o
end

--- 获取应用ID
---@return integer
function CDemiSdk:GetAppId()
    return serverinfo.DEMI_SDK.app_id
end

--- 获取应用密钥
---@return string
function CDemiSdk:GetAppKey()
    return serverinfo.DEMI_SDK.app_key
end

--- 获取机器ID
---@return integer
function CDemiSdk:GetMachineId()
    return serverinfo.DEMI_SDK.machine_id
end

--- 获取广告密钥
---@return string
function CDemiSdk:GetAdKey()
    return serverinfo.DEMI_SDK.ad_key
end

--- 生成签名
---@param mParam table<string, string|number> 参数表
---@return string MD5签名
function CDemiSdk:Sign(mParam)
    local lKey = table_key_list(mParam)
    table.sort(lKey)
    local s = ""
    for _, sKey in ipairs(lKey) do
        s = s..sKey.."="..mParam[sKey].."&"
    end
    s = s.."key="..self:GetAppKey()
    return md5.sumhexa(s)
end

--- 为广告生成签名
---@param s string 待签名字符串
---@return string MD5签名
function CDemiSdk:SignForAd(s)
    s = s.."&"..self:GetAdKey()
    return md5.sumhexa(s)
end

--- 生成支付ID
---@return integer 支付ID
function CDemiSdk:GeneratePayid()
    return self.m_oPayId:GeneratePayid(self:GetAppId(), self:GetMachineId())
end

---@class CPayId 支付ID生成器
---@field m_iSeqBase integer 序列号基数
---@field m_iLastTimeStamp? integer 上次时间戳
---@field m_iSequence? integer 当前序列号
CPayId = {}
CPayId.__index = CPayId

--- 雪花算法常量
CPayId.c_iUsingEpoch = 1503644905000
CPayId.c_iAppidBits = 14
CPayId.c_iMachineidBits = 3
CPayId.c_iSequenceBits = 7
CPayId.c_iTimestampShift = CPayId.c_iAppidBits + CPayId.c_iMachineidBits + CPayId.c_iSequenceBits
CPayId.c_iAppidShift = CPayId.c_iMachineidBits + CPayId.c_iSequenceBits
CPayId.c_iMachineidShift = CPayId.c_iSequenceBits

--- 创建支付ID生成器
---@param iSeqBase integer 序列号基数
---@return CPayId
function CPayId:New(iSeqBase)
    local o = setmetatable({}, self)
    o.m_iSeqBase = iSeqBase
    o.m_iLastTimeStamp = nil
    return o
end

--- 获取最大序列号
---@return integer
function CPayId:GetMaxSequence()
    return (1<<self.c_iSequenceBits) -1
end

--- 获取当前时间戳(毫秒)
---@return integer
function CPayId:GetCurrentTimeStamp()
    return math.floor(get_time(true) * 1000)
end

--- 获取序列号
---@return integer
function CPayId:GetSequence()
    local iTime = self:GetCurrentTimeStamp()
    if self.m_iLastTimeStamp and iTime == self.m_iLastTimeStamp then
        self.m_iSequence = self.m_iSequence + PAY_SERVICE_COUNT
        assert(self.m_iSequence <= self:GetMaxSequence(), string.format("pay sequence bigger than %s", self:GetMaxSequence()))
    else
        self.m_iSequence = self.m_iSeqBase
        self.m_iLastTimeStamp = iTime
    end
    return self.m_iSequence
end

function CPayId:GeneratePayid(iAppId, iMachineId)
    local iTimeStamp = self:GetCurrentTimeStamp() - self.c_iUsingEpoch
    local iSequence = self:GetSequence()
    return (iTimeStamp << self.c_iTimestampShift) | iAppId << self.c_iAppidShift | (iMachineId << self.c_iMachineidShift) | iSequence
end
