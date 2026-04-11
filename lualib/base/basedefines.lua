---@module basedefines
---基础对象状态定义模块
---定义对象的生命周期状态常量

---@class BASEOBJ_STATUS 基础对象状态枚举
---@field is_alive integer 对象存活状态，值为1
---@field is_release integer 对象已释放状态，值为2
BASEOBJ_STATUS = {
    is_alive = 1,
    is_release = 2,
}
