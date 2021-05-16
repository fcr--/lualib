local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local SortedDict = require 'lualib.struct.sorteddict'

local SortedDictTest = oo.class(BaseTest)


function SortedDictTest:test_empty()
  local sd = SortedDict:new()
  self:assert_deep_equal({}, sd:keys())
  self:assert_deep_equal({}, sd:values())
  self:assert_deep_equal({}, sd:items())
  local count = 0
  for k, v in sd:pairs() do count = count + 1 end
  self:assert_equal(count, 0)
  self:assert_nil(sd:get 'k')
end


function SortedDictTest:test_single()
  local sd = SortedDict:new()
  for _, v in ipairs{'v1', 'v2'} do
    sd:set('k', v)
    self:assert_equal(v, sd:get 'k')
    self:assert_deep_equal({'k'}, sd:keys())
    self:assert_deep_equal({v}, sd:values())
    self:assert_deep_equal({{k='k', v=v}}, sd:items())
  end
  self:assert_nil(sd:get 'x')
end


function SortedDictTest:test_set_del()
  local sd = SortedDict:new()
  local shuffled = 'qzapiyemhxwvdjrnlfgcstukob123456789'
  local chars = {}
  for c in shuffled:gmatch '.' do
    sd:set(c, c)
    chars[#chars+1] = c
    table.sort(chars)
    self:assert_deep_equal(chars, sd:keys())
    self:assert_deep_equal(chars, sd:values())
  end
  for c in shuffled:gmatch '.' do
    for i = 1, #chars do if chars[i] == c then table.remove(chars, i) break end end
    local oldvalue = sd:del(c)
    self:assert_equal(oldvalue, c)
    self:assert_deep_equal(chars, sd:keys())
    self:assert_deep_equal(chars, sd:values())
  end
end


local function check_balanced(t)
  if not t then return 0 end
  local h1, h2 = check_balanced(t[1]), check_balanced(t[2])
  assert(math.abs(h1 - h2) <= 1)
  return math.max(h1, h2)
end


function SortedDictTest:test_balanced()
  local shuffled = 'qzapiyemhxwvdjrnlfgcstukob123456789'
  local sd = SortedDict:new()
  for c in shuffled:gmatch '.' do
    sd:set(c, 1)
    check_balanced(sd.root)
  end
  for c in shuffled:gmatch '.' do
    sd:del(c)
    check_balanced(sd.root)
  end
end


function SortedDictTest:test_clone()
  -- TODO: implement
end


SortedDictTest:run_if_main()


return SortedDictTest
