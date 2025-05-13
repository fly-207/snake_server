#include "xor.h"

static uint64_t ORX_KEY_MAP[8] = {};


/*
输入的 k = 0xe07aea3911363aa9
    ORX_KEY_MAP[0] = 0xa9
    ORX_KEY_MAP[1] = 0x3a
    ORX_KEY_MAP[2] = 0x36
    ORX_KEY_MAP[3] = 0x11
    ORX_KEY_MAP[4] = 0x39
    ORX_KEY_MAP[5] = 0xea
    ORX_KEY_MAP[6] = 0x7a
    ORX_KEY_MAP[7] = 0xe0
*/
void xor_init(uint64_t k)
{
    int i;
    for (i = 0; i < 8; i++)
    {
        ORX_KEY_MAP[i] = (k >> (i * 8)) & 0xff;
    }
};


/*
mark = size % 10 + 1

    每隔 mark 个字节跳过，不加密。

sp_mark = size % 2 ? size % 20 : size / 7

    sp_mark 是一个特别的位置：

    如果 size 是奇数，则为 size % 20；

    如果是偶数，则为 size / 7。

    这个位置的字节会用 0xa3 进行 XOR 加密，而不是用 key。

遍历每个字节：

    如果当前索引 i 是 mark 的倍数（即 i % mark == 0），跳过，不处理；

    如果是 sp_mark 位置，则对 buff[i] ^= 0xa3；

    否则，执行 buff[i] ^= ORX_KEY_MAP[i % 8]，按8字节 key 循环异或
*/

void xor_code(unsigned char *buff, uint32_t size)
{
    int i;
    int mark = size % 10 + 1;
    int sp_mark = size % 2 ? size % 20 : size / 7;
    for (i = 0; i < size; i++)
    {
        if (i % mark == 0)
            continue;
        if (i == sp_mark)
            buff[i] ^= 0xa3;
        else
            buff[i] ^= ORX_KEY_MAP[i % 8];
    };
};
