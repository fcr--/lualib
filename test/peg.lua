local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local peg = require 'lualib.peg'

local PegTest = oo.class(BaseTest)

function PegTest:test_string()
  local g = peg.String'foo'
  self:assert_deep_equal({false, {message='expected string "foo"', pos=1}}, {g:parse'bar'})
  self:assert_deep_equal({grammar=g, pos=1, len=3}, g:parse'foo')
end

PegTest:run_if_main(...)

return PegTest
