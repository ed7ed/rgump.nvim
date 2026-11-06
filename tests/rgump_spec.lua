local root_dir = vim.fn.getcwd() .. "/tests/data"
local rgump = require("rgump.core")

-- Mock the plenary assert since plenary provides it in its busted environment
-- Actually plenary.busted injects `assert` globally into the test scope!

describe("RGump Core", function()
  -- local root_dir
  local test_ex = root_dir .. "/test.ex"
  local test_erl = root_dir .. "/test.erl"

  describe("Elixir", function()
    it("finds a standard function definition", function()
      local results = rgump.find("test", test_ex, root_dir, 0)
      assert.are.same(1, #results, "Should find exactly 1 function definition")
      assert.are.same(3, results[1].lnum)
      assert.truthy(results[1].text:match("def test%(foo, bar%) do"))
    end)

    it("ignores commented-out function definitions", function()
      local results = rgump.find("test", test_ex, root_dir, 0)
      for _, r in ipairs(results) do
        assert.is_not.same(2, r.lnum, "Should ignore commented line 2")
      end
    end)

    it("finds variable assignments", function()
      local results = rgump.find("test_var", test_ex, root_dir, 0)
      assert.are.same(1, #results)
      assert.truthy(results[1].text:match("test_var = 1234"))
    end)

    it("finds modules (alias)", function()
      local results = rgump.find("Test", test_ex, root_dir, 0)
      assert.are.same(1, #results)
      assert.truthy(results[1].text:match("defmodule Test do"))
    end)

    it("finds macros", function()
      local results = rgump.find("my_macro", test_ex, root_dir, 0)
      -- test_macro.ex has 1, test.ex has 1
      assert.are.same(2, #results)
    end)

    it("finds delegated functions", function()
      local results = rgump.find("my_delegated_func", test_ex, root_dir, 0)
      assert.are.same(1, #results)
      assert.truthy(results[1].text:match("defdelegate my_delegated_func"))
    end)

    it("finds guards", function()
      local results = rgump.find("is_my_guard", test_ex, root_dir, 0)
      assert.are.same(1, #results)
      assert.truthy(results[1].text:match("defguard is_my_guard"))
    end)

    it("does not find non-existent symbols", function()
      local results = rgump.find("i_do_not_exist", test_ex, root_dir, 0)
      assert.are.same(0, #results)
    end)
  end)

  describe("Erlang", function()
    it("finds function definitions", function()
      local results = rgump.find("test", test_erl, root_dir, 0)
      -- In Erlang tests it finds 4 matches for 'test' across module/function
      assert.are.same(4, #results)
    end)

    it("ignores commented-out lines", function()
      local results = rgump.find("test_var", test_erl, root_dir, 0)
      assert.are.same(1, #results, "Should find 1 variable, ignoring the commented one")
      assert.truthy(results[1].text:match("test_var = 1234"))
    end)
  end)
end)

describe("Integration Tests (Full Test Data suite)", function()
  local proj1 = root_dir .. "/proj1"
  local proj3 = root_dir .. "/proj3-clj"

  local function assert_find(word, file, root, expected_text)
    local res = rgump.find(word, file, root, 0)
    assert.truthy(#res > 0, "Expected to find at least one match for " .. word)
    if expected_text then
      local found = false
      for _, r in ipairs(res) do
        if r.text:match(expected_text) then
          found = true
        end
      end
      assert.truthy(found, "Expected match to contain text: " .. expected_text)
    end
  end

  it("finds JavaScript symbols", function()
    assert_find("doSomeStuff", proj1 .. "/src/js/fake.js", proj1, "function doSomeStuff")
    assert_find("resized", proj1 .. "/src/js/fake.js", proj1, "%$scope.resized = function")
    assert_find("MyComponent", proj1 .. "/src/js/react.js", proj1, "class MyComponent")
  end)

  it("finds PHP symbols", function()
    assert_find("label", proj1 .. "/src/php/php8.php", proj1, "function label")
    assert_find("getId", proj1 .. "/src/php/php8.php", proj1, "function getId")
  end)

  it("finds C++ symbols", function()
    assert_find("Foo", proj1 .. "/src/cpp/test.cpp", proj1, "class Foo")
    assert_find("bar", proj1 .. "/src/cpp/test.cpp", proj1, "int bar")
    assert_find("ExternalThing", proj1 .. "/src/cpp/external.h", proj1, "class ExternalThing")
  end)

  it("finds Org-mode blocks", function()
    assert_find("myblock", proj1 .. "/src/org/named-blocks.org", proj1, "#%+name: myblock")
  end)

  it("finds Clojure symbols", function()
    assert_find("blah", proj3 .. "/file1.clj", proj3, "defn blah")
    assert_find("foo*", proj3 .. "/file1.clj", proj3, "defn%- foo%*")
  end)
end)
