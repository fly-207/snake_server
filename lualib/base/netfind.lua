---@module "base.netfind"
--- 网络协议查找模块
--- 提供协议类型和名称的双向查找功能

---@class NetfindModule 网络查找模块
---@field Init fun(f: string) 初始化
---@field FindC2GSByType fun(iType: integer): table? 根据类型查找C2GS协议
---@field FindGS2CByType fun(iType: integer): table? 根据类型查找GS2C协议
---@field FindC2GSByName fun(sName: string): integer? 根据名称查找C2GS协议类型
---@field FindGS2CByName fun(sName: string): integer? 根据名称查找GS2C协议类型
local M = {}

---@type table 协议查找表
local mFind

--- 初始化协议查找模块
---@param f string 协议文件路径
function M.Init(f)
    local f, s = loadfile_ex(f, "bt")
    if not f then
        print("netfind init error", s)
        return
    end
    mFind = f()
end

--- 根据类型查找C2GS协议
---@param iType integer 协议类型
---@return table? 协议信息
function M.FindC2GSByType(iType)
    return mFind.C2GS[iType]
end

--- 根据类型查找GS2C协议
---@param iType integer 协议类型
---@return table? 协议信息
function M.FindGS2CByType(iType)
    return mFind.GS2C[iType]
end

--- 根据名称查找C2GS协议类型
---@param sName string 协议名称
---@return integer? 协议类型
function M.FindC2GSByName(sName)
    return mFind.C2GS_BY_NAME[sName]
end

--- 根据名称查找GS2C协议类型
---@param sName string 协议名称
---@return integer? 协议类型
function M.FindGS2CByName(sName)
    return mFind.GS2C_BY_NAME[sName]
end

return M
