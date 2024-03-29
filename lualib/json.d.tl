local record json
   -- tables that can be used as metatables containing __jsontype='array' and 'object':
   Array: metatable<JsonValue>
   Object: metatable<JsonValue>

   -- parse'null' returns this specific object.
   -- It is not equal to nil, and it is not a falsely value:
   Nil: table

   type JsonValue = string | {any:JsonValue} | number | boolean | nil
   type string_position = integer
   type wide_char = integer

   -- returns true if the value is an Array (or false if it is an object), according to:
   --   value's metatable has __jsontype -> getmetatable(value).__jsontype == 'array'
   --   value is an empty table, or value[1] ~= nil -> True
   --   otherwise -> False (it's an Object)
   is_array: function(value: table): boolean

   record EncodeOptions
      -- whether to allow inf, -inf and nan, defaults to false:
      allow_invalid_numbers: nil | boolean
      -- skip non-string keys instead of erroring:
      skip_invalid_keys: nil | boolean
      -- can be used to specify when to encode a table as an array:
      is_array: nil | function(value: table, path: {string|number}): boolean
      -- if you want an encoding different than utf-8 (which is a bad idea btw):
      charset_decoder: nil | function(str: string, i: string_position): string_position, wide_char
   end

   -- Quotes a string to a json string: ie: 'hello\nworld' -> '"hello\\nworld"'
   encode_string: function(str: string, opts: EncodeOptions): string

   -- Encodes a value into a json string.
   -- Newlines, control characters and those outside ASCII will be escaped.
   encode: function(value: JsonValue, opts: nil | EncodeOptions): string

   -- Parses a json string: Note: parse'null' = json.Nil (~= nil)
   parse: function(str: string): JsonValue

   -- Pretty print:
   pp: function(value: JsonValue): string
end

return json
