---@module "public.derivedfile"
--- 派生文件管理模块
--- 管理服务中的派生文件树结构

--import module

--- 派生文件树配置
--- key: 服务名称, value: 子目录列表
---@type table<string, string[]>
DERIVED_TREE = {
    war = {"ai", "buff", "perform"},
    rank = {"common"},
    world = {"fuben", "item", "npc", "task", "skill", "org"}
}

--- 创建派生文件管理器
---@return CDerivedFileMgr
function NewDerivedFileMgr(...)
    return CDerivedFileMgr:New(...)
end

---@class CDerivedFileMgr 派生文件管理器
---@field m_mFileTrees table 文件树结构
CDerivedFileMgr = {}
CDerivedFileMgr.__index = CDerivedFileMgr

--- 创建派生文件管理器实例
---@return CDerivedFileMgr
function CDerivedFileMgr:New()
    local o = setmetatable({}, self)
    o.m_mFileTrees = {}
    o:Init()
    return o
end

--- 初始化
function CDerivedFileMgr:Init()
    self:ScanDirs()
end

--- 释放资源
function CDerivedFileMgr:Release()
    release(self)
end

--- 重新加载
function CDerivedFileMgr:Reload()
    self:ScanDirs()
end

--- 扫描目录
function CDerivedFileMgr:ScanDirs()
    if not DERIVED_TREE[MY_SERVICE_NAME] then
        return
    end
    for _, sDirs in pairs(DERIVED_TREE[MY_SERVICE_NAME]) do
        self:ScanFiles(sDirs)
    end
end

--- 扫描文件
---@param ... string 目录路径组件
function CDerivedFileMgr:ScanFiles(...)
    local lfs = require "lfs"

    local lRoot = table.pack(...)
    local sRoot = service_file_path(table.concat(lRoot, "/"))
    for n in lfs.dir(sRoot) do
        if n == "." or n == ".." then
            goto continue
        end
        local sPath = sRoot.."/"..n
        local sFileMode = lfs.attributes(sPath, "mode")
        if sFileMode == "directory" then
            self:ScanFiles(..., n)
        elseif sFileMode == "file" then
            if string.sub(n, -4, -1) == ".lua" then
                local sName = string.sub(n, 1, -5)
                local mTree = self.m_mFileTrees
                for _, sNode in ipairs(lRoot) do
                    if not mTree[sNode] then
                        mTree[sNode] = {}
                    end
                    mTree = mTree[sNode]
                end
                mTree[sName] = true
            end
        end
        ::continue::
    end
end

--- 检查文件是否存在
---@param ... string 文件路径组件
---@return boolean 文件是否存在
function CDerivedFileMgr:ExistFile(...)
    local mTree = self.m_mFileTrees
    for _, sNode in ipairs(table.pack(...)) do
        if not mTree[sNode] then
            return false
        end
        mTree = mTree[sNode]
    end
    return true
end
