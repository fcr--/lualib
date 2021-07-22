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


function RSATest:test_decrypt_without_pq()
  local rsa_full = RSA.setup(p1, p2)
  local rsa_public = RSA:new{n=rsa_full.n}
  local rsa_private = RSA:new{n=rsa_full.n, d=rsa_full.d}
  local m = bigint.fromstring('raw', 'Hello!')
  local c = rsa_public:bigint_encrypt(m)
  -- this should be slower than using rsa_full because we cannot use CRT:
  self:assert_equal(rsa_private:bigint_decrypt(c), m)
end


function RSATest:test_signature()
  local rsa_full = RSA.setup(p1, p2)
  local rsa_public = RSA:new{n=rsa_full.n}
  local m = bigint.fromstring('raw', 'Hello!')
  local s = rsa_full:bigint_sign(m)
  self:assert_equal(rsa_public:bigint_is_signature_valid(m, s), true)
  self:assert_equal(rsa_public:bigint_is_signature_valid(m, s+bigint.one), false)
end


RSATest:run_if_main()


return RSATest
