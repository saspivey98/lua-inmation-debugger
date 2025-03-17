local lm = require "luamake"

lm:conf {
    flags = "/utf-8",
}

require "compile.common.config"

local platform = lm.runtime_platform

lm.defines = "_WIN32_WINNT=0x0602"
lm.builddir = ("build/%s/%s"):format(platform, lm.mode)

require "compile.common.runtime"
require "compile.common.launcher"

if lm.mode ~= "debug" then
    lm:msvc_copydll "copy_vcredist" {
        type = "vcrt",
        outputs = 'publish/vcredist/'..platform
    }
end

local ArchAlias = {
    ["win32-x64"] = "x64",
    ["win32-ia32"] = "x86",
}

lm:lua_dll ('launcher.'..ArchAlias[platform]) {
    bindir = "publish/bin",
    export_luaopen = "off",
    deps = {
        "launcher_source",
    }
}

lm:phony "launcher" {
    deps = 'launcher.'..ArchAlias[platform]
}

--DEPENDENCIES

lm:copy 'copy_argparse.lua' {
    inputs = 'src/dependencies/argparse.lua',
    outputs = 'publish/runtime/win32-x64/lua53/argparse.lua'
}

lm:copy 'copy_brieflz.dll' {
    inputs = 'src/dependencies/brieflz.dll',
    outputs = 'publish/runtime/win32-x64/lua53/brieflz.dll'
}

lm:copy 'copy_cliargs.lua' {
    inputs = 'src/dependencies/cliargs.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs.lua'
}

lm:copy 'copy_cURL.lua' {
    inputs = 'src/dependencies/cURL.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cURL.lua'
}

lm:copy 'copy_dkjson.lua' {
    inputs = 'src/dependencies/dkjson.lua',
    outputs = 'publish/runtime/win32-x64/lua53/dkjson.lua'
}

lm:copy 'copy_esi-lcurl-http-client.lua' {
    inputs = 'src/dependencies/esi-lcurl-http-client.lua',
    outputs = 'publish/runtime/win32-x64/lua53/esi-lcurl-http-client.lua'
}

lm:copy 'copy_esi-pibridge.lua' {
    inputs = 'src/dependencies/esi-pibridge.lua',
    outputs = 'publish/runtime/win32-x64/lua53/esi-pibridge.lua'
}

lm:copy 'copy_esi-variables.lua' {
    inputs = 'src/dependencies/esi-variables.lua',
    outputs = 'publish/runtime/win32-x64/lua53/esi-variables.lua'
}

lm:copy 'copy_globtopattern.lua' {
    inputs = 'src/dependencies/globtopattern.lua',
    outputs = 'publish/runtime/win32-x64/lua53/globtopattern.lua'
}

lm:copy 'copy_lcurl.dll' {
    inputs = 'src/dependencies/lcurl.dll',
    outputs = 'publish/runtime/win32-x64/lua53/lcurl.dll'
}

lm:copy 'copy_lfs.dll' {
    inputs = 'src/dependencies/lfs.dll',
    outputs = 'publish/runtime/win32-x64/lua53/lfs.dll'
}

lm:copy 'copy_lpeg.dll' {
    inputs = 'src/dependencies/lpeg.dll',
    outputs = 'publish/runtime/win32-x64/lua53/lpeg.dll'
}

lm:copy 'copy_ltn12.lua' {
    inputs = 'src/dependencies/ltn12.lua',
    outputs = 'publish/runtime/win32-x64/lua53/ltn12.lua'
}

lm:copy 'copy_luacov.lua' {
    inputs = 'src/dependencies/luacov.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luacov.lua'
}

lm:copy 'copy_luaxp.lua' {
    inputs = 'src/dependencies/luaxp.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luaxp.lua'
}

lm:copy 'copy_lxp.dll' {
    inputs = 'src/dependencies/lxp.dll',
    outputs = 'publish/runtime/win32-x64/lua53/lxp.dll'
}

lm:copy 'copy_mediator.lua' {
    inputs = 'src/dependencies/mediator.lua',
    outputs = 'publish/runtime/win32-x64/lua53/mediator.lua'
}

lm:copy 'copy_mime.lua' {
    inputs = 'src/dependencies/mime.lua',
    outputs = 'publish/runtime/win32-x64/lua53/mime.lua'
}

lm:copy 'copy_mimetypes.lua' {
    inputs = 'src/dependencies/mimetypes.lua',
    outputs = 'publish/runtime/win32-x64/lua53/mimetypes.lua'
}

lm:copy 'copy_mongo.dll' {
    inputs = 'src/dependencies/mongo.dll',
    outputs = 'publish/runtime/win32-x64/lua53/mongo.dll'
}

lm:copy 'copy_mosquitto.dll' {
    inputs = 'src/dependencies/mosquitto.dll',
    outputs = 'publish/runtime/win32-x64/lua53/mosquitto.dll'
}

lm:copy 'copy_pb.dll' {
    inputs = 'src/dependencies/pb.dll',
    outputs = 'publish/runtime/win32-x64/lua53/pb.dll'
}

lm:copy 'copy_protoc.lua' {
    inputs = 'src/dependencies/protoc.lua',
    outputs = 'publish/runtime/win32-x64/lua53/protoc.lua'
}

lm:copy 'copy_rapidjson.dll' {
    inputs = 'src/dependencies/rapidjson.dll',
    outputs = 'publish/runtime/win32-x64/lua53/rapidjson.dll'
}

lm:copy 'copy_re.lua' {
    inputs = 'src/dependencies/re.lua',
    outputs = 'publish/runtime/win32-x64/lua53/re.lua'
}

lm:copy 'copy_schema.lua' {
    inputs = 'src/dependencies/schema.lua',
    outputs = 'publish/runtime/win32-x64/lua53/schema.lua'
}

lm:copy 'copy_socket.lua' {
    inputs = 'src/dependencies/socket.lua',
    outputs = 'publish/runtime/win32-x64/lua53/socket.lua'
}

lm:copy 'copy_ssl.dll' {
    inputs = 'src/dependencies/ssl.dll',
    outputs = 'publish/runtime/win32-x64/lua53/ssl.dll'
}

lm:copy 'copy_ssl.lua' {
    inputs = 'src/dependencies/ssl.lua',
    outputs = 'publish/runtime/win32-x64/lua53/ssl.lua'
}

lm:copy 'copy_syslib.lua' {
    inputs = 'src/dependencies/syslib.lua',
    outputs = 'publish/runtime/win32-x64/lua53/syslib.lua'
}
lm:copy 'copy_xlsx.lua' {
    inputs = 'src/dependencies/xlsx.lua',
    outputs = 'publish/runtime/win32-x64/lua53/xlsx.lua'
}

lm:copy 'copy_xmlize.lua' {
    inputs = 'src/dependencies/xmlize.lua',
    outputs = 'publish/runtime/win32-x64/lua53/xmlize.lua'
}

-------------------FOLDERS---------------------------------

lm:copy 'copy_brimworks_zip.dll' {
    inputs = 'src/dependencies/brimworks/zip.dll',
    outputs = 'publish/runtime/win32-x64/lua53/brimworks/zip.dll'
}

-------------------BUSTED---------------------------------

lm:copy 'copy_busted_block.lua' {
    inputs = 'src/dependencies/busted/block.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/block.lua'
}

lm:copy 'copy_busted_compatibility.lua' {
    inputs = 'src/dependencies/busted/compatibility.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/compatibility.lua'
}

lm:copy 'copy_busted_context.lua' {
    inputs = 'src/dependencies/busted/context.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/context.lua'
}

lm:copy 'copy_busted_core.lua' {
    inputs = 'src/dependencies/busted/core.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/core.lua'
}

lm:copy 'copy_busted_done.lua' {
    inputs = 'src/dependencies/busted/done.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/done.lua'
}

lm:copy 'copy_busted_environment.lua' {
    inputs = 'src/dependencies/busted/environment.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/environment.lua'
}

lm:copy 'copy_busted_execute.lua' {
    inputs = 'src/dependencies/busted/execute.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/execute.lua'
}

lm:copy 'copy_busted_fixtures.lua' {
    inputs = 'src/dependencies/busted/fixtures.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/fixtures.lua'
}

lm:copy 'copy_busted_init.lua' {
    inputs = 'src/dependencies/busted/init.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/init.lua'
}

lm:copy 'copy_busted_luajit.lua' {
    inputs = 'src/dependencies/busted/luajit.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/luajit.lua'
}

lm:copy 'copy_busted_options.lua' {
    inputs = 'src/dependencies/busted/options.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/options.lua'
}

lm:copy 'copy_busted_runner.lua' {
    inputs = 'src/dependencies/busted/runner.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/runner.lua'
}

lm:copy 'copy_busted_status.lua' {
    inputs = 'src/dependencies/busted/status.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/status.lua'
}

lm:copy 'copy_busted_utils.lua' {
    inputs = 'src/dependencies/busted/utils.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/utils.lua'
}

-------------------BUSTED_LANGUAGES---------------------------------

lm:copy 'copy_busted_languages_ar.lua' {
    inputs = 'src/dependencies/busted/languages/ar.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/ar.lua'
}

lm:copy 'copy_busted_languages_de.lua' {
    inputs = 'src/dependencies/busted/languages/de.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/de.lua'
}

lm:copy 'copy_busted_languages_en.lua' {
    inputs = 'src/dependencies/busted/languages/en.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/en.lua'
}

lm:copy 'copy_busted_languages_es.lua' {
    inputs = 'src/dependencies/busted/languages/es.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/es.lua'
}

lm:copy 'copy_busted_languages_fr.lua' {
    inputs = 'src/dependencies/busted/languages/fr.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/fr.lua'
}

lm:copy 'copy_busted_languages_is.lua' {
    inputs = 'src/dependencies/busted/languages/is.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/is.lua'
}

lm:copy 'copy_busted_languages_it.lua' {
    inputs = 'src/dependencies/busted/languages/it.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/it.lua'
}

lm:copy 'copy_busted_languages_ja.lua' {
    inputs = 'src/dependencies/busted/languages/ja.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/ja.lua'
}

lm:copy 'copy_busted_languages_ko.lua' {
    inputs = 'src/dependencies/busted/languages/ko.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/ko.lua'
}

lm:copy 'copy_busted_languages_nl.lua' {
    inputs = 'src/dependencies/busted/languages/nl.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/nl.lua'
}

lm:copy 'copy_busted_languages_pt-BR.lua' {
    inputs = 'src/dependencies/busted/languages/pt-BR.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/pt-BR.lua'
}

lm:copy 'copy_busted_languages_ro.lua' {
    inputs = 'src/dependencies/busted/languages/ro.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/ro.lua'
}

lm:copy 'copy_busted_languages_ru.lua' {
    inputs = 'src/dependencies/busted/languages/ru.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/ru.lua'
}

lm:copy 'copy_busted_languages_th.lua' {
    inputs = 'src/dependencies/busted/languages/th.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/th.lua'
}

lm:copy 'copy_busted_languages_ua.lua' {
    inputs = 'src/dependencies/busted/languages/ua.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/ua.lua'
}

lm:copy 'copy_busted_languages_zh.lua' {
    inputs = 'src/dependencies/busted/languages/zh.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/languages/zh.lua'
}

-------------------BUSTED_MODULES---------------------------------

lm:copy 'copy_busted_modules_cli.lua' {
    inputs = 'src/dependencies/busted/modules/cli.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/cli.lua'
}

lm:copy 'copy_busted_modules_configuration_loader.lua' {
    inputs = 'src/dependencies/busted/modules/configuration_loader.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/configuration_loader.lua'
}

lm:copy 'copy_busted_modules_filter_loader.lua' {
    inputs = 'src/dependencies/busted/modules/filter_loader.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/filter_loader.lua'
}

lm:copy 'copy_busted_modules_helper_loader.lua' {
    inputs = 'src/dependencies/busted/modules/helper_loader.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/helper_loader.lua'
}

lm:copy 'copy_busted_modules_luacov.lua' {
    inputs = 'src/dependencies/busted/modules/luacov.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/luacov.lua'
}

lm:copy 'copy_busted_modules_output_handler_loader.lua' {
    inputs = 'src/dependencies/busted/modules/output_handler_loader.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/output_handler_loader.lua'
}

lm:copy 'copy_busted_modules_standalone_loader.lua' {
    inputs = 'src/dependencies/busted/modules/standalone_loader.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/standalone_loader.lua'
}

lm:copy 'copy_busted_modules_test_file_loader.lua' {
    inputs = 'src/dependencies/busted/modules/test_file_loader.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/test_file_loader.lua'
}

lm:copy 'copy_busted_modules_files_lua.lua' {
    inputs = 'src/dependencies/busted/modules/files/lua.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/files/lua.lua'
}

lm:copy 'copy_busted_modules_files_moonscript.lua' {
    inputs = 'src/dependencies/busted/modules/files/moonscript.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/files/moonscript.lua'
}

lm:copy 'copy_busted_modules_files_terra.lua' {
    inputs = 'src/dependencies/busted/modules/files/terra.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/modules/files/terra.lua'
}

-------------------BUSTED_outputHandlers---------------------------------

lm:copy 'copy_busted_outputHandlers_base.lua' {
    inputs = 'src/dependencies/busted/outputHandlers/base.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/outputHandlers/base.lua'
}

lm:copy 'copy_busted_outputHandlers_gtest.lua' {
    inputs = 'src/dependencies/busted/outputHandlers/gtest.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/outputHandlers/gtest.lua'
}

lm:copy 'copy_busted_outputHandlers_json.lua' {
    inputs = 'src/dependencies/busted/outputHandlers/json.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/outputHandlers/json.lua'
}

lm:copy 'copy_busted_outputHandlers_junit.lua' {
    inputs = 'src/dependencies/busted/outputHandlers/junit.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/outputHandlers/junit.lua'
}

lm:copy 'copy_busted_outputHandlers_plainTerminal.lua' {
    inputs = 'src/dependencies/busted/outputHandlers/plainTerminal.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/outputHandlers/plainTerminal.lua'
}

lm:copy 'copy_busted_outputHandlers_sound.lua' {
    inputs = 'src/dependencies/busted/outputHandlers/sound.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/outputHandlers/sound.lua'
}

lm:copy 'copy_busted_outputHandlers_TAP.lua' {
    inputs = 'src/dependencies/busted/outputHandlers/TAP.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/outputHandlers/TAP.lua'
}

lm:copy 'copy_busted_outputHandlers_utfTerminal.lua' {
    inputs = 'src/dependencies/busted/outputHandlers/utfTerminal.lua',
    outputs = 'publish/runtime/win32-x64/lua53/busted/outputHandlers/utfTerminal.lua'
}

-------------------cliargs---------------------------------

lm:copy 'copy_cliargs_config_loader.lua' {
    inputs = 'src/dependencies/cliargs/config_loader.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/config_loader.lua'
}

lm:copy 'copy_cliargs_constants.lua' {
    inputs = 'src/dependencies/cliargs/constants.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/constants.lua'
}

lm:copy 'copy_cliargs_core.lua' {
    inputs = 'src/dependencies/cliargs/core.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/core.lua'
}

lm:copy 'copy_cliargs_parser.lua' {
    inputs = 'src/dependencies/cliargs/parser.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/parser.lua'
}

lm:copy 'copy_cliargs_printer.lua' {
    inputs = 'src/dependencies/cliargs/printer.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/printer.lua'
}

lm:copy 'copy_cliargs_utils_disect.lua' {
    inputs = 'src/dependencies/cliargs/utils/disect.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/utils/disect.lua'
}

lm:copy 'copy_cliargs_utils_disect_argument.lua' {
    inputs = 'src/dependencies/cliargs/utils/disect_argument.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/utils/disect_argument.lua'
}

lm:copy 'copy_cliargs_utils_filter.lua' {
    inputs = 'src/dependencies/cliargs/utils/filter.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/utils/filter.lua'
}

lm:copy 'copy_cliargs_utils_lookup.lua' {
    inputs = 'src/dependencies/cliargs/utils/lookup.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/utils/lookup.lua'
}

lm:copy 'copy_cliargs_utils_shallow_copy.lua' {
    inputs = 'src/dependencies/cliargs/utils/shallow_copy.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/utils/shallow_copy.lua'
}

lm:copy 'copy_cliargs_utils_split.lua' {
    inputs = 'src/dependencies/cliargs/utils/split.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/utils/split.lua'
}

lm:copy 'copy_cliargs_utils_trim.lua' {
    inputs = 'src/dependencies/cliargs/utils/trim.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/utils/trim.lua'
}

lm:copy 'copy_cliargs_utils_wordwrap.lua' {
    inputs = 'src/dependencies/cliargs/utils/wordwrap.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cliargs/utils/wordwrap.lua'
}

-------------------cURL---------------------------------

lm:copy 'copy_cURL_safe.lua' {
    inputs = 'src/dependencies/cURL/safe.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cURL/safe.lua'
}

lm:copy 'copy_cURL_utils.lua' {
    inputs = 'src/dependencies/cURL/utils.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cURL/utils.lua'
}

lm:copy 'copy_cURL_impl_cURL.lua' {
    inputs = 'src/dependencies/cURL/impl/cURL.lua',
    outputs = 'publish/runtime/win32-x64/lua53/cURL/impl/cURL.lua'
}

-------------------depgraph---------------------------------

lm:copy 'copy_depgraph_cli.lua' {
    inputs = 'src/dependencies/depgraph/cli.lua',
    outputs = 'publish/runtime/win32-x64/lua53/depgraph/cli.lua'
}

lm:copy 'copy_depgraph_init.lua' {
    inputs = 'src/dependencies/depgraph/init.lua',
    outputs = 'publish/runtime/win32-x64/lua53/depgraph/init.lua'
}

lm:copy 'copy_depgraph_scan.lua' {
    inputs = 'src/dependencies/depgraph/scan.lua',
    outputs = 'publish/runtime/win32-x64/lua53/depgraph/scan.lua'
}

lm:copy 'copy_depgraph_luacheck_lexer.lua' {
    inputs = 'src/dependencies/depgraph/luacheck/lexer.lua',
    outputs = 'publish/runtime/win32-x64/lua53/depgraph/luacheck/lexer.lua'
}

lm:copy 'copy_depgraph_luacheck_linearize.lua' {
    inputs = 'src/dependencies/depgraph/luacheck/linearize.lua',
    outputs = 'publish/runtime/win32-x64/lua53/depgraph/luacheck/linearize.lua'
}

lm:copy 'copy_depgraph_luacheck_parser.lua' {
    inputs = 'src/dependencies/depgraph/luacheck/parser.lua',
    outputs = 'publish/runtime/win32-x64/lua53/depgraph/luacheck/parser.lua'
}

lm:copy 'copy_depgraph_luacheck_utils.lua' {
    inputs = 'src/dependencies/depgraph/luacheck/utils.lua',
    outputs = 'publish/runtime/win32-x64/lua53/depgraph/luacheck/utils.lua'
}

-------------------luacov---------------------------------

lm:copy 'copy_luacov_defaults.lua' {
    inputs = 'src/dependencies/luacov/defaults.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luacov/defaults.lua'
}

lm:copy 'copy_luacov_hook.lua' {
    inputs = 'src/dependencies/luacov/hook.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luacov/hook.lua'
}

lm:copy 'copy_luacov_linescanner.lua' {
    inputs = 'src/dependencies/luacov/linescanner.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luacov/linescanner.lua'
}

lm:copy 'copy_luacov_reporter.lua' {
    inputs = 'src/dependencies/luacov/reporter.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luacov/reporter.lua'
}

lm:copy 'copy_luacov_runner.lua' {
    inputs = 'src/dependencies/luacov/runner.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luacov/runner.lua'
}

lm:copy 'copy_luacov_stats.lua' {
    inputs = 'src/dependencies/luacov/stats.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luacov/stats.lua'
}

lm:copy 'copy_luacov_tick.lua' {
    inputs = 'src/dependencies/luacov/tick.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luacov/tick.lua'
}

lm:copy 'copy_luacov_util.lua' {
    inputs = 'src/dependencies/luacov/util.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luacov/util.lua'
}

lm:copy 'copy_luacov_reporter_default.lua' {
    inputs = 'src/dependencies/luacov/reporter/default.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luacov/reporter/default.lua'
}

-------------------luasql---------------------------------

lm:copy 'copy_luasql_odbc.dll' {
    inputs = 'src/dependencies/luasql/odbc.dll',
    outputs = 'publish/runtime/win32-x64/lua53/luasql/odbc.dll'
}

-------------------luassert---------------------------------

lm:copy 'copy_luassert_array.lua' {
    inputs = 'src/dependencies/luassert/array.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/array.lua'
}

lm:copy 'copy_luassert_assert.lua' {
    inputs = 'src/dependencies/luassert/assert.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/assert.lua'
}

lm:copy 'copy_luassert_assertions.lua' {
    inputs = 'src/dependencies/luassert/assertions.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/assertions.lua'
}

lm:copy 'copy_luassert_compatibility.lua' {
    inputs = 'src/dependencies/luassert/compatibility.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/compatibility.lua'
}

lm:copy 'copy_luassert_init.lua' {
    inputs = 'src/dependencies/luassert/init.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/init.lua'
}

lm:copy 'copy_luassert_match.lua' {
    inputs = 'src/dependencies/luassert/match.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/match.lua'
}

lm:copy 'copy_luassert_mock.lua' {
    inputs = 'src/dependencies/luassert/mock.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/mock.lua'
}

lm:copy 'copy_luassert_modifiers.lua' {
    inputs = 'src/dependencies/luassert/modifiers.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/modifiers.lua'
}

lm:copy 'copy_luassert_namespaces.lua' {
    inputs = 'src/dependencies/luassert/namespaces.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/namespaces.lua'
}

lm:copy 'copy_luassert_spy.lua' {
    inputs = 'src/dependencies/luassert/spy.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/spy.lua'
}

lm:copy 'copy_luassert_state.lua' {
    inputs = 'src/dependencies/luassert/state.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/state.lua'
}

lm:copy 'copy_luassert_stub.lua' {
    inputs = 'src/dependencies/luassert/stub.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/stub.lua'
}

lm:copy 'copy_luassert_util.lua' {
    inputs = 'src/dependencies/luassert/util.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/util.lua'
}

-------------------luassert_formatters---------------------------------

lm:copy 'copy_luassert_formatters_binarystring.lua' {
    inputs = 'src/dependencies/luassert/formatters/binarystring.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/formatters/binarystring.lua'
}

lm:copy 'copy_luassert_formatters_init.lua' {
    inputs = 'src/dependencies/luassert/formatters/init.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/formatters/init.lua'
}

-------------------luassert_languages---------------------------------

lm:copy 'copy_luassert_languages_ar.lua' {
    inputs = 'src/dependencies/luassert/languages/ar.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/languages/ar.lua'
}

lm:copy 'copy_luassert_languages_de.lua' {
    inputs = 'src/dependencies/luassert/languages/de.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/languages/de.lua'
}

lm:copy 'copy_luassert_languages_en.lua' {
    inputs = 'src/dependencies/luassert/languages/en.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/languages/en.lua'
}

lm:copy 'copy_luassert_languages_fr.lua' {
    inputs = 'src/dependencies/luassert/languages/fr.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/languages/fr.lua'
}

lm:copy 'copy_luassert_languages_is.lua' {
    inputs = 'src/dependencies/luassert/languages/is.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/languages/is.lua'
}

lm:copy 'copy_luassert_languages_ja.lua' {
    inputs = 'src/dependencies/luassert/languages/ja.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/languages/ja.lua'
}

lm:copy 'copy_luassert_languages_nl.lua' {
    inputs = 'src/dependencies/luassert/languages/nl.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/languages/nl.lua'
}

lm:copy 'copy_luassert_languages_ru.lua' {
    inputs = 'src/dependencies/luassert/languages/ru.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/languages/ru.lua'
}

lm:copy 'copy_luassert_languages_ua.lua' {
    inputs = 'src/dependencies/luassert/languages/ua.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/languages/ua.lua'
}

lm:copy 'copy_luassert_languages_zh.lua' {
    inputs = 'src/dependencies/luassert/languages/zh.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/languages/zh.lua'
}

-------------------luassert_matchers---------------------------------

lm:copy 'copy_luassert_matchers_composite.lua' {
    inputs = 'src/dependencies/luassert/matchers/composite.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/matchers/composite.lua'
}

lm:copy 'copy_luassert_matchers_core.lua' {
    inputs = 'src/dependencies/luassert/matchers/core.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/matchers/core.lua'
}

lm:copy 'copy_luassert_matchers_init.lua' {
    inputs = 'src/dependencies/luassert/matchers/init.lua',
    outputs = 'publish/runtime/win32-x64/lua53/luassert/matchers/init.lua'
}

-------------------lxp---------------------------------

lm:copy 'copy_lxp_lom.lua' {
    inputs = 'src/dependencies/lxp/lom.lua',
    outputs = 'publish/runtime/win32-x64/lua53/lxp/lom.lua'
}

lm:copy 'copy_lxp_threat.lua' {
    inputs = 'src/dependencies/lxp/threat.lua',
    outputs = 'publish/runtime/win32-x64/lua53/lxp/threat.lua'
}

lm:copy 'copy_lxp_totable.lua' {
    inputs = 'src/dependencies/lxp/totable.lua',
    outputs = 'publish/runtime/win32-x64/lua53/lxp/totable.lua'
}

-------------------mime---------------------------------

lm:copy 'copy_mime_core.dll' {
    inputs = 'src/dependencies/mime/core.dll',
    outputs = 'publish/runtime/win32-x64/lua53/mime/core.dll'
}

-------------------pl---------------------------------

lm:copy 'copy_pl_app.lua' {
    inputs = 'src/dependencies/pl/app.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/app.lua'
}

lm:copy 'copy_pl_array2d.lua' {
    inputs = 'src/dependencies/pl/array2d.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/array2d.lua'
}

lm:copy 'copy_pl_class.lua' {
    inputs = 'src/dependencies/pl/class.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/class.lua'
}

lm:copy 'copy_pl_compat.lua' {
    inputs = 'src/dependencies/pl/compat.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/compat.lua'
}

lm:copy 'copy_pl_comprehension.lua' {
    inputs = 'src/dependencies/pl/comprehension.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/comprehension.lua'
}

lm:copy 'copy_pl_config.lua' {
    inputs = 'src/dependencies/pl/config.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/config.lua'
}

lm:copy 'copy_pl_data.lua' {
    inputs = 'src/dependencies/pl/data.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/data.lua'
}

lm:copy 'copy_pl_Date.lua' {
    inputs = 'src/dependencies/pl/Date.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/Date.lua'
}

lm:copy 'copy_pl_dir.lua' {
    inputs = 'src/dependencies/pl/dir.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/dir.lua'
}

lm:copy 'copy_pl_file.lua' {
    inputs = 'src/dependencies/pl/file.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/file.lua'
}

lm:copy 'copy_pl_func.lua' {
    inputs = 'src/dependencies/pl/func.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/func.lua'
}

lm:copy 'copy_pl_import_into.lua' {
    inputs = 'src/dependencies/pl/import_into.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/import_into.lua'
}

lm:copy 'copy_pl_init.lua' {
    inputs = 'src/dependencies/pl/init.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/init.lua'
}

lm:copy 'copy_pl_input.lua' {
    inputs = 'src/dependencies/pl/input.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/input.lua'
}

lm:copy 'copy_pl_lapp.lua' {
    inputs = 'src/dependencies/pl/lapp.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/lapp.lua'
}

lm:copy 'copy_pl_lexer.lua' {
    inputs = 'src/dependencies/pl/lexer.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/lexer.lua'
}

lm:copy 'copy_pl_List.lua' {
    inputs = 'src/dependencies/pl/List.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/List.lua'
}

lm:copy 'copy_pl_luabalanced.lua' {
    inputs = 'src/dependencies/pl/luabalanced.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/luabalanced.lua'
}

lm:copy 'copy_pl_Map.lua' {
    inputs = 'src/dependencies/pl/Map.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/Map.lua'
}

lm:copy 'copy_pl_MultiMap.lua' {
    inputs = 'src/dependencies/pl/MultiMap.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/MultiMap.lua'
}

lm:copy 'copy_pl_operator.lua' {
    inputs = 'src/dependencies/pl/operator.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/operator.lua'
}

lm:copy 'copy_pl_OrderedMap.lua' {
    inputs = 'src/dependencies/pl/OrderedMap.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/OrderedMap.lua'
}

lm:copy 'copy_pl_path.lua' {
    inputs = 'src/dependencies/pl/path.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/path.lua'
}

lm:copy 'copy_pl_permute.lua' {
    inputs = 'src/dependencies/pl/permute.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/permute.lua'
}

lm:copy 'copy_pl_pretty.lua' {
    inputs = 'src/dependencies/pl/pretty.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/pretty.lua'
}

lm:copy 'copy_pl_seq.lua' {
    inputs = 'src/dependencies/pl/seq.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/seq.lua'
}

lm:copy 'copy_pl_Set.lua' {
    inputs = 'src/dependencies/pl/Set.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/Set.lua'
}

lm:copy 'copy_pl_sip.lua' {
    inputs = 'src/dependencies/pl/sip.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/sip.lua'
}

lm:copy 'copy_pl_strict.lua' {
    inputs = 'src/dependencies/pl/strict.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/strict.lua'
}

lm:copy 'copy_pl_stringio.lua' {
    inputs = 'src/dependencies/pl/stringio.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/stringio.lua'
}

lm:copy 'copy_pl_stringx.lua' {
    inputs = 'src/dependencies/pl/stringx.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/stringx.lua'
}

lm:copy 'copy_pl_tablex.lua' {
    inputs = 'src/dependencies/pl/tablex.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/tablex.lua'
}

lm:copy 'copy_pl_template.lua' {
    inputs = 'src/dependencies/pl/template.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/template.lua'
}

lm:copy 'copy_pl_test.lua' {
    inputs = 'src/dependencies/pl/test.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/test.lua'
}

lm:copy 'copy_pl_text.lua' {
    inputs = 'src/dependencies/pl/text.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/text.lua'
}

lm:copy 'copy_pl_types.lua' {
    inputs = 'src/dependencies/pl/types.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/types.lua'
}

lm:copy 'copy_pl_url.lua' {
    inputs = 'src/dependencies/pl/url.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/url.lua'
}

lm:copy 'copy_pl_utils.lua' {
    inputs = 'src/dependencies/pl/utils.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/utils.lua'
}

lm:copy 'copy_pl_xml.lua' {
    inputs = 'src/dependencies/pl/xml.lua',
    outputs = 'publish/runtime/win32-x64/lua53/pl/xml.lua'
}

-------------------say---------------------------------

lm:copy 'copy_say_init.lua' {
    inputs = 'src/dependencies/say/init.lua',
    outputs = 'publish/runtime/win32-x64/lua53/say/init.lua'
}

-------------------socket---------------------------------

lm:copy 'copy_socket_core.dll' {
    inputs = 'src/dependencies/socket/core.dll',
    outputs = 'publish/runtime/win32-x64/lua53/socket/core.dll'
}

lm:copy 'copy_socket_ftp.lua' {
    inputs = 'src/dependencies/socket/ftp.lua',
    outputs = 'publish/runtime/win32-x64/lua53/socket/ftp.lua'
}

lm:copy 'copy_socket_headers.lua' {
    inputs = 'src/dependencies/socket/headers.lua',
    outputs = 'publish/runtime/win32-x64/lua53/socket/headers.lua'
}

lm:copy 'copy_socket_http.lua' {
    inputs = 'src/dependencies/socket/http.lua',
    outputs = 'publish/runtime/win32-x64/lua53/socket/http.lua'
}

lm:copy 'copy_socket_smtp.lua' {
    inputs = 'src/dependencies/socket/smtp.lua',
    outputs = 'publish/runtime/win32-x64/lua53/socket/smtp.lua'
}

lm:copy 'copy_socket_tp.lua' {
    inputs = 'src/dependencies/socket/tp.lua',
    outputs = 'publish/runtime/win32-x64/lua53/socket/tp.lua'
}

lm:copy 'copy_socket_url.lua' {
    inputs = 'src/dependencies/socket/url.lua',
    outputs = 'publish/runtime/win32-x64/lua53/socket/url.lua'
}

-------------------ssl---------------------------------

lm:copy 'copy_ssl_https.lua' {
    inputs = 'src/dependencies/ssl/https.lua',
    outputs = 'publish/runtime/win32-x64/lua53/ssl/https.lua'
}

-------------------syslib---------------------------------

lm:copy 'copy_syslib_config.lua' {
    inputs = 'src/dependencies/syslib/config.lua',
    outputs = 'publish/runtime/win32-x64/lua53/syslib/config.lua'
}

lm:copy 'copy_syslib_model.lua' {
    inputs = 'src/dependencies/syslib/model.lua',
    outputs = 'publish/runtime/win32-x64/lua53/syslib/model.lua'
}

-------------------system---------------------------------

lm:copy 'copy_system_core.dll' {
    inputs = 'src/dependencies/system/core.dll',
    outputs = 'publish/runtime/win32-x64/lua53/system/core.dll'
}

lm:copy 'copy_system_init.lua' {
    inputs = 'src/dependencies/system/init.lua',
    outputs = 'publish/runtime/win32-x64/lua53/system/init.lua'
}

-------------------term---------------------------------

lm:copy 'copy_term_color.lua' {
    inputs = 'src/dependencies/term/colors.lua',
    outputs = 'publish/runtime/win32-x64/lua53/term/color.lua'
}

lm:copy 'copy_term_core.dll' {
    inputs = 'src/dependencies/term/core.dll',
    outputs = 'publish/runtime/win32-x64/lua53/term/core.dll'
}

lm:copy 'copy_term_cursor.lua' {
    inputs = 'src/dependencies/term/cursor.lua',
    outputs = 'publish/runtime/win32-x64/lua53/term/cursor.lua'
}

lm:copy 'copy_term_init.lua' {
    inputs = 'src/dependencies/term/init.lua',
    outputs = 'publish/runtime/win32-x64/lua53/term/init.lua'
}