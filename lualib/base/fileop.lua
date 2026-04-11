---@module fileop
---文件操作工具模块
---提供文件的读写、重命名、检查等常用操作

local skynet = require "skynet"
local lfs = require "lfs"

---检查文件是否存在
---@param sFile string 文件路径
---@return boolean exists 文件是否存在
function exist_file(sFile)
    local f = io.open(sFile)
    if not f then
        return false
    end
    f:close()
    return true
end

---追加写入文件内容
---@param sFile string 文件路径
---@param content string 要写入的内容
---@return boolean success 是否写入成功
function write_file(sFile,content)
    local f = io.open(sFile,"a")
    if not f then
        return false
    end
    f:write(content.."\n")
    f:close()
    return true
end

---重命名文件
---@param sOldFile string 原文件路径
---@param sNewFile string 新文件路径
---@return boolean success 是否成功
---@return string|nil error 错误信息
function rename_file(sOldFile,sNewFile)
    if not exist_file(sOldFile) then
        return false
    end
    local statu,err = os.rename(sOldFile,sNewFile)
    if not statu then
        return false,err
    end
    return true
end

---获取文件最后修改时间
---@param sFile string 文件路径
---@return integer|nil time 修改时间戳，文件不存在则返回nil
function file_last_changetime(sFile)
    if not exist_file(sFile) then
        return
    end
    local time = lfs.attributes(sFile,"change")
    return time
end

---创建文件夹
---@param sFold string 文件夹路径
---@return boolean success 是否成功
function create_folder(sFold)
    if exist_file(sFold) then
        return true
    end
    local bSuc,err = lfs.mkdir(sFold)
    if not bSuc then
        skynet.error("mkdir err "..sFold.." Msg: "..err)
    end
    return bSuc
end

---获取指定路径下的所有文件夹
---@param sPath string 路径
---@return string[] list 文件夹名列表
function get_all_folders(sPath)
    local list = {}
    for file in lfs.dir(sPath) do
        local f = sPath .. '/' .. file
        local attr = lfs.attributes(f)
        if attr.mode == "directory" then
            table.insert(list,file)
        end
    end
    return list
end

---获取指定路径下的所有文件
---@param sPath string 路径
---@return string[] list 文件名列表
function get_all_files(sPath)
    local list = {}
    for file in lfs.dir(sPath) do
        if file == "." or file == ".." then
            goto continue
        end
        local f = sPath .. '/' .. file
        local attr = lfs.attributes(f)
        if attr.mode == "file" then
            table.insert(list,file)
        end
        ::continue::
    end
    return list
end

---通过文件句柄写入内容
---@param f file* 文件句柄
---@param content string 要写入的内容
---@return boolean success 是否写入成功
function write_file_byfd(f,content)
    if not f then
        return false
    end
    f:write(content.."\n")
    f:flush()
    return true
end