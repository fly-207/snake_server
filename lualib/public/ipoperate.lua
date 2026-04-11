---@module "public.ipoperate"
--- IP操作模块
--- 提供IP地址转换、子网匹配、白名单检查等功能

--import module

--- 将IP地址转换为数字
---@param sIp string IP地址字符串
---@return integer IP地址对应的数字
function ip2number(sIp)
    local a, b, c, d = string.match(sIp, "(%d+)%.(%d+)%.(%d+)%.(%d+)")
    a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
    return math.floor((a << 24) | (b << 16) | (c << 8) | d)
end

--- 转换子网地址
---@param sSubnet string 子网地址(CIDR格式, 如"192.168.1.0/24")
---@return integer, integer 网络地址数字, 子网掩码位数
function trans_subnet(sSubnet)
    local sNet, sMask = string.match(sSubnet, "([%d%.]+)%/(%d+)")
    return ip2number(sNet), tonumber(sMask)
end

--- 检查IP是否在白名单中
---@param sIp string IP地址
---@return boolean 是否在白名单中
function is_white_ip(sIp)
    if not sIp then
        return false
    end
    local mWhiteIp = {
        "112.94.5.240/28",      -- liantong
        "219.135.195.92/32",    -- dianxin
        "58.248.197.15/32",     -- dianxin 动态IP需要替换
    }
    local iIpNumber = ip2number(sIp)
    for _, sSubnet in ipairs(mWhiteIp) do
        local iNetNumber, iIpMask = trans_subnet(sSubnet)
        local bit = 32 - tonumber(iIpMask)
        if ((iIpNumber >> bit) << bit) == ((iNetNumber >> bit) << bit) then
            return true
        end
    end
    return false
end
