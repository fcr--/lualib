local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local base64 = require 'lualib.base64'

local Base64Test = oo.class(BaseTest)

local long_string = "xe6LAPBF9BxyggKWGjwFaVGcNnHmBy5+5B/hSGitCinAmRxrIQDGmya7CGdU"
local long_bin = (
  "\197\238\139\0\240E\244\28r\130\2\150\26<\5iQ\1566q\230\7.~\228\31\225Hh\173\n" ..
  ")\192\153\28k!\0\198\155&\187\8gT"
)


function Base64Test:test_encode()
  self:assert_equal(base64.encode '', '')
  self:assert_equal(base64.encode 'x', 'eA==')
  self:assert_equal(base64.encode 'holañmundo', 'aG9sYcOxbXVuZG8=')
  self:assert_equal(base64.encode(long_bin), long_string)
end

function Base64Test:test_decode()
  self:assert_equal(base64.decode '', '')
  self:assert_equal(base64.decode 'eA==', 'x')
  self:assert_equal(base64.decode 'aG9sYcOxbXVuZG8=', 'holañmundo')
  self:assert_equal(base64.decode(long_string), long_bin)
end

function Base64Test:test_reencode_range()
  for i = 0, #long_bin do
    local substr = long_bin:sub(1, i)
    self:assert_equal(base64.decode(base64.encode(substr)), substr)
  end
end

Base64Test:run_if_main()


return Base64Test
