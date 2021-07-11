local oo = require 'lualib.oo'
local bigint = require 'lualib.bigint'


local RSA = oo.class()


function RSA:_init(opts)
  -- public key is (e, n), required for encrypting messages:
  self.e = opts.e or bigint.new(65537)
  self.n = opts.n
  -- private key component d:
  self.d = opts.d
  -- p&q (the prime factors of n) are optional, but they can accelerate decryption:
  self.p = opts.p
  self.q = opts.q
end


function RSA.setup(p, q, e)
  -- p&q are prime numbers, default exponent is usually either 3 (unsafe?) or 2^16+1
  e = e or bigint.new(65537)
  -- Charmichael's Totien of n, used for computing d:
  local pm1, qm1 = p-bigint.one, q-bigint.one
  local ctn = pm1 / pm1:gcd(qm1) * qm1
  return RSA:new{e=e, d=e:invmod(ctn), n=p*q, p=p, q=q}
end


function RSA:bigint_encrypt(m)
  return m:powmod(self.e, self.n)
end


function RSA:bigint_decrypt(c)
  -- using the Chinese Remainder Theorem:
  if self.p and self.q then
    if not self.qinv then
      self.dp = self.d % (self.p-bigint.one)
      self.dq = self.d % (self.q-bigint.one)
      self.qinv = self.q:invmod(self.p)
    end
    local m1 = c:powmod(self.dp, self.p)
    local m2 = c:powmod(self.dq, self.q)
    local h = self.qinv * (m1 - m2) % self.p
    return (m2 + h * self.q) % self.n
  end
  -- simplified slower computation:
  return c:powmod(self.d, self.n)
end


return RSA
