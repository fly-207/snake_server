---@module tableop
---表操作工具模块
---提供表的生成、复制、转换等常用操作

---从表生成列表
---@param t table 源表
---@param func function|nil 转换函数
---@param bIsMap boolean|nil 是否作为map遍历(pairs)，否则作为数组遍历(ipairs)
---@return any[] r 生成的列表
function list_generate(t, func, bIsMap)
    local r = {}
    if not bIsMap then
        for _, v in ipairs(t) do
            if func then
                v = func(v)
            end
            table.insert(r, v)
        end
    else
        for _, v in pairs(t) do
            if func then
                v = func(v)
            end
            table.insert(r, v)
        end
    end
    return r
end

---清空列表内容
---@param t any[] 要清空的列表
function list_clear(t)
    for i = #t, 1, -1 do
        t[i] = nil
    end
end

---计算表的元素数量(包括非数组部分)
---@param t table 要计算的表
---@return integer count 元素数量
function table_count(t)
    local iLen = 0
    for k, v in pairs(t) do
        iLen = iLen + 1
    end
    return iLen
end

---将表的字符串键转换为数字键
---@param t table<string, any> 源表
---@return table<integer, any> mNew 转换后的表
function table_to_int_key(t)
    local mNew = {}
    for k, v in pairs(t) do
        mNew[tonumber(k)] = v
    end
    return mNew
end

---将表的键转换为数据库键格式
---@param t table 源表
---@return table mNew 转换后的表
function table_to_db_key(t)
    local mNew = {}
    for k, v in pairs(t) do
        mNew[db_key(k)] = v
    end
    return mNew
end

---将列表转换为以元素为键的表
---@param l any[] 源列表
---@param v any|nil 值，默认为索引
---@return table<any, any> t 转换后的表
function list_key_table(l, v)
    local t = {}
    for idx, k in pairs(l) do
        t[k] = v or idx
    end
    return t
end

---获取表的所有键组成的列表
---@param t table 源表
---@return any[] l 键列表
function table_key_list(t)
    local l = {}
    for k, v in pairs(t) do
        table.insert(l, k)
    end
    return l
end

---获取表的所有值组成的列表
---@param t table 源表
---@return any[] l 值列表
function table_value_list(t)
    local l = {}
    for k, v in pairs(t) do
        table.insert(l, v)
    end
    return l
end

---浅拷贝表
---@param t table 源表
---@return table m 拷贝后的新表
function table_copy(t)
    local m = {}
    for k, v in pairs(t) do
        m[k] = v
    end
    return m
end

---深拷贝表
---@param t table 源表
---@return table result 深拷贝后的新表
function table_deep_copy(t)
    local r = {}
    local f
    f = function (ot)
        if r[ot] then
            return r[ot]
        end
        local m = {}
        r[ot] = m
        for k, v in pairs(ot) do
            local ok, ov = k, v
            if type(k) == "table" then
                ok = f(k)
            end
            if type(v) == "table" then
                ov = f(v)
            end
            m[ok] = ov
        end
        return m
    end

    return f(t)
end

---根据权重随机选择一个键
---@param tbl table<any, number> 权重表 {key: weight}
---@return any|nil key 选中的键，表为空则返回nil
function table_choose_key(tbl)
    if table_count(tbl) <= 0 then
        return
    end
    local iSumPa = 0
    for key,value in pairs(tbl) do
        iSumPa = iSumPa + value
    end
    if iSumPa <= 0 then return end

    local iRnd = math.random(iSumPa)
    for key,value in pairs(tbl) do
        if value >= iRnd then
            return key
        end
        iRnd = iRnd - value
    end
end

---切片列表
---@param l any[] 源列表
---@param iStart integer 开始索引
---@param iEnd integer 结束索引
---@return any[] lRes 切片后的新列表
function list_split(l, iStart, iEnd)
    local lRes = {}
    for idx = iStart, iEnd do
        local value = l[idx]
        if value == nil then
            break
        elseif type(value) == "table" then
            value = table_deep_copy(value)
        end
        table.insert(lRes, value)
    end
    return lRes
end

---检查元素是否在列表中
---@param l any[] 列表
---@param r any 要查找的元素
---@return boolean exists 是否存在
function table_in_list(l, r)
    for _, v in ipairs(l) do
        if v == r then
            return true
        end
    end
    return false
end

---根据键列表深度获取表中的值
---@param t table 源表
---@param keylist any[] 键列表
---@return any|nil value 获取的值，不存在则返回nil
function table_get_depth(t, keylist)
    assert(type(t) == "table")
    assert(#keylist > 0)
    local v = t
    for _, k in ipairs(keylist) do
        if type(k) ~= "number" and type(k) ~= "string" then
            return nil
        end
        if type(v) ~= "table" then
            return nil
        end
        v = v[k]
    end
    return v
end

function table_get_set_depth(t, keylist)
    local v = t
    for _, k in ipairs(keylist) do
        if type(k) ~= "number" and type(k) ~= "string" then
            return nil
        end
        if type(v) ~= "table" then
            return nil
        end
        if not v[k] then
            v[k] = {}
        end
        v = v[k]
    end
    return v
end

function table_set_depth(t, keylist, lastkey, value)
    local mTable = table_get_set_depth(t, keylist)
    if not mTable then
        return false
    end
    mTable[lastkey] = value
    return true
end

function table_del_depth_casc(t, keylist, lastkey)
    local lDepthTables = {}
    local v = t
    for idx, k in ipairs(keylist) do
        if type(k) ~= "number" and type(k) ~= "string" then
            return false
        end
        if type(v) ~= "table" then
            return false
        end
        if not v[k] then
            return false
        end
        table.insert(lDepthTables, {k, v}) -- key, mFather
        v = v[k]
    end
    v[lastkey] = nil
    if not next(v) then
        while true do
            local lFatherInfo = table.remove(lDepthTables)
            if not lFatherInfo then
                return true
            end
            local sKey, mFather = table.unpack(lFatherInfo)
            if not next(mFather[sKey]) then
                mFather[sKey] = nil
            else
                return true
            end
        end
    end
    return true
end

function table_combine(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

function list_combine(l1, l2)
    for _,v in ipairs(l2) do
      l1[#l1+1] = v
   end
   return l1
end

function table_all_true(t, f)
    for k, v in pairs(t) do
        if not f(k, v) then
            return false
        end
    end
    return true
end

function ConvertTblToStr(tbl)
    local str = "{"
    local Head = true
    if type(tbl) == "table" then
        for key,value in pairs(tbl) do
            if not Head then
                str = str .. ","
            else
                Head = false
            end
            if type(key) == "number" then
                    str = str .. "["..key .."]="
            else
                    str = str.. "['"..key .."']="
            end
            if  value == nil then
                str = str .."nil,"
            elseif type(value) == "boolean" then
                str = str ..tostring(value)
            elseif type(value) == "number" then
                str = str .. value
            elseif type(value) == "table" then
                str = str ..ConvertTblToStr(value)
            elseif type(value) == "string" then
                str = str .."\""..value.."\""
            else
                str = str .. type(value)
            end
        end
    else
        print("ConvertTblToStr failed,param is not a table,it is a "..type(tbl))
    end
    str = str.."}"
    return str
end

