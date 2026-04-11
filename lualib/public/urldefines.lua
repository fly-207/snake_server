---@module "public.urldefines"
--- URL定义模块
--- 定义外部服务的URL路径

--import module

local serverinfo = import(lualib_path("public.serverinfo"))

--- DemiSDK URL配置
---@type table
URLDEMI = {
    prefix = "/demisdk",
    dev_prefix = "/demisdkdev",
    url = {
        login_verify = "/v1/sdkc/integration/verify.json",
        pre_pay = "/v1/sdkc/integration/prePay.json",
    }
}

--- 信鸽推送URL配置
---@type table
XGPUSH = {
    prefix = "/xgpush",
    url = {
        single_account = "/v2/push/single_account",
    }
}

--- 广告API URL配置
---@type table
ADAPI = {
    prefix = "/adapi",
    dev_prefix = "/devadapi",
    url = {
        adapi = "/log",
    }
}

--- 获取外部服务地址
---@return string 外部服务主机地址
function get_out_host()
    return serverinfo.get_out_host()
end

--- 获取DemiSDK URL
---@param key string URL标识
---@return string 完整URL路径
function get_demi_url(key)
    local sPrefix
    if serverinfo.DEMI_SDK.pro_env then
        sPrefix = URLDEMI.prefix
    else
        sPrefix = URLDEMI.dev_prefix
    end
    local sUrl = URLDEMI.url[key]
    return sPrefix..sUrl
end

--- 获取信鸽推送URL
---@param key string URL标识
---@return string 完整URL路径
function get_xg_url(key)
    return XGPUSH.prefix..XGPUSH.url[key]
end

--- 获取广告API URL
---@param key string URL标识
---@return string 完整URL路径
function get_adapi_url(key)
    local sPrefix
    if serverinfo.DEMI_SDK.pro_env then
        sPrefix = ADAPI.prefix
    else
        sPrefix = ADAPI.dev_prefix
    end
    return sPrefix..ADAPI.url[key]
end

