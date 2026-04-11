---@module netproto
---网络协议管理模块
---封装 protobuf 和 netfind 模块，提供协议编解码和消息查找功能

local skynet = require "skynet"

---@class netproto 网络协议管理模块
---@field Init fun() 初始化协议模块
---@field Update fun() 更新/重载协议模块
---@field ProtobufFunc fun(sFunc: string, ...): any 调用 protobuf 模块的函数
---@field NetfindFunc fun(sFunc: string, ...): any 调用 netfind 模块的函数
local M = {}

---@type table protobuf 模块引用
local pm
---@type table netfind 模块引用
local nm

---初始化协议模块
---加载 protobuf 定义文件和消息定义文件
function M.Init()
    pm = require "base.protobuf"
    nm = require "base.netfind"
    pm.register_file(skynet.getenv("proto_file"))
    nm.Init(skynet.getenv("proto_define"))
end

---更新/重载协议模块
---清除缓存并重新初始化
function M.Update()
    package.loaded["base.protobuf"] = nil
    package.loaded["base.netfind"] = nil
    M.Init()
end

---调用 protobuf 模块的函数
---@param sFunc string 函数名
---@param ... any 函数参数
---@return any result 函数返回值
function M.ProtobufFunc(sFunc, ...)
    return pm[sFunc](...)
end

---调用 netfind 模块的函数
---@param sFunc string 函数名
---@param ... any 函数参数
---@return any result 函数返回值
function M.NetfindFunc(sFunc, ...)
    return nm[sFunc](...)
end

return M
