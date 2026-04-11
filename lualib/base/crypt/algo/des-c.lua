
---@module "base.crypt.algo.des-c"
--- DES加密模块(C语言实现)
--- 使用 ldes C扩展库实现的 DES 加密解密功能，性能优于纯Lua实现

local ldes = require "ldes"

---@class DES_C
---@field BLOCK_SIZE integer DES块大小(8字节)
---@field encrypt fun(sKey: string, sInput: string): string 加密函数
---@field decrypt fun(sKey: string, sInput: string): string 解密函数
local DES = {};

--- DES块大小(8字节)
DES.BLOCK_SIZE = 8;

--- DES加密
---@param sKey string 8字节密钥
---@param sInput string 输入数据
---@return string 加密后的数据
DES.encrypt = function(sKey, sInput)
	return ldes.desencode(sKey, sInput)
end

--- DES解密
---@param sKey string 8字节密钥
---@param sInput string 加密数据
---@return string 解密后的数据
DES.decrypt = function(sKey, sInput)
	return ldes.desdecode(sKey, sInput)
end

return DES;
