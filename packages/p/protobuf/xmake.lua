package("protobuf", function()
    set_homepage("https://developers.google.com/protocol-buffers/")
    set_description("Google's data interchange format for cpp")

    add_urls("https://github.com/protocolbuffers/protobuf/releases/download/v$(version)/protobuf-cpp-$(version).zip")

    add_versions("21.7", "87f3265aac463cbca6ca5c23a52a75aebbf645c986f521e68c13259d138b2874")

    add_configs("zlib", {description = "Enable zlib", default = true, type = "boolean"})

    add_deps("cmake")

    add_links("protobuf", "pthread")

    on_load(function (package)
        package:addenv("PATH", "bin")
        if package:config("zlib") then
            package:add("deps", "zlib")
        end
    end)

    on_install(function (package)
        os.cd("cmake")
        io.replace("CMakeLists.txt", "set(protobuf_DEBUG_POSTFIX \"d\"", "set(protobuf_DEBUG_POSTFIX \"\"", {plain = true})
        local configs = {"-Dprotobuf_BUILD_TESTS=OFF", "-Dprotobuf_BUILD_PROTOC_BINARIES=ON"}
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        if package:config("zlib") then
            table.insert(configs, "-Dprotobuf_WITH_ZLIB=ON")
        end
        import("package.tools.cmake").install(package, configs, {buildir = "build"})
        os.trycp("build/Release/protoc.exe", package:installdir("bin"))
    end)

    on_test(function (package)
        if package:is_cross() then
            return
        end
        io.writefile("test.proto", [[
            syntax = "proto3";
            package test;
            message TestCase {
                string name = 4;
            }
            message Test {
                repeated TestCase case = 1;
            }
        ]])
        os.vrun("protoc test.proto --cpp_out=.")
        assert(package:check_cxxsnippets({test = io.readfile("test.pb.cc")}, {configs = {includedirs = {".", package:installdir("include")}, languages = "c++11"}}))
    end)
end)