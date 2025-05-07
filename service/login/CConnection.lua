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


print("CConnection 文件被导入")

CConnection = {}
CConnection.__index = CConnection
inherit(CConnection, logic_base_cls())

function CConnection:New(source, handle, ip, port)
    local o = super(CConnection).New(self)
    o.m_iGateAddr = source
    o.m_iHandle = handle
    o.m_sIP = ip
    o.m_iPort = port
    o.m_sAccount = nil
    o.m_iChannel = 0
    o.m_sCpsChannel = ""
    o.m_sAccountToken = nil
    o.m_iFakePlatform = nil
    o.m_mCbtPay = nil
    o.m_iForceLogin = 0
    o.m_sServerTag = nil
    o.m_oBigPacketMgr = bigpacket.CBigPacketMgr:New()

    o.m_oStatus = status.NewStatus()
    o.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.no_account)

    return o
end

function CConnection:Release()
    baseobj_safe_release(self.m_oBigPacketMgr)
    self.m_oBigPacketMgr = nil
    baseobj_safe_release(self.m_oStatus)
    self.m_oStatus = nil
    super(CConnection).Release(self)
end

function CConnection:GetNetHandle()
    return self.m_iHandle
end

function CConnection:Send(sMessage, mData)
    net.Send({gate = self.m_iGateAddr, fd = self.m_iHandle}, sMessage, mData)
end

function CConnection:SendBig(sMessage,mData)
    bigpacket.SendBig({gate = self.m_iGateAddr, fd = self.m_iHandle}, sMessage, mData)
end

function CConnection:SetAccount(sAccount)
    self.m_sAccount = sAccount
end

function CConnection:GetAccount()
    return self.m_sAccount
end

function CConnection:SetChannel(iChannel)
    self.m_iChannel = iChannel
end

function CConnection:GetChannel()
    return self.m_iChannel
end

function CConnection:SetCpsChannel(sCps)
    self.m_sCpsChannel = sCps
end

function CConnection:GetCpsChannel()
    return self.m_sCpsChannel
end

function CConnection:SetDevice(sDevice)
    self.m_sDevice = sDevice
end

function CConnection:GetDevice()
    return self.m_sDevice
end

function CConnection:SetMac(sMac)
    self.m_sMac = sMac
end

function CConnection:GetMac()
    return self.m_sMac
end

function CConnection:SetFakePlatform(iPlatform)
    self.m_iFakePlatform = iPlatform
end

function CConnection:GetFakePlatform()
    return self.m_iFakePlatform
end

function CConnection:SetPlatform(iPlatform)
    self.m_iPlatform = iPlatform
end

function CConnection:GetPlatform()
    return self.m_iPlatform
end

function CConnection:SetClientVer(sVersion)
    self.m_sClientVer = sVersion
end

function CConnection:GetClientVer()
    return self.m_sClientVer
end

function CConnection:SetIMEI(sIMEI)
    self.m_sIMEI = sIMEI
end

function CConnection:GetIMEI()
    return self.m_sIMEI
end

function CConnection:SetClientOs(sClientOs)
    self.m_sClientOs = sClientOs
end

function CConnection:GetClientOs()
    return self.m_sClientOs
end

function CConnection:SetUDID(sUDID)
    self.m_sUDID = sUDID
end

function CConnection:GetUDID()
    return self.m_sUDID
end

function CConnection:SetAccountToken(sToken)
    self.m_sAccountToken = sToken
end

function CConnection:GetAccountToken()
    return self.m_sAccountToken
end

function CConnection:QueryLogin(mData)
    local iHandle = self:GetNetHandle()
    local fCallback = function (mRecord,mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:QueryLogin2(mData)
        end
    end
    interactive.Request(".clientupdate","common","QueryLogin",mData,fCallback)
end

function CConnection:QueryLogin2(mData)
    local mClientResInfo = mData["res_file"] or {}
    if table_count(mClientResInfo["res_file"]) > 0 or mClientResInfo["code"] then
        self:SendBig("GS2CQueryLogin",{delete_file = mClientResInfo["delete_file"],res_file = mClientResInfo["res_file"],code= mClientResInfo["code"]})
    else
        self:Send("GS2CQueryLogin",{delete_file = mClientResInfo["delete_file"],res_file = mClientResInfo["res_file"],code = mClientResInfo["code"]})
    end
end

function CConnection:InitAccountInfo(sToken, endfunc)
    local iHandle = self:GetNetHandle()
    local iNo = string.match(sToken, "%w+_(%d+)")
    local sServiceName = string.format(".loginverify%s",iNo)
    router.Request("cs", sServiceName, "common", "GSGetVerifyAccount", {
        token = sToken,
    }, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_InitAccountInfo1(mData, sToken, endfunc)
        end
    end)
end

function CConnection:_InitAccountInfo1(mData, sToken, endfunc)
    if mData.errcode ~= 0 then
        endfunc(2)
        return
    end
    
    local iHandle = self:GetNetHandle()
    local mAccount = mData.account
    self:SetAccount(mAccount.account)
    self:SetChannel(mAccount.channel)
    self:SetFakePlatform(mAccount.platform)
    self:SetCpsChannel(mAccount.cps)
    router.Request("cs", ".datacenter", "common", "GetCbtPayInfo", {
        account = mAccount.account,
        channel = mAccount.channel,
    },
    function(mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_InitAccountInfo2(mData, endfunc)
        end
    end)
end

function CConnection:_InitAccountInfo2(mData, endfunc)
    if mData.cbtpay then
        self.m_mCbtPay = mData.cbtpay
    end
    endfunc(0)
end

function CConnection:LoginAccount(mData)
    local app_ver = mData.app_ver
    if is_production_env() and app_ver ~= version.APP_VERSION then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_app_version, cmd="维护中，请您耐心等待"})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local sToken, sAccount = mData.token, mData.account

    if (not sToken or sToken == "") and (is_production_env() or not sAccount or sAccount == "") then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_account_env})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local iStatus = self.m_oStatus:Get()
    assert(iStatus, "connection status is nil")
    local oGateMgr = global.oGateMgr
    if iStatus ~= gamedefines.LOGIN_CONNECTION_STATUS.no_account then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.in_login_account)

    self:SetMac(mData.mac)
    self:SetDevice(mData.device)
    self:SetPlatform(mData.platform)
    self:SetIMEI(mData.imei)
    self:SetClientOs(mData.os)
    self:SetClientVer(mData.client_ver)
    self:SetUDID(mData.udid)

    if sToken and sToken ~= "" then
        self:SetAccountToken(sToken)

        local iHandle = self:GetNetHandle()
        self:InitAccountInfo(sToken, function (errcode)
            local oConn = global.oGateMgr:GetConnection(iHandle)
            if oConn then
                oConn:_LoginAccount1(errcode)
            end
        end)
    else
        self:SetChannel(0)
        self:SetAccount(sAccount)
        self:_LoginAccount1(0)
    end
end

function CConnection:_LoginAccount1(errcode)
    if errcode ~= 0 then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.invalid_token})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end
    local oGateMgr = global.oGateMgr
    local sAccount = self:GetAccount()
    local iChannel = self:GetChannel()
    local sCpsChannel = self:GetCpsChannel()
    local iFakePlatform = self:GetFakePlatform()

    local bCheck, sMsg = oGateMgr:CheckAccoutLogin(sAccount, self:GetChannel(), self.m_sIP)
    if not bCheck then
        self:Send("GS2CNotify", {
            cmd = sMsg,
        })
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local isLogin =oGateMgr:ValidPlayerLogin(sAccount, iChannel, self.m_sIP)

    print("oGateMgr:IsOpen()"..(oGateMgr:IsOpen() and "1" or "0").."isLogin:"..(isLogin and "1" or "0"))
    if not oGateMgr:IsPreCreateRole() and not oGateMgr:IsOpen() and not oGateMgr:ValidPlayerLogin(sAccount, iChannel, self.m_sIP) then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.in_maintain, cmd="服务器即将开放敬请期待"})
         return
    end

    local iHandle = self:GetNetHandle()
    global.oInviteCodeMgr:CheckInviteCode(iChannel, sAccount, function (iResult)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:Send("GS2CInviteCodeResult", {errcode = iResult})
            if iResult == 0 then
                oConn:_LoginAccount2()
            end
        end
    end)
end

function  CConnection:_LoginAccount2()
    local sAccount = self:GetAccount()
    local iChannel = self:GetChannel()
    local iHandle = self:GetNetHandle()
    local mInfo = {
        module = "playerdb",
        cmd = "GetPlayerListByAccount",
        cond = {account = sAccount, channel = iChannel, platform = self:GetFakePlatform()},
    }
    gamedb.LoadDb("login", "common", "DbOperate", mInfo, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_LoginAccount3(mRecord, mData)
        end
    end)
end

function CConnection:_LoginAccount3(mRecord, mData)
    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)

    local lRet = {}
    local lData = mData.data
    for _, v in ipairs(lData) do
        if not v.deleted then
            local mBase = v.base_info or {}
            local iIcon = mBase.icon -- TODO 预留，需要返回这个，model_info可能反而不需要
            local mModelInfo = mBase.model_info or {}
            local mModel = {
                shape = mModelInfo.shape,
                scale = mModelInfo.scale,
                color = mModelInfo.color,
                mutate_texture = mModelInfo.mutate_texture,
                weapon = mModelInfo.weapon,
                adorn = mModelInfo.adorn,
            }
            table.insert(lRet, {pid = v.pid, grade = mBase.grade, name = v.name, model_info = mModel, school = mBase.school})
        end
    end
    self:Send("GS2CLoginAccount", {account = mData.account, channel = mData.channel, role_list = lRet})
end

function CConnection:GMLoginPid(mData)
    if is_production_env() then
        return
    end

    self:SetMac(mData.mac)
    self:SetDevice(mData.device)
    self:SetPlatform(mData.platform)
    self:SetIMEI(mData.imei)
    self:SetClientOs(mData.os)
    self:SetClientVer(mData.client_ver)
    self:SetUDID(mData.udid)

    local iHandle = self:GetNetHandle()
    local iPid = mData.pid
    if not iPid then
        self:Send("GS2CNotify", {
            cmd = "error null pid",
        })
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end
    local mInfo = {
        module = "playerdb",
        cmd = "GetPlayer",
        cond = {pid = iPid},
    }
    gamedb.LoadGameDb("gs10001", "login", "common", "DbOperate", mInfo, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_GMLoginPid1(iPid, mData)
        end
    end)
end

function CConnection:_GMLoginPid1(iPid, mData)
    local oGateMgr = global.oGateMgr

    local m = mData.data
    if not m or not next(m) then
        self:Send("GS2CNotify", {
            cmd = "no such pid",
        })
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    self:SetAccount(m.account)
    self:SetChannel(m.channel)
    self:SetFakePlatform(m.platform)
    self:SetCpsChannel("")

    local iStatus = self.m_oStatus:Get()
    assert(iStatus, "connection status is nil")
    local oGateMgr = global.oGateMgr
    if iStatus ~= gamedefines.LOGIN_CONNECTION_STATUS.no_account then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end
    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)

    self:LoginRole({pid=iPid})
end

--账号对应角色数目
function CConnection:CheckAccountRoleAmount(fCallback)
    local sAccount = self:GetAccount()
    local iChannel = self:GetChannel()
    local iHandle = self:GetNetHandle()
    local iPlatform = self:GetFakePlatform()
    local mInfo = {
        module = "playerdb",
        cmd = "GetPlayerListByAccount",
        cond = {account = sAccount, channel = iChannel, platform = iPlatform},
    }
    gamedb.LoadDb("login", "common", "DbOperate", mInfo, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:CheckAccountRoleAmount2(mRecord, mData, fCallback)
        end
    end)
end

function CConnection:CheckAccountRoleAmount2(mRecord, mData, fCallback)
    local mCnt = {}
    local lData = mData.data
    for _, v in ipairs(lData) do
        if not v.deleted then
            local sServerTag = v.born_server
            if mCnt[sServerTag] then
                mCnt[sServerTag] = mCnt[sServerTag] + 1
            else
                mCnt[sServerTag] = 1
            end
        end
    end
    fCallback(mCnt)
end

function CConnection:CreateRole(mData)
    local sServerKey = mData.server_key
    if not sServerKey or sServerKey == "" then
        sServerKey = get_server_key()
    end
    mData.server_key = sServerKey

    if sServerKey == get_server_key() or global.oGateMgr:IsLinkedServer(sServerKey) then
        self:_CreateRole2(0, mData)
    end
end

function CConnection:_CreateRole2(iErrCode, mData)
    if iErrCode ~= 0 then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_server_key})
        return
    end

    local iHandle = self:GetNetHandle()
    local fCallback = function (mCnt)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_CreateRole3(mCnt, mData)
        end
    end
    self:CheckAccountRoleAmount(fCallback)
end

function CConnection:_CreateRole3(mCnt, mData)
    local iTot = 0
    for k, cnt in pairs(mCnt) do
        iTot = iTot + cnt
    end
    local sServerTag = get_server_tag(mData.server_key)
    if mCnt[sServerTag] and mCnt[sServerTag] >= 3 then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.role_max_limit})
        self:Send("GS2CNotify", {cmd="您在同一服务器所拥有的角色不能超过3个哦"})
        return
    end
    local bFirstRole = iTot <= 0
    self:TrueCreateRole(mData, bFirstRole)
end

function CConnection:TrueCreateRole(mData, bFirstRole)
    local iStatus = self.m_oStatus:Get()
    assert(iStatus, "connection status is nil")
    local oGateMgr = global.oGateMgr

    if iStatus ~= gamedefines.LOGIN_CONNECTION_STATUS.login_account then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.in_create_role)

    local iRoleType = mData.role_type
    local sName = trim(mData.name)
    local iSchool = mData.school
    local sServerKey = mData.server_key
    local sServerTag = get_server_tag(sServerKey)

    local mRoleType = res["daobiao"]["roletype"]
    local mInfo = mRoleType[iRoleType]
    local lSchool = mInfo.school
    if not sName or sName == "" or not mInfo or not table_in_list(lSchool, iSchool) then
        record.debug(string.format("TrueCreateRole account %s, channel %s, roletype %s school %s", self:GetAccount(), self:GetChannel(), iRoleType, iSchool))
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local iHandle = self:GetNetHandle()
    local mInfo = {
        module = "namecounter",
        cmd = "InsertNewNameCounter",
        data = {name = sName},
    }
    gamedb.LoadDb("login", "common", "DbOperate", mInfo, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_TrueCreateRole1(mRecord, mData, iRoleType, sName, iSchool, sServerTag, bFirstRole)
        elseif mData.success then
            gamedb.SaveDb("login", "common", "DbOperate", {
                module = "namecounter",
                cmd = "DeleteName",
                cond = {name = sName},
            })
            record.error("create role InsertNewNameCounter ret no handle revert: %s", sName)
        end
    end)
end

function CConnection:_TrueCreateRole1(mRecord, mData, iRoleType, sName, iSchool, sServerTag, bFirstRole)
    if not mData.success then
        self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.name_exist})
    else
        local mRoleType = res["daobiao"]["roletype"]
        local mInfo = mRoleType[iRoleType]

        local iHandle = self:GetNetHandle()
        router.Request("cs", ".datacenter", "common", "TryCreateRole", {
            server = get_server_tag(),
            born_server = sServerTag,
            account = self:GetAccount(),
            channel = self:GetChannel(),
            platform = self:GetFakePlatform(),
            name = sName,
            school = iSchool,
            icon = mInfo.shape
        }, function (mRecord, mData)
            local oConn = global.oGateMgr:GetConnection(iHandle)
            if oConn then
                oConn:_TrueCreateRole2(mData, iRoleType, sName, iSchool, sServerTag, bFirstRole)
            elseif mData.id then
                gamedb.SaveDb("login", "common", "DbOperate", {
                    module = "namecounter",
                    cmd = "DeleteName",
                    cond = {name = sName},
                })
                router.Send("cs", ".datacenter", "common", "RevertRole", {pid = mData.id})
                record.error("create role datacenter TryCreateRole ret no handle revert: %s %s", mData.id, sName)
            end
        end)
    end
end

function CConnection:_TrueCreateRole2(mData, iRoleType, sName, iSchool, sServerTag, bFirstRole)
    local id = mData.id
    if not id then
        self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_id})
        gamedb.SaveDb("login", "common", "DbOperate", {
            module = "namecounter",
            cmd = "DeleteName",
            cond = {name = sName},
        })
        record.error("create role no id ret revert: %s", sName)
        return
    end
    local sAccount = self:GetAccount()
    local iChannel = self:GetChannel()
    local iFakePlatform = self:GetFakePlatform()

    local mRoleType = res["daobiao"]["roletype"]
    local mInfo = mRoleType[iRoleType]

    local mCreateInfo = self:GetCreateInfo(sServerTag, sAccount, iChannel, iFakePlatform, id, iSchool, mInfo)
    mCreateInfo.name = sName
    local mInfo = {
        module = "playerdb",
        cmd = "CreatePlayer",
        data = {data = mCreateInfo},
    }
    gamedb.SaveDb("login", "common", "DbOperate", mInfo)

    local mInfo = {
        module = "offlinedb",
        cmd = "CreateOffline",
        data = {data = {pid = id}},
    }
    gamedb.SaveDb("login", "common", "DbOperate", mInfo)
    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)

    if bFirstRole then
        self:LogRegisterAccount()
    end

    -- 数据中心 角色创建日志
    local mAnalyLog = self:GetBaseAnalyData()
    mAnalyLog["role_id"] = id
    mAnalyLog["role_name"] = sName
    mAnalyLog["profession"] = iSchool
    mAnalyLog["role_level"] = 0
    mAnalyLog["fight_point"] = 0
    mAnalyLog["outside"] = iRoleType
    analy.log_data("CreatRole", mAnalyLog)

    local oGateMgr = global.oGateMgr
    if not oGateMgr:IsOpen() and not oGateMgr:ValidPlayerLogin(sAccount, iChannel, self.m_sIP) then
        self:PreCreateRoleAnnounce(1106)
        return
    end

    self:Send("GS2CCreateRole", {
        account = sAccount,
        channel = iChannel,
        create_time = mCreateInfo.create_time,
        role = {
            pid = id,
            grade = mCreateInfo.base_info.grade,
            name = mCreateInfo.name,
            icon = mCreateInfo.base_info.icon,
            school = iSchool,
            model_info = {
                shape = mCreateInfo.base_info.model_info.shape,
                scale = mCreateInfo.base_info.model_info.scale,
                color = mCreateInfo.base_info.model_info.color,
                mutate_texture = mCreateInfo.base_info.model_info.mutate_texture,
                weapon = mCreateInfo.base_info.model_info.weapon,
                adorn = mCreateInfo.base_info.model_info.adorn,
            }
        }
    })
end

function CConnection:LogRegisterAccount()
    local mLogData = {}
    mLogData.account = self:GetAccount()
    mLogData.channel = self:GetChannel()
    record.user("account", "create", mLogData)

    analy.log_data("RegisterAccount", self:GetBaseAnalyData())

    --　当前账号只有一个角色的时候记录
    local iHandle = self:GetNetHandle()
    router.Request("cs", ".datacenter", "common", "GetRoleListByAccount", {
        account = self:GetAccount(),
        channel = self:GetChannel(),
        platform = self:GetFakePlatform(),
    }, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_LogRegisterAccount(mData.roles)
        end
    end)
end

function CConnection:_LogRegisterAccount(lRoleList)
    --　当前账号只有一个角色的时候记录
    if not lRoleList or #lRoleList ~= 1 then return end

    analy.log_data("RegisterAccount_2", self:GetBaseAnalyData()) 
end

function CConnection:GetCreateInfo(sServerTag, sAccount, iChannel, iFakePlatform, iPid, iSchool, mExtend)
    mExtend = mExtend or {}
    local mData = {
            pid = iPid,
            account = sAccount,
            channel = iChannel,
            platform = iFakePlatform,
            name = string.format("DEBUG%d", iPid),
            create_time = get_time(),
            born_server = sServerTag,
            now_server = get_server_tag(),
            deleted = false,
            base_info = {
                grade = 0,
                sex = mExtend.sex,
                school = iSchool,
                icon = mExtend.shape,
                role_type = mExtend.roletype,
                model_info = {
                    shape = mExtend.shape,
                    scale = 0,
                    color = {0,},
                    mutate_texture = 0,
                    weapon = 0,
                    adorn = 0,
                },
            },
            active_info = {map_id = 1001, pos = {x = 100, y = 100, z  = 0, face_x = 0, face_y = 0, face_z = 0}},
        }
        return mData
end

function CConnection:LoginRole(mData)
    local iStatus = self.m_oStatus:Get()
    assert(iStatus, "connection status is nil")
    local oGateMgr = global.oGateMgr

    if iStatus ~= gamedefines.LOGIN_CONNECTION_STATUS.login_account then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.in_login_role)

    analy.log_data("LoginAccount", self:GetBaseAnalyData())

    self.m_iForceLogin = mData.force or 0
    local pid = mData.pid
    local iHandle = self:GetNetHandle()
    local mInfo = {
        module = "playerdb",
        cmd = "GetPlayer",
        cond = {pid = pid},
    }
    gamedb.LoadGameDb(self.m_sServerTag, "login", "common", "DbOperate", mInfo, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_LoginRole1(mRecord, mData)
        end
    end)
end

function CConnection:_LoginRole1(mRecord, mData)
    local oGateMgr = global.oGateMgr

    local m = mData.data
    if not m or (m and m.account ~= self:GetAccount() and m.channel ~= self:GetChannel()) then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end
    local pid = mData.pid

    if m.deleted then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end
    if m.ban_time and m.ban_time > get_time() then
        self:Send("GS2CNotify", {
            cmd = "账号已被封停，请联系客服",
        })
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local oLoginQueueMgr = global.oLoginQueueMgr
    if not oLoginQueueMgr:ValidLogin(pid, self.m_iHandle) then
        self:OnStartLoginQueue(pid)
        return
    end

    local sAccountToken = self:GetAccountToken()
    local sRoleToken = oGateMgr:DispatchRoleToken()
    oGateMgr:EnterLoginQueue(pid, {
        conn = {
            handle = self.m_iHandle,
            gate = self.m_iGateAddr,
            ip = self.m_sIP,
            port = self.m_iPort,
        },
        role = {
            account = self:GetAccount(),
            channel = self:GetChannel(),
            cps = self:GetCpsChannel(),
            account_token = sAccountToken,
            role_token = sRoleToken,
            pid = mData.pid,
            mac = self:GetMac(),
            device = self:GetDevice(),
            fake_platform = self:GetFakePlatform(),
            platform = self:GetPlatform(),
            create_time = m.create_time,
            born_server = m.born_server,
            now_server = m.now_server,
            imei = self:GetIMEI(),
            os = self:GetClientOs(),
            client_ver = self:GetClientVer(),
            udid = self:GetUDID(),
            cbtpay = self.m_mCbtPay,
            forcelogin = self.m_iForceLogin,
        }
    })
end

function CConnection:LoginResult(mData)
    local iErrcode = mData.errcode
    local pid = mData.pid
    local sToken = mData.token
    local oGateMgr = global.oGateMgr
    oGateMgr:LeaveLoginQueue(pid)
    if iErrcode == gamedefines.ERRCODE.ok then
        self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_role)
        self:Add2TokenCache(pid, sToken)
    elseif iErrcode == gamedefines.ERRCODE.login_ks then
        global.oLoginQueueMgr:OnLogout(pid)
    else
        self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
        self:Send("GS2CLoginError", {pid = pid, errcode = iErrcode})
    end
end

function CConnection:ReLoginRole(mData)
    local app_ver = mData.app_ver
    if is_production_env() and app_ver ~= version.APP_VERSION then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_app_version})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local pid = mData.pid
    local role_token = mData.role_token

    local oGateMgr = global.oGateMgr
    local mInfo = oGateMgr:GetCacheInfo(pid, role_token)
    if not mInfo then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.invalid_role_token})
        return
    end

    self:SetAccount(mInfo.account)
    self:SetChannel(mInfo.channel)
    self:SetCpsChannel(mInfo.cps)
    self:SetMac(mInfo.mac)
    self:SetDevice(mInfo.device)
    self:SetPlatform(mInfo.platform)
    self:SetFakePlatform(mInfo.fake_platform)
    self:SetIMEI(mInfo.imei)
    self:SetClientOs(mInfo.os)
    self:SetClientVer(mInfo.client_ver)
    self:SetUDID(mData.udid)
    self.m_sServerTag = mInfo.servertag

    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
    self:LoginRole(mData)
end

function CConnection:Add2TokenCache(pid, sToken)
    local oGateMgr = global.oGateMgr
    local mRoleInfo = {
        pid = pid,
        account = self:GetAccount(),
        channel = self:GetChannel(),
        cps = self:GetCpsChannel(),
        mac = self:GetMac(),
        device = self:GetDevice(),
        platform = self:GetPlatform(),
        fake_platform = self:GetFakePlatform(),
        imei = self:GetIMEI(),
        os = self:GetClientOs(),
        client_ver = self:GetClientVer(),
        udid = self:GetUDID(),
        servertag = self.m_sServerTag,
    }
    oGateMgr:Add2TokenCache(pid, sToken, mRoleInfo)
end

function CConnection:GetLoginPendingRole()
    return self.m_iLoginPendingRole
end

function CConnection:OnStartLoginQueue(pid)
    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
    self.m_iLoginPendingRole = pid
end

function CConnection:QuitLoginQueue()
    local iPid = self.m_iLoginPendingRole
    self.m_iLoginPendingRole = nil

    local oLoginQueueMgr = global.oLoginQueueMgr
    oLoginQueueMgr:QuitQueue(iPid)
end

function CConnection:GetBaseAnalyData()
    return {
        account_id = self:GetAccount(),
        ip = self.m_sIP,
        device_model = self:GetDevice(),
        udid = self:GetUDID(),
        os = self:GetClientOs(),
        version = self:GetClientVer(),
        app_channel = self:GetChannel(),
        sub_channel = self:GetCpsChannel(),
        server = get_server_key(),
        plat = self:GetPlatform(),
    }
end

function CConnection:GS2CLoginError(pid, errcode, cmd)
    self:Send("GS2CLoginError", {pid = pid, errcode = errcode, cmd = cmd})
end

function CConnection:PreCreateRoleAnnounce(iText)
    local sMsg = util.GetTextData(iText)
    self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.pre_create_role, cmd = sMsg})
end

function CConnection:KSLoginRole(mData)
    if not is_ks_server() then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_server_key})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local iHandle = self:GetNetHandle()
    local fCallback = function (mRec, mRet)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_KSLoginRole(mData, mRet.serverkey)
        end
    end
    interactive.Request(".world", "login", "GetPlayerServerKey", {pid=mData.pid}, fCallback)
end

function CConnection:_KSLoginRole(mData, sServerKey)
    self.m_sServerTag = sServerKey
    if not sServerKey then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_server_key})
        global.oGateMgr:KickConnection(self.m_iHandle)
        record.warning(string.format("CConnection:_KSLoginRole ServerKey:%s Pid:%s", sServerKey, mData.pid))
        return
    end 
    self:LoginRoleByPid(mData)
end

function CConnection:LoginRoleByPid(mData)
    local sToken = mData.token
    if (not sToken or sToken == "") and is_production_env() then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_account_env})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local iHandle = self:GetNetHandle()
    if sToken and sToken ~= "" then
        self:SetAccountToken(sToken)
        self:DoVerifyLoginToken(sToken, function (mInfo)
            local oConn = global.oGateMgr:GetConnection(iHandle)
            if oConn then
                oConn:_LoginRoleByPid2(mData, mInfo.errcode, mInfo.account)
            end
        end)    
    else
        local iPid = mData.pid
        self:LoadPlayerInfo(iPid, function (mInfo)
            local oConn = global.oGateMgr:GetConnection(iHandle)
            if oConn then
                oConn:_LoginRoleByPid2(mData, 0, mInfo.data)
            end
        end)    
    end
end

function CConnection:_LoginRoleByPid2(mData, iErrcode, mInfo)
    if iErrcode ~= 0 then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.invalid_token})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end
    if not mInfo then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_account_env})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end   

    self:SetMac(mData.mac)
    self:SetDevice(mData.device)
    self:SetPlatform(mData.platform)
    self:SetIMEI(mData.imei)
    self:SetClientOs(mData.os)
    self:SetClientVer(mData.client_ver)
    self:SetUDID(mData.udid)

    self:SetAccount(mInfo.account)
    self:SetChannel(mInfo.channel)
    self:SetFakePlatform(mInfo.platform)
    self:SetCpsChannel(mInfo.cps)

    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
    self:LoginRole({pid=mData.pid})
end

function CConnection:DoVerifyLoginToken(sToken, endfunc)
    local iNo = string.match(sToken, "%w+_(%d+)")
    local sServiceName = string.format(".loginverify%s",iNo)
    router.Request("cs", sServiceName, "common", "GSGetVerifyAccount", {
        token = sToken,
    }, function (mRecord, mData)
        endfunc(mData)
    end)
end

function CConnection:LoadPlayerInfo(iPid, endfunc)
    local mInfo = {
        module = "playerdb",
        cmd = "GetPlayer",
        cond = {pid = iPid},
    }
    gamedb.LoadGameDb(self.m_sServerTag, "login", "common", "DbOperate", mInfo, function (mRec, mRet)
        endfunc(mRet)
    end)
end

function CConnection:BackLoginRole(mData)
    self:LoginRoleByPid(mData)
end
