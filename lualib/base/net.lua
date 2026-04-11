---@module "base.net"
--- 网络通信模块
--- 提供客户端与服务器之间的网络协议处理，支持protobuf编解码

local skynet = require "skynet"
local netpack = require "netpack"
local extype = require "base.extype"
local netproto = require "base.netproto"
local rt_monitor = require "base.rt_monitor"
local bigpacket = import(lualib_path("public.bigpacket"))
local cjson = require "cjson"
local unpack = table.unpack

---@class NetModule 网络模块
---@field PushMerge fun(iAddr: integer, lNet?: table[]) 推送合并消息
---@field DispatchProxy fun(netcmd: table) 代理分发
---@field Dispatch fun(netcmd: table) 消息分发
---@field PackData fun(sMessage: string, mData: table): string 打包数据
---@field PackMergeData fun(sMessage: string, mData: table): string 打包合并数据
---@field Send fun(mMailBox: table, sMessage: string, mData: table) 发送消息
---@field Mask fun(sMessage: string, mData: table): table 消息掩码
---@field UnMask fun(sMessage: string, mData: table): table 消息解掩码
local M = {}

--- 推送合并消息
---@param iAddr integer 目标地址
---@param lNet? table[] 消息列表
function M.PushMerge(iAddr, lNet)
    lNet = lNet or {}
    skynet.send(iAddr, "zinc_client_merge", lNet)
end

--- 代理模式的消息分发
---@param netcmd table 网络命令处理器
function M.DispatchProxy(netcmd)
    skynet.register_protocol {
        name = "zinc_client_merge",
        id = extype.ZINC_CLIENT_MERGE,
        pack = skynet.pack,
    }

    skynet.register_protocol {
        name = "zinc_client",
        id = extype.ZINC_CLIENT,
        unpack = function (...) return ... end,
        dispatch = function (session, source, msg, sz)
            if netcmd then
                local sData = netpack.tostring2(msg, sz)
                assert(#sData >= 6, "zinc_client unpack error")
                local fd = sData:byte(1)*(2^24) + sData:byte(2)*(2^16) + sData:byte(3)*(2^8) + sData:byte(4)
                local iType = sData:byte(5)*(2^8) + sData:byte(6)
                netcmd.Invoke(fd, iType, string.sub(sData, 7))
            end
        end,
    }
end

--- 消息分发处理
---@param netcmd table 网络命令处理器
function M.Dispatch(netcmd)
    skynet.register_protocol {
        name = "zinc",
        id = extype.ZINC,
        pack = function ( ... )
            return ...
        end,
    }

    skynet.register_protocol {
        name = "zinc_client",
        id = extype.ZINC_CLIENT,
        unpack = function (...) return ... end,
        dispatch = function (session, source, msg, sz)

            if netcmd then
                local sData = netpack.tostring2(msg, sz)
                assert(#sData >= 6, "zinc_client unpack error")

                local fd = sData:byte(1)*(2^24) + sData:byte(2)*(2^16) + sData:byte(3)*(2^8) + sData:byte(4)

                -- 消息号, 例如 C2GSLoginAccount 对应的 iType 是 1001
                local iType = sData:byte(5)*(2^8) + sData:byte(6)

                -- m 包含两个值 ( [模块名login], iType对应的协议串C2GSLoginAccount), 协议串==处理函数名==pb结构体名
                local m = netproto.NetfindFunc("FindC2GSByType", iType)
                local s1 = string.format("zinc_client find proto type: %d, fd: %d", iType, fd)
                assert(m, s1)
                local mData, sMsg = netproto.ProtobufFunc("decode", m[2], string.sub(sData, 7))

                local s2 = string.format("zinc_client decode proto module: %s, cmd: %s, msg: %s, fd: %d", m[1], m[2], sMsg, fd)
                assert(mData, s2)

                print(string.format("gate zinc_client 消息 fd=%s iType=%s module: %s, cmd: %s, err-msg: %s, fd: %d", fd, iType, m[1], m[2], sMsg, fd))
                print(string.format("gate zinc_client 消息 fd=%s iType=%s mData: %s", fd, iType, cjson.encode(mData)))

                local net_module = m[1]
                local msg_name = m[2]
                safe_call(function ()
                    rt_monitor.mo_call({"net", net_module, msg_name}, netcmd.Invoke, net_module, msg_name, fd, mData)
                end)
            end
        end,
    }

    skynet.register_protocol {
        name = "zinc_client_merge",
        id = extype.ZINC_CLIENT_MERGE,
        unpack = skynet.unpack,
        dispatch = function (session, source, netlst)
            if netcmd then
                for _, v in ipairs(netlst) do
                    safe_call(function ()
                        local iFd, iType, sData = unpack(v)
                        local m = netproto.NetfindFunc("FindC2GSByType", iType)
                        assert(m, string.format("zinc_client_merge find proto err type: %d, fd: %d", iType, iFd))
                        local mData, sMsg = netproto.ProtobufFunc("decode", m[2], sData)
                        assert(mData, string.format("zinc_client_merge decode proto err module: %s, cmd: %s, msg: %s, fd: %d", m[1], m[2], sMsg, iFd))
                        rt_monitor.mo_call({"net", m[1], m[2]}, netcmd.Invoke, m[1], m[2], iFd, mData)
                    end)
                end
            end
        end,
    }
end

function M.Mask(sMessage, mData)
    assert(not mData.mask, "Mask fail should has no mask field")
    local m = netproto.ProtobufFunc("name_fields", sMessage)
    assert(m.mask == 1, "Mask fail mask field should be id 1")
    local mRet = {}
    local mMod = {}
    local iMax = 0
    for k, v in pairs(mData) do
        local iNo = assert(m[k], string.format("Mask fail %s error", k))
        local iMod, iRet = (iNo-1)//4, iNo%4
        local iMask = mMod[iMod] or 0
        mRet[k] = v
        if iRet > 0 then
            iMask = iMask | (2^(iRet-1))
        else
            iMask = iMask | (2^3)
        end
        mMod[iMod] = iMask
        iMax = math.max(iMod, iMax)
    end
    local sMask = ""
    for i = iMax, 0, -1 do
        sMask = sMask .. string.format("%x", mMod[i] or 0)
    end
    mRet.mask = sMask
    return mRet
end

function M.UnMask(sMessage, mData)
    if not mData.mask then
        mData.mask = ""
    end
    local m = netproto.ProtobufFunc("id_fields", sMessage)
    assert(m[1] == "mask", "Mask fail mask field should be id 1")
    local sMask = mData.mask
    local iLen = #sMask
    local mRet = {}
    for i = 1, iLen do
        local iByte = tonumber(string.char(sMask:byte(i)), 16)
        for j = 1, 4 do
            local k = (iLen - i) * 4 + j
            if k == 1 then
                goto continue
            end
            local b = (2 ^ (j - 1)) & iByte
            if b~=0 then
                local sKey = assert(m[k], string.format("UnMask fail %s error", k))
                mRet[sKey] = mData[sKey]
            end
            ::continue::
        end
    end
    return mRet
end

function M.PackData(sMessage, mData)
    local iType = netproto.NetfindFunc("FindGS2CByName", sMessage)
    assert(iType, "PackData error, undefined proto")
    local sEncode = netproto.ProtobufFunc("encode", sMessage, mData)
    local iNum = 2
    local iPow = 8 * (iNum - 1)
    local lst = {}
    for i = 1, iNum do
        table.insert(lst,  string.char((iType//(2^iPow))%256))
        iPow = iPow - 8
    end
    table.insert(lst, sEncode)
    sEncode = table.concat(lst, "")
    sEncode = string.pack(">s2", sEncode)
    return sEncode
end


function M.PackMergeData(sMessage,mData)
    local iType = netproto.NetfindFunc("FindGS2CByName", sMessage)
    assert(iType, "PackData error, undefined proto")
    local sEncode = netproto.ProtobufFunc("encode", sMessage, mData)
    local iNum = 2
    local iPow = 8 * (iNum - 1)
    local lst = {}
    for i = 1, iNum do
        table.insert(lst,  string.char((iType//(2^iPow))%256))
        iPow = iPow - 8
    end
    table.insert(lst, sEncode)
    sEncode = table.concat(lst, "")
    return sEncode
end

function M.Send(mMailBox, sMessage, mData)
    local sData = M.PackData(sMessage, mData)
    print(string.format("net 发送消息 pb_name=%s", sMessage), mData)
    M.SendRaw(mMailBox, sData)
end

function M.SendRawList(mMailBox, lDataList)
    for _, v in ipairs(lDataList) do
        M.SendRaw(mMailBox, v)
    end
end

function M.SendRaw(mMailBox, sData)
    local iGateAddr = mMailBox.gate
    local fd = mMailBox.fd

    local iPow = 0
    local lst = {sData,}
    for i = 1, 4 do
        table.insert(lst, string.char((fd//(2^iPow))%256))
        iPow = iPow + 8
    end
    sData = table.concat(lst, "")

    print(string.format("net 发送到网关 mMailBox=%s data长度=%s", cjson.encode(mMailBox), #sData))

    skynet.send(iGateAddr, "zinc" , sData)
end

--大包打包协议
function M.SendMergePacket(mMailBox,lMessage)
    lMessage = lMessage or {}
    local lPacketsData = {}
    for _,mMessage in ipairs(lMessage) do
        local sMessage = mMessage.message
        local mData = mMessage.data
        local sEncode = M.PackMergeData(sMessage,mData)
        table.insert(lPacketsData,sEncode)
    end
    local sMessage = "GS2CMergePacket"
    local mData = {
        packets = lPacketsData,
    }
    bigpacket.SendBig(mMailBox,sMessage,mData)
end

function M.SendMergePacketRaw(mMailBox,lPacketsData)
    lPacketsData = lPacketsData or {}
    local sMessage = "GS2CMergePacket"
    local mData = {
        packets = lPacketsData
    }
    bigpacket.SendBig(mMailBox,sMessage,mData)
end

return M
