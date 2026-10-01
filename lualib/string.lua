---@param str string
---@param pattern string
---@return string[]
local function split(str, pattern)
   ---@type string[]
   local parts = {}
   ---@type integer, integer
   local cursor, from = 1, 1
   ---@type boolean
   local last_match_was_empty_separator = true

   while cursor <= #str do
      local match_start, match_end = str:find(pattern, cursor)
      if not match_start then break end

      if match_end < match_start then
         if last_match_was_empty_separator then
            cursor = cursor + 1
         end
         last_match_was_empty_separator = true
      else
         parts[#parts+1] = str:sub(from, match_start-1)
         cursor = match_end + 1
         from = cursor
         last_match_was_empty_separator = false
      end
   end
   parts[#parts+1] = str:sub(from)
   return parts
end

return {
   split = split,
}
