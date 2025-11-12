-- NekoLog: An easy-to-use, modern, lightweight, and efficient C++20 logging library
package("nekolog")
    set_homepage("https://github.com/moehoshio/NekoLog")
    set_description("An easy-to-use, modern, lightweight, and efficient C++20 logging library")
    set_license("MIT OR Apache-2.0")

    set_urls("https://github.com/moehoshio/NekoLog/archive/refs/tags/v$(version).tar.gz",
             "https://github.com/moehoshio/NekoLog.git")

    add_versions("1.0.0", "5FAD6EBF1C117FA68831F9D70110F5A3F5EAAC6C3DD00F002D8FE434AB2C5B65")

    add_configs("modules", {description = "Enable C++20 modules support", default = false, type = "boolean"})
    add_configs("tests", {description = "Build tests", default = false, type = "boolean"})

    add_deps("cmake")
    -- NekoSchema dependency will be fetched via FetchContent until it's published to xmake-repo
    -- Uncomment when NekoSchema is available:
    -- add_deps("nekoschema")

    on_install(function (package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DNEKO_LOG_BUILD_TESTS=" .. (package:config("tests") and "ON" or "OFF"))
        table.insert(configs, "-DNEKO_LOG_USE_MODULES=" .. (package:config("modules") and "ON" or "OFF"))
        -- Enable auto-fetch to get NekoSchema via FetchContent
        table.insert(configs, "-DNEKO_LOG_AUTO_FETCH_DEPS=ON")
        
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <neko/log/nlog.hpp>
            void test() {
                neko::log::info("Hello, NekoLog!");
            }
        ]]}, {configs = {languages = "c++20"}}))
    end)
