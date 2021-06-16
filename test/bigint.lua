local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local bigint = require 'lualib.bigint'


local BigIntTest = oo.class(BaseTest)


local new = bigint.new
local function m(t) return setmetatable(t, bigint.mt) end


function BigIntTest:test_new()
  self:assert_deep_equal(new(7), m{7, sign=1})
  self:assert_deep_equal(new(-4), m{4, sign=-1})
  self:assert_deep_equal(new(0), m{sign=0})
  self:assert_deep_equal(new(0x10002), m{2, 1, sign=1})
  self:assert_deep_equal(new'0', bigint.zero)
  self:assert_deep_equal(new'00', bigint.zero)
  self:assert_deep_equal(new'5', new(5))
  self:assert_deep_equal(new'00000000000000000000001', bigint.one)
  self:assert_deep_equal(new'1234567', m{54919, 18, sign=1})
  self:assert_deep_equal(new'-1234567', m{54919, 18, sign=-1})
  self:assert_deep_equal(new'12345678', m{24910, 188, sign=1})
  self:assert_deep_equal(new'0x414f69a371947399bad117e0ffcd08e',
    m{0xd08e, 0xffc, 0x117e, 0x9bad, 0x4739, 0x3719, 0xf69a, 0x414, sign=1})
  self:assert_deep_equal(new'0x0', bigint.zero)
  self:assert_deep_equal(new'0x1', bigint.one)
  self:assert_deep_equal(new'0x12', m{0x12, sign=1})
  self:assert_deep_equal(new'0x123', m{0x123, sign=1})
  self:assert_deep_equal(new'0x1234', m{0x1234, sign=1})
  self:assert_deep_equal(new'0x12345', m{0x2345, 0x1, sign=1})
  self:assert_deep_equal(new'0x123456', m{0x3456, 0x12, sign=1})
  self:assert_deep_equal(new'0x1234567', m{0x4567, 0x123, sign=1})
  self:assert_deep_equal(new'0x12345678', m{0x5678, 0x1234, sign=1})
  self:assert_deep_equal(new'0x123456789', m{0x6789, 0x2345, 1, sign=1})
  self:assert_deep_equal(new'-0x1', -bigint.one)
  self:assert_deep_equal(new'-0x12', m{0x12, sign=-1})
  self:assert_deep_equal(new'-0x123', m{0x123, sign=-1})
  self:assert_deep_equal(new'-0x1234', m{0x1234, sign=-1})
  self:assert_deep_equal(new'-0x12345', m{0x2345, 0x1, sign=-1})
  self:assert_deep_equal(new'-0x123456', m{0x3456, 0x12, sign=-1})
  self:assert_deep_equal(new'-0x1234567', m{0x4567, 0x123, sign=-1})
  self:assert_deep_equal(new'-0x12345678', m{0x5678, 0x1234, sign=-1})
  self:assert_deep_equal(new'-0x123456789', m{0x6789, 0x2345, 1, sign=-1})
end


function BigIntTest:test___add()
  self:assert_deep_equal(new(2) + new(5), new(7))
  self:assert_deep_equal(new(2) + new(-5), new(-3))
  self:assert_deep_equal(new(-2) + new(5), new(3))
  self:assert_deep_equal(new(5) + new(-2), new(3))
  self:assert_deep_equal(new(-5) + new(2), new(-3))
  self:assert_deep_equal(new(-3) + new(-3), new(-6))
  self:assert_deep_equal(new(3) + new(-3), new(0))

  self:assert_deep_equal(new(0x10002) + new(0), new(0x10002))
  self:assert_deep_equal(new(0) + new(0x10002), new(0x10002))
  self:assert_deep_equal(new(-0x10002) + new(0), new(-0x10002))
  self:assert_deep_equal(new(0) + new(-0x10002), new(-0x10002))
  
  self:assert_deep_equal(new(0x10000) + new(2), new(0x10002))
  self:assert_deep_equal(new(2) + new(0x10000), new(0x10002))
  self:assert_deep_equal(new(0x10000) + new(-2), new(0xfffe))
  self:assert_deep_equal(new(-2) + new(0x10000), new(0xfffe))
  self:assert_deep_equal(new(-0x10000) + new(2), new(-0xfffe))
  self:assert_deep_equal(new(2) + new(-0x10000), new(-0xfffe))
  self:assert_deep_equal(new(-0x10000) + new(-2), new(-0x10002))
  self:assert_deep_equal(new(-2) + new(-0x10000), new(-0x10002))
end


function BigIntTest:test___eq()
  self:assert_equal(new(7) == new(7), true)
  self:assert_equal(new(7) == new(-7), false)
  self:assert_equal(new(-7) == new(-7), true)
  self:assert_equal(new(0x10002) == new(0x10002), true)
  self:assert_equal(new(0x10001) == new(0x10002), false)
  self:assert_equal(new(1) == new(0x10001), false)
  self:assert_equal(new(1) == bigint.one, true)
  -- should break with non-normalized values
  self:assert_equal(new(1) == m{sign=1, 1, 0}, false)
end


function BigIntTest:test___tostring()
  self:assert_equal(tostring(new(0)), '0')
  self:assert_equal(tostring(new(0x10000789a)), '0x10000789a')
  self:assert_equal(tostring(new(-0x3ffff)), '-0x3ffff')
end


function BigIntTest:test___unm()
  self:assert_equal(-new(0x30004), new(-0x30004))
  self:assert_equal(-new(-0x30004), new(0x30004))
  self:assert_equal(-bigint.zero, bigint.zero)
end


function BigIntTest:test_band()
  self:assert_equal(new(1+2):band(new(2+4)), new(2))
  self:assert_equal(new(1):band(bigint.zero), new(0))
  self:assert_equal(new(0x10006):band(new(3)), new(2))
  self:assert_equal(new(1+2):band(-new(2+4)), new(2))
  self:assert_equal((-new(1+2)):band(new(2+4)), new(2))
  self:assert_equal((-new(1+2)):band(-new(2+4)), new(-2))
end


function BigIntTest:test_bmul()
  self:assert_equal(new(42):bmul(bigint.zero), bigint.zero)
  self:assert_equal(bigint.zero:bmul(new(42)), bigint.zero)
  self:assert_equal(new(0x10002):bmul(new(-0x30004)), new(-0x3000a0008))
  self:assert_equal(new(-2):bmul(new(-3)), new(6))
  self:assert_equal(
    new'0x78431badc0ffee876':bmul(new'0xc1f7e493209a577ef5a'),
    new'0x5b1f0bfe95a6b35bc8dd508d17c4b77de37c')
end


function BigIntTest:test_bor()
  self:assert_equal(new(3):bor(new(6)), new(7))
  self:assert_equal(bigint.one:bor(bigint.zero), bigint.one)
  self:assert_equal(bigint.zero:bor(new(-5)), new(-5))
  self:assert_equal(new(0x10003):bor(new(6)), new(0x10007))
  self:assert_equal(new(3):bor(-new(6)), new(-7))
  self:assert_equal((-new(3)):bor(new(6)), new(-7))
  self:assert_equal((-new(3)):bor(-new(6)), new(-7))
end


function BigIntTest:test_bxor()
  self:assert_equal(new(3):bxor(new(6)), new(5))
  self:assert_equal(bigint.one:bxor(bigint.zero), bigint.one)
  self:assert_equal(bigint.zero:bxor(new(-5)), new(-5))
  self:assert_equal(new(0x10003):bxor(new(6)), new(0x10005))
  self:assert_equal(new(3):bxor(-new(6)), new(-5))
  self:assert_equal((-new(3)):bxor(new(6)), new(-5))
  self:assert_equal((-new(3)):bxor(-new(6)), new(5))
end


function BigIntTest:test_lenbits()
  self:assert_equal(bigint.one:lenbits(), 1)
  self:assert_equal(new(-4):lenbits(), 3)
  self:assert_equal(new(0):lenbits(), 0)
  self:assert_equal(new(1000):lenbits(), 10)
  self:assert_equal(new(0xffff):lenbits(), 16)
  self:assert_equal(new(0x10002):lenbits(), 17)
end


function BigIntTest:test_tonumber()
  self:assert_equal(bigint.zero:tonumber(), 0)
  self:assert_equal(new(438912):tonumber(), 438912)
  self:assert_equal(new(-1234567890):tonumber(), -1234567890)
end


function BigIntTest:test_tostring()
  -- hex format:
  self:assert_equal(bigint.zero:tostring'hex', '0')
  self:assert_equal(new(0x10000789a):tostring'hex', '0x10000789a')
  self:assert_equal(new(-0x3ffff):tostring'hex', '-0x3ffff')
  self:assert_equal(bigint.zero:tostring('hex', {zero='0x0'}), '0x0')
  self:assert_equal(new(9):tostring('hex', {plus_sign='¿'}), '¿0x9')
  self:assert_equal(new(-1):tostring('hex', {minus_sign='¬'}), '¬0x1')
  self:assert_equal(new(-1):tostring('hex', {prefix='!'}), '-!1')
  -- dec format:
  self:assert_equal(bigint.zero:tostring'dec', '0')
  self:assert_equal(new(1234567890):tostring'dec', '1234567890')
  self:assert_equal(new(-1234567890):tostring'dec', '-1234567890')
  self:assert_equal(m{0, 1, sign=1}:tostring'dec', '65536')
  self:assert_equal(
    m{0,0,0,0, 0,0,0,0, 0,0,1, sign=1}:tostring'dec',
    '1461501637330902918203684832716283019655932542976')
  -- raw format:
  self:assert_equal(bigint.zero:tostring'raw', '\0')
  self:assert_equal(bigint.zero:tostring('raw', {zero='?'}), '?')
  self:assert_equal(new(42):tostring'raw', '\42')
  self:assert_equal(new(127):tostring'raw', '\127')
  self:assert_equal(new(128):tostring'raw', '\0\128')
  self:assert_equal(new(0x0102):tostring'raw', '\1\2')
  self:assert_equal(new(0x7fff):tostring'raw', '\127\255')
  self:assert_equal(new(0x8000):tostring'raw', '\0\128\0')
  self:assert_equal(new(-1):tostring'raw', '\255')
  self:assert_equal(new(-2):tostring'raw', '\254')
  self:assert_equal(new(-128):tostring'raw', '\128')
  self:assert_equal(new(-129):tostring'raw', '\255\127')
  self:assert_equal(new(-0x0103):tostring'raw', '\254\253')
  self:assert_equal(new(-0x8000):tostring'raw', '\128\0')
  self:assert_equal(new(1234567890):tostring'raw', 'I\150\2\210')
  self:assert_equal(new(-1234567890):tostring'raw', '\182i\253.')
end


BigIntTest:run_if_main()


return BigIntTest
