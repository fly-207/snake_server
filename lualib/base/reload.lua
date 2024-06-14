-- 定义一个模块管理器Ms
local Ms = {}

-- 导入模块函数，用于加载并缓存模块
-- @param sModule 字符串，表示要导入的模块路径，可以使用斜杠或点分隔
-- @return 返回导入的模块，如果模块已存在则直接返回
function import(sModule)
    -- 将模块路径中的斜杠替换为点，以符合Lua模块命名规范
    local sKey = string.gsub(sModule, "/", ".")
    -- 如果模块已缓存，则直接返回
    if not Ms[sKey] then
        -- 将点分隔的模块路径转换为文件路径
        local sPath = string.gsub(sModule, "%.", "/") .. ".lua"
        -- 创建一个新环境表，并将其元表设置为全局环境，以便模块可以访问全局变量
        local m = setmetatable({}, {__index = _G})
        -- 加载模块文件并执行，如果加载失败，则打印错误信息并返回nil
        local f, s = loadfile_ex(sPath, "bt", m)
        if not f then
            print("import error", s)
            return
        end
        -- 执行模块文件中的代码
        f()
        -- 将执行后得到的环境表缓存为该模块的代表
        Ms[sKey] = m
    end
    return Ms[sKey]
end

-- 重新加载模块函数，用于更新已导入的模块
-- @param sModule 字符串，表示要重新加载的模块路径
function reload(sModule)
    -- 将模块路径中的斜杠替换为点
    local sKey = string.gsub(sModule, "/", ".")
    -- 获取已缓存的模块环境表
    local om = Ms[sKey]
    -- 如果模块未被缓存，则直接返回
    if not om then
        return
    end
    -- 构建模块文件的路径
    local sPath = string.gsub(sModule, "%.", "/") .. ".lua"
    -- 复制当前模块环境表，用于后续的回滚操作
    local cm = table_copy(om)
    -- 加载模块文件并执行，如果加载失败，则打印错误信息并返回
    local f, s = loadfile_ex(sPath, "bt", om)
    if not f then
        print("reload error", s)
        return
    end
    -- 执行模块文件中的代码，以更新模块
    f()

    -- 尝试使用递归方法更新模块中的表
    local bStatus, sErr = pcall(function ()
        local visited = {}
        local recu
        -- 递归更新表的函数
        recu = function (new, old)
            if visited[old] then
                return
            end
            visited[old] = true
            for k, v in pairs(new) do
                local o = old[k]
                if type(v) ~= type(o) then
                    old[k] = v
                else
                    if type(v) == "table" then
                        recu(v, o)
                    else
                        old[k] = v
                    end
                end
            end
            for k, v in pairs(old) do
                if not rawget(new, k) then
                    old[k] = nil
                end
            end
        end

        -- 遍历当前模块环境表，对其中的表进行更新
        for k, v in pairs(om) do
            local o = cm[k]
            if type(o) == type(v) and type(v) == "table" then
                recu(v, o)
                om[k] = o
            end
        end
    end)
    
    -- 如果更新失败，则回滚模块状态
    if not bStatus then
        print("reload failed", sErr)
        local l = {}
        for k, v in pairs(om) do
            if not cm[k] then
                table.insert(l, k)
            else
                om[k] = cm[k]
            end
        end
        for _, k in ipairs(l) do
            om[k] = nil
        end
    end
end