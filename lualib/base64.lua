local bit = bit or require 'bit32'

local BASE64_CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
local BASE64URL_CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'

local default_options = {
  charset = BASE64_CHARSET,
  clean_spaces = true,
}


local function gen_character_map(charset)
  local res = {inv={}}
  if #charset == 65 then
    res.padding = charset:sub(65, 65)
  elseif #charset == 64 then
    res.padding = ''
  else
    error 'Invalid charset, should have length 64 or 65 (for optional padding char)'
  end
  for i = 0, 63 do
    local c = charset:sub(i+1, i+1)
    res.inv[c:byte()] = i
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


local function decode(input, options)
  options = options or default_options
  local charset_map = charset_maps[options.charset or default_options.charset]

  local clean_spaces = default_options.clean_spaces
  if options.clean_spaces ~= nil then clean_spaces = default_options.clean_spaces end
  -- we run find and gsub separately to avoid creating intermediate strings
  if clean_spaces and input:find '%s' then
    input = input:gsub('%s', '')
  end

  -- input_len is the offset of the last non-padding char
  local input_len = #input
  local padding_len = 0
  if charset_map.padding ~= '' then
    assert(#input % 4 == 0, 'input length must be a multiple of 4')
    -- find returns index from the beginning of the string to the position of the first padding char,
    -- that's why we substract 1 from the total and add 1 to the default:
    input_len = (input:find(charset_map.padding, -2, true) or input_len+1)-1
    padding_len = #input - input_len
  else
    -- how many bytes are needed until the length is a multiple of 4
    padding_len = bit.band(input_len, -4) - input_len
    assert(padding_len < 3, 'invalid padding amount')
  end

  local inv = charset_map.inv
  local res = {}
  for i = 1, input_len-3, 4 do
    local a1, a2, a3, a4 = input:byte(i, i+3)
    local b1, b2, b3, b4 = inv[a1], inv[a2], inv[a3], inv[a4]
    res[#res+1] = string.char(
      bit.bor(bit.lshift(b1, 2), bit.rshift(b2, 4)),
      bit.bor(bit.lshift(bit.band(b2, 15), 4), bit.rshift(b3, 2)),
      bit.bor(bit.lshift(bit.band(b3, 3), 6), b4)
    )
  end

  if padding_len == 1 then
    local a1, a2, a3 = input:byte(input_len-2, input_len)
    local b1, b2, b3 = inv[a1], inv[a2], inv[a3]
    res[#res+1] = string.char(
      bit.bor(bit.lshift(b1, 2), bit.rshift(b2, 4)),
      bit.bor(bit.lshift(bit.band(b2, 15), 4), bit.rshift(b3, 2))
    )
  elseif padding_len == 2 then
    local a1, a2 = input:byte(input_len-1, input_len)
    local b1, b2 = inv[a1], inv[a2]
    res[#res+1] = string.char(
      bit.bor(bit.lshift(b1, 2), bit.rshift(b2, 4))
    )
  end

  return table.concat(res)
end


return {
  encode = encode,
  decode = decode,
  BASE64_CHARSET = BASE64_CHARSET,
  BASE64URL_CHARSET = BASE64URL_CHARSET,
}
