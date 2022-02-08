local record uuid
   record UUID
      -- 16 bytes long string stored in little endian.
      bytes: function(UUID): string

      -- returns textual representation in hexa with dashes in the middle.
      metamethod __tostring: function(UUID): string

      -- constructor:
      new: function(cls: UUID, bytes_or_text: string): UUID
   end

   -- Time + Ethernet MAC based uuid
   -- TODO: v1: function(): string

   -- Random uuid
   -- TODO: v4: function(): string

   pattern: string
   pattern_ver: string  -- matches an uuid grouping the version octet
   pattern_full: string  -- same as: '^' .. pattern_ver .. '$'
end

return uuid
