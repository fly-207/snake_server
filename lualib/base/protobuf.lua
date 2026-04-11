---@module "base.protobuf"
--- Protobuf 编解码模块
--- 提供 Protocol Buffers 的编码、解码、打包、解包功能

local c = require "protobuf.c"

local setmetatable = setmetatable
local type = type
local table = table
local assert = assert
local pairs = pairs
local ipairs = ipairs
local string = string
local print = print
local io = io
local tinsert = table.insert
local rawget = rawget

---@class ProtobufModule Protobuf模块
---@field GC userdata GC对象
---@field lasterror fun(): string 获取最后错误
---@field encode fun(message: string, t: table, func?: function, ...): string|any 编码消息
---@field decode fun(typename: string, buffer: string, length?: integer): table|false, string? 解码消息
---@field unpack fun(pattern: string, buffer: string, length: integer): ... 解包消息
---@field pack fun(pattern: string, ...): string 打包消息
---@field check fun(typename: string, field?: string): boolean|integer 检查类型
---@field all_fields fun(typename: string): table 获取所有字段
---@field name_fields fun(typename: string): table 按名称获取字段
---@field id_fields fun(typename: string): table 按ID获取字段
---@field copy_repeated fun(t: table, k: string): table 复制重复字段
---@field copy_message fun(t: table): table 复制消息
---@field register fun(buffer: string) 注册协议
---@field register_file fun(filename: string) 注册协议文件
---@field default fun(typename: string, tbl: table): table 设置默认值
local M = {}

---@type table<string, table> 模式缓存
local _pattern_cache = {}

---@type userdata Protobuf环境
local P,GC

P = debug.getregistry().PROTOBUF_ENV

if P then
    GC = c._gc()
else
    P= c._env_new()
    GC = c._gc(P)
end

M.GC = GC

--- 获取最后的错误信息
---@return string 错误信息
function M.lasterror()
    return c._last_error(P)
end

---@type table<string, table> 解码类型缓存
local decode_type_cache = {}

---@type table 读取元表
local _R_meta = {}

function _R_meta:__index(key)
    local fc = decode_type_cache[self._CType][key]
    if not fc then
        return
    end
    local v = fc(self, key)
    self[key] = v
    return v
end

---@type table 读取器函数表
local _reader = {}

--- 读取浮点数
---@param key string 字段名
---@return number
function _reader:real(key)
    return c._rmessage_real(self._CObj , key , 0)
end

--- 读取字符串
---@param key string 字段名
---@return string
function _reader:string(key)
    return c._rmessage_string(self._CObj , key , 0)
end

--- 读取布尔值
---@param key string 字段名
---@return boolean
function _reader:bool(key)
    return c._rmessage_int(self._CObj , key , 0) ~= 0
end

--- 读取子消息
---@param key string 字段名
---@param message_type string 消息类型
---@return table?
function _reader:message(key, message_type)
    local rmessage = c._rmessage_message(self._CObj , key , 0)
    if rmessage then
        local v = {
            _CObj = rmessage,
            _CType = message_type,
            _Parent = self,
        }
        return setmetatable( v , _R_meta )
    end
end

--- 读取整数
---@param key string 字段名
---@return integer
function _reader:int(key)
    return c._rmessage_int(self._CObj , key , 0)
end

--- 读取重复浮点数数组
---@param key string 字段名
---@return number[]
function _reader:real_repeated(key)
    local cobj = self._CObj
    local n = c._rmessage_size(cobj , key)
    local ret = {}
    for i=0,n-1 do
        tinsert(ret,  c._rmessage_real(cobj , key , i))
    end
    return ret
end

--- 读取重复字符串数组
---@param key string 字段名
---@return string[]
function _reader:string_repeated(key)
    local cobj = self._CObj
    local n = c._rmessage_size(cobj , key)
    local ret = {}
    for i=0,n-1 do
        tinsert(ret,  c._rmessage_string(cobj , key , i))
    end
    return ret
end

--- 读取重复布尔数组
---@param key string 字段名
---@return boolean[]
function _reader:bool_repeated(key)
    local cobj = self._CObj
    local n = c._rmessage_size(cobj , key)
    local ret = {}
    for i=0,n-1 do
        tinsert(ret,  c._rmessage_int(cobj , key , i) ~= 0)
    end
    return ret
end

--- 读取重复消息数组
---@param key string 字段名
---@param message_type string 消息类型
---@return table[]
function _reader:message_repeated(key, message_type)
    local cobj = self._CObj
    local n = c._rmessage_size(cobj , key)
    local ret = {}
    for i=0,n-1 do
        local m = {
            _CObj = c._rmessage_message(cobj , key , i),
            _CType = message_type,
            _Parent = self,
        }
        tinsert(ret, setmetatable( m , _R_meta ))
    end
    return ret
end

--- 读取重复整数数组
---@param key string 字段名
---@return integer[]
function _reader:int_repeated(key)
    local cobj = self._CObj
    local n = c._rmessage_size(cobj , key)
    local ret = {}
    for i=0,n-1 do
        tinsert(ret,  c._rmessage_int(cobj , key , i))
    end
    return ret
end

--[[
#define PBC_INT 1
#define PBC_REAL 2
#define PBC_BOOL 3
#define PBC_ENUM 4
#define PBC_STRING 5
#define PBC_MESSAGE 6
#define PBC_FIXED64 7
#define PBC_FIXED32 8
#define PBC_BYTES 9
#define PBC_INT64 10
#define PBC_UINT 11
#define PBC_UNKNOWN 12
#define PBC_REPEATED 128
]]

_reader[1] = function(msg) return _reader.int end
_reader[2] = function(msg) return _reader.real end
_reader[3] = function(msg) return _reader.bool end
_reader[4] = function(msg) return _reader.string end
_reader[5] = function(msg) return _reader.string end
_reader[6] = function(msg)
    local message = _reader.message
    return    function(self,key)
            return message(self, key, msg)
        end
end
_reader[7] = _reader[1]
_reader[8] = _reader[1]
_reader[9] = _reader[5]
_reader[10] = _reader[7]
_reader[11] = _reader[7]

_reader[128+1] = function(msg) return _reader.int_repeated end
_reader[128+2] = function(msg) return _reader.real_repeated end
_reader[128+3] = function(msg) return _reader.bool_repeated end
_reader[128+4] = function(msg) return _reader.string_repeated end
_reader[128+5] = function(msg) return _reader.string_repeated end
_reader[128+6] = function(msg)
    local message = _reader.message_repeated
    return    function(self,key)
            return message(self, key, msg)
        end
end
_reader[128+7] = _reader[128+1]
_reader[128+8] = _reader[128+1]
_reader[128+9] = _reader[128+5]
_reader[128+10] = _reader[128+7]
_reader[128+11] = _reader[128+7]

local _decode_type_meta = {}

function _decode_type_meta:__index(key)
    local t, msg = c._env_type(P, self._CType, key)
    if not _reader[t] then
        self[key] = false
    else
        self[key] = _reader[t](msg)
    end
    return self[key]
end

setmetatable(decode_type_cache , {
    __index = function(self, key)
        local v = setmetatable({ _CType = key } , _decode_type_meta)
        self[key] = v
        return v
    end
})

local function decode_message( message , buffer, length)
    local rmessage = c._rmessage_new(P, message, buffer, length)
    if rmessage then
        local self = {
            _CObj = rmessage,
            _CType = message,
        }
        c._add_rmessage(GC,rmessage)
        return setmetatable( self , _R_meta )
    end
end

----------- encode ----------------

---@type table<string, table> 编码类型缓存
local encode_type_cache = {}

--- 编码消息内部函数
---@param CObj userdata C对象
---@param message_type string 消息类型
---@param t table 数据表
local function encode_message(CObj, message_type, t)
    local type = encode_type_cache[message_type]
    for k,v in pairs(t) do
        local func = type[k]
        func(CObj, k , v)
    end
end

---@type table 写入器函数表
local _writer = {
    real = c._wmessage_real,
    enum = c._wmessage_string,
    string = c._wmessage_string,
    int = c._wmessage_int,
}

--- 写入布尔值
---@param k string 字段名
---@param v boolean 值
function _writer:bool(k,v)
    c._wmessage_int(self, k, v and 1 or 0)
end

--- 写入子消息
---@param k string 字段名
---@param v table 消息表
---@param message_type string 消息类型
function _writer:message(k, v , message_type)
    local submessage = c._wmessage_message(self, k)
    encode_message(submessage, message_type, v)
end

--- 写入重复浮点数数组
---@param k string 字段名
---@param v number[] 值数组
function _writer:real_repeated(k,v)
    for _,v in ipairs(v) do
        c._wmessage_real(self,k,v)
    end
end

--- 写入重复布尔数组
---@param k string 字段名
---@param v boolean[] 值数组
function _writer:bool_repeated(k,v)
    for _,v in ipairs(v) do
        c._wmessage_int(self, k, v and 1 or 0)
    end
end

--- 写入重复字符串数组
---@param k string 字段名
---@param v string[] 值数组
function _writer:string_repeated(k,v)
    for _,v in ipairs(v) do
        c._wmessage_string(self,k,v)
    end
end

--- 写入重复消息数组
---@param k string 字段名
---@param v table[] 消息表数组
---@param message_type string 消息类型
function _writer:message_repeated(k,v, message_type)
    for _,v in ipairs(v) do
        local submessage = c._wmessage_message(self, k)
        encode_message(submessage, message_type, v)
    end
end

--- 写入重复整数数组
---@param k string 字段名
---@param v integer[] 值数组
function _writer:int_repeated(k,v)
    for _,v in ipairs(v) do
        c._wmessage_int(self,k,v)
    end
end

_writer[1] = function(msg) return _writer.int end
_writer[2] = function(msg) return _writer.real end
_writer[3] = function(msg) return _writer.bool end
_writer[4] = function(msg) return _writer.string end
_writer[5] = function(msg) return _writer.string end
_writer[6] = function(msg)
    local message = _writer.message
    return    function(self,key , v)
            return message(self, key, v, msg)
        end
end
_writer[7] = _writer[1]
_writer[8] = _writer[1]
_writer[9] = _writer[5]
_writer[10] = _writer[7]
_writer[11] = _writer[7]

_writer[128+1] = function(msg) return _writer.int_repeated end
_writer[128+2] = function(msg) return _writer.real_repeated end
_writer[128+3] = function(msg) return _writer.bool_repeated end
_writer[128+4] = function(msg) return _writer.string_repeated end
_writer[128+5] = function(msg) return _writer.string_repeated end
_writer[128+6] = function(msg)
    local message = _writer.message_repeated
    return    function(self,key, v)
            return message(self, key, v, msg)
        end
end

_writer[128+7] = _writer[128+1]
_writer[128+8] = _writer[128+1]
_writer[128+9] = _writer[128+5]
_writer[128+10] = _writer[128+7]
_writer[128+11] = _writer[128+7]

---@type table 编码类型元表
local _encode_type_meta = {}

function _encode_type_meta:__index(key)
    local t, msg = c._env_type(P, self._CType, key)
    local func = assert(_writer[t],key)(msg)
    self[key] = func
    return func
end

setmetatable(encode_type_cache , {
    __index = function(self, key)
        local v = setmetatable({ _CType = key } , _encode_type_meta)
        self[key] = v
        return v
    end
})

function M.encode( message, t , func , ...)
    local encoder = c._wmessage_new(P, message)
    assert(encoder ,  message)
    encode_message(encoder, message, t)
    if func then
        local buffer, len = c._wmessage_buffer(encoder)
        local ret = func(buffer, len, ...)
        c._wmessage_delete(encoder)
        return ret
    else
        local s = c._wmessage_buffer_string(encoder)
        c._wmessage_delete(encoder)
        return s
    end
end

--------- unpack ----------

---@type table<integer, table> 模式类型映射
local _pattern_type = {
    [1] = {"%d","i"},
    [2] = {"%F","r"},
    [3] = {"%d","b"},
    [5] = {"%s","s"},
    [6] = {"%s","m"},
    [7] = {"%D","d"},
    [128+1] = {"%a","I"},
    [128+2] = {"%a","R"},
    [128+3] = {"%a","B"},
    [128+5] = {"%a","S"},
    [128+6] = {"%a","M"},
    [128+7] = {"%a","D"},
}

_pattern_type[4] = _pattern_type[1]
_pattern_type[8] = _pattern_type[1]
_pattern_type[9] = _pattern_type[5]
_pattern_type[10] = _pattern_type[7]
_pattern_type[11] = _pattern_type[7]
_pattern_type[128+4] = _pattern_type[128+1]
_pattern_type[128+8] = _pattern_type[128+1]
_pattern_type[128+9] = _pattern_type[128+5]
_pattern_type[128+10] = _pattern_type[128+7]
_pattern_type[128+11] = _pattern_type[128+7]


--- 创建模式
---@param pattern string 模式字符串
---@return table? 模式对象
local function _pattern_create(pattern)
    local iter = string.gmatch(pattern,"[^ ]+")
    local message = iter()
    local cpat = {}
    local lua = {}
    for v in iter do
        local tidx = c._env_type(P, message, v)
        local t = _pattern_type[tidx]
        assert(t,tidx)
        tinsert(cpat,v .. " " .. t[1])
        tinsert(lua,t[2])
    end
    local cobj = c._pattern_new(P, message , "@" .. table.concat(cpat," "))
    if cobj == nil then
        return
    end
    c._add_pattern(GC, cobj)
    local pat = {
        CObj = cobj,
        format = table.concat(lua),
        size = 0
    }
    pat.size = c._pattern_size(pat.format)

    return pat
end

setmetatable(_pattern_cache, {
    __index = function(t, key)
        local v = _pattern_create(key)
        t[key] = v
        return v
    end
})

--- 解包消息
---@param pattern string 模式字符串
---@param buffer string 二进制数据
---@param length integer 数据长度
---@return ... 解包结果
function M.unpack(pattern, buffer, length)
    local pat = _pattern_cache[pattern]
    return c._pattern_unpack(pat.CObj , pat.format, pat.size, buffer, length)
end

--- 打包消息
---@param pattern string 模式字符串
---@param ... any 打包参数
---@return string 打包结果
function M.pack(pattern, ...)
    local pat = _pattern_cache[pattern]
    return c._pattern_pack(pat.CObj, pat.format, pat.size , ...)
end

--- 检查类型或字段是否存在
---@param typename string 类型名
---@param field? string 字段名
---@return boolean|integer 检查结果
function M.check(typename , field)
    if field == nil then
        return c._env_type(P,typename)
    else
        return c._env_type(P,typename,field) ~=0
    end
end

--------------

---@type table<string, table> 默认值缓存
local default_cache = {}

-- todo : clear default_cache, v._CObj

--- 获取默认值表
---@param typename string 类型名
---@return table 默认值元表
local function default_table(typename)
    local v = default_cache[typename]
    if v then
        return v
    end

    v = { __index = assert(decode_message(typename , "")) }

    default_cache[typename]  = v
    return v
end

---@type table 解码消息元表
local decode_message_mt = {}

--- 解码消息回调
---@param typename string 类型名
---@param buffer string 二进制数据
---@return table 解码结果
local function decode_message_cb(typename, buffer)
    --return setmetatable ( { typename, buffer } , decode_message_mt)
    local ret = {}
    assert(c._decode(P, decode_message_cb , ret , typename, buffer), typename)
    return setmetatable(ret , default_table(typename))
end

--- 解码消息
---@param typename string 类型名
---@param buffer string 二进制数据
---@param length? integer 数据长度
---@return table|false 解码结果或false
---@return string? 错误信息
function M.decode(typename, buffer, length)
    local ret = {}
    local ok = c._decode(P, decode_message_cb , ret , typename, buffer, length)
    if ok then
        return setmetatable(ret , default_table(typename))
    else
        return false , c._last_error(P)
    end
end

--- 获取所有字段
---@param typename string 类型名
---@return table 字段列表
function M.all_fields(typename)
    return c._field_all(P, typename)
end

--- 按名称获取字段
---@param typename string 类型名
---@return table 字段映射
function M.name_fields(typename)
    return c._fields_by_name(P, typename)
end

--- 按ID获取字段
---@param typename string 类型名
---@return table 字段映射
function M.id_fields(typename)
    return c._fields_by_id(P, typename)
end

--- 复制重复字段
---@param t table 源表
---@param k string 字段名
---@return table 复制的列表
function M.copy_repeated(t, k)
    local tn = t._CType
    assert(tn, "copy_message err")
    local it = c._env_type(P, tn, k)
    assert(it>=128, "copy_message err")
    local l = {}
    if it == 128 + 6 then
        for _, v2 in ipairs(t[k]) do
            tinsert(l, M.copy_message(v2))
        end
    else
        for _, v2 in ipairs(t[k]) do
            tinsert(l, v2)
        end
    end
    return l
end

--- 复制消息
---@param t table 源消息表
---@return table 复制的消息
function M.copy_message(t)
    local tn = t._CType
    assert(tn, "copy_message err")
    local afl = M.all_fields(tn)
    local m = {}
    for _, v in ipairs(afl) do
        local k = v[2]
        local it = v[3]
        if it >= 128 then
            local l = {}
            if it == 128 + 6 then
                for _, v2 in ipairs(t[k]) do
                    tinsert(l, M.copy_message(v2))
                end
            else
                for _, v2 in ipairs(t[k]) do
                    tinsert(l, v2)
                end
            end
            m[k] = l
        else
            if it == 6 then
                m[k] = M.copy_message(t[k])
            else
                m[k] = t[k]
            end
        end
    end
    return m
end

--- 展开延迟解码的表
---@param tbl table 要展开的表
local function expand(tbl)
    local typename = rawget(tbl , 1)
    local buffer = rawget(tbl , 2)
    tbl[1] , tbl[2] = nil , nil
    assert(c._decode(P, decode_message_cb , tbl , typename, buffer), typename)
    setmetatable(tbl , default_table(typename))
end

function decode_message_mt.__index(tbl, key)
    expand(tbl)
    return tbl[key]
end

function decode_message_mt.__pairs(tbl)
    expand(tbl)
    return pairs(tbl)
end

--- 设置默认值
---@param typename string 类型名
---@param tbl table 要设置的表
---@return table 设置后的表
local function set_default(typename, tbl)
    for k,v in pairs(tbl) do
        if type(v) == "table" then
            local t, msg = c._env_type(P, typename, k)
            if t == 6 then
                set_default(msg, v)
            elseif t == 128+6 then
                for _,v in ipairs(v) do
                    set_default(msg, v)
                end
            end
        end
    end
    return setmetatable(tbl , default_table(typename))
end

--- 注册协议
---@param buffer string 协议二进制数据
function M.register(buffer)
    c._env_register(P, buffer)
end

--- 注册协议文件
---@param filename string 文件名
function M.register_file(filename)
    local f = assert(io.open(filename , "rb"))
    local buffer = f:read "*a"
    c._env_register(P, buffer)
    f:close()
end

M.default=set_default

return M
