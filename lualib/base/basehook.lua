---@module basehook
---钩子函数模块
---提供基础和逻辑钩子函数的设置和执行机制
---用于在特定时机执行自定义回调

local skynet = require "skynet"

---@type function|nil 基础钩子函数
local base_func
---@type function|nil 逻辑钩子函数
local logic_func

---@class basehook 钩子函数模块
local M = {}

---设置基础钩子函数
---@param f function|nil 新的钩子函数
---@return function|nil old 旧的钩子函数
function M.set_base(f)
    local old = base_func
    base_func = f
    return old
end

---设置逻辑钩子函数
---@param f function|nil 新的钩子函数
---@return function|nil old 旧的钩子函数
function M.set_logic(f)
    local old = logic_func
    logic_func = f
    return old
end

---执行所有钩子函数
---先执行逻辑钩子，再执行基础钩子
function M.hook()
    if logic_func then
        safe_call(logic_func)
    end
    if base_func then
        safe_call(base_func)
    end
end

return M
