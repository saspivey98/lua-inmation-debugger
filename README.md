# lua-debug

## Requirements

* Lua 5.3
* Platform: Windows, macOS, Linux, Android, NetBSD, FreeBSD

## Feature

* Adds `syslib` to global packages
* Breakpoints
* Function breakpoints
* Conditional breakpoints
* Hit Conditional breakpoints
* Step over, step in, step out
* Watches
* Evaluate expressions
* Exception
* Remote debugging
* Support WSL

## Build

Install [luamake](https://github.com/actboy168/luamake) (use `x64 native tools command prompt for VS 2022`)

```bash
git clone https://github.com/actboy168/luamake
pushd luamake
git submodule init
git submodule update
.\compile\install.bat(msvc)
./compile/install.sh (other)
popd
```

Clone repo.

```bash
git clone https://github.com/saspivey98/Lua-on-Windows
cd lua-debug
git submodule init
git submodule update
```

Download depedencies.

``` bash
luamake lua compile/download_deps.lua
```

Build

```bash
luamake -mode release
```

## Install to VSCode

1. Package extension by running `vsce package` in the `/publish/` directory. (You will need to install vsce by `npm i -g vsce`)
2. Install extension by clicking extensions, and then click the ellipse `...` in the top corner. Select `Install from VSIX`.
3. For release, `Run task：Copy Publish`
