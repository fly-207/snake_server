#include "skynet.h"
#include "skynet_malloc.h"

#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#if defined(__APPLE__)
#include <sys/time.h>
#endif


/*
我来总结一下这个 lua-measure.c 文件的主要功能：
这是一个用于 Lua 代码性能测量的 C 模块，主要提供以下功能：
时间测量功能
	提供毫秒级(timestamp())和微秒级(timestamp_us())的时间戳获取
	支持跨平台(Windows/Unix/MacOS)的时间测量
函数调用追踪
	通过 Lua hook 机制追踪函数调用
	记录函数进入(on_enter_func)和离开(on_leave_func)的时间点
	统计每个函数的调用次数和总执行时间
协程支持
	提供对 Lua 协程的测量支持
	包含 yield 和 resume 操作的性能测量
	可以判断是否是主线程(is_mainthread)
性能分析功能
	可以开启(lopen)和关闭(lclose)性能测量
	提供性能数据的打印功能(lprint)
	支持按时间消耗排序的性能报告
性能监控
	可以设置性能警告阈值(WASTE_MS_LIMIT = 200ms)
	记录超过阈值的函数调用
	维护一个性能消耗列表(MEASURE_WASTE_LIST)
调试功能
	提供 start 和 stop 函数用于调试时间段的测量
	可以获取调试时间间隔
	这个模块主要用于：
性能分析和优化
	函数调用追踪
	耗时操作检测
	协程性能监控
	生成性能报告
它通过 Lua 的 hook 机制和注册表来存储性能数据，可以帮助开发者找出代码中的性能瓶颈和耗时操作。

*/
//upvalues
#define YIELD_RESUME 1

//key
#define TOTAL_COUNT 1
#define TOTAL_TIME 2
#define TIMESTAMP 3
#define CALLNAME 4
#define SINGLE_TIME 5
#define STACK_COUNT 6
#define DEBUG_TIME 7

#define WASTE_MS_LIMIT 200
#define WASTE_MAX_LEN 10000
#define NOTE_STAY_MS_LIMIT 180000

struct TimeCostInfo {
	const char* key;
	uint64_t time;
	int cnt;
} ;

static inline struct skynet_context*
get_ctx(lua_State *L)
{
	lua_getfield(L, LUA_REGISTRYINDEX, "skynet_context");
	struct skynet_context *ctx = lua_touserdata(L,-1);
	lua_pop(L, 1);
	return ctx;
}

static inline void
newmetatable(lua_State *L)
{
	lua_newtable(L);
	lua_pushliteral(L, "k");
	lua_setfield(L, -2, "__mode");
	return ;
}

static uint64_t
timestamp()
{
	uint64_t ms = 0;
#if !defined(__APPLE__)
	struct timespec ti;
	clock_gettime(CLOCK_REALTIME, &ti);
	ms += (uint64_t)(ti.tv_sec*1000);
	ms += (uint64_t)(ti.tv_nsec/1000000);
#else
	struct timeval tv;
	gettimeofday(&tv, NULL);
	ms += (uint64_t)(tv.tv_sec*1000);
	ms += (uint64_t)(tv.tv_usec/1000);
#endif
	return ms;
}

static uint64_t
timestamp_us()
{
	uint64_t us = 0;
#if !defined(__APPLE__)
	struct timespec ti;
	clock_gettime(CLOCK_REALTIME, &ti);
	us += (uint64_t)(ti.tv_sec*1000*1000);
	us += (uint64_t)(ti.tv_nsec/1000);
#else
	struct timeval tv;
	gettimeofday(&tv, NULL);
	us += (uint64_t)(tv.tv_sec*1000*1000);
	us += (uint64_t)(tv.tv_usec);
#endif
	return us;
}

static inline uint64_t
diff(uint64_t last, uint64_t now)
{
	return (now > last) ? (now - last) : 0;
}

static void
cotimestamp(lua_State *L, uint64_t stamp)
{
	lua_pushstring(L, "MEASURE_CO_MAP");
	lua_rawget(L, LUA_REGISTRYINDEX);
	lua_pushthread(L);
	lua_rawget(L, -2);

	int i1;
	if (lua_isnil(L, -1)) {
		lua_pop(L, 1);
	} else {
		i1 = lua_gettop(L);

		lua_pushinteger(L, stamp);
		lua_rawseti(L, i1, TIMESTAMP);

		lua_pop(L, 1);
	}

	lua_pop(L, 1);
}

static void
codebugtime(lua_State *L, uint64_t stamp)
{
	lua_pushstring(L, "MEASURE_CO_MAP");
	lua_rawget(L, LUA_REGISTRYINDEX);
	lua_pushthread(L);
	lua_rawget(L, -2);

	int i1;
	if (lua_isnil(L, -1)) {
		lua_pop(L, 1);
	} else {
		i1 = lua_gettop(L);

		lua_pushinteger(L, stamp);
		lua_rawseti(L, i1, DEBUG_TIME);

		lua_pop(L, 1);
	}

	lua_pop(L, 1);
}

static uint64_t
cogetdebugtime(lua_State *L)
{
	lua_pushstring(L, "MEASURE_CO_MAP");
	lua_rawget(L, LUA_REGISTRYINDEX);
	lua_pushthread(L);
	lua_rawget(L, -2);

	uint64_t ret_time = -1;
	int i1;
	if (lua_isnil(L, -1)) {
		lua_pop(L, 1);
	} else {
		i1 = lua_gettop(L);

		lua_rawgeti(L, i1, DEBUG_TIME);
		ret_time = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_pop(L, 1);
	}

	lua_pop(L, 1);

	return ret_time;
}

static uint64_t
coupdate(lua_State *L, uint64_t stamp)
{
	lua_pushstring(L, "MEASURE_CO_MAP");
	lua_rawget(L, LUA_REGISTRYINDEX);
	lua_pushthread(L);
	lua_rawget(L, -2);

	uint64_t ret_time = 0;
	int i1;
	if (lua_isnil(L, -1)) {
		lua_pop(L, 1);

		lua_pushthread(L);
		lua_newtable(L);
		i1 = lua_gettop(L);

		lua_pushinteger(L, 0);
		lua_rawseti(L, i1, TOTAL_TIME);
		lua_pushinteger(L, stamp);
		lua_rawseti(L, i1, TIMESTAMP);
		lua_pushinteger(L, -1);
		lua_rawseti(L, i1, DEBUG_TIME);

		lua_rawset(L, -3);
		ret_time = 0;
	} else {
		i1 = lua_gettop(L);

		lua_rawgeti(L, i1, TOTAL_TIME);
		lua_rawgeti(L, i1, TIMESTAMP);
		uint64_t total_time = lua_tointeger(L, -2);
		uint64_t timestamp = lua_tointeger(L, -1);
		lua_pop(L, 2);

		ret_time = total_time + (stamp - timestamp);
		lua_pushinteger(L, ret_time);
		lua_rawseti(L, i1, TOTAL_TIME);
		lua_pushinteger(L, stamp);
		lua_rawseti(L, i1, TIMESTAMP);

		lua_pop(L, 1);
	}

	lua_pop(L, 1);

	return ret_time;
}

static void
on_enter_func(lua_State *L, char *callname) {
	uint64_t sts = timestamp();
	uint64_t ts = coupdate(L, sts);

	lua_pushstring(L, "MEASURE_NOTE_MAP");
	lua_rawget(L, LUA_REGISTRYINDEX);
	lua_pushthread(L);
	lua_rawget(L, -2);

	int i1, i2;
	if (lua_isnil(L, -1)) {
		lua_pop(L, 1);

		lua_pushthread(L);
		lua_newtable(L);
		i1 = lua_gettop(L);

		lua_pushstring(L, callname);
		lua_newtable(L);
		i2 = lua_gettop(L);

		lua_pushinteger(L, ts);
		lua_rawseti(L, i2, TIMESTAMP);
		lua_pushinteger(L, 1);
		lua_rawseti(L, i2, STACK_COUNT);

		lua_rawset(L, i1);

		lua_rawset(L, -3);
	} else {
		i1 = lua_gettop(L);
		lua_pushstring(L, callname);
		lua_rawget(L, i1);
		if (lua_isnil(L, -1)) {
			lua_pop(L, 1);
			lua_pushstring(L, callname);
			lua_newtable(L);
			i2 = lua_gettop(L);

			lua_pushinteger(L, ts);
			lua_rawseti(L, i2, TIMESTAMP);
			lua_pushinteger(L, 1);
			lua_rawseti(L, i2, STACK_COUNT);

			lua_rawset(L, i1);
		} else {
			i2 = lua_gettop(L);

			lua_rawgeti(L, i2, TIMESTAMP);
			uint64_t htime = lua_tointeger(L, -1);
			lua_pop(L, 1);

			//defense error left data
			if ((ts - htime) >= NOTE_STAY_MS_LIMIT) {
				lua_pushinteger(L, ts);
				lua_rawseti(L, i2, TIMESTAMP);
				lua_pushinteger(L, 1);
				lua_rawseti(L, i2, STACK_COUNT);
			} else {
				lua_rawgeti(L, i2, STACK_COUNT);
				int stack_count = lua_tointeger(L, -1);
				lua_pop(L, 1);

				lua_pushinteger(L, stack_count + 1);
				lua_rawseti(L, i2, STACK_COUNT);
			}

			lua_pop(L, 1);
		}

		lua_pop(L, 1);
	}

	lua_pop(L, 1);
}

static void
on_leave_func(lua_State *L, char *callname) {
	uint64_t sts = timestamp();
	uint64_t ts = coupdate(L, sts);

	lua_pushstring(L, "MEASURE_NOTE_MAP");
	lua_rawget(L, LUA_REGISTRYINDEX);
	lua_pushthread(L);
	lua_rawget(L, -2);

	int i1, i2;
	if (!lua_isnil(L, -1)) {
		i1 = lua_gettop(L);
		lua_pushstring(L, callname);
		lua_rawget(L, i1);

		if (!lua_isnil(L, -1)) {
			i2 = lua_gettop(L);

			lua_rawgeti(L, i2, TIMESTAMP);
			lua_rawgeti(L, i2, STACK_COUNT);
			uint64_t timestamp = lua_tointeger(L, -2);
			int stack_count = lua_tointeger(L, -1);
			lua_pop(L, 2);
			stack_count = stack_count - 1;
			lua_pushinteger(L, stack_count);
			lua_rawseti(L, i2, STACK_COUNT);

			if (stack_count <= 0) {
				uint64_t timediff = diff(timestamp, ts);

				lua_pushstring(L, "MEASURE_RESULT_MAP");
				lua_rawget(L, LUA_REGISTRYINDEX);
				lua_pushstring(L, callname);
				lua_rawget(L, -2);

				int ii1;
				if (lua_isnil(L, -1)) {
					lua_pop(L, 1);

					lua_pushstring(L, callname);
					lua_newtable(L);
					ii1 = lua_gettop(L);

					lua_pushinteger(L, 1);
					lua_rawseti(L, ii1, TOTAL_COUNT);
					lua_pushinteger(L, timediff);
					lua_rawseti(L, ii1, TOTAL_TIME);

					lua_rawset(L, -3);
				} else {
					ii1 = lua_gettop(L);

					lua_rawgeti(L, ii1, TOTAL_COUNT);
					lua_rawgeti(L, ii1, TOTAL_TIME);
					int total_count = lua_tointeger(L, -2);
					uint64_t total_time = lua_tointeger(L, -1);
					lua_pop(L, 2);

					lua_pushinteger(L, total_count + 1);
					lua_rawseti(L, ii1, TOTAL_COUNT);
					lua_pushinteger(L, total_time + timediff);
					lua_rawseti(L, ii1, TOTAL_TIME);

					lua_pop(L, 1);
				}
				lua_pop(L, 1);

				if (timediff >= WASTE_MS_LIMIT) {
					lua_pushstring(L, "MEASURE_WASTE_LIST");
					lua_rawget(L, LUA_REGISTRYINDEX);
					int len = lua_rawlen(L, -1);

					lua_newtable(L);
					lua_pushinteger(L, sts);
					lua_rawseti(L, -2, TIMESTAMP);
					lua_pushstring(L, callname);
					lua_rawseti(L, -2, CALLNAME);
					lua_pushinteger(L, timediff);
					lua_rawseti(L, -2, SINGLE_TIME);

					int windex = len%WASTE_MAX_LEN + 1;
					lua_rawseti(L, -2, windex);

					lua_pop(L, 1);
				}

				lua_pushstring(L, callname);
				lua_pushnil(L);
				lua_rawset(L, i1);
			}

			lua_pop(L, 1);
		} else {
			lua_pop(L, 1);
		}

		lua_pop(L, 1);
	} else {
		lua_pop(L, 1);
	}

	lua_pop(L, 1);
}

static void
hook(lua_State *L, lua_Debug *ar) {
  	lua_getinfo(L, "nS", ar);

  	char callname[200];
  	sprintf(callname, "%s line:%d func:%s", ar->short_src, ar->linedefined, ar->name);

  	if (strcmp(ar->what, "C")) {
  		if (ar->event == 0) {
  			on_enter_func(L, callname);
  		} else if (ar->event == 4) {
  			lua_Debug previous_ar;
  			if (lua_getstack(L, 1, &previous_ar) != 0) {
  				lua_getinfo(L, "nS", &previous_ar);
  				char precallname[200];
  				sprintf(precallname, "%s line:%d func:%s", previous_ar.short_src, previous_ar.linedefined, previous_ar.name);
  				on_leave_func(L, precallname);
  			}
  			on_enter_func(L, callname);
  		} else {
  			on_leave_func(L, callname);
  		}
  	}
}

static int
lopen(lua_State *L)
{
	luaL_checktype(L, -1, LUA_TTHREAD);
	lua_State *L1 = lua_tothread(L, -1);
	lua_sethook(L1, (lua_Hook)hook, LUA_MASKCALL | LUA_MASKRET, 0);
	return 0;
}

static int
lclose(lua_State *L)
{
	luaL_checktype(L, -1, LUA_TTHREAD);
	lua_State *L1 = lua_tothread(L, -1);
	lua_sethook(L1, (lua_Hook)hook, 0, 0);
	//MEASURE_RESULT_MAP
	lua_pushstring(L, "MEASURE_RESULT_MAP");
	lua_newtable(L);
	lua_rawset(L, LUA_REGISTRYINDEX);
	//MEASURE_WASTE_LIST
	lua_pushstring(L, "MEASURE_WASTE_LIST");
	lua_newtable(L);
	lua_rawset(L, LUA_REGISTRYINDEX);
	return 0;
}

static int
lis_mainthread(lua_State *L)
{
	luaL_checktype(L, -1, LUA_TTHREAD);
	lua_State *L1 = lua_tothread(L, -1);
    	lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_MAINTHREAD);
    	lua_State *L2 = lua_tothread(L, -1);
    	lua_pop(L, 1);
    	bool is = false;
    	if (L1 == L2) {
    		is = true;
    	}
    	lua_pushboolean(L, is);
    	return 1;
}

static int
lyield(lua_State *L) {
	uint64_t sts = timestamp();
	coupdate(L, sts);
	lua_CFunction co_yield = lua_tocfunction(L, lua_upvalueindex(YIELD_RESUME));
	return co_yield(L);
}

static int
lresume(lua_State *L) {
	luaL_checktype(L, 1, LUA_TTHREAD);

	uint64_t sts = timestamp();

	lua_State* mL = lua_tothread(L, 1);
	cotimestamp(mL, sts);

	lua_CFunction co_resume = lua_tocfunction(L, lua_upvalueindex(YIELD_RESUME));
	return co_resume(L);
}

static int
lstart(lua_State *L)
{
	uint64_t sts = timestamp();
	uint64_t ts = coupdate(L, sts);
	codebugtime(L, ts);
	return 0;
}

static int
lstop(lua_State *L)
{
	uint64_t debug_time = cogetdebugtime(L);

	if (debug_time < 0) {
		lua_pushnumber(L, 0);
		return 1;
	}
	uint64_t sts = timestamp();
	uint64_t ts = coupdate(L, sts);
	codebugtime(L, -1);	
	uint64_t interval = diff(debug_time, ts);

	double fs = interval/1000.0;
	lua_pushnumber(L, fs);
	return 1;
}

static int
linfo(lua_State *L)
{
	lua_pushstring(L, "MEASURE_RESULT_MAP");
	lua_rawget(L, LUA_REGISTRYINDEX);
	lua_pushstring(L, "MEASURE_WASTE_LIST");
	lua_rawget(L, LUA_REGISTRYINDEX);
	return 2;
}

static int
ltimestamp(lua_State *L)
{
	lua_pushnumber(L, timestamp());
	return 1;
}

static int
ltimestamp_us(lua_State *L)
{
	lua_pushnumber(L, timestamp_us());
	return 1;
}

static int 
_comp_cost(const void * a, const void * b) {
	const struct TimeCostInfo * ca = a;
	const struct TimeCostInfo * cb = b;

	uint64_t diff_time = cb->time - ca->time;
	if (diff_time != 0) {
		return diff_time;
	} else {
		return cb->cnt < ca->cnt;
	}
}

static int
lprint(lua_State *L)
{
	struct skynet_context * ctx = get_ctx(L);
	lua_pushstring(L, "MEASURE_RESULT_MAP");
	lua_rawget(L, LUA_REGISTRYINDEX);

	int n = 0;
	lua_pushnil(L);
	while (lua_next(L, -2)) {
		lua_pop(L, 1);
		++ n;
	}
	size_t sz = (sizeof(struct TimeCostInfo)) * n;
	struct TimeCostInfo * p = skynet_malloc(sz);

	struct TimeCostInfo * k = p;
	lua_pushnil(L);
	while (lua_next(L, -2)) {
		const char * key = lua_tostring(L,-2);
		int i = lua_gettop(L);
		lua_rawgeti(L, i, TOTAL_COUNT);
		lua_rawgeti(L, i, TOTAL_TIME);
		int total_count = lua_tointeger(L, -2);
		uint64_t total_time = lua_tointeger(L, -1);
		
		struct TimeCostInfo * c = k;
		++ k;
		c->key = key;
		c->cnt = total_count;
		c->time = total_time;
		lua_pop(L, 3);
	}

	qsort(p , n , sizeof(struct TimeCostInfo), _comp_cost);

	skynet_error(ctx, "\n\n\n");
	skynet_error(ctx, "time   cnt    func");
	struct TimeCostInfo * j = p;
	for (; j<p+n; j++) {
		skynet_error(ctx, "%-6d %-6d %s", j->time, j->cnt, j->key);
	}

	skynet_free(p);
	return 0;
}

int
luaopen_measure(lua_State *L) {
	luaL_checkversion(L);

	luaL_Reg l[] = {
		{ "open" , lopen },
		{ "close" , lclose },
		{ "start" , lstart },
		{ "stop" , lstop },
		{ "info" , linfo },
		{ "yield" , lyield },
		{ "resume" , lresume },
		{"is_mainthread", lis_mainthread},
		{"timestamp", ltimestamp},
		{"timestamp_us", ltimestamp_us},
		{"print", lprint},
		{ NULL, NULL },
	};

	//MEASURE_WEAKTABLE_META
	lua_pushstring(L, "MEASURE_WEAKTABLE_META");
	newmetatable(L);
    	lua_rawset(L, LUA_REGISTRYINDEX);
    	//MEASURE_RESULT_MAP
    	lua_pushstring(L, "MEASURE_RESULT_MAP");
    	lua_newtable(L);
    	lua_rawset(L, LUA_REGISTRYINDEX);
    	//MEASURE_WASTE_LIST
        	lua_pushstring(L, "MEASURE_WASTE_LIST");
    	lua_newtable(L);
    	lua_rawset(L, LUA_REGISTRYINDEX);
    	//MEASURE_NOTE_MAP
    	lua_pushstring(L, "MEASURE_NOTE_MAP");
    	lua_newtable(L);
    	lua_pushstring(L, "MEASURE_WEAKTABLE_META");
    	lua_rawget(L, LUA_REGISTRYINDEX);
    	lua_setmetatable(L, -2);
    	lua_rawset(L, LUA_REGISTRYINDEX);
    	//MEASURE_CO_MAP
    	lua_pushstring(L, "MEASURE_CO_MAP");
    	lua_newtable(L);
    	lua_pushstring(L, "MEASURE_WEAKTABLE_META");
    	lua_rawget(L, LUA_REGISTRYINDEX);
    	lua_setmetatable(L, -2);
    	lua_rawset(L, LUA_REGISTRYINDEX);

	luaL_newlibtable(L, l);

	// cfunction (coroutine.resume or coroutine.yield)
	lua_pushnil(L);
	luaL_setfuncs(L, l, 1);

	int libtable = lua_gettop(L);

	lua_getglobal(L, "coroutine");

	lua_getfield(L, -1, "resume");
	lua_CFunction co_resume = lua_tocfunction(L, -1);
	lua_pop(L, 1);

	lua_getfield(L, libtable, "resume");
	lua_pushcfunction(L, co_resume);
	lua_setupvalue(L, -2, 1);
	lua_pop(L, 1);

	lua_getfield(L, -1, "yield");
	lua_CFunction co_yield = lua_tocfunction(L, -1);
	lua_pop(L, 1);

	lua_getfield(L, libtable, "yield");
	lua_pushcfunction(L, co_yield);
	lua_setupvalue(L, -2, 1);
	lua_pop(L, 1);

	lua_settop(L, libtable);

	return 1;
}
