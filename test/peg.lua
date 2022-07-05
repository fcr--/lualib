local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local peg = require 'lualib.peg'

local PegTest = oo.class(BaseTest)

local function a(pos, len, g, ...)
   local any_grammar = BaseTest.create_set('any_grammar',
      function(v) return oo.isinstance(v, peg.Grammar) end)
   return {pos=pos, len=len, grammar=g or any_grammar, ...}
end

function PegTest:test_concat()
   local gf = peg.String 'foo'
   local gb = peg.String 'bar'
   local g = peg.Concat(gf, gb)
   self:assert_deep_equal({false, {message='expected string "foo"', pos=1}}, {g:parse 'xfoobar'})
   self:assert_deep_equal({false, {message='expected string "bar"', pos=4}}, {g:parse 'foox'})
   self:assert_deep_equal(a(1,6,g, a(1,3,gf), a(4,3,gb)), g:parse 'foobar')
   self:assert_deep_equal(a(1,6,g, a(1,3,gf), a(4,3,gb)), g:parse 'foobarx')
end

function PegTest:test_string()
   local g = peg.String 'foo'
   self:assert_deep_equal({false, {message='expected string "foo"', pos=1}}, {g:parse 'xfoo'})
   self:assert_deep_equal(a(1,3,g), g:parse 'foo')
   self:assert_deep_equal(a(1,3,g), g:parse 'foox')
end

PegTest:run_if_main()

return PegTest
