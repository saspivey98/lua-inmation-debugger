local lm = require "luamake"

require "compile.common.detect_platform"
require "compile.luadbg.build"

local runtimes = {}

lm.cxx = "c++17"

local bindir = "publish/runtime/"..lm.runtime_platform

lm:source_set 'onelua' {
    includes = {
        "3rd/bee.lua/3rd/lua/",
        "3rd/bee.lua/",
        "src/luadebug/",
    },
    sources = {
        "src/luadebug/luadbg/onelua.c",
        "3rd/bee.lua/3rd/lua/bee_utf8_crt.cpp"
    },
    msvc = {
        sources = ("3rd/bee.lua/3rd/lua/fast_setjmp_%s.s"):format(lm.arch)
    },
    linux = {
        flags = "-fPIC"
    },
    netbsd = {
        flags = "-fPIC"
    },
    freebsd = {
        flags = "-fPIC"
    },
    gcc = {
        flags = "-Wno-maybe-uninitialized"
    }
}

lm:source_set 'luadbg' {
    deps = "onelua",
    includes = {
        "src/luadebug",
        "3rd/bee.lua",
        "3rd/bee.lua/3rd/lua",
    },
    sources = {
        "src/luadebug/luadbg/*.cpp",
    },
    linux = {
        flags = "-fPIC"
    },
    netbsd = {
        flags = "-fPIC"
    },
    freebsd = {
        flags = "-fPIC"
    },
    windows = {
        defines = {
            "_CRT_SECURE_NO_WARNINGS",
            "_WIN32_WINNT=0x0602",
        },
    }
}

local luaver = "lua53"
runtimes[#runtimes + 1] = luaver.."/lua"
if lm.os == "windows" then
    runtimes[#runtimes + 1] = luaver.."/"..luaver
end

if lm.os == "windows" then
    lm:shared_library(luaver.."/"..luaver) {
        rootdir = '3rd/lua/'..luaver,
        bindir = bindir,
        includes = {
            '..',
        },
        sources = {
            "*.c",
            "!lua.c",
            "!luac.c",
        },
        defines = {
            "LUA_BUILD_AS_DLL",
            -- luaver == "lua51" and "_CRT_SECURE_NO_WARNINGS",
            -- luaver == "lua52" and "_CRT_SECURE_NO_WARNINGS",
            -- luaver == "lua-latest" and "LUA_VERSION_LATEST",
        }
    }

    lm:executable(luaver..'/lua') {
        rootdir = '3rd/lua/'..luaver,
        bindir = bindir,
        output = "lua",
        deps = luaver..'/'..luaver,
        includes = {
            '..',
        },
        sources = {
            "lua.c",
            "../../../compile/windows/lua-debug.rc",
        },
        defines = {
            -- luaver == "lua51" and "_CRT_SECURE_NO_WARNINGS",
            -- luaver == "lua52" and "_CRT_SECURE_NO_WARNINGS",
            -- luaver == "lua-latest" and "LUA_VERSION_LATEST",
        }
    }
else
    lm:executable(luaver..'/lua') {
        rootdir = '3rd/lua/'..luaver,
        bindir = bindir,
        includes = {
            '.',
            '..',
        },
        sources = {
            "*.c",
            "!luac.c",
        },
        defines = {
            -- luaver == "lua51" and "_XOPEN_SOURCE=600",
            -- luaver == "lua52" and "_XOPEN_SOURCE=600",
            -- luaver == "lua-latest" and "LUA_VERSION_LATEST",
        },
        visibility = "default",
        links = "m",
        linux = {
            defines = "LUA_USE_LINUX",
            links = { "pthread", "dl" },
            ldflags = "-Wl,-E",
        },
        netbsd = {
            defines = "LUA_USE_LINUX",
            links = "pthread",
            ldflags = "-Wl,-E",
        },
        freebsd = {
            defines = "LUA_USE_LINUX",
            links = "pthread",
            ldflags = "-Wl,-E",
        },
        android = {
            defines = "LUA_USE_LINUX",
            links = "dl",
        },
        macos = {
            defines = {
                "LUA_USE_MACOSX",
                luaver == "lua51" and "LUA_USE_DLOPEN",
            },
        }
    }
    --end
end

local luaSrcDir = "3rd/lua/"..luaver

runtimes[#runtimes + 1] = luaver.."/luadebug"
lm:shared_library(luaver..'/luadebug') {
    bindir = bindir,
    deps = {
        "luadbg",
        "compile_to_luadbg",
    },
    defines = {
        luaver == "lua-latest" and "LUA_VERSION_LATEST",
    },
    includes = {
        luaSrcDir,
        "3rd/bee.lua/",
        "3rd/bee.lua/3rd/lua-seri",
        "src/luadebug/",
    },
    sources = {
        "src/luadebug/*.cpp",
        "src/luadebug/symbolize/*.cpp",
        "src/luadebug/thunk/*.cpp",
        "src/luadebug/util/*.cpp",
        "src/luadebug/".."compat/5x".."/**/*.cpp",
    },
    windows = {
        deps = luaver..'/'..luaver,
        defines = {
            "_CRT_SECURE_NO_WARNINGS",
            "_WIN32_WINNT=0x0602",
            ("LUA_DLL_VERSION="..luaver)
        },
        links = {
            "version",
            "ws2_32",
            "user32",
            "shell32",
            "ole32",
            "delayimp",
            "dbghelp",
            "ntdll",
            "synchronization",
        },
        ldflags = {
            ("/DELAYLOAD:%s.dll"):format(luaver),
        },
    },
    macos = {
        frameworks = "Foundation"
    },
    linux = {
        links = "pthread",
        crt = "static",
    },
    netbsd = {
        links = "pthread",
    },
    freebsd = {
        links = "pthread",
        crt = "static",
    },
    android = {
        links = "m",
    }
}

lm:phony "runtime" {
    inputs = runtimes
}
