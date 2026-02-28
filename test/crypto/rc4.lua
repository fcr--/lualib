local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local Rc4 = require 'lualib.crypto.rc4'

local Rc4Test = oo.class(BaseTest)


local function to_hex(s)
  return (s:gsub('.', function(c)
    return string.format('%02X', string.byte(c))
  end))
end


function Rc4Test:test_wikipedia_vectors()
  -- Test vectors from Wikipedia: https://en.wikipedia.org/wiki/RC4#Test_vectors
  local tests = {
    {key = 'Key', plaintext = 'Plaintext', ciphertext = {0xBB, 0xF3, 0x16, 0xE8, 0xD9, 0x40, 0xAF, 0x0A, 0xD3}},
    {key = 'Wiki', plaintext = 'pedia', ciphertext = {0x10, 0x21, 0xBF, 0x04, 0x20}},
    {key = 'Secret', plaintext = 'Attack at dawn', ciphertext = {0x45, 0xA0, 0x1F, 0x64, 0x5F, 0xC3, 0x5B, 0x38, 0x35, 0x52, 0x54, 0x4B, 0x9B, 0xF5}},
  }

  for i, t in ipairs(tests) do
    local rc4 = Rc4:new{key = t.key}
    local encrypted = rc4:encrypt(t.plaintext)
    local expected = string.char((unpack or table.unpack)(t.ciphertext))
    if encrypted ~= expected then
      error(string.format('Test case %d failed. Expected %s, got %s', i, to_hex(expected), to_hex(encrypted)))
    end
  end
end


function Rc4Test:test_decryption()
  local key = 'VerySecretKey'
  local plaintext = 'This is a secret message that should be decrypted correctly.'
  
  local rc4_enc = Rc4:new{key = key}
  local ciphertext = rc4_enc:encrypt(plaintext)
  
  local rc4_dec = Rc4:new{key = key}
  local decrypted = rc4_dec:encrypt(ciphertext)
  
  self:assert_equal(decrypted, plaintext)
end


function Rc4Test:test_bytes_method()
  local rc4 = Rc4:new{key = 'Key'}
  -- First 3 bytes of stream for key "Key" are 0xEB, 0x9F, 0x77
  local b = rc4:bytes(3)
  self:assert_deep_equal(b, {0xEB, 0x9F, 0x77})
end


function Rc4Test:test_large_input()
  -- Test the chunked processing in Rc4:encrypt for inputs > 1024 bytes
  local key = 'Key'
  local plaintext = string.rep('A', 2000)
  
  local rc4_enc = Rc4:new{key = key}
  local ciphertext = rc4_enc:encrypt(plaintext)
  self:assert_equal(#ciphertext, 2000)
  
  local rc4_dec = Rc4:new{key = key}
  local decrypted = rc4_dec:encrypt(ciphertext)
  self:assert_equal(decrypted, plaintext)
end


Rc4Test:run_if_main()


return Rc4Test
