local bit = bit or require 'bit32'

local bxor = bit.bxor
local bnot = bit.bnot
local band = bit.band
local rshift = bit.rshift
local lshift = bit.lshift
local rol = bit.rol or function(w, offset)
  return bxor(lshift(w, offset), rshift(w, 32-offset))
end


local function word2bytes(w)
  return rshift(w, 24), band(rshift(w, 16), 255), band(rshift(w, 8), 255), band(w, 255)
end
local function bytes2word(b0, b1, b2, b3)
  return bxor(lshift(b0, 24), lshift(band(b1, 255), 16), lshift(band(b2, 255), 8), band(b3, 255))
end


local sbox = {
  [0]=0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
  0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
  0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
  0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
  0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
  0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
  0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
  0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
  0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
  0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
  0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
  0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
  0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
  0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
  0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
  0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
}

local sbox_inv = {}
for i, v in pairs(sbox) do sbox_inv[v] = i end

local function subbytes(a)
  local x0, x1, x2, x3 = word2bytes(a)
  return bytes2word(sbox[x0], sbox[x1], sbox[x2], sbox[x3])
end

local function subbytes_inv(a)
  local x0, x1, x2, x3 = word2bytes(a)
  return bytes2word(sbox_inv[x0], sbox_inv[x1], sbox_inv[x2], sbox_inv[x3])
end


local function shiftrows(c0, c1, c2, c3)
  -- c0, c1, c2, c3: columns (left to right) of the state to rotate.
  local c00, c01, c02, c03 = word2bytes(c0)
  local c10, c11, c12, c13 = word2bytes(c1)
  local c20, c21, c22, c23 = word2bytes(c2)
  local c30, c31, c32, c33 = word2bytes(c3)
  return bytes2word(c00, c11, c22, c33),
    bytes2word(c10, c21, c32, c03),
    bytes2word(c20, c31, c02, c13),
    bytes2word(c30, c01, c12, c23)
end

local function shiftrows_inv(c0, c1, c2, c3)
  -- c0, c1, c2, c3: columns (left to right) of the state to rotate.
  local c00, c01, c02, c03 = word2bytes(c0)
  local c10, c11, c12, c13 = word2bytes(c1)
  local c20, c21, c22, c23 = word2bytes(c2)
  local c30, c31, c32, c33 = word2bytes(c3)
  return bytes2word(c00, c31, c22, c13),
    bytes2word(c10, c01, c32, c23),
    bytes2word(c20, c11, c02, c33),
    bytes2word(c30, c21, c12, c03)
end


local function mixcolumn(col)
  -- most significant byte contains the byte for the uppermost row.
  local x0, x1, x2, x3 = word2bytes(col)
  -- yi = 2*xi (mod ζ⁸+ζ⁴+ζ³+ζ+1)
  local y0 = x0 >= 128 and bxor(x0+x0, 0x11b) or x0+x0
  local y1 = x1 >= 128 and bxor(x1+x1, 0x11b) or x1+x1
  local y2 = x2 >= 128 and bxor(x2+x2, 0x11b) or x2+x2
  local y3 = x3 >= 128 and bxor(x3+x3, 0x11b) or x3+x3
  return bytes2word(
    bxor(y0, y1, x1, x2, x3),
    bxor(x0, y1, y2, x2, x3),
    bxor(x0, x1, y2, y3, x3),
    bxor(y0, x0, x1, x2, y3))
end

local function mixcolumn_inv(col)
  -- most significant byte contains the byte for the uppermost row.
  local x0, x1, x2, x3 = word2bytes(col)
  -- yi = 2*xi (mod ζ⁸+ζ⁴+ζ³+ζ+1), zi=4*xi, w=8*xi
  local y0 = x0 >= 128 and bxor(x0+x0, 0x11b) or x0+x0
  local y1 = x1 >= 128 and bxor(x1+x1, 0x11b) or x1+x1
  local y2 = x2 >= 128 and bxor(x2+x2, 0x11b) or x2+x2
  local y3 = x3 >= 128 and bxor(x3+x3, 0x11b) or x3+x3

  local z0 = y0 >= 128 and bxor(y0+y0, 0x11b) or y0+y0
  local z1 = y1 >= 128 and bxor(y1+y1, 0x11b) or y1+y1
  local z2 = y2 >= 128 and bxor(y2+y2, 0x11b) or y2+y2
  local z3 = y3 >= 128 and bxor(y3+y3, 0x11b) or y3+y3

  local w0 = z0 >= 128 and bxor(z0+z0, 0x11b) or z0+z0
  local w1 = z1 >= 128 and bxor(z1+z1, 0x11b) or z1+z1
  local w2 = z2 >= 128 and bxor(z2+z2, 0x11b) or z2+z2
  local w3 = z3 >= 128 and bxor(z3+z3, 0x11b) or z3+z3
  return bytes2word(
    bxor(w0, z0, y0,  w1, y1, x1,  w2, z2, x2,  w3, x3),  -- 0e 0b 0d 09 = 1110 1011 1101 1001
    bxor(w0, x0,  w1, z1, y1,  w2, y2, x2,  w3, z3, x3),  -- 09 0e 0b 0d = 1001 1110 1011 1101
    bxor(w0, z0, x0,  w1, x1,  w2, z2, y2,  w3, y3, x3),  -- 0d 09 0e 0b = 1101 1001 1110 1011
    bxor(w0, y0, x0,  w1, z1, x1,  w2, x2,  w3, z3, y3))  -- 0b 0d 09 0e = 1011 1101 1001 1110
end


local function addroundkey(W, round, c0, c1, c2, c3)
  -- W is the array returned by keyschedule,
  -- round is the round number 0..(10, 12, 14)
  -- c0, c1, c2, c3: columns of the state
  local i = 4*round + 1
  return bxor(c0, W[i]), bxor(c1, W[i+1]), bxor(c2, W[i+2]), bxor(c3, W[i+3])
end


local function cipher(W, c0, c1, c2, c3)
  c0, c1, c2, c3 = addroundkey(W, 0, c0, c1, c2, c3)

  local Nr = #W/4-1  -- since #W == 4*(Nr+1)
  for round = 1, Nr-1 do
    c0, c1, c2, c3 = subbytes(c0), subbytes(c1), subbytes(c2), subbytes(c3)
    c0, c1, c2, c3 = shiftrows(c0, c1, c2, c3)
    c0, c1, c2, c3 = mixcolumn(c0), mixcolumn(c1), mixcolumn(c2), mixcolumn(c3)
    c0, c1, c2, c3 = addroundkey(W, round, c0, c1, c2, c3)
  end

  c0, c1, c2, c3 = subbytes(c0), subbytes(c1), subbytes(c2), subbytes(c3)
  c0, c1, c2, c3 = shiftrows(c0, c1, c2, c3)
  return addroundkey(W, Nr, c0, c1, c2, c3)
end

-- This function decrypts a single aes block, where W is the result of
-- keyschedule and c0, c1, c3, c3 is the cipher text represented as 4 32bit
-- integers of the AES state columns.
--   The result is the plain text as 4 32bit integers.
local function cipher_inv(W, c0, c1, c2, c3)
  local Nr = #W/4-1  -- since #W == 4*(Nr+1)
  c0, c1, c2, c3 = addroundkey(W, Nr, c0, c1, c2, c3)

  for round = Nr-1, 1, -1 do
    c0, c1, c2, c3 = shiftrows_inv(c0, c1, c2, c3)
    c0, c1, c2, c3 = subbytes_inv(c0), subbytes_inv(c1), subbytes_inv(c2), subbytes_inv(c3)
    c0, c1, c2, c3 = addroundkey(W, round, c0, c1, c2, c3)
    c0, c1, c2, c3 = mixcolumn_inv(c0), mixcolumn_inv(c1), mixcolumn_inv(c2), mixcolumn_inv(c3)
  end

  c0, c1, c2, c3 = shiftrows_inv(c0, c1, c2, c3)
  c0, c1, c2, c3 = subbytes_inv(c0), subbytes_inv(c1), subbytes_inv(c2), subbytes_inv(c3)
  return addroundkey(W, 0, c0, c1, c2, c3)
end


local keyschedule_rcon = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36}
for i, v in ipairs(keyschedule_rcon) do keyschedule_rcon[i] = lshift(v, 24) end

local function keyschedule(key)
  -- key is a string of 4 to 8 words (16 to 32 bytes) (AES-128 to AES-256)
  assert(#key==16 or #key==24 or #key==32, 'invalid key length')
  local n = #key / 4
  local rounds = ({[4]=11, [6]=13, [8]=15})[n]
  local W = {}
  for i = 1, n do
    W[i] = bytes2word(key:byte(4*i-3, 4*i))
  end
  for i = n, 4*rounds-1 do
    if i%n == 0 then
      W[i+1] = bxor(W[i-n+1], subbytes(rol(W[i], 8)), keyschedule_rcon[i/n])
    elseif n > 6 and i%n == 4 then
      W[i+1] = bxor(W[i-n+1], subbytes(W[i]))
    else
      W[i+1] = bxor(W[i-n+1], W[i])
    end
  end
  return W
end


return {
  subbytes = subbytes,
  shiftrows = shiftrows,
  mixcolumn = mixcolumn,
  addroundkey = addroundkey,
  cipher = cipher,
  cipher_inv = cipher_inv,
  keyschedule = keyschedule,
}
