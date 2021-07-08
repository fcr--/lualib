--[[
#Base class for simple Unit Testing

Example to start with:

    local BaseTest = require 'lualib.basetest'
    local oo = require 'lualib.oo'

    local MyTest = oo.class(BaseTest)

    function MyTest:test_something()
      self:assert_equal(42, tonumber '42')
      self:assert_nil(('y'):match 'x')
      self:assert_not_nil(42)
      self:assert_type(self.assert_type, 'function')
      self:assert_deep_equal({42, b={117, ''}}, {42, b={117, ''}})
    end

    ... -- add more tests

    MyTest:run_if_main()

    return MyTest
]]

local oo = require 'lualib.oo'


local BaseTest = oo.class()


-- class method:
function BaseTest:run_all_tests(opts)
  -- runs all the test in the class (including superclasses) plus all tests in the linked_classes
  local cls = self -- self must be a BaseTest subclass (not an instance),
  local method_names_set = {}

  while cls ~= nil do
    -- metatables' indexes must be tables for
    local index = rawget(cls, '__index')
    if type(index) ~= 'table' then break end

    for name, fun in pairs(index) do
      if type(name) == 'string' and name:match'^test_' and type(fun) == 'function' then
        method_names_set[name] = true
      end
    end
    cls = getmetatable(index)
  end

  local method_names = {}
  for name in pairs(method_names_set) do
    method_names[#method_names + 1] = name
  end

  local results = self:run_tests_named(opts, (unpack or table.unpack)(method_names))

  local subopts = opts.skip_summary and opts or setmetatable({skip_summary=true}, {__index=opts})
  for _, cls in ipairs(self._linked_classes or {}) do
    for _, res in ipairs(cls:run_all_tests(subopts)) do
      results[#results + 1] = res
    end
  end

  if not opts.skip_summary then
    local error_count = 0
    local groups = {} -- short_src -> List<res>
    local short_src_list = {} -- List<short_src: str>
    for _, res in ipairs(results) do
      if res.exception then
        error_count = error_count + 1
        local group = groups[res.short_src]
        if group then group[#group+1] = res.method_name else
          groups[res.short_src] = {res.method_name}
          short_src_list[#short_src_list + 1] = res.short_src
        end
      end
    end
    table.sort(short_src_list)

    if error_count == 0 then
      print(('\n\27[1;32m%d tests run total, 0 errors!\27[0m'):format(#results))
    else
      print(('\n\27[1;31m%d tests run total, %d errors:\27[0m'):format(#results, error_count))
      for _, short_src in ipairs(short_src_list) do
        print(('  %s: %s'):format(short_src, table.concat(groups[short_src], ', ')))
      end
    end
  end

  return results
end


-- class method:
function BaseTest:run_tests_named(opts, ...)
  local results = {} -- list of errors

  -- takes a list of method names
  self:setup_class()

  local instance = self:new()
  for i = 1, select('#', ...) do
    local method_name = select(i, ...)

    instance:setup()

    local func = instance[method_name]
    local co = coroutine.create(func)
    local finished, ret = coroutine.resume(co, instance)

    local res = {
      method_name = method_name,
      short_src = debug.getinfo(func, 'S').short_src, -- filename in most cases
    }
    if not finished then
      -- the coroutine yielded or threw an error, either way the value goes into ret
      res.exception = ret
      res.traceback = debug.traceback(co)
      print(('on %s(%s):'):format(res.short_src, method_name))
      print(('\27[31;1m%s\27[0m\n%s'):format(
        tostring(res.exception):gsub('\n', '\27[0m\n\27[31;1m'),
        res.traceback
      ))
    end
    results[#results + 1] = res

    instance:cleanup()
  end

  self:cleanup_class()
  return results
end


-- class method:
function BaseTest:run_if_main()
  -- Helper that calls self:run_all_tests if the test file is executed directly.
  -- Additionally it will make the program exit with an error code if there were failed tests.
  local function require_was_found()
    for i = 3, 1000000 do
      local info = debug.getinfo(i, 'f')
      if info == nil then return false end -- running as main
      if info.func == require then return true end -- this is being loaded as a module
    end
    error 'Too deeply nested, this probably means run_if_main is broken'
  end

  -- being called from the main script means require is not in the stack trace
  if not require_was_found() then
    for _, res in ipairs(self:run_all_tests{}) do
      if res.exception then os.exit(1) end
    end
  end
end


-- class method:
function BaseTest:link_class(cls)
  local linked_classes = self._linked_classes
  assert(type(cls) == 'table')
  if linked_classes then
    linked_classes[#linked_classes + 1] = cls
  else
    self._linked_classes = {cls}
  end
  return self
end


-- class method:
function BaseTest:setup_class()
  -- run once before the execution of a set of methods of a class
end


-- class method:
function BaseTest:cleanup_class()
  -- run once after all of methods of the class were executed
end


function BaseTest:setup()
  -- run before calling each test_* method
end


function BaseTest:cleanup()
  -- run after calling each test_* method
end


function BaseTest:assert_equal(x, y)
  if x ~= y then
    error(('expected %s == %s'):format(x, y))
  end
end


function BaseTest:assert_nil(x)
  if x ~= nil then
    error(('expected not nil but received %s: %q'):format(type(x), x))
  end
end


function BaseTest:assert_not_equal(x, y)
  if x == y then
    error(('expected %s == %s'):format(x, y))
  end
end


function BaseTest:assert_not_nil(x)
  if x == nil then
    error(('expected not nil but received %s: %q'):format(type(x), x))
  end
end


function BaseTest:assert_type(x, typ)
  assert(({['nil']=1, number=1, string=1, boolean=1, table=1, ['function']=1, thread=1, userdata=1})[typ])
  if type(x) ~= typ then
    error(('expected %s but received %s: %q'):format(typ, type(x), x))
  end
end


local SetMark = {}


-- static method:
function BaseTest.create_set(name, matches)
  -- use this function to create your own set of elements to check by assert_deep_equal
  return setmetatable({name=name, matches=matches}, SetMark)
end


BaseTest.any = BaseTest.create_set('any value', function() return true end)
for _, t in ipairs{'string', 'function', 'number', 'table', 'boolean', 'thread', 'userdata'} do
  BaseTest['any_'..t] = BaseTest.create_set('any '..t, function(v) return type(v) == t end)
end
BaseTest.any_integer = BaseTest.create_set(
  'any integer', function(v) return type(v) == 'number' and math.floor(v) == v and v ~= v+1 end
)


function BaseTest:assert_deep_equal(x, y, path, inspected, diffs)
  if not path then
    path = {} -- Stack<string>
    inspected = {} -- Set<table>
    diffs = {} -- List<string>
  end
  local function add_diff(fmt, ...)
    diffs[#diffs + 1] = ('  %s: ' .. fmt):format(table.concat(path, '.'), ...)
  end
  if getmetatable(y) == SetMark then x,y=y,x end
  if getmetatable(x) == SetMark then
    if not x.matches(y) then
      add_diff('expecting %s, found %s: %s', x.name, type(y), y)
    end
  elseif type(x) ~= type(y) then
    add_diff('different types: %s %s', type(x), type(y))
  elseif type(x) == 'table' then
    if not inspected[x] or not inspected[y] then
      inspected[x] = true
      inspected[y] = true
      if getmetatable(x) ~= getmetatable(y) then
        add_diff('different metatables: %s %s', getmetatable(x), getmetatable(y))
      end
      local inspected_keys = {} -- Set<keys>
      local depth = #path + 1
      for k, v in pairs(x) do
        inspected_keys[k] = true
        path[depth] = k
        self:assert_deep_equal(v, y[k], path, inspected, diffs)
      end
      for k, v in pairs(y) do
        if not inspected_keys[k] then
          path[depth] = k
          self:assert_deep_equal(x[k], v, path, inspected, diffs)
        end
      end
      path[depth] = nil
      inspected[x] = nil
      inspected[y] = nil
    end
  elseif x ~= y then
    add_diff('different %s: %s ~= %s', type(x), x, y)
  end
  if #path == 0 and #diffs > 0 then
    error(('%d difference%s found:\n'):format(#diffs, #diffs>1 and 's' or '') .. table.concat(diffs, '\n'))
  end
end


return BaseTest
