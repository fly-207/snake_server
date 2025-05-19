--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local router = require "base.router"
local extype = require "base.extype"
local res = require "base.res"
local record = require "public.record"


CGateMgr = {}
CGateMgr.__index = CGateMgr
inherit(CGateMgr, logic_base_cls())

function CGateMgr:New()
    local o = super(CGateMgr).New(self)
    o.m_mGates = {}
    o.m_mNoteConnections = {}
    o.m_mSk2Handle = {}
    return o
end

function CGateMgr:Release()
    for _, v in pairs(self.m_mGates) do
        baseobj_safe_release(v)
    end
    self.m_mGates = {}
    super(CGateMgr).Release(self)
end

function CGateMgr:Init()
    local f1
    f1 = function ()
            self:DelTimeCb("_CheckHeartBeat")
            self:AddTimeCb("_CheckHeartBeat", 10*1000, f1)
            self:_CheckHeartBeat()
    end
    f1()
end

function CGateMgr:AddGate(oGate)
    self.m_mGates[oGate.m_iAddr] = oGate
end

function CGateMgr:GetGate(iAddr)
    return self.m_mGates[iAddr]
end

function CGateMgr:GetConnection(iHandle)
    return self.m_mNoteConnections[iHandle]
end

function CGateMgr:SetConnection(iHandle, oConn)
    self.m_mNoteConnections[iHandle] = oConn
end

function CGateMgr:KickConnection(iHandle)
    local oConnection = self:GetConnection(iHandle)
    if oConnection then
        skynet.send(oConnection.m_iGateAddr, "text", "kick", oConnection.m_iHandle)
        local oGate = self:GetGate(oConnection.m_iGateAddr)
        if oGate and oGate:GetConnection(iHandle) then
            oGate:DelConnection(iHandle)
        end
    end
end

function CGateMgr:SendR2P(sServerKey, iCmd, mData)
    local iHandle = self.m_mSk2Handle[sServerKey]
    if iHandle then
        local oConnection = self:GetConnection(iHandle)
        if oConnection then
            oConnection:SendR2P(iCmd, mData)
        end
    end
end

function CGateMgr:BindConnection2Server(iHandle, sServerKey)
    self.m_mSk2Handle[sServerKey] = iHandle
end

function CGateMgr:UnBindConnection2Server(sServerKey)
    self.m_mSk2Handle[sServerKey] = nil
end

function CGateMgr:_CheckHeartBeat()
    local iCurrTime = get_time()
    local lv = table_value_list(self.m_mNoteConnections)
    for _, oConnection in ipairs(lv) do
        if iCurrTime - oConnection:GetLastHeartBeatTime() >= 2*60 then
            record.warning(string.format("router_s CGateMgr _CheckHeartBeat ill connection %s %s", oConnection:GetServerKey(), oConnection:GetNetHandle()))
            self:KickConnection(oConnection:GetNetHandle())
        end
    end
end

function CGateMgr:PackAllServerStatus()
    local mResult = {}
    for sServerTag, iHandle in pairs(self.m_mSk2Handle) do
        local oConn = self:GetConnection(iHandle)
        mResult[sServerTag] = oConn and oConn:GetLastHeartBeatTime() or 0
    end
    return mResult
end

