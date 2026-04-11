---@module "public.channelinfo"
--- 渠道信息模块
--- 提供渠道配置信息的获取功能

-- import file

local res = require "base.res"

local serverinfo = import(lualib_path("public.serverinfo"))

--- 获取渠道信息配置
---@return table 渠道信息表
function get_channel_info()
    if serverinfo.is_h7d_server() then
        return res["daobiao"]["h7dchannel"]
    else
        return res["daobiao"]["demichannel"]
    end
end 

--- 获取同类渠道列表
---@param iChannel integer 渠道ID
---@return integer[] 同类渠道ID列表
function get_same_channels(iChannel)
    if serverinfo.is_h7d_server() then
        return res["daobiao"]["h7dchannelgroup"][iChannel] or {iChannel}
    else
        return res["daobiao"]["channelgroup"][iChannel] or {iChannel}
    end
end
---- 需要处理的