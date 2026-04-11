---@module "public.serverflag"
--- 服务器标记模块
--- 定义服务器特殊标记和功能开关

-- import module

--- 邀请功能开启服务器列表
---@type table<string, integer>
INVITE_LIST = {
    ["pro_gs20001"] = 1,
}

--- 关闭新手引导服务器列表
---@type table<string, integer>
CLOSE_GUIDE = {
    ["pro_gs20001"] = 1,
}

--- 检查是否开启邀请功能
---@return integer? 是否开启
function is_open_invite()
    return INVITE_LIST[get_server_key()]
end

--- 检查是否关闭新手引导
---@return integer? 是否关闭
function is_close_guide()
    return CLOSE_GUIDE[get_server_key()]
end
