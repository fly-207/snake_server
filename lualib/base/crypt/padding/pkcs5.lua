---@module "base.crypt.padding.pkcs5"
--- PKCS5 填充模块
--- 实现 PKCS#5 (PKCS#7) 填充和清除功能，用于块加密的数据对齐

local tinsert = table.insert
local tconcat = table.concat
local schar = string.char
local sbyte = string.byte
local ssub = string.sub

---@class PKCS5Module
---@field fill fun(s: string, ib: integer): string 对字符串进行PKCS5填充
---@field clear fun(s: string, ib: integer): string 清除PKCS5填充
local M = {}

--- 对字符串进行PKCS5填充，使长度对齐到块大小
---@param s string 原始字符串
---@param ib integer 块大小(字节)
---@return string 填充后的字符串
function M.fill(s, ib)
	local iLen = #s
	local iLeft = ib - iLen%ib
	local l = {s,}
	local sm = schar(iLeft)
	for i = 1, iLeft do
		tinsert(l, sm)
	end
	return tconcat(l)
end

--- 清除PKCS5填充，恢复原始数据
---@param s string 带填充的字符串
---@param ib integer 块大小(字节)
---@return string 去除填充后的字符串
function M.clear(s, ib)
	local iLen = #s
	local iLeft = sbyte(s, iLen)
	assert(iLen>iLeft, "pkcs5 clear failed1")
	for i = 1, iLeft do
		assert(sbyte(s, iLen - i + 1) == iLeft, "pkcs5 clear failed2")
	end
	return ssub(s, 1, iLen - iLeft)
end

return M
