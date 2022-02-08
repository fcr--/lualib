local bit = bit or require 'bit32'

local BASE64_CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
local BASE64URL_CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'

local default_options = {
  charset = BASE64_CHARSET,
}


local function gen_character_map(charset)
  local res = {}
  if #charset == 65 then
    res.padding = charset:sub(65, 65)
  elseif #charset == 64 then
    res.padding = ''
  else
    error 'Invalid charset, should have length 64 or 65 (for optional padding char)'
  end
  for i = 0, 63 do
    local c = charset:sub(i+1, i+1)
    res[c] = i
    res[i] = c
  end
  return res
end


local charset_maps = setmetatable({}, {__index = function(t, k)
  local m = rawget(t, k)
  if not m then
    m = gen_character_map(k)
    t[k] = m
  end
  return m
end})


local function encode(input, options)
  options = options or default_options
  local charset_map = charset_maps[options.charset or default_options.charset]
  local res = {}
  for i = 1, #input-2, 3 do
    local b1, b2, b3 = input:byte(i, i+2)
    res[#res+1] = ('%s%s%s%s'):format(
      charset_map[bit.rshift(b1, 2)],
      charset_map[bit.bor(bit.lshift(bit.band(b1, 3), 4), bit.rshift(b2, 4))],
      charset_map[bit.bor(bit.lshift(bit.band(b2, 15), 2), bit.rshift(b3, 6))],
      charset_map[bit.band(b3, 0x3f)]
    )
  end
  if #input % 3 == 2 then
    local b1, b2 = input:byte(#input-1, #input)
    res[#res+1] = ('%s%s%s%s'):format(
      charset_map[bit.rshift(b1, 2)],
      charset_map[bit.bor(bit.lshift(bit.band(b1, 3), 4), bit.rshift(b2, 4))],
      charset_map[bit.lshift(bit.band(b2, 15), 2)],
      charset_map.padding
    )
  elseif #input % 3 == 1 then
    local b1 = input:byte(#input)
    res[#res+1] = ('%s%s%s%s'):format(
      charset_map[bit.rshift(b1, 2)],
      charset_map[bit.lshift(bit.band(b1, 3), 4)],
      charset_map.padding,
      charset_map.padding
    )
  end
  return table.concat(res)
end


return {
  encode = encode,
  BASE64_CHARSET = BASE64_CHARSET,
  BASE64URL_CHARSET = BASE64URL_CHARSET,
}
