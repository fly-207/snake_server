--import module

CBigPacketMgr = {}
CBigPacketMgr.__index = CBigPacketMgr

function CBigPacketMgr:New()
    local o = setmetatable({}, self)
    o.m_mBigPacketCache = {}
    return o
end

function CBigPacketMgr:Release()
    release(self)
end

function CBigPacketMgr:AddBigPacketCache(iType, sData)
    local l = self.m_mBigPacketCache[iType]
    if not l then
        l = {}
        self.m_mBigPacketCache[iType] = l
    end
    table.insert(l, sData)
end

function CBigPacketMgr:GetBigPacketCache(iType)
    return self.m_mBigPacketCache[iType]
end

function CBigPacketMgr:ClrBigPacketCache(iType)
    self.m_mBigPacketCache[iType] = nil
end

---@param iClientType: 协议类型
---@param sData: 协议数据
---@param iTotal: 总共包个数
---@param iIndex: 当前第几个
---@param fd:
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
