local lm = require "luamake"

require "compile.common.frida"

lm:lua_src 'launcher_source' {
    deps = {
        "frida",
    },
    includes = {
        "3rd/bee.lua",
        "3rd/frida_gum/gumpp",
        "src/launcher",
    },
    sources = {
        "src/launcher/**/*.cpp",
    },
    defines = {
        "BEE_INLINE",
    },
    windows = {
        defines = "_CRT_SECURE_NO_WARNINGS",
        links = {
            "ws2_32",
            "user32",
            "shell32",
            "ole32",
            "delayimp",
            "ntdll",
            "Version"
        },
        ldflags = {
            "/NODEFAULTLIB:LIBCMT"
        }
    },
    linux = {
        flags = "-fPIC",
    }
}
