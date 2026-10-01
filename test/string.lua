local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local string_lib = require 'lualib.string'

local StringTest = oo.class(BaseTest)

function StringTest:test_split_basic()
   local split = string_lib.split
   self:assert_deep_equal(split('a,b,c', ','), {'a', 'b', 'c'})
   self:assert_deep_equal(split('foo-bar-xyz', '-'), {'foo', 'bar', 'xyz'})
   self:assert_deep_equal(split('hello', ','), {'hello'})
   self:assert_deep_equal(split('', ','), {''})
   self:assert_deep_equal(split(',aa,,b,', ','), {'', 'aa', '', 'b', ''})
end

function StringTest:test_split_patterns()
   local split = string_lib.split
   self:assert_deep_equal(split('foo1bar2baz', '%d'), {'foo', 'bar', 'baz'})
end

function StringTest:test_split_empty_separators()
   -- tests where the separators may match to empty strings
   local split = string_lib.split
   self:assert_deep_equal(split('abc', ''), {'abc'})
   self:assert_deep_equal(split('abc', ' *'), {'abc'})
   self:assert_deep_equal(split('a  bc', ' *'), {'a', 'bc'})
   self:assert_deep_equal(split('a   bc', ' ?'), {'a', '', '', 'bc'})
   self:assert_deep_equal(split(' a b c ', ' *'), {'', 'a', 'b', 'c', ''})
end


StringTest:run_if_main()


return StringTest
