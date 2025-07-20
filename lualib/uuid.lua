local oo = require 'lualib.oo'
local sha1 = require 'lualib.crypto.sha1'


local UUID = oo.class()


function UUID:_init(bytes_or_text)
  if #bytes_or_text == 36 and bytes_or_text:find(
      '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$'
  ) then
    self._text_representation = bytes_or_text
  elseif #bytes_or_text == 16 then
    self._binary_representation = bytes_or_text
  else
    return error('Invalid UUID')
  end
end


function UUID:__tostring()
  if not self._text_representation then
    local b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, bA, bB, bC, bD, bE, bF =
    self._binary_representation:byte(1, 16)

    self._text_representation = (
      '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x'
    ):format(b0, b1, b2, b3, b4, b5,  b6, b7,  b8, b9,  bA, bB,  bC, bD, bE, bF)
  end
  return self._text_representation
end


function UUID:bytes()
  if not self._binary_representation then
    self._binary_representation = self._text_representation:gsub('-', ''):gsub('..', function(b)
      return string.char(tonumber(b, 16))
    end)
  end
  return self._binary_representation
end

-- TODO:
--   implement uuid v1 to v3 and v5


local function patch_version(bytes, version)
  return ('%s%c%c%c%s'):format(
    bytes:sub(1, 6),
    version*16 + bytes:byte(7)%0x10,  -- 0xV0..0xVf (the V here represents the version number)
    bytes:byte(8),
    0x80 + bytes:byte(9)%0x40,  -- 0x80..0xbf
    bytes:sub(10)
  )
end

local state
function UUID.init_state(random_file)
   if random_file then
      state = assert(random_file:read(16), 'error reading 16 random bytes')
   else
      local fd = io.open('/dev/urandom', 'rb') or assert(io.open('/dev/random', 'rb'))
      state = assert(random_file:read(16), 'error reading 16 random bytes')
      fd:close()
   end
end

local function v4()
   if not state then UUID.init_state() end

   -- we use sha1 as a safe-ish PRNG:
   state = sha1(state, true)
   -- by adding padding we hide the internal state for the next call:
   local bytes = sha1('INIT'..state..'END', true):sub(1, 16)

   return UUID:new(patch_version(bytes, 4))
end


local function v5(namespace, name)
  local hash = sha1(namespace:bytes() .. name, true)
  return UUID:new(patch_version(hash:sub(1, 16), 5))
end


return {
  UUID = UUID,
  v4 = v4,
  v5 = v5,
  pattern = '%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x',
  pattern_ver = '%x%x%x%x%x%x%x%x%-%x%x%x%x%-(%x)%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x',
  pattern_full = '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-(%x)%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$',
}
