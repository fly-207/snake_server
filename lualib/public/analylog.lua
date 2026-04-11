---@module "public.analylog"
--- 分析日志模块
--- 提供游戏各类分析日志的记录接口

local skynet = require "skynet"
local res = require "base.res"
local record = require "public.record"
local gdefines = import(lualib_path("public.gamedefines")) 
local analy = import(lualib_path("public.dataanaly"))

--- 记录玩家系统变化日志
---@param oPlayer table 玩家对象
---@param sType string 系统类型
---@param sSubtype? string 子类型
---@param mCost? table 消耗数据
function LogSystemInfo(oPlayer, sType, sSubtype, mCost)
    local mLog = {}
    mLog["type"] = sType
    mLog["change_detail"] = tostring(sSubtype or "")
    mLog["consume_detail"] = mCost or ""
    LogBaseInfo(oPlayer, "PlayerSystemChange", mLog)
end

--- 记录玩家嬋徒列表变化
---@param oPlayer table 玩家对象
---@param oSummon table 嬋徒对象
---@param iOperate integer 操作类型(0更新 1增加 2删除)
function LogPlayerSummonInfo(oPlayer, oSummon, iOperate)
    LogBaseInfo(oPlayer, "PlayerSummon", {
        summon_id = oSummon:TraceRealNo() or 0,
        sid = oSummon:TypeID(),
        operate = iOperate,
        summ_level = oSummon:GetGrade(),
        summ_score = oSummon:GetScore()
    })
end

--- 记录商城购买日志
---@param oPlayer table 玩家对象
---@param iShop integer 商店ID
---@param iMoneyType integer 货币类型
---@param iSid integer 商品ID
---@param iAmount integer 购买数量
---@param iTotal integer 总费用
function LogMallBuy(oPlayer, iShop, iMoneyType, iSid, iAmount, iTotal)
    local mLog = oPlayer:BaseAnalyInfo()
    mLog["yuanbao_before"] = 0
    mLog["consume_yuanbao"] = 0
    mLog["yuanbao_bd_before"] = 0
    mLog["consume_yuanbao_bd"] = 0
    mLog["shop_id"] = iShop
    mLog["shop_sub_id"] = 1
    mLog["currency_type"] = iMoneyType
    mLog["item_id"] = iSid
    mLog["price"] = iPrice
    mLog["num"] = iAmount
    mLog["consume_count"] = iTotal
    mLog["remain_currency"] = 0
    analy.log_data("MallBuy", mLog)
end

--- 记录结婚信息日志
---@param oPlayer table 玩家对象 
---@param iMale integer 男方玩家ID
---@param sMale string 男方名称
---@param iFemale integer 女方玩家ID
---@param sFemale string 女方名称
---@param iMarryType integer 婚姻类型
---@param iOperate integer 操作类型
function LogMarryInfo(oPlayer, iMale, sMale, iFemale, sFemale, iMarryType, iOperate)
    LogBaseInfo(oPlayer, "MarryInfo", {
        male_pid = iMale,
        male_name = sMale,
        female_pid = iFemale,
        female_name = sFemale,
        marry_type = iMarryType,
        operate = iOperate,
    })
end

--- 记录玩法参与日志
---@param oPlayer table 玩家对象
---@param sType string 玩法类型
---@param iWanFa integer 玩法ID
---@param iOperate integer 操作(1参与 2完成)
function LogWanFaInfo(oPlayer, sType, iWanFa, iOperate)
    LogBaseInfo(oPlayer, "WanFaInfo", {
        wf_type = sType,
        wf_id = iWanFa or 0,
        operate = iOperate,
    })
end

--- 记录玩家战斗信息日志
---@param oPlayer table 玩家对象
---@param sType string 战斗类型
---@param iStage integer 关卡ID
---@param iOperate integer 操作(1参与 2胜利 3失败 4逃跑)
function LogWarInfo(oPlayer, sType, iStage, iOperate)
    LogBaseInfo(oPlayer, "WarInfo", {
        stage_type = sType or "",
        stage_id = iStage or 0,
        operate = iOperate,
    })
end

--- 记录禁言信息日志
---@param oPlayer table 玩家对象
---@param sMsg string 被禁言的消息
---@param iRule integer 触发规则ID
function LogBanChat(oPlayer, sMsg, iRule)
    LogBaseInfo(oPlayer, "BanChat", {
        chat_msg = sMsg,
        rule_id = iRule,
    })
end

--- 记录背包变化日志
---@param oPlayer table 玩家对象
---@param iOperate integer 操作类型
---@param iSid integer 物品ID
---@param iAmount integer 变化数量
---@param sReason string 变化原因
function LogBackpackChange(oPlayer, iOperate, iSid, iAmount, sReason)
    local mAnalyLog = oPlayer:BaseAnalyInfo()
    mAnalyLog["operation"] = iOperate
    mAnalyLog["item_id"] = iSid
    mAnalyLog["num"] = iAmount
    mAnalyLog["remain_num"] = oPlayer:GetItemAmount(iSid)
    mAnalyLog["reason"] = sReason
    analy.log_data("BackpackChange", mAnalyLog)
end

--- 记录分析日志统一方法
---@param oPlayer table 玩家对象
---@param sFile string 日志文件名
---@param mLog? table 日志数据
function LogBaseInfo(oPlayer, sFile, mLog)
    mLog = mLog or {}
    analy.log_data(sFile, table_combine(oPlayer:BaseAnalyInfo(), mLog))
end

function FastCostLog(mFastCost)
    local mCostLog = {}
    if mFastCost["goldcoin"] then
        mCostLog[gdefines.MONEY_TYPE.GOLDCOIN] = mFastCost["goldcoin"]
    end
    if mFastCost["silver"] then
        mCostLog[gdefines.MONEY_TYPE.SILVER] = mFastCost["silver"]
    end
    if mFastCost["gold"] then
        mCostLog[gdefines.MONEY_TYPE.GOLD] = mFastCost["gold"]
    end
    for iSid, iAmount in pairs(mFastCost["item"]) do
        mCostLog[iSid] = iAmount
    end
    return mCostLog
end

-- 不递归
function table_format_concat(m)
    if type(m) ~= "table" then return m end

    local s
    for k,v in pairs(m) do
        if not s then
            s = string.format("%s+%s", k, v)
        else
            s = string.format("%s&%s+%s", s, k, v)
        end
    end
    return s or ""
end
