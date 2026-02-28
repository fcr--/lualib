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

return {
  char = char,
}
