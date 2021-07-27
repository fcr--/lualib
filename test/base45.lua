local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local base45 = require 'lualib.base45'

local Base45Test = oo.class(BaseTest)


function Base45Test:test_encode()
  -- examples from the spec: https://datatracker.ietf.org/doc/html/draft-faltstrom-base45-03
  self:assert_equal(base45.encode 'AB', 'BB8')
  self:assert_equal(base45.encode 'Hello!!', '%69 VD92EX0')
  self:assert_equal(base45.encode 'base-45', 'UJCLQE7W581')
  self:assert_equal(base45.encode 'ietf!', 'QED8WEX0')
end


function Base45Test:test_decode()
  -- examples from the spec: https://datatracker.ietf.org/doc/html/draft-faltstrom-base45-03
  self:assert_equal(base45.decode 'BB8', 'AB')
  self:assert_equal(base45.decode '%69 VD92EX0', 'Hello!!')
  self:assert_equal(base45.decode 'UJCLQE7W581', 'base-45')
  self:assert_equal(base45.decode 'QED8WEX0', 'ietf!')
end


Base45Test:run_if_main()


return Base45Test
