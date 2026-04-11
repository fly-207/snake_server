---@module commonop
---通用操作工具模块
---提供服务器信息获取、文件加载、打印等常用全局函数

local skynet = require "skynet"

---获取服务器Key
---@return string key 服务器Key (如 "s1_gs1")
get_server_key = function ()
    return MY_SERVER_KEY
end

---获取服务器集群名
---@param server_key string|nil 服务器Key，默认当前服务器
---@return string cluster 集群名
get_server_cluster = function (server_key)
    if not server_key then
        return MY_SERVER_CLUSTER
    end
    return string.match(server_key, "(%w+)_%w+")
end

---获取服务器标签
---@param server_key string|nil 服务器Key，默认当前服务器
---@return string tag 服务器标签
get_server_tag = function (server_key)
    if not server_key then
        return MY_SERVER_TAG
    end
    return string.match(server_key, "%w+_(%w+)")
end

---获取服务器类型
---@param server_key string|nil 服务器Key，默认当前服务器
---@return string type 服务器类型 (如 "gs", "cs")
get_server_type = function (server_key)
    if not server_key then
        return MY_SERVER_TYPE
    end
    return string.match(server_key, "%w+_(%a+)%d*")
end

---获取服务器ID
---@param server_key string|nil 服务器Key，默认当前服务器
---@return integer|nil id 服务器ID
get_server_id = function (server_key)
    if not server_key then
        return MY_SERVER_ID
    end
    return tonumber(string.match(server_key, "%w+_%a+(%d*)"))
end

---根据服务器标签生成完整的服务器Key
---@param server_tag string 服务器标签
---@return string key 完整的服务器Key
make_server_key = function (server_tag)
    assert(server_tag, "make server key error: no server tag")
    return get_server_cluster().."_"..server_tag
end

local floor = math.floor
local random = math.random

---扩展的loadfile函数
---@param sFileName string 文件名
---@param sMode string|nil 加载模式，默认"bt"
---@param mEnv table|nil 环境表，默认_ENV
---@return function f 加载的函数
loadfile_ex = function (sFileName, sMode, mEnv)
    sMode = sMode or "bt"
    mEnv = mEnv or _ENV
    local h = io.open(sFileName, "rb")
    assert(h, string.format("loadfile_ex fail %s", sFileName))
    local sData = h:read("*a")
    h:close()
    local f, s = load(sData, sFileName, sMode, mEnv)
    assert(f, string.format("loadfile_ex fail %s", s))
    return f
end

---增强的打印函数，支持表的序列化输出
---@param ... any 要打印的参数
print = function ( ... )
    local lInfo = table.pack(...)
    local lResult = {}
    for i = 1, #lInfo do
        if type(lInfo[i]) == "table" then
            table.insert(lResult, require("base.extend").Table.serialize(lInfo[i]))
        elseif lInfo[i] == nil then
            table.insert(lResult, "nil")
        else
            table.insert(lResult, lInfo[i])
        end
    end
    skynet.error(table.unpack(lResult))
end

---检查是否为生产环境
---@return boolean isProd 是否为生产环境
is_production_env = function ()
    local serverinfo = import(lualib_path("public.serverinfo"))
    return serverinfo.IS_PRODUCTION_ENV
end

---检查是否开启自动性能测量
---@return boolean isOpen 是否开启
is_auto_open_measure = function ()
    return IS_AUTO_OPEN_MEASURE ~= 0
end

---检查是否开启基础对象自动跟踪
---@return boolean isOpen 是否开启
is_auto_track_baseobject = function ()
    return IS_AUTO_TRACK_BASEOBJECT ~= 0
end

is_auto_monitor = function ()
    return IS_AUTO_MONITOR ~= 0
end

service_path = function (sPath)
    return string.format("service.%s.%s", MY_SERVICE_NAME, sPath)
end

service_file_path = function (sPath)
    return string.format("service/%s/%s", MY_SERVICE_NAME, sPath)
end

lualib_path = function (sPath)
    return string.format("lualib.%s", sPath)
end

serialize_table = function (t)
    return require("base.extend").Table.serialize(t)
end

table_print = function (t)
    print(require("base.extend").Table.serialize(t))
end

table_print_pretty = function (t)
    print(require("base.extend").Table.pretty_serialize(t))
end

baseobj_safe_release = function (o)
    local baserecycle = require "base.baserecycle"
    baserecycle.now_release(o)
end

baseobj_delay_release = function (o)
    local baserecycle = require "base.baserecycle"
    baserecycle.wait_release(o)
end

release = function (o)
    for _, v in ipairs(table_key_list(o)) do
        o[v] = nil
    end
    o._release = true
    setmetatable(o, {__newindex = function (t, k, v)
        error(string.format("attempt to operate a release obj %s %s", k, v))
    end})
end

is_release = function (o)
    return o._release == true
end

inherit = function (child, parent)
    setmetatable(child, parent)
end

super = function (child)
    return getmetatable(child)
end

logic_base_cls = function ()
    local baseobj = import(lualib_path("base.baseobj"))
    return baseobj.CBaseObject
end

local function Trace(sMsg)
    skynet.error(debug.traceback(sMsg))
end

safe_call = function (func, ...)
    return xpcall(func, Trace, ...)
end

db_key = function (k)
    return tostring(k)
end

--只取3位小数,不提供其他可能性
decimal = function (val)
    return floor(val*1000)*0.001
end

my_floor = function (val)
    return floor(tonumber(string.format('%.14g', val)))
end

in_random = function (i, j)
    j = j or 100
    return random(j) <= i
end

save_all = function ()
    local servicesave = require "base.servicesave"
    servicesave.SaveAll()
end

is_cs_server = function()
    return get_server_type() == "cs"
end

is_gs_server = function()
    return get_server_type() == "gs"
end

is_bs_server = function()
    return get_server_type() == "bs"
end

is_ks_server = function()
    return get_server_type() == "ks"
end

