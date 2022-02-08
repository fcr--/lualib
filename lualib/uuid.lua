local oo = require 'lualib.oo'

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
  if self._text_representation then
    return self._text_representation
  end

  local b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, bA, bB, bC, bD, bE, bF =
    self._binary_representation:byte(1, 16)

  self._text_representation = (
    '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x'
  ):format(b0, b1, b2, b3, b4, b5,  b6, b7,  b8, b9,  bA, bB,  bC, bD, bE, bF)
end

function UUID:bytes()
  if self._binary_representation then
    return self._binary_representation
  end
end

-- TODO:
--   implement uuid v1 to v5

return {
  UUID = UUID,
  pattern = '%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x',
  pattern_ver = '%x%x%x%x%x%x%x%x%-%x%x%x%x%-(%x)%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x',
  pattern_full = '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-(%x)%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$',
}
