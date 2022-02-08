local type b64string = string

local record base64
   record base64_options
      -- 64 or 65 byte string, last byte will be used as padding (if present)
      charset: string
   end

   encode: function(input: string): b64string
   encode: function(input: string, options: base64_options): b64string

   BASE64_CHARSET: string
   BASE64URL_CHARSET: string
end

return base64
