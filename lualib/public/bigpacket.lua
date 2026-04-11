---@module "public.bigpacket"
--- 大包处理模块
--- 用于处理超过单个网络包大小限制的大数据传输

--import module

---@class CBigPacketMgr 大包管理器
---@field m_mBigPacketCache table<integer, string[]> 大包缓存
CBigPacketMgr = {}
CBigPacketMgr.__index = CBigPacketMgr

--- 创建大包管理器实例
---@return CBigPacketMgr
function CBigPacketMgr:New()
    local o = setmetatable({}, self)
    o.m_mBigPacketCache = {}
    return o
end

--- 释放大包管理器
function CBigPacketMgr:Release()
    release(self)
end

--- 添加大包缓存数据
---@param iType integer 协议类型
---@param sData string 数据片段
function CBigPacketMgr:AddBigPacketCache(iType, sData)
    local l = self.m_mBigPacketCache[iType]
    if not l then
        l = {}
        self.m_mBigPacketCache[iType] = l
    end
    table.insert(l, sData)
end

--- 获取大包缓存数据
---@param iType integer 协议类型
---@return string[]? 数据片段列表
function CBigPacketMgr:GetBigPacketCache(iType)
    return self.m_mBigPacketCache[iType]
end

--- 清除大包缓存数据
---@param iType integer 协议类型
function CBigPacketMgr:ClrBigPacketCache(iType)
    self.m_mBigPacketCache[iType] = nil
end

--- 处理大包数据
---@param iClientType integer 协议类型
---@param sData string 协议数据
---@param iTotal integer 总包数
---@param iIndex integer 当前包索引
---@param fd integer 客户端文件描述符
function CBigPacketMgr:HandleBigPacket(iClientType, sData, iTotal, iIndex, fd)

    -- 首个消息体
    if iIndex == 1 then
        self:ClrBigPacketCache(iClientType)
    end

    self:AddBigPacketCache(iClientType, sData)
    local l = self:GetBigPacketCache(iClientType)

    -- 追加第 iIndex 后总数量检验
    if #l ~= iIndex then
        self:ClrBigPacketCache(iClientType)
        assert(false, "HandleBigPacket index error")
    else
        -- 所有消息都已经追加完成
        if iIndex == iTotal then
            self:ClrBigPacketCache(iClientType)

            local netproto = require "base.netproto"
            local netcmd = import(service_path("netcmd.init"))

            local sResult = table.concat(l, "")
            local m = netproto.NetfindFunc("FindC2GSByType", iClientType)
            assert(m, "HandleBigPacket FindC2GSByType error")
            local mData, sMsg = netproto.ProtobufFunc("decode", m[2], sResult)
            assert(mData, sMsg)
            netcmd.Invoke(m[1], m[2], fd, mData)
        end
    end
end

--- 打包大数据为多个小包
---@param sMessage string 消息名称
---@param mData table 数据
---@return string[] 打包后的字符串列表
function PackBigData(sMessage, mData)
    local netproto = require "base.netproto"
    local net = require "base.net"

    local iType = netproto.NetfindFunc("FindGS2CByName", sMessage)
    assert(iType, "PackBigData error")
    local sEncode = netproto.ProtobufFunc("encode", sMessage, mData)

    local iLen = #sEncode
    local iSplit = 10*1024
    local iStart = 1
    local l = {}
    local lRet = {}
    while iStart <= iLen do
        local iNext = iStart + iSplit
        local s = string.sub(sEncode, iStart, iNext - 1)
        iStart = iNext
        table.insert(l, s)
    end
    for k, v in ipairs(l) do
        table.insert(lRet, net.PackData("GS2CBigPacket", {
            type = iType,
            total = #l,
            index = k,
            data = v,
        }))
    end

    return lRet
end

function SendBig(mMailBox, sMessage, mData)
    local net = require "base.net"
    local lRet = PackBigData(sMessage, mData)
    net.SendRawList(mMailBox, lRet)
end

function SendBigRaw(mMailBox, lRet)
    net.SendRawList(mMailBox, lRet)
end
