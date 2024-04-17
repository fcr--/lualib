--[[
#Pure lua SHA-3

This implementation will try to conform to SHA-3 os defined in: [NIST FIPS.202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf)
with the help of: [Computer Security (3rd ed.) - Appendix K: SHA-3, William Stallings](https://people.duke.edu/~tkb13/courses/ncsu-csc405-2015fa/RESOURCES/Compsec3e_Appendices/K-SHA-3.pdf)

Note that this implementation is full vulnerabilities like not caring
about side channel attacks, memory cleanup, locking memory to avoid
swapping, memory guards, performance, etc...

Do not use this code in production expecting security or performance.

For the sake of simplicity this implementation has fixed state size with
b=1600, thus: w=64, ℓ=6; but since the bit library only supports 32-bit
words we represent our state as a 0-base indexed int32 table, int32[0..49],
where:

    state[2*(i+5*j)]   = A[i,j, 0] ‖ … ‖ A[i,j,31]
    state[2*(i+5*j)+1] = A[i,j,32] ‖ … ‖ A[i,j,63]
    Lane(i, j)         = A[i,j,0] ‖ … ‖ A[i,j,63]
                       = state[2*(i+5*j)] ‖ state[2*(i+5*j)+1]
    state[0] ‖ … ‖ state[49]
       = Lane(0,0) ‖ Lane(1,0) ‖ Lane(2,0) ‖ Lane(3,0) ‖ Lane(4,0)
       ‖ Lane(0,1) ‖ Lane(1,1) ‖ Lane(2,1) ‖ Lane(3,1) ‖ Lane(4,1)
       ‖ Lane(0,2) ‖ Lane(1,2) ‖ Lane(2,2) ‖ Lane(3,2) ‖ Lane(4,2)
       ‖ Lane(0,3) ‖ Lane(1,3) ‖ Lane(2,3) ‖ Lane(3,3) ‖ Lane(4,3)
       ‖ Lane(0,4) ‖ Lane(1,4) ‖ Lane(2,4) ‖ Lane(3,4) ‖ Lane(4,4).
]]

local bit = bit or require 'bit32'

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bnot = bit.bnot
local rshift = bit.rshift
local lshift = bit.lshift
local rol = bit.rol or function(word, bits) return bor(lshift(word, bits), rshift(word, 32-bits)) end
local tohex = bit.tohex or function(word) return ('%08x'):format(bor(0, word)) end
local function encode_word(w)
  -- encoded in big-endian:
  return string.char(rshift(w, 24), band(255, rshift(w, 16)), band(255, rshift(w, 8)), band(255, w))
end


local iota_constants = {
  [ 0] = {hi=0x00000000, lo=0x00000001},
  [ 1] = {hi=0x00000000, lo=0x00008082},
  [ 2] = {hi=0x80000000, lo=0x0000808A},
  [ 3] = {hi=0x80000000, lo=0x80008000},
  [ 4] = {hi=0x00000000, lo=0x0000808B},
  [ 5] = {hi=0x00000000, lo=0x80000001},
  [ 6] = {hi=0x80000000, lo=0x80008081},
  [ 7] = {hi=0x80000000, lo=0x00008009},
  [ 8] = {hi=0x00000000, lo=0x0000008A},
  [ 9] = {hi=0x00000000, lo=0x00000088},
  [10] = {hi=0x00000000, lo=0x80008009},
  [11] = {hi=0x00000000, lo=0x8000000A},
  [12] = {hi=0x00000000, lo=0x8000808B},
  [13] = {hi=0x80000000, lo=0x0000008B},
  [14] = {hi=0x80000000, lo=0x00008089},
  [15] = {hi=0x80000000, lo=0x00008003},
  [16] = {hi=0x80000000, lo=0x00008002},
  [17] = {hi=0x80000000, lo=0x00000080},
  [18] = {hi=0x00000000, lo=0x0000800A},
  [19] = {hi=0x80000000, lo=0x8000000A},
  [20] = {hi=0x80000000, lo=0x80008081},
  [21] = {hi=0x80000000, lo=0x00008080},
  [22] = {hi=0x00000000, lo=0x80000001},
  [23] = {hi=0x80000000, lo=0x80008008},
}
local function iota(state, ir)
  -- here we modify state[0] and state[1] only (aka Lane(0,0)): RC = lo‖hi
  local round_constant = iota_constants[ir]
  state[0] = bxor(state[0], round_constant.lo)
  state[1] = bxor(state[1], round_constant.hi)
end

local function keccak_p24(state, nr)
  for round = 0, 23 do
    state = chi(pi(rho(theta(state)))), round
    iota(state, round)
  end
end

local function shake256(message, output_format, output_size)
  error 'not implemented'
end

return {
  internals = {
    iota_constants = iota_constants,
    iota = iota,
  },
  sha3_224 = nil,
  sha3_256 = nil,
  sha3_384 = nil,
  sha3_512 = nil,
  shake128 = nil,
  shake256 = shake256,
}
