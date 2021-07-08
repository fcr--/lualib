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
local tenmillion = setmetatable({38528, 152, sign=1}, mt)

local atombits = 16
local atombase = lshift(1, atombits)
local atommask = atombase - 1
-- (10000, 4) for atombase 16
local atomdecmodulo, atomdecexp = 1, 0
while atomdecmodulo * 10 < atombase do
  atomdecmodulo = atomdecmodulo * 10
  atomdecexp = atomdecexp + 1
end


local empty
local normalize


local function new(n)
  if n == 0 or n == '0' then return zero end
  if n == 1 then return one end
  local res = empty(1)
  if type(n) == 'number' then
    assert(n == math.floor(n), 'bigints must be integers')
    if n < 0 then
      n = -n
      res.sign = -1
    end
    while n ~= 0 do
      res[#res+1] = n % atombase
      n = math.floor(n / atombase)
    end
  elseif type(n) == 'string' then
    local sign, start, base = 1, 1, 10
    if n:find('^-') then sign, start = -1, 2 end
    if n:find('^0x', start) then base, start = 16, start+2 end
    if base == 10 then
      res = zero
      -- we must iterate starting on a give position start-6<=i<=start,
      -- such that the last token has size 7, this means that this initial
      -- position i has to be congruent with #n-6 modulo 7, that's why we
      -- subtract that crazy stuff:
      for i = start-(start+6-#n)%7, #n-6, 7 do
        local chunk = n:sub(math.max(i, start), i+6)
        res = res:bmul(tenmillion) + new(tonumber(chunk))
      end
    elseif base == 16 then
      assert(atombits%4 == 0, 'not supported for this atombits value')
      local hexdigits = atombits / 4
      for i = #n-hexdigits+1, start-hexdigits+1, -hexdigits do
        res[#res+1] = tonumber(n:sub(math.max(i, start), i+hexdigits-1), 16)
      end
    else
      error 'unsupported base'  -- this error cannot happen, but meh...
    end
    res.sign = sign
  else
    error 'TODO: implement'
  end
  return normalize(res)
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


function empty(sign)
  return setmetatable({sign = sign}, mt)
end


-- mutates x removing trailing zeros and adjusting the sign to 0 if necessary
function normalize(x)
  for i = #x, 1, -1 do
    if x[i] ~= 0 then break end
    x[i] = nil
  end
  if #x == 0 then x.sign = 0 end
  return x
end


-- returns the sign of the first argument:
local function raw_add(x, y)
  local res = empty(x.sign)
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
  local res = empty(x.sign)
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
  if self.sign == 0 or other.sign == 0 then return zero end
  if self == one then return other end
  if other == one then return self end

  -- For "small"-ish numbers we might just use the traditional multiplication
  -- since it takes about the same time as the karatsuba versions but without
  -- making so much garbage (aka, let's avoid adding extra work to the gc):
  if #self < 400 or #other < 400 then return self:bmul(other) end

  -- Even though kmul_unrolled generates a bit more garbage, it's a bit
  -- faster than kmul_unrolled2 (btw, on my computer a threshold of 185 seems
  -- to maximize the runtime ratio over bmul):
  return self:kmul_unrolled(other, 185)
end


-- power must be an integer number
function mt:__pow(power)
  error 'TODO: implement'
end


function mt:__sub(other)
  if rawequal(self, other) then return zero end
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
  return setsign(self:copy(), -self.sign)
end


function bigint:abs()
  return setsign(self:copy(), math.abs(self.sign))
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
  local res = empty(math.max(self.sign, other.sign))
  for i = 1, math.min(#self, #other) do
    res[i] = band(self[i], other[i])
  end
  return normalize(res)
end


-- Hamming Weight of its absolute number.
function bigint:bcount()
  local weights4bit = {[0]=0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4}
  local sum = 0
  for i, x in ipairs(self) do
    sum = sum + weights4bit[band(x, 15)]; x = rshift(x, 4)
    sum = sum + weights4bit[band(x, 15)]; x = rshift(x, 4)
    sum = sum + weights4bit[band(x, 15)]; x = rshift(x, 4)
    sum = sum + weights4bit[band(x, 15)]
  end
  return sum
end


-- Basic Multiplication:
function bigint:bmul(other)
  local res = empty(self.sign * other.sign)
  if res.sign == 0 then return res end
  for j = 1, #other do
    local carry = 0
    for i = 1, #self do
      -- note that B * C + D + E, with A if B,C,D and E having N bits will
      -- be representable in 2N bits, since:
      -- (2^N-1)*(2^N-1) + (2^N-1) + (2^N-1) == 2^(2N)-1
      local mul = self[i]*other[j] + (res[i+j-1] or 0) + carry
      carry = rshift(mul, atombits)
      res[i+j-1] = band(mul, atommask)
    end
    if carry ~= 0 then
      -- biggest index was at res[#self+j-1]:
      res[#self+j] = carry
    end
  end
  return res  -- there's no need to normalize it
end


function bigint:bor(other)
  local T = {[-1] = -1, [0] = 1, 1}
  local res = empty(math.min(T[self.sign], T[other.sign]))
  for i = 1, math.max(#self, #other) do
    res[i] = bor(self[i] or 0, other[i] or 0)
  end
  return normalize(res)
end


function bigint:bxor(other)
  local T = {[-1] = -1, [0] = 1, 1}
  local res = empty(T[self.sign] * T[other.sign])
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


function bigint:copy()
  local res = empty(self.sign)
  for i = 1, #self do res[i] = self[i] end
  return res
end


function bigint:divmodatom(d)
  if d < 0 then
    self.sign = -self.sign
    local q, r = self:divmodatom(-d)
    self.sign = -self.sign
    return q, -r
  end
  assert(d > 0, 'division by zero')
  local res = empty(self.sign)
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


-- Karatsuba multiplication:
function bigint:kmul(other, karatsuba_threshold)
  local nmin = math.min(#self, #other)
  if nmin < karatsuba_threshold then
    return self:bmul(other)
  end

  local m = math.floor(nmin / 2 + 0.6)
  local x0, y0, x1, y1 = empty(1), empty(1), empty(1), empty(1)
  for i = 1, m do
    x0[i] = self[i]
    y0[i] = other[i]
  end
  normalize(x0)
  normalize(y0)
  for i = m+1, #self do x1[#x1+1] = self[i] end
  for i = m+1, #other do y1[#y1+1] = other[i] end

  local p2 = x1:kmul(y1, karatsuba_threshold)
  local p0 = x0:kmul(y0, karatsuba_threshold)
  x0:mutable_unsigned_add(x1)
  y0:mutable_unsigned_add(y1)
  local p1 = x0:kmul(y0, karatsuba_threshold) - p2 - p0

  return setsign(
    p2:lshift(2*m*atombits) + p1:lshift(m*atombits) + p0,
    self.sign * other.sign)
end


function bigint:kmul_unrolled(other, karatsuba_threshold)
  local nmin = math.min(#self, #other)
  if nmin < karatsuba_threshold then
    return self:bmul(other)
  end

  local m = math.floor(nmin / 2 + 0.6)
  local x0, y0, x1, y1 = empty(1), empty(1), empty(1), empty(1)
  for i = 1, m do
    x0[i] = self[i]
    y0[i] = other[i]
  end
  normalize(x0)
  normalize(y0)
  for i = m+1, #self do x1[#x1+1] = self[i] end
  for i = m+1, #other do y1[#y1+1] = other[i] end

  local p2 = x1:kmul_unrolled(y1, karatsuba_threshold)
  local p0 = x0:kmul_unrolled(y0, karatsuba_threshold)
  x0:mutable_unsigned_add(x1)
  y0:mutable_unsigned_add(y1)
  local p1 = x0:kmul_unrolled(y0, karatsuba_threshold)  -- - p2 - p0

  -- equivalent to: p1 = p1 - y
  -- (here we assume p1 >= y)
  local function raw_sub_from_p1(substraend)
    local carry = 0
    --print('p1', p1)
    --print('  -'..name, substraend)
    for i = 1, #p1 do
      local t = p1[i] - (substraend[i] or 0) - carry
      p1[i] = band(t, atommask)
      carry = t<0 and 1 or 0
    end
    if carry ~= 0 then
      error(('carry ~= 0, %s - %s'):format(p1, substraend))
    end
  end
  raw_sub_from_p1(p2)
  raw_sub_from_p1(p0)
  normalize(p1)

  local function add_into_p0_with_offset(src, offset_words)
    if src.sign == 0 then return end
    for i = #p0+1, offset_words do
      p0[i] = 0
    end
    local carry = 0
    for i = 1, #src do
      local t = (p0[i+offset_words] or 0) + src[i] + carry
      p0[i+offset_words] = band(t, atommask)
      carry = rshift(t, atombits)
    end
    local i = #src + 1
    while carry > 0 do
      local t = (p0[i+offset_words] or 0) + carry
      p0[i+offset_words] = band(t, atommask)
      carry = rshift(t, atombits)
      i = i + 1
    end
  end

  add_into_p0_with_offset(p2, m+m)
  add_into_p0_with_offset(p1, m)
  return setsign(p0, self.sign * other.sign)
end


-- This version is not used, however I leave it here as an example of an
-- optimization attempt that actually doesn't work.  I suspect that the
-- reason is that across all recursive calls the average abs(#self-#other)
-- is greater than on kmul_unrolled, meaning less opportunities for reducing
-- the total number of multiplications performed.
-- Also, reusing the nodes means that we cannot use the mutable_unsigned_add.
function bigint:kmul_unrolled2(other, karatsuba_threshold)
  local function build_karatsuba_tree(n, length, depth)
    local m = math.floor(length / 2 + 0.6)
    if depth <= 0 then
      return {n=n}
    end

    local hi_n, lo_n = empty(1), empty(1)
    for i = 1, m do lo_n[i] = n[i] end
    for i = m+1, #n do hi_n[#hi_n+1] = n[i] end
    return {
      hi = build_karatsuba_tree(hi_n, m, depth-1),
      lo = build_karatsuba_tree(normalize(lo_n), m, depth-1),
      n = n,
    }
  end
  local length = math.min(#self, #other)
  -- number of bisections:
  local depth = math.floor(math.log(length/karatsuba_threshold, 2))
  local tself = build_karatsuba_tree(self, length, depth)
  local tother = build_karatsuba_tree(other, length, depth)

  local function karatsuba_rec(node1, node2, length)
    if not node1.lo or not node2.lo then
      return node1.n:bmul(node2.n)
    end

    local m = math.floor(length / 2 + 0.6)
    local p2 = karatsuba_rec(node1.hi, node2.hi, m)
    local p0 = karatsuba_rec(node1.lo, node2.lo, m)
    local p1 = (node1.hi.n + node1.lo.n):kmul_unrolled2(node2.hi.n + node2.lo.n, karatsuba_threshold)  -- - p2 - p0

    -- equivalent to: p1 = p1 - y
    -- (here we assume p1 >= y)
    local function raw_sub_from_p1(substraend)
      local carry = 0
      --print('p1', p1)
      --print('  -'..name, substraend)
      for i = 1, #p1 do
        local t = p1[i] - (substraend[i] or 0) - carry
        p1[i] = band(t, atommask)
        carry = t<0 and 1 or 0
      end
      if carry ~= 0 then
        error(('carry ~= 0, %s - %s'):format(p1, substraend))
      end
    end
    raw_sub_from_p1(p2)
    raw_sub_from_p1(p0)
    normalize(p1)

    local function add_into_p0_with_offset(src, offset_words)
      if src.sign == 0 then return end
      for i = #p0+1, offset_words do
        p0[i] = 0
      end
      local carry = 0
      for i = 1, #src do
        local t = (p0[i+offset_words] or 0) + src[i] + carry
        p0[i+offset_words] = band(t, atommask)
        carry = rshift(t, atombits)
      end
      local i = #src + 1
      while carry > 0 do
        local t = (p0[i+offset_words] or 0) + carry
        p0[i+offset_words] = band(t, atommask)
        carry = rshift(t, atombits)
        i = i + 1
      end
    end

    add_into_p0_with_offset(p2, m+m)
    add_into_p0_with_offset(p1, m)
    return setsign(p0, self.sign * other.sign)
  end

  return karatsuba_rec(tself, tother, length)
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
  local res = empty(self.sign)
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


function bigint:mutable_unsigned_add(other)
  local carry = 0
  for i = 1, #other do
    local t = (self[i] or 0) + other[i] + carry
    self[i] = band(t, atommask)
    carry = rshift(t, atombits)
  end
  local i = #other + 1
  while carry > 0 do
    local t = (self[i] or 0) + carry
    self[i] = band(t, atommask)
    carry = rshift(t, atombits)
    i = i + 1
  end
end


-- mutable equivalent to doing: x + bigint.new(self.sign * atom)
function bigint:mutable_unsigned_add_atom(atom)
  assert(atom >= 0 and atom < atombase and math.floor(atom) == atom, 'invalid atom')
  local i = 1
  while atom > 0 do
    local t = (self[i] or 0) + atom
    self[i] = band(t, atommask)
    atom = rshift(t, atombits)
    i = i + 1
  end
end


function bigint:powmod(power, mod)
  error 'TODO: implement'
end


function bigint:rshift(n)
  local res = empty(self.sign)
  local natoms, nbits = math.floor(n / atombits), n % atombits
  local tmp = rshift(self[1 + natoms], nbits)
  for i = 1, #self - natoms do
    tmp = bor(tmp, lshift(self[i + natoms + 1] or 0, atombits))
    res[i] = band(tmp, atommask)
    tmp = rshift(tmp, atombits)
  end
  return res
end


function bigint:tonumber()
  local sum = 0
  for i = #self, 1, -1 do
    sum = sum * atombase + self[i]
  end
  return sum * self.sign
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
