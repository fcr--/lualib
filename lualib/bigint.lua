--[[
# bigint: Library for Big Integers.

Internal representation: an atom is divided in 1..n atoms
- sign: -1, 0 or 1, the sign... duh...
- [1]: contains the least significant atom...
- ...
- [n]: the uppermost atom, must be non-zero
]]
local bit = bit or require 'bit32'

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bnot = bit.bnot
local rshift = bit.rshift
local lshift = bit.lshift

local bigint = {}
local mt = {__index = bigint}

local one = setmetatable({1, sign=1}, mt)
local zero = setmetatable({sign=0}, mt)

local atombits = 16
local atombase = lshift(1, atombits)
local atommask = atombase - 1
-- (10000, 4) for atombase 16
local atomdecmodulo, atomdecexp = 1, 0
while atomdecmodulo * 10 < atombase do
  atomdecmodulo = atomdecmodulo * 10
  atomdecexp = atomdecexp + 1
end

local function new(n)
  if n == 0 then return zero end
  if n == 1 then return one end
  local res = setmetatable({}, mt)
  if type(n) == 'number' then
    assert(n == math.floor(n), 'bigints must be integers')
    if n < 0 then
      n = -n
      res.sign = -1
    else
      res.sign = 1
    end
    while n ~= 0 do
      res[#res+1] = n % atombase
      n = math.floor(n / atombase)
    end
  else
    error 'TODO: implement'
  end
  return res
end

-- CRT: A function that returns an x: 0<=x<min{ns}, such that:
--    x % ns[i] == as[i] for all 1<=i<=#ns
local function crt(ns, as)
  local prod = ns[1]
  for i = 2, #ns do prod = prod * ns[i] end

  local sum = 0
  for i, n in ipairs(ns) do
    local N = prod / n
    local inv = select(2, N:gcd(n)) -- (inv*N)%n == 1
    sum = sum + as[i]*inv*N
  end
  return sum % prod
end

local function copy(x)
  local res = setmetatable({sign = x.sign}, mt)
  for i = 1, #x do res[i] = x[i] end
  return res
end

-- mutates x removing trailing zeros and adjusting the sign to 0 if necessary
local function normalize(x)
  for i = #x, 1, -1 do
    if x[i] ~= 0 then break end
    x[i] = nil
  end
  if #x == 0 then x.sign = 0 end
  return x
end

-- returns the sign of the first argument:
local function raw_add(x, y)
  local res = setmetatable({sign = x.sign}, mt)
  local carry = 0
  for i = 1, math.max(#x, #y) do
    local t = (x[i] or 0) + (y[i] or 0) + carry
    res[i] = band(t, atommask)
    carry = rshift(t, atombits)
  end
  if carry > 0 then
    res[#res+1] = carry
  end
  return res
end

-- precondition: abs(x) >= abs(y)
-- returns the sign of the first argument
local function raw_sub(x, y)
  local res = setmetatable({sign = x.sign}, mt)
  local carry = 0
  for i = 1, #x do
    local t = x[i] - (y[i] or 0) - carry
    res[i] = band(t, atommask)
    carry = t<0 and 1 or 0
  end
  assert(carry == 0)
  return normalize(res)
end

-- simple utility function to shorten the code of several methods
local function setsign(x, sign)
  x.sign = sign
  return x
end

function mt:__add(other)
  if self.sign == 0 then return other end
  if other.sign == 0 then return self end
  if self.sign == other.sign then return raw_add(self, other) end

  if self:abscmp(other) > 0 then
    -- 2+(-1)=>pos, (-2)+1=>neg (self's sign)
    return raw_sub(self, other)
  else -- 1+(-2)=>neg, (-1)+2=>pos (other's sign)
    return raw_sub(other, self)
  end
end

function mt:__div(other)
  return select(1, self:divmod(other))
end

function mt:__eq(other)
  return self:cmp(other) == 0
end

function mt:__le(other)
  return self:cmp(other) <= 0
end

function mt:__lt(other)
  return self:cmp(other) < 0
end

function mt:__mod(other)
  return select(2, self:divmod(other))
end

function mt:__mul(other)
  error 'TODO: implement'
end

-- power must be an integer number
function mt:__pow(power)
  error 'TODO: implement'
end

function mt:__sub(other)
  -- controlled mutation (don't try this at home):
  other.sign = -other.sign
  local res = self + other
  other.sign = -other.sign
  return res
end

function mt:__tostring()
  return self:tostring 'hex'
end

function mt:__unm()
  return setsign(copy(self), -self.sign)
end

function bigint:abs()
  return setsign(copy(self), math.abs(self.sign))
end

-- compare absolute values returning -1, 0 or 1 depending on whether the
-- absolute value of self is <, = or > than the absolute value of other
function bigint:abscmp(other)
  if #self < #other then return -1 end
  if #self > #other then return 1 end
  for i = #self, 1, -1 do
    local delta = self[i] - other[i]
    if delta < 0 then return -1 end
    if delta > 0 then return 1 end
  end
  return 0
end

function bigint:band(other)
  local res = setmetatable({sign = math.max(self.sign, other.sign)}, mt)
  for i = 1, math.min(#self, #other) do
    res[i] = band(self[i], other[i])
  end
  return normalize(res)
end

function bigint:bor(other)
  local T = {[-1] = -1, [0] = 1, 1}
  local res = setmetatable({sign = math.min(T[self.sign], T[other.sign])}, mt)
  for i = 1, math.max(#self, #other) do
    res[i] = bor(self[i] or 0, other[i] or 0)
  end
  return normalize(res)
end

function bigint:bxor(other)
  local T = {[-1] = -1, [0] = 1, 1}
  local res = setmetatable({sign = T[self.sign] * T[other.sign]}, mt)
  for i = 1, math.max(#self, #other) do
    res[i] = bxor(self[i] or 0, other[i] or 0)
  end
  return normalize(res)
end

function bigint:cmp(other)
  if self.sign < other.sign then return -1 end
  if self.sign > other.sign then return 1 end
  if self.sign >= 0 then return self:abscmp(other) end
  return -self:abscmp(other)
end

function bigint:divmodatom(d)
  if d < 0 then
    self.sign = -self.sign
    local q, r = self:divmodatom(-d)
    self.sign = -self.sign
    return q, -r
  end
  assert(d > 0, 'division by zero')
  local res = setmetatable({sign = self.sign}, mt)
  local remainder = 0
  for i = #self, 1, -1 do
    local tmp = bor(lshift(remainder, atombits), self[i])
    res[i] = math.floor(tmp / d)
    remainder = tmp % d
  end
  -- we must always ensure: ⌊x/d⌋*d + (x%d) == x
  -- the modulus is different to the remainder in that it always has the
  -- same sign as the divisor d.
  if self.sign < 0 and remainder ~= 0 then
    -- add 1 to res' value:
    for i = 1, #res do
      res[i] = (res[i] or 0) + 1
      if res[i] < atombase then break end
      res[i] = 0
    end
    return res, d - remainder
  end
  return normalize(res), remainder
end

function bigint:gcd(other)
  if self.sign == 0 or other.sign == 0 then
    return one
  end
  if self.sign < 0 then self = self:abs() end
  if other.sign < 0 then other = other:abs() end

  local pr, r = self, other
  local ps, s = one, zero
  local pt, t = zero, one
  while r.sign ~= 0 do
    local q = pr / r
    pr, r = r, pr - q*r
    ps, s = s, ps - q*s
    pt, t = t, pt - q*t
  end
  if ps.sign < 0 then ps = ps + other:abs() end
  return pr, ps, pt
end

function bigint:iseven()
  return band(self[1] or 0, 1) == 0
end

function bigint:isodd()
  return not self:iseven()
end

function bigint:lenbits()
  if self.sign == 0 then return 0 end
  local log2 = (#self - 1) * atombits
  local n = self[#self]
  if n >= 256 then
    log2 = log2 + 8
    n = rshift(n, 8)
  end
  while n > 0 do
    log2 = log2 + 1
    n = rshift(n, 1)
  end
  return log2
end

function bigint:lshift(n)
  local res = setmetatable({sign = self.sign}, mt)
  local natoms, nbits = math.floor(n / atombits), n % atombits
  for i = 1, natoms do
    res[i] = 0
  end
  local tmp = 0
  for i = natoms + 1, natoms + #self do
    tmp = bor(tmp, lshift(self[i - natoms], nbits))
    res[i] = band(tmp, atommask)
    tmp = rshift(tmp, atombits)
  end
  return res
end

function bigint:powmod(power, mod)
  error 'TODO: implement'
end

function bigint:rshift(n)
  local res = setmetatable({sign = self.sign}, mt)
  local natoms, nbits = math.floor(n / atombits), n % atombits
  local tmp = rshift(self[1 + natoms], nbits)
  for i = 1, #self - natoms do
    tmp = bor(tmp, lshift(self[i + natoms + 1] or 0, atombits))
    res[i] = band(tmp, atommask)
    tmp = rshift(tmp, atombits)
  end
  return res
end

function bigint:tostring(fmt, opts)
  local tokens
  local needsreverse = false
  opts = opts or {}

  if fmt == 'hex' then
    -- this is way faster than base10
    if self.sign == 0 then return opts.zero or '0' end
    tokens = {
      self.sign < 0 and (opts.minus_sign or '-') or (opts.plus_sign or ''),
      opts.prefix or '0x',
    }
    assert(atombits%4 == 0, 'not supported for this atombits value')
    local hexformat = ('%%0%dx'):format(atombits / 4)
    tokens[#tokens + 1] = ('%x'):format(self[#self])
    for i = #self-1, 1, -1 do
      tokens[#tokens + 1] = hexformat:format(self[i])
    end

  elseif fmt == 'raw' then
    -- same as java's BigInteger toByteArray:
    -- > Returns a byte array containing the two's-complement representation
    -- > of this BigInteger. The byte array will be in big-endian byte-order:
    -- > the most significant byte is in the zeroth element. The array will
    -- > contain the minimum number of bytes required to represent this
    -- > BigInteger
    assert(atombits==16, 'not supported for this atombits value')
    if self.sign == 0 then return opts.zero or '\0' end
    tokens = {}
    if self.sign > 0 then
      local x = self[#self]
      if x < 128 then
        tokens[1] = string.char(x)
      elseif x < 32768 then
        tokens[1] = string.char(rshift(x, 8), band(x, 255))
      else  -- we need an extra nil byte :(
        tokens[1] = string.char(0, rshift(x, 8), band(x, 255))
      end
      for i = #self - 1, 1, -1 do
        x = self[i]
        tokens[#tokens+1] = string.char(rshift(x, 8), band(x, 255))
      end
    else
      -- the negative case is a bit tricky, we need to reverse the parts
      needsreverse = true

      local carry = 1
      local x
      for i = 1, #self - 1 do
        x = self[i] - carry
        carry = x < 0 and 1 or 0
        x = bxor(x, 0xffff)
        tokens[#tokens+1] = string.char(rshift(x, 8), band(x, 255))
      end
      -- self[#self] here is always >0, thus we can substract the carry no
      -- matter its value, yet its uppermost bit must be zero (before the xor)
      x = self[#self] - carry
      if x < 128 then
        tokens[#tokens+1] = string.char(bxor(0xff, x))
      else
        local y = bxor(0xffff, x)
        tokens[#tokens+1] = string.char(rshift(y, 8), band(y, 255))
        if x >= 32768 then
          tokens[#tokens+1] = '\255'
        end
      end
    end

  elseif fmt == 'dec' then
    if self.sign == 0 then return opts.zero or '0' end
    tokens = {}
    local n = self.sign > 0 and self or -self
    local decformat = ('%%0%dd'):format(atomdecexp)
    local r
    while n > zero do
      n, r = n:divmodatom(atomdecmodulo)
      if n ~= zero then
        tokens[#tokens+1] = decformat:format(r)
      else
        -- last token, without leading zeros, r is always > 0:
        tokens[#tokens+1] = ('%d'):format(r)
      end
    end
    -- the sign is added at the end because we reverse the array:
    tokens[#tokens+1] = (
      self.sign < 0 and (opts.minus_sign or '-') or (opts.plus_sign or '')
    )
    needsreverse = true
  else
    error 'unsupported base'
  end
  if needsreverse then
    for i = 1, math.floor(#tokens/2) do
      tokens[i], tokens[#tokens-i+1] = tokens[#tokens-i+1], tokens[i]
    end
  end
  return table.concat(tokens)
end

return {
  atombase = atombase,
  atombits = atombits,
  atommask = atommask,
  crt = crt,
  mt = mt,
  new = new,
  one = one,
  zero = zero,
}
