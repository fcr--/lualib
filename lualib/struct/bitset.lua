local oo = require 'lualib.oo'
local unpack = unpack or table.unpack

local BitSet = oo.class()
BitSet.Strings = oo.class(BitSet)

BitSet.start = 0  -- default

local MAX_STRING_SIZE = 256

function BitSet.Strings:_init(opts)
   if opts.start ~= nil and opts.start ~= 0 then
      self.start = opts.start
   end
   ---@type string[]
   self._strings, self.size = self:_build_strings_from_iter(opts.iter)
end

function BitSet.Strings:_build_strings_from_iter(iter)
   local strings = {}
   local buffer = {}
   local bitindex = 1
   local bytevalue = 0
   local bytes_in_buffer = 0
   local size = 0
   for b in iter do
      size = size + 1
      if b then
         bytevalue = bytevalue + bitindex
      end
      bitindex = bitindex + bitindex
      if bitindex == 256 then
         bitindex = 1
         bytes_in_buffer = bytes_in_buffer + 1
         buffer[bytes_in_buffer] = bytevalue
         bytevalue = 0
         if bytes_in_buffer == MAX_STRING_SIZE then
            strings[#strings+1] = string.char(unpack(buffer))
            bytes_in_buffer = 0
         end
      end  -- 2**8 -> 2**0
   end
   if bitindex > 1 then
      bytes_in_buffer = bytes_in_buffer + 1
      buffer[bytes_in_buffer] = bytevalue
   end
   if bytes_in_buffer > 0 then
      strings[#strings+1] = string.char(unpack(buffer, 1, bytes_in_buffer))
   end
   return strings, size
end

return BitSet
