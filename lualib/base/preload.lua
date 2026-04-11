---@module "base.preload"
--- 预加载模块
--- 在服务启动时初始化全局变量和基础模块

local skynet = require "skynet"

---@type integer 当前服务地址
MY_ADDR = skynet.self()
---@type string 服务器标识
MY_SERVER_KEY = skynet.getenv("server_key")
---@type string 服务器本地IP
MY_SERVER_LOCAL_IP = skynet.getenv("server_local_ip")
---@type string 当前服务名称
MY_SERVICE_NAME = ...
---@type integer? 是否自动开启性能测量
IS_AUTO_OPEN_MEASURE = tonumber(skynet.getenv("AUTO_OPEN_MEASURE"))
---@type integer? 是否自动跟踪基础对象
IS_AUTO_TRACK_BASEOBJECT = tonumber(skynet.getenv("AUTO_TRACK_BASEOBJECT"))
---@type integer? 是否自动开启监控
IS_AUTO_MONITOR = tonumber(skynet.getenv("AUTO_MONITOR"))
---@type string 基础日志路径
LOG_BASE_PATH = skynet.getenv("LOG_BASE_PATH")
---@type string 数据库文件路径
DB_FILE_PATH = skynet.getenv("DB_FILE_PATH")

require "base.commonop"

local tbpool = require "base.tbpool"
tbpool.Init()

local servicetimer = require "base.servicetimer"
servicetimer.Init()

require "base.reload"
require "base.timeop"
require "base.fileop"
require "base.stringop"
require "base.tableop"
require "base.vector3"

---@type string 服务器集群标识
MY_SERVER_CLUSTER = get_server_cluster(MY_SERVER_KEY)
---@type string 服务器标签
MY_SERVER_TAG = get_server_tag(MY_SERVER_KEY)
---@type string 服务器类型
MY_SERVER_TYPE = get_server_type(MY_SERVER_KEY)
---@type integer 服务器ID
MY_SERVER_ID = get_server_id(MY_SERVER_KEY)

local basehook = require "base.basehook"
local baserecycle = require "base.baserecycle"
local interactive = require "base.interactive"
local servicesave = require "base.servicesave"
local netproto = require "base.netproto"

skynet.dispatch_finish_hook(basehook.hook)
basehook.set_base(function ()
    baserecycle.recycle()
end)

interactive.Init()
netproto.Init()
servicesave.Init()

create_folder(LOG_BASE_PATH)
create_folder(LOG_BASE_PATH..MY_SERVER_KEY)
if is_ks_server() then
    create_folder(DB_FILE_PATH)
end
