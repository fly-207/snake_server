大话许仙的服务端代码

编译时可能出现错误

    # debian 出错错误
        
        relocation R_X86_64_32 against `.rodata.str1.1' can not be used when making a PIE object; recompile with -fPIE

    # centos7安装了某些库后导致

        jemalloc_cpp.cpp:56: undefined reference to `std::set_new_handler(void (*)())'

为了稳妥起见, 用 centos7 一个新环境编译

先不要考虑 skynet 版本问题, 后续整理好流程后要替换成最新版本

