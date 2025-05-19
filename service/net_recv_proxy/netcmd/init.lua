--import module

local global = require "global"
local skynet = require "skynet"
local cjson = require "cjson"

function Invoke(iFd, iType, sData)
    local oProxy = global.oProxy

    print(string.format("网络消息 服务=%s iFd=%s iType=%s sData=%s",SERVICE_NAME, iFd, iType, cjson.encode(mData)))

    if oProxy then
        oProxy:DoAddRecv(iFd, iType, sData)
    end
end
