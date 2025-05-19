--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local router = require "base.router"
local extype = require "base.extype"
local res = require "base.res"
local record = require "public.record"

CConnection = import(service_path("CConnection")).CConnection
CGate = import(service_path("CGate")).CGate
CGateMgr = import(service_path("CGateMgr")).CGateMgr

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
