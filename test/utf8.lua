local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local utf8 = require 'lualib.utf8'

local Utf8Test = oo.class(BaseTest)


function Utf8Test:test_char()
  -- 1-byte (ASCII)
  self:assert_equal(utf8.char(0x24), '$')
  
  -- 2-byte
  self:assert_equal(utf8.char(0xA2), '¢')
  self:assert_equal(utf8.char(0x07FF), '\223\191')
  
  -- 3-byte
  self:assert_equal(utf8.char(0x20AC), '€')
  self:assert_equal(utf8.char(0xFFFF), '\239\191\191')
  
  -- 4-byte
  self:assert_equal(utf8.char(0x10FFFD), '\244\143\191\189')
  self:assert_equal(utf8.char(0x1F600), '😀')
end


function Utf8Test:test_multiple_chars()
  -- Test calling with multiple arguments
  self:assert_equal(utf8.char(0x48, 0x65, 0x6C, 0x6C, 0x6F), 'Hello')
end


function Utf8Test:test_invalid_codepoint()
  -- Test error handling for out-of-range code points
  self:assert_error(function() utf8.char(0x110000) end)
end


Utf8Test:run_if_main()


return Utf8Test
