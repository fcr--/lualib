local charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:'
local index_to_char = {}
local char_to_index = {}
local byte_to_index = {}
for i = 0, #charset - 1 do
  local c = charset:sub(i+1, i+1)
  index_to_char[i] = c
  char_to_index[c] = i
  byte_to_index[c:byte()] = i
end

local function encode(data)
  local res = {}
  for i = 1, #data, 2 do
    local b1, b2 = data:byte(i, i+1)
    if b2 == nil then
      res[#res+1] = index_to_char[b1%45]
      res[#res+1] = index_to_char[math.floor(b1/45)]
    else
      local n = b1*256 + b2
      res[#res+1] = index_to_char[n%45]
      n = math.floor(n / 45)
      res[#res+1] = index_to_char[n%45]
      res[#res+1] = index_to_char[math.floor(n/45)]
    end
  end
  return table.concat(res)
end

local function decode(data, allow_errors)
  local res = {}
  if allow_errors then
    -- there may be invalid base45 chars which we will ignore:
    data = data:upper():gsub('.', function(c)
      if not char_to_index[c] then return '' end
      return c
    end)
    -- there may be an additional trailing byte:
    if data % 3 == 1 then data:sub(1, #data-1) end
  end

  for i = 1, #data, 3 do
    local b1, b2, b3 = data:byte(i, i+2)
    local i1 = byte_to_index[b1]
    local i2 = byte_to_index[b2]
    if not i1 then error('invalid byte '..b1..' at position '..i) end
    if not i2 then error('invalid byte '..b2..' at position '..i+1) end
    if b3 == nil then
      res[#res+1] = string.char(i1 + i2*45)
    else
      local i3 = byte_to_index[b3]
      if not i3 then error('invalid byte '..b3..' at position '..i+2) end
      local n = (i3*45 + i2)*45 + i1
      res[#res+1] = string.char(math.floor(n / 256), n % 256)
    end
  end
  return table.concat(res)
end

return {
  encode = encode,
  decode = decode,
}
