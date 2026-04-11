---@module geometry
---几何运算工具模块
---提供浮点数与整数坐标的转换功能
---用于处理游戏中的坐标精度问题

---@class geometry 几何工具模块
local M = {}

---将浮点数转换为整数(乘以1000)
---@param f number 浮点数
---@return integer i 转换后的整数
function M.Cover(f)
    return math.floor(f*1000)
end

---将整数恢复为浮点数(除以1000)
---@param i integer 整数
---@return number f 恢复后的浮点数
function M.Recover(i)
    return i/1000
end

return M
