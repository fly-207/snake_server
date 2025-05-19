--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local router = require "base.router"
local extype = require "base.extype"
local res = require "base.res"
local record = require "public.record"

CConnection = {}
CConnection.__index = CConnection
inherit(CConnection, logic_base_cls())

function CConnection:New(source, handle, ip, port)
    local o = super(CConnection).New(self)
    o.m_iGateAddr = source
    o.m_iHandle = handle
    o.m_sIP = ip
    o.m_iPort = port
    o.m_sServerKey = nil
    o.m_iLastHeartBeatTime = get_time()
    return o
end

function CConnection:GetNetHandle()
    return self.m_iHandle
end

function CConnection:HandleHeartBeat(sServerKey)
    local oGateMgr = global.oGateMgr
    self.m_sServerKey = sServerKey
    oGateMgr:BindConnection2Server(self.m_iHandle, sServerKey)
    self.m_iLastHeartBeatTime = get_time()
    self:SendR2P(router.PROTO_R2P.R2PHeartBeat, {})
end

function CConnection:GetServerKey()
    return self.m_sServerKey
end

function CConnection:GetLastHeartBeatTime()
    return self.m_iLastHeartBeatTime
end

function CConnection:SendR2P(iCmd, mData)
        local l = {
            string.char(iCmd%256),
            skynet.packstring(mData or {}),
        }
        local s = string.pack(">s2", table.concat(l, ""))

        l = {s,}
        local iPow = 0
        for i = 1, 4 do
            table.insert(l, string.char((self.m_iHandle//(2^iPow))%256))
            iPow = iPow + 8
        end
        s = table.concat(l, "")

        skynet.send(self.m_iGateAddr, "zinc" , s)
end
