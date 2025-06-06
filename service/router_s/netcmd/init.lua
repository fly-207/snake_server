--import module

local global = require "global"
local skynet = require "skynet"
local router = require "base.router"
local record = require "public.record"
local cjson = require "cjson"

function Invoke(iCmd, fd, mData)
    local oGateMgr = global.oGateMgr
    local oConn = oGateMgr:GetConnection(fd)

    -- 排除 心跳 协议日志
    if iCmd ~= 102 then
        print(string.format("router服务端 网络消息 服务=%s iCmd=%s fd=%s mData=%s",SERVICE_NAME, iCmd, fd, cjson.encode(mData)))
    end

    if oConn then
        if iCmd == router.PROTO_P2R.P2RRouter then
            local mPRecord = mData.record
            oGateMgr:SendR2P(mPRecord.dessk, router.PROTO_R2P.R2PRouter, mData)
        elseif iCmd == router.PROTO_P2R.P2RHeartBeat then
            local sServerKey = mData.sk
            oConn:HandleHeartBeat(sServerKey)
        elseif iCmd == router.PROTO_P2R.P2RRouterBig then
            oGateMgr:SendR2P(mData.sk, router.PROTO_R2P.R2PRouterBig, mData)
        else
            record.warning(string.format("router_s netcmd fail %d", iCmd))
        end
    end
end
