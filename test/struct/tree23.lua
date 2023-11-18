local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local empty = require 'lualib.struct.tree23'

local Tree23Test = oo.class(BaseTest)

local empty_mt = getmetatable(empty)
local two_mt = getmetatable(empty:set(1))
local three_mt = getmetatable(empty:set(1):set(2))

function Tree23Test:test_empty()
   self:assert_not_nil(empty_mt)
   for k in ('ak av bk bv p q r'):gmatch '%S+' do
      self:assert_nil(empty[k])
   end
   self:assert_nil(empty:getkv 'k')
   self:assert_nil(empty:get 'k')
   self:assert_equal(false, empty:has 'k')
   local call_count = 0
   empty:visit(call_count)
   self:assert_equal(0, call_count)
   self:assert_deep_equal({}, empty:keys())
   self:assert_deep_equal({}, empty:values())
   self:assert_deep_equal({}, empty:items())
   for _, _ in empty:pairs() do
      error 'This code should not be called'
   end
end

function Tree23Test:test_single_2tree()
   local single, incr = empty:set('foo', 42)
   self:assert_equal(true, incr)
   self:assert_not_equal(empty_mt, two_mt)
   for k, expected in pairs {ak='foo', av=42, p=empty, q=empty} do
      self:assert_equal(expected, single[k])
   end
   self:assert_nil(single:get 'bar')
   self:assert_nil(single:get 'zzz')
   local err = self:assert_error(single.get, single, 42)
   self:assert_pattern(err, 'attempt to compare.*number')
   self:assert_equal(42, single:get 'foo')

   local single2, incr2 = single:set('foo', 43)
   for k, expected in pairs {ak='foo', av=43, p=empty, q=empty} do
      self:assert_equal(expected, single2[k])
   end
   self:assert_equal(false, incr2)
   self:assert_equal(42, single:get 'foo')

   local call_count = 0
   local function visitor(k, v)
      self:assert_equal(k, 'foo')
      self:assert_equal(v, 42)
      call_count = call_count + 1
   end
   single:visit(visitor)
   single:visit(visitor, nil, nil)
   single:visit(visitor, 'abc')
   single:visit(visitor, 'foo')
   single:visit(visitor, 'foo', 'xyz')
   single:visit(visitor, 'abc', 'xyz')
   single:visit(visitor, 'abc', 'foo')
   single:visit(visitor, nil, 'foo')
   single:visit(visitor, nil, 'xyz')
   self:assert_equal(9, call_count)

   call_count = 0
   -- test outside range:
   single:visit(visitor, 'fop')
   single:visit(visitor, 'fop', 'abc')
   single:visit(visitor, 'fop', 'xyz')
   single:visit(visitor, 'foo', 'abc')
   single:visit(visitor, 'abc', 'cde')
   single:visit(visitor, nil, 'abc')
   self:assert_equal(0, call_count)

   self:assert_deep_equal({'foo'}, single:keys())
   self:assert_deep_equal({42}, single:values())
   self:assert_deep_equal({{k='foo', v=42}}, single:items())
   self:assert_deep_equal({foo=42}, single:totable())
   self:assert_deep_equal({}, single:keys('abc', 'cde'))
   self:assert_deep_equal({}, single:values('abc', 'cde'))
   self:assert_deep_equal({}, single:items('abc', 'cde'))
   self:assert_deep_equal({}, single:totable('abc', 'cde'))

   call_count = 0
   for k, v in single:pairs('abc', 'cde') do visitor(k, v) end
   for k, v in single:pairs('wxy', 'xyz') do visitor(k, v) end
   self:assert_equal(0, call_count)
   for k, v in single:pairs('abc', 'xyz') do visitor(k, v) end
   for k, v in single:pairs() do visitor(k, v) end
   self:assert_equal(2, call_count)
end


function Tree23Test:test_single_3tree()
   local t, incr = empty:set('b', 2):set('d', 4)

   self:assert_equal(false, incr)
   self:assert_deep_equal(t, empty:set('d', 4):set('b', 2))
   for k, expected in pairs {
      ak='b', av=2, bk='d', bv=4,
      p=empty, q=empty, r=empty,
   } do
      self:assert_equal(expected, t[k])
   end
   self:assert_not_equal(two_mt, three_mt)

   self:assert_nil(t:get 'a')
   self:assert_nil(t:get 'c')
   self:assert_nil(t:get 'e')
   local err = self:assert_error(t.get, t, 42)
   self:assert_pattern(err, 'attempt to compare.*number')
   self:assert_equal(2, t:get 'b')
   self:assert_equal(4, t:get 'd')

   local t2, incr2 = t:set('b', 200)
   self:assert_deep_equal(empty:set('b', 200):set('d', 4), t2)
   self:assert_equal(false, incr2)
   self:assert_equal(200, t2:get 'b')
   self:assert_equal(2, t:get 'b')

   local t3, incr3 = t:set('d', 400)
   self:assert_deep_equal(empty:set('b', 2):set('d', 400), t3)
   self:assert_equal(false, incr3)
   self:assert_equal(400, t3:get 'd')
   self:assert_equal(4, t:get 'd')

   local keys = ''
   local function visitor(k, v)
      self:assert_pattern(k, '^[bd]$')
      self:assert_equal(v, ({b=2, d=4})[k])
      keys = keys .. k
   end
   t:visit(visitor)
   t:visit(visitor, nil, nil)
   t:visit(visitor, 'abc')
   t:visit(visitor, 'd')
   t:visit(visitor, 'a', 'b')
   t:visit(visitor, 'abc', 'xyz')
   t:visit(visitor, 'b', 'd')
   t:visit(visitor, nil, 'd')
   t:visit(visitor, nil, 'xyz')
   self:assert_equal('bdbdbddbbdbdbdbd', keys)

   keys = ''
   -- test outside range:
   t:visit(visitor, 'e')
   t:visit(visitor, 'e', 'a')
   t:visit(visitor, 'e', 'x')
   t:visit(visitor, 'd', 'a')
   t:visit(visitor, 'aa', 'ab')
   t:visit(visitor, nil, 'abc')
   self:assert_equal('', keys)

   self:assert_deep_equal({'b', 'd'}, t:keys())
   self:assert_deep_equal({2, 4}, t:values())
   self:assert_deep_equal({{k='b', v=2}, {k='d', v=4}}, t:items())
   self:assert_deep_equal({b=2, d=4}, t:totable())
   self:assert_deep_equal({}, t:keys('abc', 'acde'))
   self:assert_deep_equal({}, t:values('abc', 'acde'))
   self:assert_deep_equal({}, t:items('abc', 'acde'))
   self:assert_deep_equal({}, t:totable('abc', 'acde'))

   for k, v in t:pairs('abc', 'acd') do visitor(k, v) end
   for k, v in t:pairs('wxy', 'xyz') do visitor(k, v) end
   self:assert_equal('', keys)
   for k, v in t:pairs('abc', 'xyz') do visitor(k, v) end
   for k, v in t:pairs() do visitor(k, v) end
   self:assert_equal('bdbd', keys)
end


function Tree23Test:test_numbers_1_100()
   math.randomseed(87435176)
   local nums, avail = {}, {}
   for i = 1, 100 do nums[i]=i; avail[i]=i end
   local t = empty
   while next(avail) do
      local pos = math.random(#avail)
      t = t:set(avail[pos], tostring(avail[pos]))
      avail[pos] = avail[#avail]
      avail[#avail] = nil
   end
   self:assert_deep_equal(nums, t:keys())
   for i = 0.5, 101 do
      self:assert_nil(t:get(i))
   end
   self:assert_deep_equal({1, '1'}, {t:min()})

   -- now it's time to delete everything:
   local val
   for i = 1, 100 do nums[i]=i; avail[i]=i end
   while next(avail) do
      local pos = math.random(#avail)
      t, val = t:del(avail[pos])
      self:assert_equal(val, tostring(avail[pos]))
      avail[pos] = avail[#avail]
      avail[#avail] = nil
   end
   self:assert_equal(t, empty)
end


function Tree23Test:test_setsorteditems()
   local items = {}
   local t
   for i = 1, 100 do
      items[i] = {k=i, v=tostring(i)}
      t = empty:setsorteditems(items)
      self:assert_deep_equal(items, t:items())
   end
   items[101] = {k=101, v='101'}
   items[102] = {k=102, v='102'}
   t = t:setsorteditems(items, 101, 102)
   self:assert_deep_equal(items, t:items())
end

function Tree23Test:test_settable()
   local t1 = empty:settable{foo=2, taz=3, bar=1}
   self:assert_deep_equal({bar=1, foo=2, taz=3}, t1:totable())
   local t2 = t1:settable{foo=4, ccc=5}
   self:assert_deep_equal({bar=1, ccc=5, foo=4, taz=3}, t2:totable())
end


Tree23Test:run_if_main()


return Tree23Test
