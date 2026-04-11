---@module "public.util"
--- 实用工具模块
--- 提供文本处理、字符串格式化等功能

--import module
local res = require "base.res"
local gamedefines = import(lualib_path("public.gamedefines"))

local string = string
local string_gsub = string.gsub

--- 获取选项文本
---@param iText integer 文本ID
---@param tUrl string[] 文本路径
---@return string 文本内容
function GetChooseText(iText, tUrl)
    local mData = res["daobiao"]
    for _,v in ipairs(tUrl) do
        mData = mData[v]
    end
    local sText = mData["choose"][iText]["content"]
    return sText
end

--- 获取文本数据
---@param iText integer 文本ID
---@param tUrl? string[] 文本路径，默认为{"text"}
---@return string|table, table? 文本内容或回调数据, 可选参数
function GetTextData(iText, tUrl)
    -- params  tUrl: {"huodong", "fengyao"}
    -- params  iText: 1001
    local mData = res["daobiao"]
    if not tUrl then
        tUrl = {"text"}
    end
    for _,v in ipairs(tUrl) do
        mData = mData[v]
    end
    local mText = mData["text"][iText]
    assert(mText, string.format("text null, iText:%d, tUrl:%s", iText, table.concat(tUrl)))

    if mText.type == gamedefines.TEXT_TYPE.SECOND_CONFIRM then
        local lChoose = mText["choose"] or {}
        local mCbData = {}
        mCbData["sContent"] = mText["content"]
        if #lChoose > 0 then
            mCbData["sConfirm"] = mData["choose"][lChoose[1]]["content"]
            if #lChoose > 1 then
                mCbData["sCancle"] = mData["choose"][lChoose[2]]["content"]
            end
            local iCountTime = mText.count_time
            if iCountTime and iCountTime > 0 then
                mCbData["time"] = iCountTime
            end
            if mText.default_id == lChoose[2] then
                mCbData["default"] = 0
            end
        end

        return mCbData
    else
        local sText = mText["content"]
        if mText["choose"] then
            for _, s in ipairs(mText["choose"]) do
                sText = string.format("%s%s%s", sText, "&Q", GetChooseText(s, tUrl))
            end
        end
        local mArgs = {}
        local iCountTime = mText.count_time
        if iCountTime and iCountTime > 0 then
            mArgs.time = iCountTime
        end
        local iDefaultChoose = mText.default_id
        if iDefaultChoose and iDefaultChoose > 0 then
            mArgs.default = iDefaultChoose
        end
        return sText, mArgs
    end
end

--- 格式化字符串，替换占位符
---@param sText string 原始文本
---@param mReplace? table<string, string|number|table> 替换映射
---@param bColor? boolean 是否应用颜色
---@return string 格式化后的文本
function FormatString(sText, mReplace, bColor)
    assert(type(sText)=="string", "FormatColorString, sText must be string")

    if not mReplace then return sText end

    local mAllColor
    if bColor then
        mAllColor = res["daobiao"]["othercolor"]
    end

    for sKey, rReplace in pairs(mReplace) do
        local sPatten = "#"..sKey
        local sType = type(rReplace)
        local sColor = "%s"
        if bColor then
            local mColor = mAllColor[sKey]
            sColor = mColor and mColor.color or "%s"
        end

        if sType == "string" or sType == "number" then
            sText = string_gsub(sText, sPatten, {[sPatten]=string.format(sColor, rReplace)})
        elseif sType == "table" then
            local iCnt = 0
            sText = string_gsub(sText, sPatten, function()
                iCnt = iCnt+1
                return string.format(sColor, rReplace[iCnt])
            end)
        end
    end
    return sText
end

--eg1: FormatColorString ("#role使用#amount个#item获得#exp经验", {role = "玩家1", amount=1, item="#R经验道具#n",exp=1000})
--eg2: FormatColorString ("#role 打败了 #role", {role = {"张三", "李四"}})
function FormatColorString(sText, mReplace)
    return FormatString(sText, mReplace, true)
end
