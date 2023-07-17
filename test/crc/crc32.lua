local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local crc32 = require 'lualib.crc.crc32'

local Crc32Test = oo.class(BaseTest)


function Crc32Test:test_crc32()
    self:assert_equal(0x0, crc32 '')
    self:assert_equal(0x8c736521, crc32 'foo')
    self:assert_equal(0x8c736521, crc32('o', crc32('o', crc32 'f')))
    self:assert_equal(0xff000000, crc32 '\255')
    self:assert_equal(0xd202ef8d, crc32 '\0')
    self:assert_equal(0x65871d19, crc32 "\229p\195Q\206(\12\198\128 U\232z,\139\142\141\231\1\47i\216\146\168\221\182B\212N\167\30'")
    self:assert_equal(0x0, crc32 '\208\181`L\n6\164\t>\1282\218<\153t"')
end


Crc32Test:run_if_main()


return Crc32Test
