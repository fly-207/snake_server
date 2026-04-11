---@module "public.serverdefines"
--- 服务器定义模块
--- 定义服务器端口、服务数量等配置

-- 端口配置
-- 公共
---@type string 路由服务器端口列表
ROUTER_S_PORTS = "10010,10011,10012,10013"

-- CS服务器端口
---@type integer CS GM控制台端口
CS_GM_CONSOLE_PORT = 10001
---@type integer CS独裁者端口
CS_DICTATOR_PORT = 10002
---@type integer CS Web服务端口
CS_WEB_PORT = 10003
---@type string CS二维码服务端口列表
CS_QRCODE_PORTS = "10004,10005,10006,10007,10008,10009"

-- GS服务器端口
---@type integer GS GM控制台端口
GS_GM_CONSOLE_PORT = 7001
---@type integer GS独裁者端口
GS_DICTATOR_PORT = 7002
---@type integer GS Web服务端口
GS_WEB_PORT = 7003
---@type string GS网关端口列表
GS_GATEWAY_PORTS = "7011,7012,27011,27012,27013"

-- BS服务器端口
---@type integer BS GM控制台端口
BS_GM_CONSOLE_PORT = 20001
---@type integer BS独裁者端口
BS_DICTATOR_PORT = 20002
---@type integer BS Web服务端口
BS_WEB_PORT = 20003

-- KS服务器端口
---@type integer KS GM控制台端口
KS_GM_CONSOLE_PORT = 20011
---@type integer KS独裁者端口
KS_DICTATOR_PORT = 20012
---@type integer KS Web服务端口
KS_WEB_PORT = 20013

if get_server_cluster() == "dev" or get_server_cluster() == "h7demu" then
    KS_GATEWAY_PORTS = "27014,27015,27016"
else
    KS_GATEWAY_PORTS = "7011,7012,27011,27012,27013"
end

-- 服务数量配置
---@type integer 场景服务数量
SCENE_SERVICE_COUNT = 15
---@type integer 战斗服务数量
WAR_SERVICE_COUNT = 15
---@type integer Web服务数量
WEB_SERVICE_COUNT = 10
---@type integer 支付服务数量
PAY_SERVICE_COUNT = 4
---@type integer 验证服务数量
VERIFY_SERVICE_COUNT = 4
---@type integer 玩家发送服务数量
PLAYER_SEND_COUNT = 10
---@type integer 路由服务数量
ROUTERS_SERVICE_COUNT = 4
---@type integer 游戏数据库服务数量
GAMEDB_SERVICE_COUNT = 4

---@type string MongoDB用户名
MONGO_USER = "root"
---@type string MongoDB密码
MONGO_PWD = "YXTxsaj22WSJ7wTG"

-- 路由配置
---@type integer 路由客户端数量
ROUTER_CLIENT_COUNT = 10

---@class ServerDefinesModule 服务器定义模块
local M = {}

function M.get_gm_console_port()
    if is_gs_server() then
        return GS_GM_CONSOLE_PORT
    elseif is_cs_server() then
        return CS_GM_CONSOLE_PORT
    elseif is_bs_server() then
        return BS_GM_CONSOLE_PORT
    elseif is_ks_server() then
        return KS_GM_CONSOLE_PORT
    end
end

function M.get_dictator_port()
    if is_gs_server() then
        return GS_DICTATOR_PORT
    elseif is_cs_server() then
        return CS_DICTATOR_PORT
    elseif is_bs_server() then
        return BS_DICTATOR_PORT
    elseif is_ks_server() then
        return KS_DICTATOR_PORT
    end
end

function M.get_web_port()
    if is_gs_server() then
        return GS_WEB_PORT
    elseif is_cs_server() then
        return CS_WEB_PORT
    elseif is_bs_server() then
        return BS_WEB_PORT
    elseif is_ks_server() then
        return KS_WEB_PORT
    end
end

function M.get_qrcode_ports()
    if is_cs_server() then
        return CS_QRCODE_PORTS
    end
end

function M.get_gateway_ports()
    if is_gs_server() then
        return GS_GATEWAY_PORTS
    elseif is_ks_server() then
        return KS_GATEWAY_PORTS
    end
end

function M.get_ks_gateway_ports()
    return KS_GATEWAY_PORTS
end

return M
