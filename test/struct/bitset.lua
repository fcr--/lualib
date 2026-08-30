local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local BitSet = require 'lualib.struct.bitset'

local BitSetTest = oo.class(BaseTest)

---@param tfs string String whose chars are 'tttffftfttttffft', one per "bit"
---@return fun():boolean 
local _biter_chars = {[('t'):byte()]=true, [('f'):byte()]=false}
local function biter(tfs)
   local index = #tfs
   return function()
      local boolean = _biter_chars[tfs:byte(index)]
      index = index - 1
      if boolean ~= nil then return boolean end
   end
end

function BitSetTest:test_string_constructor()
   local function test(tfs, ...)
      local bs = BitSet.Strings:new{iter=biter(tfs)}
      self:assert_equal(bs.start, 0)
      self:assert_equal(bs.size, #tfs)
      self:assert_deep_equal(bs._strings, {...})
   end
   test('')
   test('f', '\0')
   test('t', '\1')
   test('tf', '\2')
   test('tt', '\3')
   test('ft', '\1')
   test('tffff', '\16')
   test('tttttttt', '\255')
   test('tffffffff', '\0\1')
   test(
      ('ffftfftftftffttfffttfttfffttfttfttttfttfffttftff'..
      'ffffftfftttftttfttttfttfftfftttfffttfttffftffttf'..
      'tfffftffftftffff'):reverse(),
      'Hello, world!\n'
   )
end

function BitSetTest:test_string_block_size()
   local MAX_STRING_SIZE = 256
   local ts = 't'
   local full_block = ('\xff'):rep(MAX_STRING_SIZE)
   local function test_block_size(byte_length)
      local ts = ('t'):rep(8*byte_length)
      local bs = BitSet.Strings:new{iter=biter(ts)}
      self:assert_equal(bs.size, #ts)
      self:assert_equal(type(bs._strings), 'table')
      for i, s in ipairs(bs._strings) do
         if i < #bs._strings then
            self:assert_equal(s, full_block)
         else
            self:assert_equal(#s + MAX_STRING_SIZE*(i-1), byte_length)
            -- by using a + in the pattern we ensure there are no empty trailing blocks:
            self:assert_pattern(s, '^\xff+$')
         end
      end
   end
   for p = 0, 12, 2 do
      test_block_size(2^p)
   end
   -- testing borders just in case:
   test_block_size(MAX_STRING_SIZE-1)
   test_block_size(MAX_STRING_SIZE)
   test_block_size(MAX_STRING_SIZE+1)
   test_block_size(1337)
end


BitSetTest:run_if_main()


return BitSetTest
