---@module "base.crypt.pattern.cbc"
--- CBC模式加密模块
--- 实现密码块链接(Cipher Block Chaining)模式，支持任意块加密算法

local array = require("base.crypt.common.array")

local tinsert = table.insert
local tremove = table.remove

---@class CBCModule
---@field Create fun(mAgol: table, mPadding: table, sKey: string, sV?: string): CBCObject 创建CBC加密对象
local M = {}

---@class CBCObject CBC加密对象
---@field m_sKey string 加密密钥
---@field m_sV string 初始化向量(IV)
---@field m_mAgol table 块加密算法模块
---@field m_mPadding table 填充模块
local CObject = {}
CObject.__index = CObject

--- 创建CBC加密对象
---@param mAgol table 块加密算法模块(如DES)
---@param mPadding table 填充模块(如PKCS5)
---@param sKey string 密钥
---@param sV? string 初始化向量，默认为密钥
---@return CBCObject
function CObject:New(mAgol, mPadding, sKey, sV)
    	local o = setmetatable({}, self)
    	o.m_sKey = sKey
    	o.m_sV = sV or sKey
    	o.m_mAgol = mAgol
    	o.m_mPadding = mPadding
    	assert(#o.m_sKey == o.m_mAgol.BLOCK_SIZE and #o.m_sV == o.m_mAgol.BLOCK_SIZE, 
    		"CBC Object New Failed")
    	return o
end

--- CBC模式加密
---@param s string 明文数据
---@return string 加密后的数据
function CObject:Encode(s)
	local lTotal = {}

	local iBlockSize = self.m_mAgol.BLOCK_SIZE
	s = self:Padding(s)
	--local lKey = array.fromString(self.m_sKey)
	local sKey = self.m_sKey
	local lInput = array.fromString(self.m_sV..s)
	local iIndex = iBlockSize
	local iLen = #lInput
	local lRecord = nil

	while (iIndex <= iLen) do
		local lBlock = {}
		for i = iIndex - iBlockSize + 1, iIndex do
			tinsert(lBlock, lInput[i])
		end

		if not lRecord then
			lRecord = lBlock
		else
			local lOut = array.xor(lRecord, lBlock)
			--lOut = self.m_mAgol.encrypt(lKey, lOut)
			lOut = array.fromString(self.m_mAgol.encrypt(sKey, array.toString(lOut)))
			for _, v in ipairs(lOut) do
				tinsert(lTotal, v)
			end
			lRecord = lOut			
		end

		iIndex = iIndex + iBlockSize
	end

	return array.toString(lTotal)
end

--- CBC模式解密
---@param s string 加密数据
---@return string 解密后的明文
function CObject:Decode(s)
	local lTotal = {}

	local iBlockSize = self.m_mAgol.BLOCK_SIZE
	--local lKey = array.fromString(self.m_sKey)
	local sKey = self.m_sKey
	local lInput = array.fromString(self.m_sV..s)
	local iIndex = iBlockSize
	local iLen = #lInput
	local lRecord = nil

	while (iIndex <= iLen) do
		local lBlock = {}
		for i = iIndex - iBlockSize + 1, iIndex do
			tinsert(lBlock, lInput[i])
		end

		if not lRecord then
			lRecord = lBlock
		else
			local lOut = lBlock
			--lOut = self.m_mAgol.decrypt(lKey, lOut)		
			lOut = array.fromString(self.m_mAgol.decrypt(sKey, array.toString(lOut)))
			lOut = array.xor(lRecord, lOut)
			for _, v in ipairs(lOut) do
				tinsert(lTotal, v)
			end
			lRecord = lBlock
		end

		iIndex = iIndex + iBlockSize
	end

	return self:UnPadding(array.toString(lTotal))
end

--- 对数据进行填充
---@param s string 原始数据
---@return string 填充后的数据
function CObject:Padding(s)
	return self.m_mPadding.fill(s, self.m_mAgol.BLOCK_SIZE)
end

--- 去除数据填充
---@param s string 带填充的数据
---@return string 去除填充后的数据
function CObject:UnPadding(s)
	return self.m_mPadding.clear(s, self.m_mAgol.BLOCK_SIZE)
end

--- 创建CBC加密对象的工厂方法
---@param mAgol table 块加密算法模块
---@param mPadding table 填充模块
---@param sKey string 密钥
---@param sV? string 初始化向量
---@return CBCObject
function M.Create(...)
     	return CObject:New(...)
end

return M
