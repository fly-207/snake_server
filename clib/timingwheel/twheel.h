// 定义宏_TWHEEL_H_ 防止头文件被多次包含
#ifndef _TWHEEL_H_
#define _TWHEEL_H_

// 引入整数类型定义的头文件
#include <stdint.h>

// 定义时间轮的常量
// TIME_NEAR_SHIFT: 近时间轮的位移计数
// TIME_NEAR: 近时间轮的槽位数量
// TIME_NEAR_MASK: 计算近时间轮槽位索引的掩码
// TIME_FAR_SHIFT: 远时间轮的位移计数
// TIME_FAR: 远时间轮的槽位数量
// TIME_FAR_MASK: 计算远时间轮槽位索引的掩码
#define TIME_NEAR_SHIFT 8
#define TIME_NEAR (1 << TIME_NEAR_SHIFT)
#define TIME_NEAR_MASK (TIME_NEAR - 1)
#define TIME_FAR_SHIFT 6
#define TIME_FAR (1 << TIME_FAR_SHIFT)
#define TIME_FAR_MASK (TIME_FAR - 1)

// 定义锁定宏 LOCK，使用自旋锁锁定时间轮结构
// X: 时间轮结构的指针
#define LOCK(X) while (__sync_lock_test_and_set(&((X)->lock),1)) {}
// 定义解锁宏 UNLOCK，释放时间轮结构的锁
#define UNLOCK(X) __sync_lock_release(&((X)->lock))

// 定义回调函数类型，用于处理超时事件
typedef void (time_Callback)(void *ud, uint64_t handle);

// 时间节点结构体，存储时间戳和句柄以及指向下一个节点的指针
struct TimeNode {
    uint32_t time; // 时间戳
    uint64_t handle; // 事件句柄
    struct TimeNode* next; // 指向下一个节点的指针
};

// 时间链表结构体，包含头节点和尾节点指针
struct TimeList {
    struct TimeNode head; // 头节点
    struct TimeNode* tail; // 尾节点指针
};

// 时间轮结构体，包含锁、当前时间、起始时间、近时间轮、远时间轮数组和溢出链表
struct TimeWheel {
    uint32_t lock; // 锁状态
    uint32_t curr_time; // 当前时间
    uint64_t start_time; // 起始时间
    struct TimeList near[TIME_NEAR]; // 近时间轮数组
    struct TimeList far[4][TIME_FAR]; // 远时间轮数组
    struct TimeList overflow; // 溢出事件链表
};

// 创建一个新的时间轮
// 参数: t - 时间轮的初始时间
// 返回: 指向创建的时间轮结构的指针
struct TimeWheel*
timewheel_create(uint64_t t);

// 释放时间轮资源
// 参数: TW - 要释放的时间轮指针
// 返回: 无
void
timewheel_release(struct TimeWheel* TW);

// 添加一个定时事件到时间轮
// 参数: TW - 时间轮指针
//       handle - 事件句柄
//       t - 相对于当前时间的延迟
// 返回: 无
void
timewheel_add_time(struct TimeWheel* TW, uint64_t handle, uint32_t t);

// 更新时间轮，处理超时事件并调用回调函数
// 参数: TW - 时间轮指针
//       t - 新的当前时间
//       cb - 超时事件回调函数
//       ud - 用户数据指针，传递给回调函数
// 返回: 无
void
timewheel_update(struct TimeWheel* TW, uint64_t t, time_Callback cb, void* ud);

#endif // _TWHEEL_H_