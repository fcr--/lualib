local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local base64 = require 'lualib.base64'

local Base64Test = oo.class(BaseTest)


function Base64Test:test_encode()
  self:assert_equal(base64.encode '', '')
  self:assert_equal(base64.encode 'holañmundo', 'aG9sYcOxbXVuZG8=')
end


Base64Test:run_if_main()


return Base64Test
