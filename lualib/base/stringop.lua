---@module stringop
---字符串操作工具模块
---提供字符串分割、索引、公式计算、修剪等常用操作

---分割字符串
---@param s string 要分割的字符串
---@param rep string 分隔符
---@param f function|nil 对每个分割结果应用的转换函数
---@param bReg boolean|nil 是否将分隔符作为正则表达式处理
---@return string[] lst 分割后的字符串列表
function split_string(s, rep, f, bReg)
    assert(rep ~= '')
    local lst = {}
    if #s > 0 then
        local bPlain
        if bReg then
            bPlain = false
        else
            bPlain = true
        end

        local iField, iStart = 1, 1
        local iFirst, iLast = string.find(s, rep, iStart, bPlain)
        while iFirst do
            lst[iField] = string.sub(s, iStart, iFirst - 1)
            iField = iField + 1
            iStart = iLast + 1
            iFirst, iLast = string.find(s, rep, iStart, bPlain)
        end
        lst[iField] = string.sub(s, iStart)

        if f then
            for k, v in ipairs(lst) do
                lst[k] = f(v)
            end
        end
    end
    return lst
end

---获取字符串指定位置的字符
---@param s string 字符串
---@param i integer 位置索引(从1开始)
---@return string|nil char 指定位置的字符，越界则返回nil
function index_string(s, i)
    local iLen = #s
    if i > iLen or i < 1 then
        return
    end
    return string.char(s:byte(i))
end

---@type table<string, function> 公式函数缓存
local fm = {}

---执行公式字符串计算
---@param s string 公式字符串
---@param m table 变量表
---@return any result 计算结果
function formula_string(s, m)
    local f = fm[s]
    if f then
        return f(m)
    else
        f = load(string.format([[
            return function (m)
                for k, v in pairs(m) do
                    _ENV[k] = v
                end

                local __r = (%s)

                for k, v in pairs(m) do
                    _ENV[k] = nil
                end
                
                return __r
            end]], s), s, "bt", {pairs = pairs,math=math})()
        fm[s] = f
        return f(m)
    end
end

---修剪字符串两端的指定字符
---@param s string 要修剪的字符串
---@param p string|nil 要修剪的字符集，默认为空格
---@return string result 修剪后的字符串
function trim(s, p)
    p = p or " "
    local pl = string.format("^[%s]*(.-)[%s]*$", p, p)
    return string.gsub(s, pl, "%1")
end
