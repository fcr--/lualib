local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local bigint = require 'lualib.bigint'
local RSA = require 'lualib.crypto.rsa'


local p1 = bigint.new '0x44145cdc85a07da9b'
local p2 = bigint.new '0x17af663a3b84710a1'


local RSATest = oo.class(BaseTest)


function RSATest:test_rsa()
  local m = bigint.new(42)
  local rsa = RSA.setup(p1, p2)
  local c = rsa:bigint_encrypt(m)
  self:assert_not_equal(m, c)
  self:assert_equal(rsa:bigint_decrypt(c), m)
end


RSATest:run_if_main()


return RSATest
