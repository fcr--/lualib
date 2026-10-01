---@param str string
---@param pattern string
---@return string[]
local function split(str, pattern)
   ---@type string[]
   local parts = {}
   ---@type integer, integer
   local cursor, from = 1, 1

   while cursor <= #str do
      local match_start, match_end = str:find(pattern, cursor)
      if not match_start then break end

      if match_end < match_start then
         cursor = cursor + 1
      else
         parts[#parts+1] = str:sub(from, match_start-1)
         cursor = match_end + 1
         from = cursor
      end
   end
   parts[#parts+1] = str:sub(from)
   return parts
end

return {
   split = split,
}
