---@module "public.statistics"
--- 统计模块
--- 提供游戏系统的消耗、产出等数据统计功能

local interactive = require "base.interactive"

---@class StatisticsModule 统计模块
---@field system_cost fun(sType: string, iPid: integer, mCosts: table, mRewards: table, bRecordPlayer?: boolean) 记录系统消耗
---@field system_player_cnt fun(sType: string, iPid: integer) 增加系统玩家计数
---@field system_collect_reward fun(sType: string, mRewards: table, iRecordPid?: integer) 收集系统奖励
---@field system_collect_cnt fun(sType: string, iPid: integer) 增加系统收集计数
---@field record_org_member fun(mData: table, mOrgCnt: table) 记录公会成员
local M = {}

--- 记录系统消耗和产出
---@param sType string 消耗类型
---@param iPid integer 玩家ID
---@param mCosts table 消耗数据
---@param mRewards table 产出数据
---@param bRecordPlayer? boolean 是否记录玩家
function M.system_cost(sType, iPid, mCosts, mRewards, bRecordPlayer)
    interactive.Send(".logstatistics", "system", "PushCostData",  {
        type = sType,
        pid = iPid,
        costs = mCosts,
        rewards = mRewards,
        count = bRecordPlayer
    })
end

--- 增加系统玩家计数
---@param sType string 系统类型
---@param iPid integer 玩家ID
function M.system_player_cnt(sType, iPid)
    interactive.Send(".logstatistics", "system", "AddCostPlayerCnt",  {type = sType, pid = iPid})
end

--- 收集系统奖励数据
---@param sType string 系统类型
---@param mRewards table 奖励数据
---@param iRecordPid? integer 记录的玩家ID
function M.system_collect_reward(sType, mRewards, iRecordPid)
    interactive.Send(".logstatistics", "system", "PushGameSystemReward",  {
        type = sType,
        pid = iRecordPid,
        rewards = mRewards,
    })
end

--- 增加系统收集计数
---@param sType string 系统类型
---@param iPid integer 玩家ID
function M.system_collect_cnt(sType, iPid)
    interactive.Send(".logstatistics", "system", "AddGameSystemCnt",  {
        type = sType,
        pid = iPid
    }) 
end

--- 记录公会成员数据
---@param mData table 成员数据
---@param mOrgCnt table 公会数据
function M.record_org_member(mData, mOrgCnt)
    interactive.Send(".logstatistics", "system", "RecordOrgMember",  {
        member = mData,
        org = mOrgCnt
    })
end

return M

