local bit = bit or require 'bit32'

local function char1(cp)
  if cp < 0x80 then
    return string.char(cp)
  elseif cp < 0x800 then
    return string.char(
      bit.bor(0xc0, bit.rshift(cp, 6)),  -- 110H_HHLL
      bit.bor(0x80, bit.band(cp, 0x3f))) -- 10LL_LLLL
  elseif cp < 0x10000 then
    return string.char(
      bit.bor(0xe0, bit.rshift(cp, 12)),
      bit.bor(0x80, bit.band(bit.rshift(cp, 6), 0x3f)),
      bit.bor(0x80, bit.band(cp, 0x3f)))
  elseif cp < 0x110000 then
    return string.char(
      bit.bor(0xf0, bit.rshift(cp, 18)),
      bit.bor(0x80, bit.band(bit.rshift(cp, 12), 0x3f)),
      bit.bor(0x80, bit.band(bit.rshift(cp, 6), 0x3f)),
      bit.bor(0x80, bit.band(cp, 0x3f)))
  end
  error('invalid unicode code point: ' .. tostring(cp))
end

local function char(...)
  local n = select('#', ...)
  if n == 1 then return char1(select(1, ...)) end

  local res = {}
  for i = 1, n do
    res[i] = char1(select(i, ...))
  end
  return table.concat(res)
end

local function decode(s, i)
   local b = s:byte(i)
   if not b then return end  -- out of bound
   if b < 0x80 then return 1, b end  -- ascii
   if b < 0xc2 then return end  -- unexpected continuation byte or invalid 0xc0, 0xc1 start
   if b < 0xe0 then  -- 2-byte utf-8 character:
      local b2 = s:byte(i+1)
      if not b2 or b2 < 0x80 or b2 > 0xbf then return end
      return 2, bit.bor(
         bit.lshift(bit.band(b, 0x1f), 6),
         bit.band(b2, 0x3f)
      )
   end
   if b < 0xf0 then  -- 3-byte utf-8 character:
      local b2, b3 = s:byte(i+1, i+2)
      if not b3 or b2<0x80 or b2>0xbf or b3<0x80 or b3>0xbf then return end
      local cp = bit.bor(
         bit.lshift(bit.band(b, 0xf), 12),
         bit.lshift(bit.band(b2, 0x3f), 6),
         bit.band(b3, 0x3f)
      )
      if cp < 0x800 then return end  -- invalid long form
      return 3, cp
   end
   if b < 0xf5 then  -- 4-byte utf-8 character:
      local b2, b3, b4 = s:byte(i+1, i+3)
      if not b4 or b2<0x80 or b2>0xbf or b3<0x80 or b3>0xbf or b4<0x80 or b4>0xbf then return end
      local cp = bit.bor(
         bit.lshift(bit.band(b, 0x7), 18),
         bit.lshift(bit.band(b2, 0x3f), 12),
         bit.lshift(bit.band(b3, 0x3f), 6),
         bit.band(b4, 0x3f)
      )
      if cp < 0x10000 or cp > 0x10ffff then return end  -- out-of-range for 4-byte utf-8 char
      return 4, cp
   end
   -- else: invalid too high start byte
end

local function arg_error(argnum, desc)
   local fname = debug.getinfo(2, 'n').name
   return error(("bad argument #%d to '%s' (%s)"):format(argnum, fname, desc))
end

local function codepoints(s, i, j, lax)
   if type(s) ~= 'string' then
      arg_error(1, ('string expected, got %s'):format(type(s)))
   end
   if not i then
      i = 1
   elseif i < 1 or i > #s+1 then
      arg_error(2, 'initial position out of bounds')
   end
   if not j then
      j = #s
   elseif j < 0 then
      j = #s + j + 1
   elseif j and j > #s then
      arg_error(2, 'final position out of bounds')
   end


end

local function len(s, i, j, lax)
   if type(s) ~= 'string' then
      arg_error(1, ('string expected, got %s'):format(type(s)))
   end
   if not i then
      i = 1
   elseif i < 1 or i > #s+1 then
      arg_error(2, 'initial position out of bounds')
   end
   if not j then
      j = #s
   elseif j < 0 then
      j = #s + j + 1
   elseif j and j > #s then
      arg_error(2, 'final position out of bounds')
   end

   local count = 0
   while i <= j do
      local charlen = decode(s, i)
      if not charlen then return nil, i end
      i = i + charlen
      count = count + 1
   end
   return count
end

return {
  char = char,
  charpattern = '[\0-\x7F\xC2-\xFD][\x80-\xBF]*',
  len = len,
  codepoints = codepoints,
}
