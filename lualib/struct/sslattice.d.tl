local type char = string

local record SSLattice
   metamethod __tostring: function(SSLattice): string

   add: function(SSLattice, word: string): SSLattice

   record TraverseOptions
      anychar: char  -- meta character in prefix that matches any character
      exact: boolean  -- the effect being true is the same as $ at prefix end on regexs
      partial: boolean  -- accept partial match, ie: on prefix FOOBAR, FOO is accepted
      final: char  -- only report strings that end with the c character
   end
   traverse: function(SSLattice, prefix: string, options: TraverseOptions): (function(): string)

   persist: function(SSLattice): string  -- converts to an optimized binary string
   load: function(SSLattice, bindata: string): SSLattice

   record CacheStats
      trees: integer
      mean: number
      entries: integer
      empty_entries: integer
      non_empty_entries: integer
   end
   cache_stats: function(): CacheStats
end

local empty = SSLattice

return empty
