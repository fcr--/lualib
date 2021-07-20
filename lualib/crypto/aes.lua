local bit = bit or require 'bit32'

local bxor = bit.bxor
local bnot = bit.bnot
local band = bit.band
local rshift = bit.rshift
local lshift = bit.lshift
local rol = bit.rol or function(w, offset)
  return bxor(lshift(w, offset), rshift(w, 32-offset))
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
  local x0 = band(a, 255)
  local x1 = band(rshift(a, 8), 255)
  local x2 = band(rshift(a, 16), 255)
  local x3 = rshift(a, 24)
  return bxor(lshift(sbox[x3], 24), lshift(sbox[x2], 16), lshift(sbox[x1], 8), sbox[x0])
end

local function mixcolumns(a0, a1, a2, a3)
  local r0, r1, r2, r3 = 0, 0, 0, 0
  for i = 0, 24, 8 do
    local x0, x1, x2, x3 = rshift(a0, 24), rshift(a1, 24), rshift(a2, 24), rshift(a3, 24)
    a0, a1, a2, a3 = lshift(a0, 8), lshift(a1, 24), lshift(a2, 24), lshift(a3, 24)
    local y0 = x0 >= 128 and bxor(x0+x0, 0x11b) or x0+x0
    local y1 = x1 >= 128 and bxor(x1+x1, 0x11b) or x1+x1
    local y2 = x2 >= 128 and bxor(x2+x2, 0x11b) or x2+x2
    local y3 = x3 >= 128 and bxor(x3+x3, 0x11b) or x3+x3
    r0 = bxor(lshift(r0, 8), y0, y1, x1, x2, x3)
    r1 = bxor(lshift(r1, 8), x0, y1, y2, x2, x3)
    r2 = bxor(lshift(r2, 8), x0, x1, y2, y3, x3)
    r3 = bxor(lshift(r3, 8), y0, x0, x1, x2, y3)
  end
  return r0, r1, r2, r3
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
    local b0, b1, b2, b3 = key:byte(4*i-3, 4*i)
    W[i] = bxor(lshift(b0, 24), lshift(b1, 16), lshift(b2, 8), b3)
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
  mixcolumn = mixcolumns,
  keyschedule = keyschedule,
}
