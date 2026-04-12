--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

-- GS 侧 loginverify 服务通过 router.Request 调用此接口
-- 先调用 CheckFirstRegister（写 register/device_register 表），再查询 roleinfo 表
-- 是账号数据首次写入 CS 数据库的触发点（每次 SDK token 验证后都会调用）
-- @param mData  table  {account, channel:[], platform, server:[], device_id}
function GetRoleList(mRecord, mData)
    local sAccount = mData.account
    local lChannel = mData.channel
    local iPlatform = mData.platform
    local lServer = mData.server
    local sDeviceId = mData.device_id

    local oDataCenter = global.oDataCenter
    local bFirst, bFirst4Device = oDataCenter:CheckFirstRegister(sAccount, lChannel, iPlatform, sDeviceId)
    local mRoleList = oDataCenter:GetRoleList(sAccount, lChannel, iPlatform, lServer)
    if mRoleList then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
            roles = mRoleList,
            first_register = bFirst and 1 or 0,
            first_register_device = bFirst4Device and 1 or 0,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function QueryRoleNowServer(mRecord, mData)
    local iPid = mData.pid

    local oDataCenter = global.oDataCenter
    local sServerTag = oDataCenter:GetRoleNowServer(iPid)
    if sServerTag then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
            server = sServerTag,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function DeleteRole(mRecord, mData)
    local sAccount = mData.account
    local iChannel = mData.channel
    local iPid = mData.pid

    local oDataCenter = global.oDataCenter
    oDataCenter:DeleteRole(sAccount, iChannel, iPid, function (errcode)
        interactive.Response(mRecord.source, mRecord.session, {errcode = errcode})
    end)
end
