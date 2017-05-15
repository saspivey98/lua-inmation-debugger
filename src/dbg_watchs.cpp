#include "dbg_watchs.h"
#include <lua.hpp>

namespace vscode
{
	intptr_t WATCH_TABLE = 0;

	static int watch_gc(lua_State* L)
	{
		watchs* w = (watchs*)lua_touserdata(L, lua_upvalueindex(1));
		w->destory();
		return 0;
	}

	watchs::watchs(lua_State* L)
		: L(L)
		, cur_(0)
		, max_(0)
	{
	}

	watchs::~watchs()
	{
		clear();
	}

	size_t watchs::add()
	{
		if (max_ < 250)
		{
			max_++;
		}
		else if (cur_ == max_)
		{
			cur_ = 0;
		}

		t_set(cur_++);
		return cur_;
	}

	bool watchs::get(size_t index)
	{
		if (index > max_ || index == 0)
		{
			return false;
		}
		t_get(index - 1);
		return true;
	}

	void watchs::clear()
	{
		if (!L) return;
		lua_pushnil(L);
		lua_rawsetp(L, LUA_REGISTRYINDEX, &WATCH_TABLE);
		cur_ = 0;
		max_ = 0;
	}

	void watchs::t_table()
	{
		if (LUA_TTABLE != lua_rawgetp(L, LUA_REGISTRYINDEX, &WATCH_TABLE)) {
			lua_pop(L, 1);
			lua_newtable(L);
			lua_pushlightuserdata(L, (void*)this);
			lua_pushcclosure(L, watch_gc, 1);
			lua_setfield(L, -2, "__gc");
			lua_setmetatable(L, -2);
			lua_pushvalue(L, -1);
			lua_rawsetp(L, LUA_REGISTRYINDEX, &WATCH_TABLE);
		}
	}

	void watchs::t_set(int n)
	{
		int top1 = lua_gettop(L);
		t_table();
		lua_pushvalue(L, -2);
		lua_rawseti(L, -2, n);
		lua_pop(L, 1);
		int top2 = lua_gettop(L);
	}

	void watchs::t_get(int n)
	{
		int top1 = lua_gettop(L);
		t_table();
		lua_rawgeti(L, -1, n);
		lua_remove(L, -2);
		int top2 = lua_gettop(L);
	}

	void watchs::destory()
	{
		L = 0;
	}
}
