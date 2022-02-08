local type b64string = string

local record base64
   record base64_options
      -- 64 or 65 byte string, last byte will be used as padding (if present)
      charset: string

      -- can be set to false to speed up decoding
      clean_spaces: boolean
   end

   encode: function(input: string): b64string
   encode: function(input: string, options: base64_options): b64string

   decode: function(input: b64string): string
   decode: function(input: b64string, options: base64_options): string

   BASE64_CHARSET: string
   BASE64URL_CHARSET: string
end

return base64
