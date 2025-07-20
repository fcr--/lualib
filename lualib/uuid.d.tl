local record uuid
   record UUID
      -- 16 bytes long string stored in little endian.
      bytes: function(UUID): string

      -- returns textual representation in hexa with dashes in the middle.
      metamethod __tostring: function(UUID): string

      -- constructor:
      new: function(cls: UUID, bytes_or_text: string): UUID

      -- can be used if you don't have /dev/urandom or /dev/random, but it must
      -- be a source of decent randomness (static method):
      init_state: function(random_file: FILE)
   end

   -- Time + Ethernet MAC based uuid
   -- TODO: v1: function(): string

   -- Project name text into namespace UUID using MD5:
   -- TODO: v3: function(ns: UUID, name: string): UUID

   v4: function(): UUID

   -- Project name text into namespace UUID using SHA-1:
   v5: function(ns: UUID, name: string): UUID

   pattern: string
   pattern_ver: string  -- matches an uuid grouping the version octet
   pattern_full: string  -- same as: '^' .. pattern_ver .. '$'
end

return uuid
