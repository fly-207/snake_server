---@module "public.record"
--- 日志记录模块
--- 提供统一的日志记录接口，支持数据库日志和文件日志

local skynet = require "skynet"
local interactive = require "base.interactive"

---@class RecordModule 日志记录模块
---@field check_log_db fun(sType: string, sSubType: string, mLog: table) 检查日志格式
---@field log_db fun(sType: string, sSubType: string, mLog: table) 记录到数据库
---@field log_unmovedb fun(sType: string, sSubType: string, mLog: table) 记录到不迁移数据库
---@field log_file fun(sSubType: string, sMsg: string, ...: any) 记录到文件
---@field user fun(sType: string, sSubType: string, mLog: table) 记录用户日志
---@field unmove fun(sType: string, sSubType: string, mLog: table) 记录不迁移日志
---@field error fun(sMsg: string, ...: any) 记录错误日志
---@field info fun(sMsg: string, ...: any) 记录信息日志
---@field warning fun(sMsg: string, ...: any) 记录警告日志
---@field debug fun(sMsg: string, ...: any) 记录调试日志
local M = {}

--- 检查日志格式是否符合导表配置
---@param sType string 日志类型
---@param sSubType string 日志子类型
---@param mLog table 日志数据
function M.check_log_db(sType, sSubType, mLog)
    local res = require "base.res"
    local mFormat = table_get_depth(res, {"daobiao", "log", sType, sSubType, "log_format"})
    assert(mFormat, string.format("check_log err: type err %s %s", sType, sSubType))
    for k, _ in pairs(mLog) do
        if not mFormat[k] and k ~= "_time" then
            assert(false, string.format("check_log err: %s %s undefined key %s", sType, sSubType, k))
            return
        end
    end
    for k, _ in pairs(mFormat) do
        if nil == mLog[k] then
            assert(false, string.format("check_log err: %s %s unformat key %s", sType, sSubType, k))
            return
        end
    end
end

function M.log_db(sType, sSubType, mLog)
    if not is_production_env() then
        safe_call(M.check_log_db, sType, sSubType, mLog)
    end
    mLog.subtype = sSubType
    interactive.Send(".logdb", "common", "PushLog",  {type = sType, data = mLog})
end

function M.log_unmovedb(sType, sSubType, mLog)
    if not is_production_env() then
        safe_call(M.check_log_db, sType, sSubType, mLog)
    end
    mLog.subtype = sSubType
    interactive.Send(".logdb", "common", "PushUnmoveLog",  {type = sType, data = mLog})
end

function M.log_file(sSubType, sMsg, ...)
    local s = string.format("[%s] %s", sSubType, string.format(sMsg, ...))
    skynet.error(s)
end

function M.user(sType, sSubType, mLog)
    M.log_db(sType, sSubType, mLog)
end

function M.unmove(sType, sSubType, mLog)
    M.log_unmovedb(sType, sSubType, mLog)
end

function M.error(sMsg, ...)
    M.log_file("ERROR", sMsg, ...)
end

function M.info(sMsg, ...)
    M.log_file("INFO", sMsg, ...)
end

function M.warning(sMsg, ...)
    M.log_file("WARNING", sMsg, ...)
end

function M.debug(sMsg, ...)
    M.log_file("DEBUG", sMsg, ...)
end

return M
