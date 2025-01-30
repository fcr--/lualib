local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local LruCache = require 'lualib.struct.lrucache'

local LruCacheTest = oo.class(BaseTest)


function LruCacheTest:check_lru(lru, keys)
  if lru:count() < 0 then error 'lru with negative size' end
  if lru:count() == 0 then
    self:assert_nil(next(lru.keys))
    self:assert_nil(lru.newest)
    self:assert_nil(lru.oldest)
    return
  end
  local prev
  local cur = lru.newest
  local count = 0
  --print('iterating', lru:count(), 'elements:')
  while cur do
    --print(('\t%d: %s={prev=%s, next=%s, key=%s, value=%s}'):format(
    --    count, tostring(cur), tostring(cur.prev), tostring(cur.next), cur.key, cur.value))
    self:assert_equal(cur.prev, prev)
    if prev then self:assert_equal(prev.next, cur) end
    self:assert_equal(lru.keys[cur.key], cur)
    self:assert_equal(cur.key, keys[count+1])
    prev = cur
    cur = cur.next
    count = count + 1
  end
  self:assert_equal(count, lru:count())
  self:assert_equal(lru.oldest, lru.keys[keys[count]])
end

function LruCacheTest:test_empty()
  local lru = LruCache:new(10)
  self:assert_equal(lru:count(), 0)
  self:assert_equal(#lru, 0)
  self:assert_nil(lru:get'foo')
  self:check_lru(lru, {})
end

function LruCacheTest:test_single()
  local lru = LruCache:new(10)
  lru:set('foo', 42)
  self:check_lru(lru, {'foo'})
  self:assert_equal(lru:get'foo', 42)
  self:check_lru(lru, {'foo'})
  self:assert_equal(lru:set('foo', 'bar'))
  self:check_lru(lru, {'foo'})
  self:assert_equal(lru:get'foo', 'bar')
end

function LruCacheTest:test_two_elements()
  local lru = LruCache:new(10)
  lru:set('foo', 42)
  lru:set('bar', 43)
  local function check(keys)
    self:check_lru(lru, keys)
    self:assert_equal(lru:peek'foo', 42)
    self:assert_equal(lru:peek'bar', 43)
  end
  check{'bar', 'foo'}; self:assert_equal(lru:get'bar', 43)
  check{'bar', 'foo'}; self:assert_equal(lru:get'foo', 42)
  check{'foo', 'bar'}; self:assert_equal(lru:get'foo', 42)
  check{'foo', 'bar'}; self:assert_equal(lru:get'bar', 43)
  check{'bar', 'foo'}
end

function LruCacheTest:test_deletion()
  local lru = LruCache:new(10)
  local items = {one=1, two=2, three=3, four=4, five=5}
  for _, w in ipairs{'five', 'four', 'three', 'two', 'one'} do
    lru:set(w, items[w])
  end
  local function check(keys)
    self:check_lru(lru, keys)
    for _, w in ipairs(keys) do
      self:assert_equal(items[w], lru:peek(w))
    end
  end
  check {'one', 'two', 'three', 'four', 'five'}
  lru:del 'one'
  check {'two', 'three', 'four', 'five'}
  lru:del 'five'
  check {'two', 'three', 'four'}
  lru:del 'three'
  check {'two', 'four'}
  lru:del 'four'
  check {'two'}
  lru:del 'two'
  check {}
end

function LruCacheTest:test_eviction()
  local lru = LruCache:new(10)
  local keys = {}
  for c in ('thistexthasmanycharactersandsomeofthemarerepeated'):gmatch '.' do
    table.insert(keys, 1, c)
    local visited = {}
    for i = 1, #keys do
      if keys[i] and not visited[keys[i]] then
        visited[keys[i]] = true
      else
        table.remove(keys, i)
      end
    end
    keys[11] = nil
    lru:set(c, 1)
    self:check_lru(lru, keys)
  end
end


LruCacheTest:run_if_main()


return LruCacheTest
