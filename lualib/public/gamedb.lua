---@module "public.gamedb"
--- 游戏数据库操作模块
--- 提供游戏数据库的读写接口，支持本地和远程数据库操作

-- import file
local interactive = require "base.interactive"
require "public.serverdefines"
local router = require "base.router"

---@type boolean 是否已初始化服务名称
local bInitName = bInitName or false
---@type integer 轮转ID
local iTurnID = iTurnID or 0
---@type string[] 服务名称列表
local mServiceName = mServiceName or {}
---@type table<string, string> 分块到服务的映射
local mBlock2Service = mBlock2Service or {}

--- 检查并初始化服务名称
function CheckInitServiceName()
    if bInitName then return end
    bInitName = true
    mBlock2Service = {}
    mServiceName = {}
    for iNo=1,GAMEDB_SERVICE_COUNT do
        table.insert(mServiceName,".gamedb"..iNo)
    end
end

--- 计算分块的哈希值
---@param sBlock string 分块标识
---@return integer 哈希值
function HashBlock(sBlock)
    if not sBlock or #sBlock <= 0 then
        return 100
    end
    local iTotal = 0
    for i = 1, #sBlock do
        iTotal = sBlock:byte(i) + iTotal
    end
    return iTotal
end

--- 获取分块对应的服务名称
---@param sBlock string 分块标识
---@return string 服务名称
function GetServiceName(sBlock)
    local iBlock = tonumber(sBlock)
    if iBlock then
        return mServiceName[iBlock % GAMEDB_SERVICE_COUNT + 1]
    end
    if mBlock2Service[sBlock] then
        return mBlock2Service[sBlock]
    end
    mBlock2Service[sBlock] = mServiceName[HashBlock(sBlock) % GAMEDB_SERVICE_COUNT + 1]
    return mBlock2Service[sBlock]
end

--- 保存数据到数据库
---@param sBlock string 分块标识
---@param sModule string 模块名
---@param sCmd string 命令名
---@param mData table 数据
function SaveDb(sBlock,sModule,sCmd,mData)
    if is_ks_server() then
        print("liuzla-debug-ks-SaveDb-")
        print(debug.traceback())
        return
    end
    CheckInitServiceName()
    interactive.Send(GetServiceName(sBlock),sModule,sCmd,mData)
end

--- 从数据库加载数据
---@param sBlock string 分块标识
---@param sModule string 模块名
---@param sCmd string 命令名
---@param mData table 查询条件
---@param func function 回调函数
function LoadDb(sBlock,sModule,sCmd,mData,func)
    if is_ks_server() then
        print("liuzla-debug-ks-LoadDb-")
        print(debug.traceback())
        return
    end
    CheckInitServiceName()
    interactive.Request(GetServiceName(sBlock),sModule,sCmd, mData,func)
end

--- 保存游戏数据到数据库(自动判断本地/远程)
---@param sServerKey string 服务器标识
---@param sBlock string 分块标识
---@param sModule string 模块名
---@param sCmd string 命令名
---@param mData table 数据
function SaveGameDb(sServerKey, sBlock, sModule, sCmd, mData)
    if is_ks_server() then
        SaveRemoteDb(sServerKey, sBlock, sModule, sCmd, mData)
    else
        SaveDb(sBlock, sModule, sCmd, mData)
    end
end

--- 从游戏数据库加载数据(自动判断本地/远程)
---@param sServerKey string 服务器标识
---@param sBlock string 分块标识
---@param sModule string 模块名
---@param sCmd string 命令名
---@param mData table 查询条件
---@param func function 回调函数
function LoadGameDb(sServerKey, sBlock, sModule, sCmd, mData, func)
    if is_ks_server() then
        LoadRemoteDb(sServerKey, sBlock, sModule, sCmd, mData, func)
    else
        LoadDb(sBlock, sModule, sCmd, mData, func)
    end
end

--- 从远程数据库加载数据
---@param sServerKey string 服务器标识
---@param sBlock string 分块标识
---@param sModule string 模块名
---@param sCmd string 命令名
---@param mData table 查询条件
---@param func function 回调函数
function LoadRemoteDb(sServerKey, sBlock, sModule, sCmd, mData, func)
    if not is_ks_server() or not sServerKey then
        print("liuzla-debug-LoadRemoteDb-", sServerKey, sBlock, sModule, sCmd)
        print(debug.traceback())
        return
    end
    CheckInitServiceName()
    router.Request(sServerKey, GetServiceName(sBlock), sModule, sCmd, mData, func)    
end

--- 保存数据到远程数据库
---@param sServerKey string 服务器标识
---@param sBlock string 分块标识
---@param sModule string 模块名
---@param sCmd string 命令名
---@param mData table 数据
function SaveRemoteDb(sServerKey, sBlock, sModule, sCmd, mData)
    if not is_ks_server() or not sServerKey then
        print("liuzla-debug-SaveRemoteDb-", sServerKey, sBlock, sModule, sCmd)
        print(debug.traceback())
        return
    end
    CheckInitServiceName()
    router.Send(sServerKey, GetServiceName(sBlock), sModule, sCmd, mData)
end

--- 保存数据到文件
---@param sKey string 数据标识
---@param mData table 数据
function SaveDb2File(sKey, mData)
    interactive.Send(".logfile", "common", "WriteDb2File",  {
        key = sKey, 
        data = mData,
    })
end

--- 将数据写入文件
---@param sName string 文件名
---@param sData string 数据内容
function write_db2file(sName, sData)
    local sPath = DB_FILE_PATH
    if create_folder(sPath) then
        local sDate = get_time_format_str(get_time(), "%Y-%m-%d-%H%M")
        local sFile = string.format("%s/%s_%s",sPath,sName,sDate)
        local fd = io.open(sFile,"a")
        write_file_byfd(fd,sData)
        fd:close()
    end
end

