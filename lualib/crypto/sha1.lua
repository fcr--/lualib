local bit = bit or require 'bit32'

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bnot = bit.bnot
local rshift = bit.rshift
local lshift = bit.lshift
local rol = bit.rol or function(word, bits) return bor(lshift(word, bits), rshift(word, 32-bits)) end
local tohex = bit.tohex or function(word) return ('%08x'):format(bor(0, word)) end

local function decode_word(message, start)
  local b0, b1, b2, b3 = message:byte(start, start + 3)
  return bor(lshift(b0, 24), lshift(b1, 16), lshift(b2, 8), b3)
end

local w = {} -- we can reuse w, as hash_chunk does not need to be reentrant:
local function hash_chunk(message, start, h0, h1, h2, h3, h4)
  -- break the chunk into 16 words:
  for i = 1, 16 do
    w[i] = decode_word(message, start + (i-1)*4)
  end
  -- schedule the remaining words:
  for i = 17, 80 do
    w[i] = rol(bxor(w[i-3], w[i-8], w[i-14], w[i-16]), 1)
  end

  local a, b, c, d, e = h0, h1, h2, h3, h4
  local f, k
  for i = 1, 80 do
    if i <= 20 then
      f = bor(band(b, c), band(bnot(b), d))
      k = 0x5a827999
    elseif i <= 40 then
      f = bxor(b, c, d)
      k = 0x6ed9eba1
    elseif i <= 60 then
      f = bor(band(b, c), band(b, d), band(c, d))
      k = 0x8f1bbcdc
    else
      f = bxor(b, c, d)
      k = 0xca62c1d6
    end

    local temp = rol(a, 5) + f + e + k + w[i]
    e = d
    d = c
    c = rol(b, 30)
    b = a
    a = temp
  end

  return band(h0 + a), band(h1 + b), band(h2 + c), band(h3 + d), band(h4 + e)
end

local function encode_word(w)
  -- encoded in big-endian:
  return string.char(rshift(w, 24), band(255, rshift(w, 16)), band(255, rshift(w, 8)), band(255, w))
end

return function(message, binary)
  local h0, h1, h2, h3, h4 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0

  -- process the initial 64 byte chunks
  for start = 1, #message - 63, 64 do
    h0, h1, h2, h3, h4 = hash_chunk(message, start, h0, h1, h2, h3, h4)
  end

  local message_len_in_bits = #message * 8

  -- 1 or 2 extra chunks (2 chunks only if #message%64 >= 56):
  last_chunks = ('%s\128%s%s%s'):format(
    -- tail part of the message:
    message:sub(math.floor(#message/64) * 64 + 1),
    -- padding made up of enough \0 bytes so that #last_chunks is multiple of 64:
    string.rep('\0', (119 - #message%64) % 64),
    -- upper word for message length in bits:
    encode_word(math.floor(message_len_in_bits / 4294967296)),
    -- lower word for message length in bits:
    encode_word(band(-1, message_len_in_bits))
  )
  for start = 1, #last_chunks - 63, 64 do
    h0, h1, h2, h3, h4 = hash_chunk(last_chunks, start, h0, h1, h2, h3, h4)
  end

  if binary then
    return ('%s%s%s%s%s'):format(encode_word(h0), encode_word(h1), encode_word(h2), encode_word(h3), encode_word(h4))
  else
    return ('%s%s%s%s%s'):format(tohex(h0), tohex(h1), tohex(h2), tohex(h3), tohex(h4))
  end
end
