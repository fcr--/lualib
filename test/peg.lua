local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local peg = require 'lualib.peg'

local PegTest = oo.class(BaseTest)

local function a(pos, len, g, ...)
   return {pos=pos, len=len, grammar=g or BaseTest.any_instance(peg.Grammar, 'Grammar'), ...}
end

function PegTest:assert_not_parses(message, pos, g, text)
   self:assert_deep_equal({false, {message=message, pos=pos}}, {g:parse(text)})
end

function PegTest:test_concat()
   local gf = peg.String 'foo'
   local gb = peg.String 'bar'
   local g = peg.Concat(gf, gb)
   self:assert_not_parses('expected string "foo"', 1, g, 'xfoobar')
   self:assert_not_parses('expected string "bar"', 4, g, 'foox')
   self:assert_deep_equal(a(1,6,g, a(1,3,gf), a(4,3,gb)), g:parse 'foobar')
   self:assert_deep_equal(a(1,6,g, a(1,3,gf), a(4,3,gb)), g:parse 'foobarx')
end

function PegTest:test_string()
   -- invalid type checks: (newproxy, for userdata, was removed from lua5.2, shame...)
   for _, x in ipairs{{}, 2, function()end, true, coroutine.create(function()end)} do
      self:assert_error(peg.String, x)
   end
   self:assert_error(peg.String, nil)
   local g = peg.String 'foo'
   self:assert_not_parses('expected string "foo"', 1, g, 'xfoo')
   self:assert_deep_equal(a(1,3,g), g:parse 'foo')
   self:assert_deep_equal(a(1,3,g), g:parse 'foox')
end

function PegTest:test_eof()
   local g = peg.EOF()
   self:assert_not_parses('expected end of text', 1, g, 'x')
   self:assert_deep_equal(a(1,0,g), g:parse '')
end

function PegTest:test_any()
   local g = peg.Any()
   self:assert_not_parses('expected any character', 1, g, '')
   self:assert_deep_equal(a(1,1,g), g:parse 'x')
end

function PegTest:test_set()
   self:assert_error(peg.Set, '')  -- empty set (use peg.EOF instead)
   self:assert_error(peg.Set, '32')  -- out of order elements
   self:assert_error(peg.Set, '15aZ')  -- out of order elements ('Z' < 'a')
   self:assert_error(peg.Set, 'xyz')  -- odd number of elements
   self:assert_error(peg.Set, '1324')  -- duplicated items in set
   local g = peg.Set 'bd'
   self:assert_not_parses('expected any character in ranges "bd"', 1, g, 'a')
   self:assert_not_parses('expected any character in ranges "bd"', 1, g, 'e')
   self:assert_not_parses('expected any character in ranges "bd"', 1, g, 'C')
   self:assert_deep_equal(a(1,1,g), g:parse 'b')
   self:assert_deep_equal(a(1,1,g), g:parse 'c')
   self:assert_deep_equal(a(1,1,g), g:parse 'd')
   g = peg.Set 'pr2588'
   local valid = {p=1, q=1, r=1, ['2']=1, ['3']=1, ['4']=1, ['5']=1, ['8']=1}
   for i = 0, 255 do
      local c = string.char(i)
      if valid[c] then
         self:assert_deep_equal(a(1,1,g), g:parse(c))
      else
         self:assert_not_parses('expected any character in ranges "pr2588"', 1, g, c)
      end
   end
end

function PegTest:test_power()
   local child = peg.String 'x'
   self:assert_error(peg.Power, 2, 1, child)  -- min > max
   self:assert_error(peg.Power, -1, 2, child)  -- min < 0
   self:assert_error(peg.Power, '1', 2, child)  -- min not number
   self:assert_error(peg.Power, 1, '2', child)  -- max not number
   self:assert_error(peg.Power, 1, 2, {})  -- child is not a Grammar
   local g = peg.Power(2, 5, child)
   self:assert_not_parses('expected string "x"', 1, g, '')
   self:assert_not_parses('expected string "x"', 2, g, 'x')
   local expected_ast = a(1, 1, g, a(1, 1, child))
   for len = g.min, g.max do
      expected_ast.len = len
      expected_ast[len] = a(len, 1, child)
      self:assert_deep_equal(expected_ast, g:parse(('x'):rep(len)))
   end
   self:assert_deep_equal(expected_ast, g:parse(('x'):rep(g.max+1)))
end

function PegTest:test_optional()
   local child = peg.String 'x'
   local g = peg.Optional(child)
   self:assert_equal(g.min, 0)
   self:assert_equal(g.max, 1)
   self:assert_equal(g.child, child)
   self:assert_equal(true, oo.isinstance(g, peg.Power))
end

function PegTest:test_zero_or_more()
   local child = peg.String 'x'
   local g = peg.ZeroOrMore(child)
   self:assert_equal(g.min, 0)
   self:assert_equal(g.max, math.huge)
   self:assert_equal(g.child, child)
   self:assert_equal(true, oo.isinstance(g, peg.Power))
end

function PegTest:test_one_or_more()
   local child = peg.String 'x'
   local g = peg.OneOrMore(child)
   self:assert_equal(g.min, 1)
   self:assert_equal(g.max, math.huge)
   self:assert_equal(g.child, child)
   self:assert_equal(true, oo.isinstance(g, peg.Power))
end

PegTest:run_if_main()

return PegTest
