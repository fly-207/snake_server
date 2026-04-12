
---@class LoginGlobal
---@field oGateMgr LoginCGateMgr 网关管理器
---@field oLoginQueueMgr LoginCLoginQueueMgr 登录队列管理器
---@field oInviteCodeMgr LoginCInviteCodeMgr 邀请码管理器
local M = {}

---@type LoginCGateMgr
M.oGateMgr = nil
---@type LoginCLoginQueueMgr
M.oLoginQueueMgr = nil
---@type LoginCInviteCodeMgr
M.oInviteCodeMgr = nil

return M
