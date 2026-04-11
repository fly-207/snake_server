---@module playersend
---玩家消息发送模块
---提供向指定玩家发送网络消息的功能
---维护玩家ID到邮箱(网络连接信息)的映射

local interactive = require "base.interactive"
local router = require "base.router"
local serverdefines = require "public.serverdefines"
local netproto = require "base.netproto"
local record = require "public.record"
local net = require "base.net"

local bigpacket = import(lualib_path("public.bigpacket"))
local unpack = table.unpack

---@class MailBox 玩家邮箱信息，包含网络连接信息
---@field gate integer 网关地址
---@field fd integer 连接文件描述符

---@class playersend 玩家消息发送模块
local M = {}

---@type table<integer, MailBox> 玩家ID到邮箱的映射
local mPlayerMail = {}
---@type table<integer, MailBox> 备用玩家邮箱映射(用于安全切换)
local mSecPlayerMail = {}
---@type boolean 是否需要使用备用邮箱
local mNeedSec = false

---设置使用备用邮箱模式
function M.SetNeedSec()
    mNeedSec = true
end

---更新玩家邮箱信息
---@param iPid integer 玩家ID
---@param mail MailBox|nil 邮箱信息
function M.UpdatePlayerMail(iPid, mail)
    if mNeedSec then
        mSecPlayerMail[iPid] = mail
    else
        mPlayerMail[iPid] = mail
    end
end

---将备用邮箱替换为主邮箱
---@param iPid integer 玩家ID
function M.ReplacePlayerMail(iPid)
    if mSecPlayerMail[iPid] then
        mPlayerMail[iPid] = mSecPlayerMail[iPid]
        mSecPlayerMail[iPid] = nil
    end
end

---获取玩家邮箱信息
---@param iPid integer 玩家ID
---@return MailBox|nil mail 邮箱信息
function M.GetPlayerMail(iPid)
    return mPlayerMail[iPid]
end

---向玩家发送消息
---@param iPid integer|nil 玩家ID
---@param sMessage string 消息名称
---@param mData table 消息数据
function M.Send(iPid, sMessage, mData)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    net.Send(mMail,sMessage,mData)
end

---向玩家发送多条消息
---@param iPid integer|nil 玩家ID
---@param lData MessageInfo[] 消息列表 {message, data}
function M.SendList(iPid,lData)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    local lData2 = {}
    for _,info in pairs(lData) do
        if info.message and info.data then
            M.Send(mMail,info.message,info.data)
        end
    end
end

---打包消息数据
---@param sMessage string 消息名称
---@param mData table 消息数据
---@return string data 打包后的数据
function M.PackData(sMessage,mData)
    return net.PackData(sMessage,mData)
end

---向玩家发送原始数据
---@param iPid integer|nil 玩家ID
---@param sData string 原始数据
function M.SendRaw(iPid, sData)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    net.SendRaw(mMail,sData)
end

---向玩家发送多条原始数据
---@param iPid integer|nil 玩家ID
---@param lData string[] 原始数据列表
function M.SendRawList(iPid,lData)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    net.SendRawList(mMail,lData)
end

---向玩家发送合并消息包
---@param iPid integer|nil 玩家ID
---@param lMessage MessageInfo[] 消息列表
function M.SendMergePacket(iPid,lMessage)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    net.SendMergePacket(mMail,lMessage)
end

---向玩家发送合并原始数据包
---@param iPid integer|nil 玩家ID
---@param lPacketsData string[] 原始数据包列表
function M.SendMergePacketRaw(iPid,lPacketsData)
    if not iPid then return end
    local mMail = mPlayerMail[iPid]
    if not mMail or type(mMail) ~= "table" then
        return
    end
    net.SendMergePacketRaw(mMail,lPacketsData)
end

function M.KFSend(sServerKey,iPid,sMessage,mData)
    local iSendAddr = ".player_send_proxy"..(iPid%PLAYER_SEND_COUNT+1)
    router.Send(get_server_tag(sServerKey), iSendAddr, "kuafu", "KFDoAddSend",
        { pid = iPid , message = sMessage , data = mData })
end

function M.KFSendRaw(sServerKey,iPid,sData)
    local iSendAddr = ".player_send_proxy"..(iPid%PLAYER_SEND_COUNT+1)
    router.Send(get_server_tag(sServerKey), iSendAddr, "kuafu", "KFSendRaw",
        { pid = iPid , sdata = sData })
end

return M
