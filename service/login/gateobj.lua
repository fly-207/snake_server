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

CConnection = import(service_path("CConnection")).CConnection

---@type LoginCGate
CGate = import(service_path("CGate")).CGate
CGateMgr = import(service_path("CGateMgr")).CGateMgr


---@return LoginCGateMgr
function NewGateMgr(...)
    local o = CGateMgr:New(...)
    return o
end

function NewGate(...)
    local o = CGate:New(...)
    return o
end

function NewConnection(...)
    local o = CConnection:New(...)
    return o
end

---@class LoginGateObj
local _M = {}
_M.NewGateMgr = NewGateMgr
_M.NewGate = NewGate
_M.NewConnection = NewConnection
return _M