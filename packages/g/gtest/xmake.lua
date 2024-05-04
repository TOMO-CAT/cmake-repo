package("gtest", function()
    set_homepage("https://github.com/google/googletest")
    set_description("Google Testing and Mocking Framework.")
    set_license("BSD-3")

    add_urls("https://github.com/google/googletest/archive/refs/tags/$(version).zip", {alias = "archive"})

    add_versions("v1.13.0", "ffa17fbc5953900994e2deec164bb8949879ea09b411e07f215bfbb1f87f4632")

    add_configs("main",  {description = "Link to the gtest_main entry point.", default = false, type = "boolean"})
    add_configs("gmock", {description = "Link to the googlemock library.", default = true, type = "boolean"})

    if is_plat("linux") then
        add_syslinks("pthread")
    end

    on_install(function (package)
        io.writefile("xmake.lua", [[
            target("gtest")
                set_kind("static")
                set_languages("cxx14")
                add_files("googletest/src/gtest-all.cc")
                add_includedirs("googletest/include", "googletest")
                add_headerfiles("googletest/include/(**.h)")

            target("gtest_main")
                set_kind("static")
                set_languages("cxx14")
                set_default(]] .. tostring(package:config("main")) .. [[)
                add_files("googletest/src/gtest_main.cc")
                add_includedirs("googletest/include", "googletest")
                add_headerfiles("googletest/include/(**.h)")

            target("gmock")
                set_kind("static")
                set_languages("cxx14")
                set_default(]] .. tostring(package:config("gmock")) .. [[)
                add_files("googlemock/src/gmock-all.cc")
                add_includedirs("googlemock/include", "googlemock", "googletest/include", "googletest")
                add_headerfiles("googlemock/include/(**.h)")
        ]])
        import("package.tools.xmake").install(package)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            int factorial(int number) { return number <= 1 ? number : factorial(number - 1) * number; }
            TEST(FactorialTest, Zero) {
              testing::InitGoogleTest(0, (char**)0);
              EXPECT_EQ(1, factorial(1));
              EXPECT_EQ(2, factorial(2));
              EXPECT_EQ(6, factorial(3));
              EXPECT_EQ(3628800, factorial(10));
            }
        ]]}, {configs = {languages = "c++14"}, includes = "gtest/gtest.h"}))

        if package:config("gmock") then
            assert(package:check_cxxsnippets({test = [[
                using ::testing::AtLeast;

                class A {
                public:
                    virtual void a_foo() { return; }
                };

                class mock_A : public A {
                public:
                    MOCK_METHOD0(a_foo, void());
                };

                class B {
                public:
                    A* target;
                    B(A* param) : target(param) {}

                    bool b_foo() { target->a_foo(); return true; }
                };

                TEST(test_code, step1) {
                    mock_A a_obj;
                    B b_obj(&a_obj);

                    EXPECT_CALL(a_obj, a_foo()).Times(AtLeast(1));

                    EXPECT_TRUE(b_obj.b_foo());
                }
            ]]}, {configs = {languages = "c++14"}, includes = {"gtest/gtest.h", "gmock/gmock.h"}}))
        end
    end)
end)
