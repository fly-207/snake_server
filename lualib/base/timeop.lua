---@module timeop
---时间操作工具模块
---提供各类时间获取和计算功能
---包括秒级时间、毫秒时间、天数、周数等计算

local skynet = require "skynet"
local servicetimer = require "base.servicetimer"

local floor = math.floor
local max = math.max
local min = math.min

---获取当前时间戳(秒)
---@param bFloat boolean|nil 是否返回浮点数
---@return number time 当前时间戳
function get_time(bFloat)
    local iTime = servicetimer.ServiceTime()
    if bFloat then
        return iTime/100
    else
        return floor(iTime/100)
    end
end

---获取服务当前运行时间
---@return integer time 服务运行时间(单位:0.01秒)
function get_current()
    return servicetimer.ServiceNow()
end

---获取当前秒数(取整)
---@return integer second 当前秒数
function get_second()
    return floor(get_current()/100)
end

---获取当前秒数(浮点)
---@return number second 当前秒数
function get_ssecond()
    return get_current()/100
end

---获取当前毫秒数
---@return integer msecond 当前毫秒数
function get_msecond()
    return get_current()*10
end

---获取服务启动时间戳
---@return integer time 服务启动时间戳(秒)
function get_starttime()
    return servicetimer.ServiceStartTime()
end

---@type integer 标准时间基准点(2017/1/2)
local iStandTime = 1483286400

---获取天数编号(从基准日期算起)
---@param iSec integer|nil 时间戳(秒)，默认当前时间
---@return integer dayNo 天数编号
function get_dayno(iSec)
    local iSec = iSec or get_time()
    local iTime = iSec - iStandTime
    local iDayNo = floor(iTime // (3600*24))
    return iDayNo
end

---获取早晨天数编号(以5点为分界)
---@param iSec integer|nil 时间戳(秒)，默认当前时间
---@return integer dayNo 天数编号
function get_morningdayno(iSec)
    local iSec = iSec or get_time()
    local iTime = iSec - iStandTime
    local iDayMorningNo = floor((iTime-5*3600) // (3600*24))
    return iDayMorningNo
end

---获取周数编号
---@param iSec integer|nil 时间戳(秒)，默认当前时间
---@return integer weekNo 周数编号
function get_weekno(iSec)
    local iSec = iSec or get_time()
    local iTime = iSec - iStandTime
    local iWeekNo = floor(iTime//(7*3600*24))
    return iWeekNo
end

---获取早晨周数编号(以5点为分界)
---@param iSec integer|nil 时间戳(秒)，默认当前时间
---@return integer weekNo 周数编号
function get_morningweekno(iSec)
    local iSec = iSec or get_time()
    local iTime = iSec - iStandTime
    local iWeekNo = floor((iTime-5*3600)//(7*3600*24))
    return iWeekNo
end

---获取小时编号
---@param iSec integer|nil 时间戳(秒)，默认当前时间
---@return integer hourNo 小时编号
function get_hourno(iSec)
    local iSec = iSec or get_time()
    local iTime = iSec - iStandTime
    local iHourNo = floor(iTime//3600)
    return iHourNo
end

---将周数编号转换为时间戳
---@param ino integer 周数编号
---@return integer sec 时间戳(秒)
function get_weekno2time(ino)
    local iSec = ino*604800 + iStandTime
    return iSec
end

---将早晨周数编号转换为时间戳
---@param ino integer 早晨周数编号
---@return integer sec 时间戳(秒)
function get_morningweekno2time(ino)
    local iSec = ino*604800+18000 + iStandTime
    return iSec
end

---@class TimeTable 时间信息表
---@field time integer 时间戳
---@field date osdate 日期信息表

---获取时间信息表
---@param iTime integer|nil 时间戳(秒)，默认当前时间
---@return TimeTable retbl 时间信息表
function get_timetbl(iTime)
    iTime = iTime or get_time()
    local retbl = {}
    retbl.time = iTime
    retbl.date = os.date("*t",iTime)
    retbl.date.wday = get_weekday(iTime)
    return retbl
end

function get_daytime(tab)
    local iFactor = tab.factor  or 1                                        --正负因子
    local iDay = tab.day or 1                                                  --距离天数
    local iAnchor = tab.anchor or 0                                     --锚点
    local iCurTime = tab.time or get_time()
    iDay = iDay * iFactor                                                             
    local iTime = iCurTime + iDay * 3600 * 24
    local date = os.date("*t",iTime)
    iTime = os.time({year=date.year,month=date.month,day=date.day,hour=iAnchor,min=0,sec=0})
    return get_timetbl(iTime)
end

function get_hourtime(tab)
    local iFactor = tab.factor or 1                                                --正负因子
    local iHour = tab.hour or 1                                                     --距离小时
    local iCurTime = tab.time or get_time()
    iHour = iHour * iFactor
    local iTime = iCurTime + iHour * 3600
    local date = os.date("*t",iTime)
    iTime = os.time({year=date.year,month=date.month,day=date.day,hour=date.hour,min=0,sec=0})
    return get_timetbl(iTime)
end

function get_mintime(tab)
    local iFactor = tab.factor or 1                                                --正负因子
    local iMin = tab.min or 1                                                      --距离小时
    local iCurTime = tab.time or get_time()
    iMin = iMin * iFactor
    local iTime = iCurTime + iMin * 60
    local date = os.date("*t",iTime)
    iTime = os.time({year=date.year,month=date.month,day=date.day,hour=date.hour,min=date.min,sec=0})
    return get_timetbl(iTime)
end

---获取指定星期几的时间信息
---@param tab table 参数表 {factor, delta, wday, hour, min, time}
---@return TimeTable retbl 时间信息表
function get_wdaytime(tab)
    local iFactor = tab.factor or 1
    local iDelta = tab.delta or 0
    iDelta = iFactor * iDelta
    local iWDay = tab.wday or 1
    local iHour = tab.hour or 0
    local iMin = tab.min or 0
    local iCurTime = tab.time or get_time()

    local iTime = iCurTime + iDelta * 3600 * 24 * 7
    local date = get_timetbl(iTime).date
    iTime = iTime + (iWDay - date.wday) * 3600 * 24 + (iHour - date.hour) * 3600 + (iMin - date.min) * 60 - date.sec
    return get_timetbl(iTime)
end

---获取星期几(1-7，周一为1)
---@param iTime integer|nil 时间戳(秒)，默认当前时间
---@return integer wday 星期几
function get_weekday(iTime)
    local iTime = iTime or get_time()
    local wday = tonumber(os.date("%w",iTime))
    if wday == 0 then
        return 7
    else
        return wday
    end
end

---获取早晨星期几(以5点为分界)
---@param iTime integer|nil 时间戳(秒)，默认当前时间
---@return integer wday 星期几
function get_morningweekday(iTime)
    local iTime = iTime or get_time()
    return get_weekday(iTime - 5 * 3600)
end

---获取本周一的时间戳
---@param iTime integer|nil 时间戳(秒)，默认当前时间
---@return integer time 周一的时间戳
function get_mondaytime(iTime)
    local iTime = iTime or get_time()
    local wday = get_weekday(iTime)
    return iTime - (wday - 1) * 24 * 3600
end

---获取格式化时间字符串
---@param iTime integer|nil 时间戳(秒)，默认当前时间
---@return string str 格式化后的时间字符串
function get_format_time(iTime)
    iTime = iTime or get_time()
    return os.date("%c", iTime)
end

---根据指定格式获取时间字符串
---@param iTime integer|nil 时间戳(秒)，默认当前时间
---@param sFormat string 格式字符串
---@return string str 格式化后的时间字符串
function get_time_format_str(iTime, sFormat)
    iTime = iTime or get_time()
    return os.date(sFormat, iTime)
end

---将秒数转换为可读字符串(如"01时23分45秒")
---@param sec integer 秒数
---@return string str 可读字符串
function get_second2string(sec)
    local s = math.floor(sec % 60)
    local m = math.floor((sec / 60)  % 60)
    local h = math.floor(sec / 3600)
    local str = ""
    if h > 0 then
        str = string.format("%s%02d时",str,h)
    end
    str = string.format("%s%02d分",str,m)
    str = string.format("%s%02d秒",str,s)
    return str
end

---将日期时间字符串转换为时间戳
---支持格式: "2018-2-1", "2018-02-01 12", "2018-02-01 12:13", "2018-02-01 12:13:14"
---@param s string 日期时间字符串
---@return integer timestamp 时间戳(秒)
function get_str2timestamp(s)
    assert(s and type(s)=="string", "timeop get_str2timestamp s not a string")
    local dl = split_string(s, " ")
    local datel = split_string(dl[1], "-")
    local timel = dl[2] and split_string(dl[2], ":") or {}
    local year, month, day = table.unpack(datel)
    assert(year and month and day, string.format("timeop get_str2timestamp date error %s", s))
    local hour, minute, secend = table.unpack(timel)
    local t = {
        year = year,
        month = month,
        day = day,
        hour = hour or 0,
        min = minute or 0,
        sec = secend or 0,
    }
    return os.time(t)
end
