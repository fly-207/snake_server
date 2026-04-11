---@module "public.resfile"
--- 资源文件模块
--- 加载导表数据、地图数据等资源文件

local eio = require("base.extend").Io
local lfs = require "lfs"

---@class ResFileModule 资源文件模块
---@field daobiao table 导表数据
---@field map table 地图数据
---@field magictime table 技能时间数据
---@field attackedtime table 受击时间数据
local M = {}

local sDaobiaoPath = "daobiao/gamedata/server/data.lua"
local sMapRoot = "cs_common/data/map/"
local sMagicPath = "cs_common/data/magictimedata.lua"
local sAttackedPath = "cs_common/data/attackedtime.lua"

--- 处理NPC区域文件
---@param sPath string 文件路径
---@return number[][] 坐标列表
local function HandleNpcAreaPath(sPath)
    local lRet = {}

    local iCnt = 0
    for s in io.lines(sPath) do
        iCnt = iCnt + 1
    end

    local y = 0.16 + (iCnt - 1)*0.32
    for s in io.lines(sPath) do
        local x = 0.16
        for j = 1, #s do
            if string.sub(s, j, j) == "1" then
                table.insert(lRet, {x, y, 0})
            end
            x = x + 0.32
        end
        y = y - 0.32
    end
    return lRet
end

--- 处理擂台地图文件
---@param sPath string 文件路径
---@return table 擂台数据
local function HandleLeiTaiPath(sPath)
    local mRet = {}
    local i = 0
    for s in io.lines(sPath) do
        i = i + 1
        local lX = {}
        for j = 1, #s do
            if string.sub(s, j, j) == "1" then
                lX[j] = 1
            end
        end
        if next(lX) then
            mRet[i] = lX
        end
    end
    local mData = {}
    mData["leitaidata"] = mRet
    mData["len"] = i
    
    return mData
end

--- 处理编舞地图文件
---@param sPath string 文件路径
---@return table 编舞数据
local function HandleDancePath(sPath)
    local mRet = {}
    local i = 0
    for s in io.lines(sPath) do
        i = i + 1
        local lX = {}
        for j = 1, #s do
            if string.sub(s, j, j) == "1" then
                lX[j] = 1
            end
        end
        if next(lX) then
            mRet[i] = lX
        end
    end
    local mData = {}
    mData["dancedata"] = mRet
    mData["len"] = i
    return mData
end

--- 处理编舞区域文件
---@param sPath string 文件路径
---@return number[][] 坐标列表
local function HandleDanceAreaPath(sPath)
    local lRet = {}

    local iCnt = 0
    for s in io.lines(sPath) do
        iCnt = iCnt + 1
    end

    local y = 0.16 + (iCnt - 1)*0.32
    for s in io.lines(sPath) do
        local x = 0.16
        for j = 1, #s do
            if string.sub(s, j, j) == "1" then
                table.insert(lRet, {x, y, 0})
            end
            x = x + 0.32
        end
        y = y - 0.32
    end
    return lRet
end

--- 加载Lua文件
---@param sPath string 文件路径
---@return any 加载结果
local function Require(sPath)
    local f = loadfile_ex(sPath, "bt")
    return f()
end

--- 加载地图目录中的所有地图数据
---@param sRoot string 地图目录路径
---@return table 地图数据集合
local function RequireMap(sRoot)
    local mNpcArea = {}
    local mNewNpcArea = {}
    local mLeiTai = {}
    local mDance = {}
    local mDancePos = {}
    for n in lfs.dir(sRoot) do
        local sPath = sRoot..n
        if lfs.attributes(sPath, "mode") == "file" then
            if string.sub(n, 1, 12) == "npc_area_new" then
                local id = tonumber(string.match(n, "%d+"))
                assert(id, string.format("read %s err", sPath))
                local l = HandleNpcAreaPath(sPath)
                mNewNpcArea[id] = l
            elseif string.sub(n, 1, 8) == "npc_area" then
                local id = tonumber(string.match(n, "%d+"))
                assert(id, string.format("read %s err", sPath))
                local l = HandleNpcAreaPath(sPath)
                mNpcArea[id] = l
            elseif string.sub(n, 1, 6) == "leitai" then
                local id = tonumber(string.match(n, "%d+"))
                assert(id, string.format("read %s err", sPath))
                local m = HandleLeiTaiPath(sPath)
                mLeiTai[id] = m
            elseif string.sub(n,1,5) == "dance" then
                local id = tonumber(string.match(n, "%d+"))
                assert(id, string.format("read %s err", sPath))
                local m = HandleDancePath(sPath)
                mDance[id] = m
                mDancePos[id]  = HandleDanceAreaPath(sPath)
            end
        end
    end
    local ret = {}
    ret.npc_area = mNpcArea
    ret.new_npc_area = mNewNpcArea
    ret.leitai = mLeiTai
    ret.dance = mDance
    ret.dancepos = mDancePos
    return ret
end

M.daobiao = Require(sDaobiaoPath)
M.map = RequireMap(sMapRoot)
M.magictime = Require(sMagicPath)
M.attackedtime = Require(sAttackedPath)

return M

