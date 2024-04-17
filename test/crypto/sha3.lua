local bit = bit or require 'bit32'
local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local sha3 = require 'lualib.crypto.sha3'

local Sha3Test = oo.class(BaseTest)


function Sha3Test:test_iota_constants()
  -- rc is an LFSR with p(x) = x^6 + x^5 + x^4 + x.
  local function rc(t)  -- t in range [0, 6+7*23==167]
    if t % 255 == 0 then return 1 end
    local r = 1
    for i = 1, t % 255 do
      r = bit.lshift(r, 1)
      if bit.band(bit.rshift(r, 8), 1) == 1 then
        r = bit.bxor(r, 0x71)
      end
    end
    return bit.band(r, 1)
  end
  local iota_constants, expected = {}, {}
  for round = 0, 23 do
    local rc_lo = 0
    for j = 0, 5 do
      rc_lo = bit.bor(rc_lo, bit.lshift(1, 2^j-1) * rc(j + 7*round))
    end
    local rc_hi = bit.lshift(1, 31) * rc(6 + 7*round)
    -- convert iota_constants into the signedness of our bit/bit32 library:
    iota_constants[round] = {
      hi = bit.bor(sha3.internals.iota_constants[round].hi, 0),
      lo = bit.bor(sha3.internals.iota_constants[round].lo, 0),
    }
    expected[round] = {hi=rc_hi, lo=rc_lo}
  end
  self:assert_deep_equal(iota_constants, expected)
end


Sha3Test:run_if_main()


return Sha3Test
