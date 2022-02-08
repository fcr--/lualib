local bigint = require 'lualib.bigint'.bigint

local record rsa
  record Rsa
    bigint_encrypt: function(Rsa, m: bigint): bigint

    -- signing in RSA is powmodding with the private key:
    bigint_sign: function(Rsa, m: bigint): bigint
    bigint_is_signature_valid: function(Rsa, m: bigint, s: bigint): boolean

    bigint_decrypt: function(Rsa, c: bigint): bigint
  end

  record rsa_options
    -- public key is (e, n), required for encrypting messages:
    e: bigint  -- defaults to 65537 (known)
    n: bigint  -- p*q

    d: bigint  -- private key component
    -- p&q (the prime factors of n) are optional, they accelerate decryption:
    p: bigint
    q: bigint
  end

  new: function(cls: Rsa, opts: rsa_options): Rsa

  -- creates a new Rsa instance with n, d (besides p, q and e)
  setup: function(p: bigint, q: bigint, e: nil | bigint): Rsa
end

return rsa
