---@module "public.dataanaly"
--- 数据分析模块
--- 提供数据分析日志的记录功能，支持基础日志和MTBI日志

local skynet = require "skynet"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"
local gdefines = import(lualib_path("public.gamedefines")) 
local serverinfo = import(lualib_path("public.serverinfo"))
local channelinfo = import(lualib_path("public.channelinfo"))

---@type table<string, file*> 文件句柄缓存
mFileFd = {}
---@type table<string, string> 文件路径缓存
mFilePath = {}

---@type table<string, file*> MTBI文件句柄缓存
mMtbiFileFd = {}
---@type table<string, string> MTBI文件路径缓存
mMtbiFilePath = {}

---@type integer? 基础日志状态
local LOG_BASE_STAUTS = nil
---@type integer? MTBI日志状态
local LOG_MTBI_STAUTS = nil

--- 检查是否开启基础日志
---@return boolean
is_log_base = function () 
    if is_production_env() then
        return true
    end

    -- 测试服
    if LOG_BASE_STAUTS then
        return LOG_BASE_STAUTS == 1
    end

    if exist_file("/home/nucleus-h7") then 
        LOG_BASE_STAUTS = 1
    else
        LOG_BASE_STAUTS = 0
    end

    return LOG_BASE_STAUTS == 1
end

--- 检查是否开启MTBI日志
---@return boolean
is_log_mtbi = function ()
    if is_production_env() then
        return true
    end

    -- 测试服
    if LOG_MTBI_STAUTS then
        return LOG_MTBI_STAUTS == 1
    end

    if exist_file("/home/nucleus-h7") then 
        LOG_MTBI_STAUTS = 1
    else
        LOG_MTBI_STAUTS = 0
    end

    return LOG_MTBI_STAUTS == 1
end

--- 记录数据分析日志
---@param sName string 日志名称
---@param mData table 日志数据
function log_data(sName, mData)
    if not is_log_base() then return end

    interactive.Send(".logfile", "common", "WriteData",  {sName = sName, data = mData})
end

--- 记录MTBI日志
---@param sName string 日志名称
---@param mData table 日志数据
function log_mtbi(sName, mData)
    if serverinfo.is_h7d_server() then return end

    if not is_log_mtbi() then return end

    interactive.Send(".logfile", "common", "WriteMtbi",  {sName = sName, data = mData}) 
end

--- 写入数据到文件
---@param sName string 文件名
---@param sData string 数据内容
function write_data(sName, sData)
    local sPath = LOG_BASE_PATH
    local sServerPath = string.format("%s/%s", sPath, MY_SERVER_KEY)
    local sFile = string.format("%s/%s/%s", sPath, MY_SERVER_KEY,sName)
    if mFilePath[sName] or (create_folder(sPath) and create_folder(sServerPath) and create_folder(sFile)) then
        local m = os.date("*t", get_time())
        local sFile = string.format("%s/%s_%04d-%02d-%02d",sFile,sName,m.year,m.month,m.day)
        local fd = mFileFd[sName]
        if not fd or mFilePath[sName] ~= sFile then
            if fd then
                fd:close()
            end
            fd = io.open(sFile,"a")
        end
        write_file_byfd(fd,sData)
        mFileFd[sName] = fd
        mFilePath[sName] = sFile
    end
end

--- 写入MTBI日志到文件
---@param sType string 日志类型
---@param mData table 日志数据
function write_mtbi(sType, mData)
    if serverinfo.is_h7d_server() then return end
        
    local sPath = LOG_MTBI_PATH
    local mFormat = table_get_depth(res, {"daobiao", "log", "mtbi", sType})
    if not mFormat then
        record.error("write_mtbi error not find type %s", sType)
        return
    end

    local sMsg = ""
    for _, mLog in pairs(mFormat["log_format"]) do
        if #sMsg > 0 then
            sMsg = sMsg.."0x01"
        end
        local sKey = mLog["id"]
        local sValue = mData[sKey]
        if sKey == "time" then
            sValue = get_time_format_str(sValue or get_time(), "%Y-%m-%d %H:%M:%S")
            -- sMsg = string.format("%s\"%s\"", sMsg, sValue)
        elseif sKey == "channel" or sKey == "app_channel" then
            sValue = GetMtbiChannel(sValue, sType)
        elseif sKey == "platform" then
            sValue = GetMtbiPlatform(sValue)
        end

        if type(sValue) == "string" then
            sValue = string.gsub(sValue, "\"", "\"\"")    
        elseif type(sValue) == "table" then
            sValue = table_mtbi_concat(sValue)
        end
        sMsg = string.format("%s\"%s\"", sMsg, sValue or "")
    end

    local sServerPath = string.format("%s/%s", sPath, MY_SERVER_KEY)
    local sFile = string.format("%s/%s/%s", sPath, MY_SERVER_KEY,sType)
    if mMtbiFilePath[sType] or (create_folder(sPath) and create_folder(sServerPath) and create_folder(sFile)) then
        local m = os.date("*t", get_time())
        local sFile = string.format("%s/%s.%s.log.%04d-%02d-%02d.csv",sFile,MY_SERVER_KEY,sType,m.year,m.month,m.day)
        local fd = mMtbiFileFd[sType]
        if not fd or mMtbiFilePath[sType] ~= sFile then
            if fd then
                fd:close()
            end
            fd = io.open(sFile,"a")
        end
        write_file_byfd(fd, sMsg)
        mMtbiFileFd[sType] = fd
        mMtbiFilePath[sType] = sFile
    end
end

--- 将表转换为key+value&key+value格式
---@param m? table 要转换的表
---@return string
function table_concat(m)
    local s = ""
    for key, val in pairs(m or {}) do
        if #s > 0 then s = s.."&" end
            
        s = s..key.."+"..val
    end
    return s
end

--- 将表转换为key&value,key&value格式(MTBI用)
---@param m? table 要转换的表
---@return string
function table_mtbi_concat(m)
    local s = ""
    for key, val in pairs(m or {}) do
        if #s > 0 then s = s.."," end
            
        s = s..key.."&"..val
    end
    return s
end

--- 获取MTBI渠道编码
---@param iChannel integer 原始渠道ID
---@param sType string 日志类型
---@return integer MTBI渠道编码
function GetMtbiChannel(iChannel, sType)
    if iChannel == 1048 then return 211 end
    if iChannel == 0 then return iChannel end

    local mChannelInfo = channelinfo.get_channel_info()
    local mChannel = mChannelInfo[iChannel]
    if not mChannel then
        record.warning("log mtbi not find channel %s %s", iChannel, sType)
        return iChannel
    end
    return mChannel["channel"]
end

--- 获取MTBI平台编码
---@param iPlatform integer 平台ID
---@return integer MTBI平台编码
function GetMtbiPlatform(iPlatform)
    if table_in_list({gdefines.PLATFORM.ios, gdefines.PLATFORM.rootios}, iPlatform) then
        -- ios
        return 219
    end
    return 220
end
