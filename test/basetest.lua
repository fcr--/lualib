local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'

local BaseTestTest = oo.class(BaseTest)


-- Testing basic functionality without using the testing framework itself.
do
  local tested = false
  local BasicBaseTestTest = oo.class(BaseTest)
  function BasicBaseTestTest:test_something()
    tested = true
  end
  local results = BasicBaseTestTest:run_all_tests{skip_summary=true}
  if not tested then error 'BaseTest testing framework is broken' end
  if #results ~= 1 then error('expected 1 result, received '..#results) end
  if results[1].method_name ~= 'test_something' then
    error(('expected method_name == test_something, it was: %s')):format(results[1].method_name)
  end
  if results[1].exception then
    error(('unexpected exception on test_something: %s'):format(results[1].exception))
  end
end


function BaseTestTest:test_assert_equal()
  self:assert_equal(3, 3)
  self:assert_equal('x', 'x')
  local ok, err = pcall(self.assert_equal, self, 3, 4)
  if ok then error '3 is not equal to 4' end
  self:assert_equal(err:match 'expected 3 == 4' ~= nil, true)
end


function BaseTestTest:test_assert_error()
  local ok, err
  err = self:assert_error(error, 'foo')
  self:assert_equal(err, 'foo')

  ok, err = pcall(self.assert_error, self, function()end)
  self:assert_equal(ok, false)
  self:assert_pattern(err, 'expected an error')

  ok, err = pcall(self.assert_error, self, 'not a function')
  self:assert_equal(ok, false)
  self:assert_pattern(err, 'invalid callable type')
end


function BaseTestTest:test_add_cleanup()
  local SampleTest = oo.class(BaseTest)
  local actions = {}
  local function old_cleanup(_self) end
  SampleTest.cleanup = old_cleanup
  function SampleTest:test_cleanup_after_success()
    self:add_cleanup(function() actions[#actions+1] = 'cs1' end)
    self:add_cleanup(function() actions[#actions+1] = 'cs2' end)
    actions[#actions+1] = 's'
  end
  function SampleTest:test_cleanup_after_failure()
    self:add_cleanup(function() actions[#actions+1] = 'cf1' end)
    self:add_cleanup(function() actions[#actions+1] = 'cf2' end)
    actions[#actions+1] = 'f'
    error 'failure'
  end
  local results = SampleTest:run_all_tests{skip_summary=true, skip_print_exceptions=true}

  local s = table.concat(actions, ',')
  self:assert_equal(s == 's,cs2,cs1,f,cf2,cf1' or s == 'f,cf2,cf1,s,cs2,cs1', true)
  self:assert_equal(#results, 2)
  -- ensure cleanup is restored to its old value:
  -- (hint: it's being modified by the add_cleanup method)
  self:assert_equal(SampleTest.cleanup, old_cleanup)
end


do
  local PatchGlobalBaseTestTest = oo.class(BaseTest)
  local patch_global_calls = {}
  function PatchGlobalBaseTestTest:patch_attribute(...)
    table.insert(patch_global_calls, {...})
  end

  function PatchGlobalBaseTestTest:test_patch_global()
    self:patch_global('foo', 42)
    self:assert_equal(#patch_global_calls, 1)
    self:assert_equal(patch_global_calls[1][1], _G)
    self:assert_equal(patch_global_calls[1][2], 'foo')
    self:assert_equal(patch_global_calls[1][3], 42)
  end

  BaseTestTest:link_class(PatchGlobalBaseTestTest)
end


function BaseTestTest:test_patch_attribute()
  local SampleTest = oo.class(BaseTest)
  local t = {name='old value'}
  local starting_dirty, not_patched = {}, {}
  function SampleTest:test_patch_global_success()
    if t.name == 'new value' then table.insert(starting_dirty, 'on success') end
    self:patch_attribute(t, 'name', 'new value')
    if t.name ~= 'new value' then table.insert(not_patched, 'on success') end
  end
  function SampleTest:test_patch_global_failure()
    if t.name == 'new value' then table.insert(starting_dirty, 'on failure') end
    self:patch_attribute(t, 'name', 'new value')
    if t.name ~= 'new value' then table.insert(not_patched, 'on failure') end
    error 'failure'
  end

  local results = SampleTest:run_all_tests{skip_summary=true, skip_print_exceptions=true}
  self:assert_equal(#results, 2)
  self:assert_equal(t.name, 'old value')
  if #starting_dirty ~= 0 then
    error(('starting dirty %s'):format(table.concat(starting_dirty, ' and ')))
  end
  if #not_patched ~= 0 then
    error(('not patched %s'):format(table.concat(not_patched, ' nor ')))
  end
end


function BaseTestTest:test_patch_upvar()
  local SampleTest = oo.class(BaseTest)
  local foo, xyz = 42, nil
  local function f()
    return foo, xyz
  end

  local starting_dirty, not_patched = {}, {}
  function SampleTest:test_patch_upvar_success()
    if foo ~= 42 then table.insert(starting_dirty, 'on success') end
    self:patch_upvar(f, 'foo', 43)
    if foo ~= 43 then table.insert(not_patched, 'on success') end
    self:patch_upvar(f, 'foo', 44)
    if foo ~= 44 then table.insert(not_patched, 'on success') end
  end
  function SampleTest:test_patch_global_failure()
    if foo ~= 42 then table.insert(starting_dirty, 'on failure') end
    self:patch_upvar(f, 'foo', 43)
    if foo ~= 43 then table.insert(not_patched, 'on failure') end
    error 'failure'
  end

  local results = SampleTest:run_all_tests{skip_summary=true, skip_print_exceptions=true}
  self:assert_equal(#results, 2)
  self:assert_equal(foo, 42)
  if #starting_dirty ~= 0 then
    error(('starting dirty %s'):format(table.concat(starting_dirty, ' and ')))
  end
  if #not_patched ~= 0 then
    error(('not patched %s'):format(table.concat(not_patched, ' nor ')))
  end

  local ok, err = pcall(self.patch_upvar, self, f, 'bar', 43)
  self:assert_equal(ok, false)
  self:assert_equal(
    err:match 'upvar named bar was not found, try with: foo, xyz' and true or
    err:match 'upvar named bar was not found, try with: xyz, foo' and true, true)
end


BaseTestTest:run_if_main()


return BaseTestTest
