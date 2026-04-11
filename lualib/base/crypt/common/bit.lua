---@module "base.crypt.common.bit"
--- 位操作模块包装器
--- 封装 bit32 模块并兼容不同 Lua 版本的位操作函数

---@class BitModule
---@field band fun(a: integer, b: integer, ...): integer 按位与操作
---@field bor fun(a: integer, b: integer, ...): integer 按位或操作
---@field bxor fun(a: integer, b: integer, ...): integer 按位异或操作
---@field bnot fun(x: integer): integer 按位取反操作
---@field lshift fun(x: integer, disp: integer): integer 左移操作
---@field rshift fun(x: integer, disp: integer): integer 右移操作
---@field lrotate fun(x: integer, disp: integer): integer 循环左移操作
---@field rrotate fun(x: integer, disp: integer): integer 循环右移操作

local ok, m = pcall(require, "bit32")
assert(ok, "not bit support found")
-- compatible
if m.rol and not m.lrotate then
	m.lrotate = m.rol
end
if m.ror and not m.rrotate then
	m.rrotate = m.ror
end

---@type BitModule
return m
