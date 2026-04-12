--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local router = require "base.router"
local extype = require "base.extype"
local res = require "base.res"
local record = require "public.record"

local util = import(lualib_path("public.util"))
local version = import(lualib_path("public.version"))
local status = import(lualib_path("base.status"))
local bigpacket = import(lualib_path("public.bigpacket"))
local gamedefines = import(lualib_path("public.gamedefines"))
local analy = import(lualib_path("public.dataanaly"))
local ipoperate = import(lualib_path("public.ipoperate"))
local serverinfo = import(lualib_path("public.serverinfo"))
local gamedb = import(lualib_path("public.gamedb"))

print("CGateMgr 文件被导入")


LOGIN_QUEUE_LIMIT = 100
WAIT_PUSH_NUM = 200

MAX_ROLE_TOKEN_ID = 10000

---@class LoginCGateMgr
CGateMgr = {}
CGateMgr.__index = CGateMgr
inherit(CGateMgr, logic_base_cls())


---comment
---@return LoginCGateMgr
function CGateMgr:New()
    local o = super(CGateMgr).New(self)
    o.m_iOpenStatus = 3    -- 0:维护状态 1:白名单可登陆 2:所有玩家可登陆
    o.m_mGates = {}
    o.m_mNoteConnections = {}

    o.m_iRoleTokenID = 0
    o.m_mRoleTokenCache = {}

    o.m_iLoginCnt = 0
    o.m_mRoleLoginQueue = {}        --　登录队列
    o.m_mRoleWaitQueue = {}         --　等待队列
 
   -- 配置信息
    o.m_iSetterVer = 0
    o.m_mIpBlacklist = {}               -- {["ip1"]=1}
    o.m_mAccountBlacklist = {}          -- {{account="369", channel=0}}
    o.m_mWhitelist = {}
    o.m_mServerInfo = {}
    o:SyncSetterConfig()
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
    self:StartCheckWaitQueue()
end

function CGateMgr:StartCheckWaitQueue()
    local f1
    f1 = function ()
        self:DelTimeCb("CheckPushWaitQueue")
        self:AddTimeCb("CheckPushWaitQueue", 1000, f1)
        self:CheckPushWaitQueue()
    end
    f1()
    local f2
    f2 = function ()
        self:DelTimeCb("ClearNoValidLogin")
        self:AddTimeCb("ClearNoValidLogin", 10 * 60 * 1000, f2)
        self:ClearNoValidLogin()
    end
    f2()
end

function CGateMgr:EnterLoginQueue(iPid,mData)
    if self.m_iLoginCnt < LOGIN_QUEUE_LIMIT then
        self:Send2WorldLogin(iPid,mData)
    else
        self:EnterWaitQueue(iPid,mData)
    end
end

function CGateMgr:EnterWaitQueue(iPid,mData)
    local mRoleWait = self.m_mRoleWaitQueue
    mRoleWait[iPid] = mData
end

function CGateMgr:Send2WorldLogin(iPid,mData)
    local mRoleLogin = self.m_mRoleLoginQueue
    if mRoleLogin[iPid] then
        self.m_LoginRepeat = self.m_LoginRepeat or 0
        self.m_LoginRepeat = self.m_LoginRepeat + 1
        record.warning("send2world repeat id : " .. iPid)
    end
    if not mRoleLogin[iPid] then
        self.m_LoginWorld = self.m_LoginWorld or 0
        self.m_LoginWorld = self.m_LoginWorld + 1
        self.m_iLoginCnt = self.m_iLoginCnt + 1
    end
    mRoleLogin[iPid] = get_time()
    interactive.Send(".world", "login", "LoginPlayer", mData)
end

function CGateMgr:LeaveLoginQueue(iPid)
    local mRoleLogin = self.m_mRoleLoginQueue
    if mRoleLogin[iPid] then
        self.m_LeaveWorld = self.m_LeaveWorld or 0
        self.m_LeaveWorld = self.m_LeaveWorld + 1
        self.m_iLoginCnt = self.m_iLoginCnt - 1
    end
    mRoleLogin[iPid] = nil
end

function CGateMgr:CheckPushWaitQueue()
    local mRoleWait = self.m_mRoleWaitQueue
    local mPush,iCnt = {},0
    for iPid,mData in pairs(mRoleWait) do
        mPush[iPid] = mData
        iCnt = iCnt + 1
        if iCnt >= WAIT_PUSH_NUM then
            break
        end
    end
    for iPid,mData in pairs(mPush) do
        mRoleWait[iPid] = nil
        self:Send2WorldLogin(iPid,mData)
    end

end

function CGateMgr:ClearNoValidLogin()
    local mRoleLogin = self.m_mRoleLoginQueue
    local mDel = {}
    local iNowTime = get_time()
    for iPid,iTime in pairs(mRoleLogin) do
        local iOverTime = iNowTime - iTime
        if iOverTime > 10*60 then
            mDel[iPid] = iOverTime
        end
    end
    for iPid,iOverTime in pairs(mDel) do
        mRoleLogin[iPid] = nil
        record.warning("loginresult back too later pid " .. iPid .. " overtime: ".. iOverTime)
    end
end

function CGateMgr:IsMaintain()
    return self.m_iOpenStatus == 0
end

-- 开放玩家预先创角阶段
function CGateMgr:IsPreCreateRole()
    return self.m_iOpenStatus == 2
end

-- 开放玩家登录状态
function CGateMgr:IsOpen()
    return self.m_iOpenStatus == 3
end

function CGateMgr:SetOpenStatus(iStatus)
    print ("gate SetOpenStatus:", iStatus)
    self.m_iOpenStatus = iStatus
end

function CGateMgr:GetOpenStatus()
    return self.m_iOpenStatus
end

function CGateMgr:AddGate(oGate)
    self.m_mGates[oGate.m_iAddr] = oGate
end

function CGateMgr:GetGate(iAddr)
    return self.m_mGates[iAddr]
end

---@return LoginCConnection
function CGateMgr:GetConnection(iHandle)
    return self.m_mNoteConnections[iHandle]
end

function CGateMgr:SetConnection(iHandle, oConn)
    self.m_mNoteConnections[iHandle] = oConn
end

function CGateMgr:KickConnection(iHandle)
    local oConnection = self:GetConnection(iHandle)
    if oConnection then
        local iStatus = oConnection.m_oStatus:Get()
        skynet.send(oConnection.m_iGateAddr, "text", "kick", oConnection.m_iHandle)
        local oGate = self:GetGate(oConnection.m_iGateAddr)
        if oGate and oGate:GetConnection(iHandle) then
            oGate:DelConnection(iHandle)
        end
    end
end

function CGateMgr:DispatchRoleToken()
    self.m_iRoleTokenID = self.m_iRoleTokenID + 1
    if self.m_iRoleTokenID >= MAX_ROLE_TOKEN_ID then
        self.m_iRoleTokenID = 1
    end
    local iToken = get_time() * MAX_ROLE_TOKEN_ID + self.m_iRoleTokenID
    return tostring(iToken)
end

function CGateMgr:Add2TokenCache(iPid, sToken, mRoleInfo)
    mRoleInfo.token = sToken
    self.m_mRoleTokenCache[iPid] = mRoleInfo
end

function CGateMgr:GetCacheInfo(iPid, sToken)
    local mData = self.m_mRoleTokenCache[iPid]
    if not mData then
        return
    end
    if mData.token ~= sToken then
        return
    end
    return mData
end

function CGateMgr:ClearCacheInfo(iPid, sToken)
    local mData = self.m_mRoleTokenCache[iPid]
    if mData and mData.token == sToken then
        self.m_mRoleTokenCache[iPid] = nil
    end
end

function CGateMgr:OnLogout(mData)
    local iPid = mData.pid
    local sToken = mData.token
    self:ClearCacheInfo(iPid, sToken)
end

function CGateMgr:IsWhiteListAccount(sAccount, iChannel)
    local mWhiteList = self.m_mWhitelist or {}
    for _, mData in pairs(mWhiteList) do
        if mData.account == sAccount and mData.channel == iChannel then
            return true
        end
    end
    return false
end

function CGateMgr:ValidPlayerLogin(sAccount, iChannel, sIP)
    if self:IsMaintain() then
        return false
    elseif self:IsOpen() then
        return true
    else
        if self:IsWhiteListAccount(sAccount, iChannel) then
            return true
        elseif ipoperate.is_white_ip(sIP) then
            return true
        else
            return false
        end
    end
end

function CGateMgr:SyncSetterConfig()
    if is_ks_server() then return end
    
    self:DelTimeCb("SyncSetterConfig")
    -- if self:IsOpen() then
    --     return
    -- end
    self:GetSetterConfig()
    self:AddTimeCb("SyncSetterConfig", 30 * 1000, function ()
        self:SyncSetterConfig()
    end)
end

function CGateMgr:GetSetterConfig()
    local f = function (mRecord, mData)
        self:ReloadSetterConfig(mData)
    end
    local m = {cmd = "GetSetterConfig", data= {server_key = get_server_key(), ver = self.m_iSetterVer}}
    router.Request("cs", ".serversetter", "common", "Forward", m, f)
end

function CGateMgr:ReloadSetterConfig(mData)
    local iErrcode = mData.errcode
    local mConfig = mData.data
    local iVer = mConfig.version
    if iErrcode > 0 then
        record.error("gatemgr ReloadSetterConfig error %s", iErrcode)
        return
    end
    if not iVer or iVer == self.m_iSetterVer then return end
    
    self.m_iSetterVer = iVer 
    self.m_mWhitelist = mConfig.whitelist or {}
    self.m_mIpBlacklist = mConfig.black_ip or {}
    self.m_mAccountBlacklist = mConfig.black_account or {}
    self.m_mServerInfo = mConfig.server_info or {}
    self.m_mLinkServers = mConfig.link_server or {}
end

function CGateMgr:IsLinkedServer(sServerKey)
    return self.m_mLinkServers[sServerKey]
end

function CGateMgr:CheckAccountLogin(sAccount, iChannel, sIP)
    if self.m_mIpBlacklist[sIP] then
        return false, "账号已被封停[0]，请联系客服"
    end

    for _, mData in pairs(self.m_mAccountBlacklist) do
        if mData["account"] == sAccount and mData["channel"] == iChannel then
            return false ,"账号已被封停[1]，请联系客服"
        end
    end
    return true, ""
end
