local oo = require 'lualib.oo'
local unpack = unpack or table.unpack

local TAG_CLASS = {
  -- For types whose meaning is the same in all applications; these types are only defined
  -- in X.208.
  UNIVERSAL = 0,

  -- For types whose meaning is specific to an application, such as X.500 directory
  -- services; types in two different applications may have the same application-specific
  -- tag and different meanings:
  APPLICATION = 64,

  -- For types whose meaning is specific to a given enterprise:
  PRIVATE = 128,

  -- For types whose meaning is specific to a given structured type; context-specific tags
  -- are used to distinguish between component types with the same underlying tag within the
  -- context of a given structured type, and component types in two different structured
  -- types may have the same tag and different meanings:
  CONTEXT = 192,
}

local TAG_CLASS_TO_NAME = {}
for name, tag_class in pairs(TAG_CLASS) do TAG_CLASS_TO_NAME[tag_class] = name end

local Node = oo.class()

local function encode_tag(node)
  -- encoding the tag:
  local tag = node.tag
  local common_header = node.tag_class + (node.constructed and 32 or 0)
  if tag < 32 then
    return string.char(common_header + tag)
  end

  -- we insert into tagbytes with the reverse order as we don't know how many we are needing:
  local tagbytes = {string.char(tag % 128)}
  tag = math.floor(tag / 128)
  while tag >= 0 do
    tagbytes[#tagbytes+1] = string.char(128 + tag % 128)
    tag = math.floor(tag / 128)
  end
  return ('%c%s'):format(common_header + 31, table.concat(tagbytes):reverse())
end

local function decode_tag(str, offset)
  -- returns: tag_class: TAG_CLASS, constructed: boolean, tag: int, next_offset: int
  -- |<bb:class><b:constructed><b_bbbb:tag>
  local byte = str:byte(offset)
  local tag_class = math.floor(byte / 64) * 64
  byte = byte - tag_class

  local constructed, tag = false, byte
  if byte > 32 then
    constructed = true
    tag = byte - 32
  end

  if tag == 31 then
    -- * If tag is 31, it is followed by 0 or more bytes with the highest bit set to 1,
    --   followed by a final byte with the highest bit set to 0.
    -- * The lowest 7 bits encode the tag data in big-endian order.
    tag = 0
    repeat
      offset = offset + 1
      byte = str:byte(offset)
      tag = tag * 128 + byte % 128
    until byte < 128
  end
  return tag_class, constructed, tag, offset + 1
end

local function encode_length(valuelen)
  -- encoding the length:
  if valuelen < 128 then
    return string.char(valuelen)
  end

  -- TODO: test lengths >= 128
  local lenbytes = {}
  repeat
    lenbytes[#lenbytes+1] = string.char(valuelen % 256)
    valuelen = math.floor(valuelen / 256)
  until valuelen == 0
  lenbytes[#lenbytes+1] = string.char(128 + #lenbytes)
  return table.concat(lenbytes):reverse()
end

local function decode_length(str, offset)
  -- returns length: int, new_offset: int

  -- short format: just the length as a single byte in the 0..127 range
  local byte = str:byte(offset)
  if byte < 128 then
    return byte, offset + 1
  end

  -- long format:
  --   * (128+length_length): byte from 129..255
  --   * (length bytes in BE): byte[length_length]
  local length = 0
  local length_length = byte - 128
  for i = offset, offset + length_length - 1 do
    length = length * 256 + str:byte(i)
  end
  return length, offset + length_length + 1
end

function Node:_init(options)
  self.name = options.name

  local tag = options.tag
  if tag then
    assert(type(tag) == 'number' and math.floor(tag) == tag and 0 <= tag)
    self.tag = tag
  end

  -- If tag is specified but tag_class is not overriden, we use CONTEXT tag_class.
  local tag_class = options.tag_class or options.tag and TAG_CLASS.CONTEXT
  if tag_class then
    assert(type(tag_class) == 'number' and TAG_CLASS_TO_NAME[tag_class])
    self.tag_class = tag_class
  end

  -- optional and default can be used for Sequence:
  if options.optional ~= nil then
    assert(type(options.optional) == 'boolean')
    self.optional = options.optional
  end

  if options.default ~= nil then
    self.default = options.default
  end

  self.encoded_tag = encode_tag(self)
end

function Node:_pre_init(options)
  local tag = options.tag

  assert(type(options.type_name) == 'string')
  assert(TAG_CLASS_TO_NAME[options.tag_class])
  assert(type(tag) == 'number' and math.floor(tag) == tag and 0 <= tag)
  assert(type(options.constructed) == 'boolean')
  assert(type(options.supports_primitive_and_constructed or false) == 'boolean')

  self.tag_class = options.tag_class
  self.tag = tag
  self.constructed = options.constructed
  self.supports_primitive_and_constructed = options.supports_primitive_and_constructed or false
  -- return self so that our subclasses can pre-init by doing local SubClass = oo.class(Node):_pre_init{...}
  return self
end

-- helper for common tlv case:
function Node:_encode_tlv(res, valuestr)
  local i = #res
  res[i+1] = self.encoded_tag
  res[i+2] = encode_length(#valuestr)
  res[i+3] = valuestr
end

function Node:encode(value)
  local res = {}
  self:_encode(res, value)
  return table.concat(res)
end

function Node:_decode(str, offset)
  -- you can use this implementation if it's enough for you
  local tag_class, constructed, tag, length_offset = decode_tag(str, offset)
  local length, data_offset = decode_length(str, length_offset)

  if tag_class ~= self.tag_class then
    error(('invalid tag_class %d (expected %d) at offset %d'):format(
      tag_class, self.tag_class, offset))
  end
  if not self.supports_primitive_and_constructed and constructed ~= self.constructed then
    error(('constructed=%s (expected %s) at offset %d'):format(
      constructed, self.constructed, offset))
  end
  if tag ~= self.tag then
    error(('invalid tag %d (expected %d) at offset %d'):format(tag, self.tag, offset))
  end

  local val = self:_decode_data(str, data_offset, length)
  return val, data_offset + length
end

function Node:_decode_data(str, data_offset, length)
  error(('%s fields do not support decoding (at data_offset %d)'):format(self.type_name, data_offset))
end

function Node:decode(str, offset, length)
  offset = offset or 1
  length = length or #str - offset + 1

  local val, new_offset = self:_decode(str, offset)

  -- the only length validation is done at this point:
  if new_offset - offset > length then
    error(('asn over-read (%d..%d)=%d > %d'):format(
      offset, new_offset, new_offset - offset, length))
  end
  return val
end


local Boolean = oo.class(Node):_pre_init {
  type_name = 'Boolean',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 1,
  constructed = false,
}

function Boolean:_encode(res, value)
  assert(type(value) == 'boolean')
  self:_encode_tlv(res, value and '\1' or '\0')
end

function Boolean:_decode_data(str, data_offset, length)
  if length ~= 1 then
    error(('Boolean value with length=%d (expected 1) at offset %d'):format(length, data_offset))
  end
  return str:byte(data_offset) ~= 0
end


local Integer = oo.class(Node):_pre_init {
  type_name = 'Integer',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 2,
  constructed = false,
}

function Integer:_encode(res, value)
  -- TODO: TEST ALL OF THIS FUNCTION!!!
  assert(value == math.floor(value), 'Integer values must be integers')
  local raw
  if value >= 0 then
    if value <= 0x7f then
      raw = string.char(value)
    elseif value <= 0x7fff then
      raw = string.char(math.floor(value / 256), value % 256)
    end
  else
    if value >= -0x80 then
      raw = string.char(256 + value)
    elseif value >= -0x8000 then
      raw = string.char(256 + math.floor(value / 256), value % 256)
    end
  end
  if not raw then
    assert(value ~= math.huge and value ~= -math.huge, 'infinite integers are not supported')
    local bytes = {}
    local bytes_len = 0
    while value < -128 or value >= 128 do
      bytes_len = bytes_len + 1
      bytes[bytes_len] = value % 256
      value = math.floor(value / 256)
    end
    -- swap bytes
    for i = 1, math.floor(bytes_len / 2) do
      local e = bytes_len - i + 1
      bytes[i], bytes[e] = bytes[e], bytes[i]
    end
    raw = string.char(value % 256, unpack(bytes))
end
  self:_encode_tlv(res, raw)
end

function Integer:_decode_data(str, data_offset, length)
  if length == 0 then
    error(('empty data for Integer at offset %d'):format(data_offset))
  end
  local byte0 = str:byte(data_offset)
  local n
  if byte0 < 128 then
    n = byte0
  else
    -- Negative numbers are a tricky beast to handle without bitwise functions:
    -- for any byte b, 255-b is equivalent to bit.bnot(b).  Then by multiplying
    -- by 256 we are doing bit.lshift(n, 8) which maintains the sign bit.
    n = -256 + byte0  -- same as -1 - (255-byte0)
  end
  for i = data_offset+1, data_offset+length-1 do
    n = n * 256 + str:byte(i)
  end
return n
end


local BigInteger = oo.class(Node):_pre_init {
  type_name = 'BigInteger',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 2,
  constructed = false,
}

function BigInteger:_encode(res, value)
  local raw_big_endian_representation = value:tostring 'raw'
  self:_encode_tlv(res, raw_big_endian_representation)
end


local BitString = oo.class(Node):_pre_init {
  type_name = 'BitString',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 3,
  constructed = false,
  supports_primitive_and_constructed = true,
}

function BitString:_init(options)
  self.format = options.format or 'bytes'
  -- valid formats:
  --   bytes: values are strings, input bitstrings must have 0 unused bits
  --   bits: values are strings with format '^[01]*$', no restrictions on input bitstrings
  assert(({bytes=1, bits=1})[self.format], 'invalid BitString format')
  Node._init(self, options)
end

function BitString:_encode(res, value)
  if self.format == 'bytes' then
    self:_encode_tlv(res, '\0'..value)
  else
    assert(value:find '^[01]*$', 'invalid bit value on BitString:new{format="bits"}')
    local bytes = {string.char((-#value)%8)}
    local byte = 0

    for i = 1, #value do
      local bit = value:byte(i) - 48  -- 48 == ('0'):byte()
      if bit > 0 then
        byte = byte + 2^(7 - (i-1)%8)
      end
      if i%8 == 0 then
        bytes[#bytes+1] = string.char(byte)
        byte = 0
      end
    end
    -- insert last byte with padding:
    if #value % 8 ~= 0 then
      bytes[#bytes+1] = string.char(byte)
    end
    self:_encode_tlv(res, table.concat(bytes))
  end
end

local OctetString = oo.class(Node):_pre_init {
  type_name = 'OctetString',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 4,
  constructed = false,  -- It's always primitive on DER
  supports_primitive_and_constructed = true,
}

function OctetString:_init(options)
  self.minlen = options.minlen or 0
  self.maxlen = options.maxlen or math.huge
  Node._init(self, options)
end

function OctetString:_encode(res, value)
  assert(type(value) == 'string', 'OctetString values must be strings')
  assert(self.minlen <= #value and #value <= self.maxlen, 'invalid OctetString string length')
  self:_encode_tlv(res, value)
end


local Null = oo.class(Node):_pre_init {
  type_name = 'Null',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 5,
  constructed = false,
}

function Null:_init(options)
  self.null = options.null
  Node._init(self, options)
end

function Null:_encode(res, value)
  assert(value == self.null, 'Expected null value to encode, use null parameter to the constructor')
  self:_encode_tlv(res, '')
end


local Oid = oo.class(Node):_pre_init {
  type_name = 'Oid',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 6,
  constructed = false,
}

function Oid:_encode_identifier(v)
  local b3, b2, b1, b0
  assert(math.floor(v) == v and 0 <= v)
  if v < 128 then return string.char(v) end
  b0, v = v % 128, math.floor(v / 128)
  if v < 128 then return string.char(128 + v, b0) end
  b1, v = v % 128 + 128, math.floor(v / 128)
  if v < 128 then return string.char(128 + v, b1, b0) end
  b2, v = v % 128 + 128, math.floor(v / 128)
  if v < 128 then return string.char(128 + v, b2, b1, b0) end
  b3, v = v % 128 + 128, math.floor(v / 128)
  if v < 128 then return string.char(128 + v, b3, b2, b1, b0) end
  error 'oid identifier too large (>=2**35)'
end

function Oid:_encode(res, value)
  -- we accept oids in a table like { 1, 2, 840, 113549, 1 }, otherwise we convert them from a string
  local identifiers = value
  if type(value) == 'string' then
    identifiers = {}
    for word in (value .. '.'):gmatch '(.-)%.' do
      assert(word:find '^%d+$', 'invalid oid string representation')
      identifiers[#identifiers + 1] = tonumber(word)
    end
  end
  local v1, v2 = identifiers[1], identifiers[2]
  assert(math.floor(v2) == v2 and v2 >= 0)
  if v1 == 0 or v1 == 1 then
    assert(math.floor(v2) == v2 and v2 <= 39, 'invalid oid value[2] for value[1] in (0, 1)')
  elseif v1 ~= 2 then
    error 'invalid oid value[1], only (0, 1, 2) allowed'
  end
  local encoded_identifiers = {self:_encode_identifier(40 * v1 + v2)}
  for i = 2, #identifiers - 1 do
    encoded_identifiers[i] = self:_encode_identifier(identifiers[i+1])
  end
  self:_encode_tlv(res, table.concat(encoded_identifiers))
end


local Choice = oo.class()
Choice.type_name = 'Choice'

function Choice:_init(options)
  self.name = options.name
  self.default = options.default
  self.optional = options.optional
  self.choices = {}  -- keys are strings like 'UNIVERSAL-5', values are Node instances
  self.choices_by_name = {}
  local function addchoice(key, node)
    if self.choices[key] then
      error('duplicated choice ' .. key)
    end
    if self.choices_by_name[node.name] then
      error('choice child with duplicated name ' .. node.name)
    end
    assert(node.name, 'Choice children must be named, in this library it is mandatory')
    self.choices[key] = node
    self.choices_by_name[node.name] = node
  end

  for i, child in ipairs(options) do
    if child.choices then -- we are adding a subchoice, weird but ok...
      for key, subchild in pairs(child.choices) do addchoice(key, subchild) end
    else
      addchoice(TAG_CLASS_TO_NAME[child.tag_class] .. '-' .. child.tag, child)
    end
  end
end

Choice.encode = Node.encode

function Choice:_encode(res, value)
  assert(type(value) == 'table')
  local name, subvalue = next(value)
  local node = self.choices_by_name[name]
  assert(node, 'choice not found')
  assert(next(value, name) == nil, 'only one value must be provided')
  node:_encode(res, subvalue)
end


local Sequence = oo.class(Node):_pre_init {
  type_name = 'Sequence',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 16,
  constructed = true,
}

function Sequence:_init(options)
  assert(options.of == nil or options[1] == nil, 'Sequence cannot be both a record and SEQUENCE OF')
  self.of = options.of
  if self.of ~= nil and not oo.isinstance(self.of, Node) and not oo.isinstance(self.of, Choice) then
    error 'Sequence "of" elements must be Nodes or Choice'
  end
  for i, child in ipairs(options) do
    self[i] = child
    assert(oo.isinstance(child, Node) or oo.isinstance(child, Choice), 'Sequence children must be Nodes or Choice')
  end
  Node._init(self, options)
end

-- cascade(a, b, c, ...) is a «false»-safe replacement for: a or b or c or ...
local function cascade(...)
  for i = 1, select('#', ...) do
    local value = select(i, ...)
    if value ~= nil then return value end
  end
end

function Sequence:_encode(res, value)
  local res_base = #res
  assert(type(value) == 'table', 'Sequence values must be tables')
  res[res_base + 1] = self.encoded_tag
  res[res_base + 2] = ''  -- this is fixed after all the children are encoded
  if self.of then
    -- simplest case, we are just encoding an array of values
    for _, v in ipairs(value) do
      self.of:_encode(res, v)
    end
  else -- we are dealing with a record sequence, values can be referenced by index or name
    for i, child in ipairs(self) do
      local v = cascade(value[i], value[child.name], child.default)
      if v ~= nil then
        child:_encode(res, v)
      elseif not child.optional then
        error(('missing child %d %s'):format(i, child.name or ''))
      end
    end
  end
  -- fix encoded length:
  local content_size = 0
  for i = res_base + 3, #res do
    content_size = content_size + #res[i]
  end
  res[res_base + 2] = encode_length(content_size)
end


local PrintableString = oo.class(Node):_pre_init {
  type_name = 'PrintableString',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 19,
  constructed = false,  -- It's always primitive on DER
  supports_primitive_and_constructed = true,
}

function PrintableString:_init(options)
  self.minlen = options.minlen or 0
  self.maxlen = options.maxlen or math.huge
  Node._init(self, options)
end

function PrintableString:_encode(res, value)
  assert(type(value) == 'string', 'PrintableString values must be strings')
  assert(self.minlen <= #value and #value <= self.maxlen, 'invalid PrintableString string length')
  assert(value:find "^[-%w '()+,./:=?]*$", 'illegal character')
  self:_encode_tlv(res, value)
end


local T61String = oo.class(Node):_pre_init {
  type_name = 'T61String',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 20,
  constructed = false,  -- It's always primitive on DER
  supports_primitive_and_constructed = true,
}

function T61String:_init(options)
  -- length is measured in T.61 bytes after conversion
  self.minlen = options.minlen or 0
  self.maxlen = options.maxlen or math.huge
  self.raw = false  -- set it to true if you want to avoid utf-8 to T.61 conversion
  Node._init(self, options)
end

-- Conversion tables are not perfect, for example G0 (ISO-2022) is not supported.
-- https://www.itu.int/rec/dologin_pub.asp?lang=e&id=T-REC-T.61-198811-S!!PDF-E&type=items
local UTF8_TO_T61 = {['¡']='\161', ['¢']='\162', ['£']='\163', ['$']='\164', ['¥']='\165',
  ['#']='\166', ['§']='\167', ['¤']='\168', ['«']='\171', ['°']='\176', ['±']='\177',
  ['²']='\178', ['³']='\179', ['×']='\180', ['µ']='\181', ['¶']='\182', ['·']='\183',
  ['÷']='\184', ['»']='\187', ['¼']='\188', ['½']='\189', ['¾']='\190', ['¿']='\191',
  ['Ω']='\224', ['Æ']='\225', ['Ð']='\226', ['ª']='\227', ['Ħ']='\228', ['Ĳ']='\230',
  ['Ŀ']='\231', ['Ł']='\232', ['Ø']='\233', ['Œ']='\234', ['º']='\235', ['Þ']='\236',
  ['Ŧ']='\237', ['Ŋ']='\238', ['ŉ']='\239', ['ĸ']='\240', ['æ']='\241', ['đ']='\242',
  ['ð']='\243', ['ħ']='\244', ['ı']='\245', ['ĳ']='\246', ['ŀ']='\247', ['ł']='\248',
  ['ø']='\249', ['œ']='\250', ['ß']='\251', ['þ']='\252', ['ŧ']='\253', ['ŋ']='\254'}
for diacritical_char, char_pairs in pairs {
  ['\193'] = 'àaÀAèeÈEìiÌIòoÒOùuÙU', -- grave
  ['\194'] = 'áaÁAćcĆCéeÉEǵgíiÍIĺlĹLńnŃNóoÓOŕrŔRśsŚSúuÚUýyÝYźzŹZ', -- acute
  ['\195'] = 'âaÂAĉcĈCêeÊEĝgĜGĥhĤHîiÎIĵjĴJôoÔOŝsŜSûuÛUŵwŴWŷyŶY', -- circumflex
  ['\196'] = 'ãaÃAẽeẼEĩiĨIñnÑNõoÕOũuŨU', -- tilde
  ['\197'] = 'āaĀAēeĒEīiĪIōoŌOūuŪU', -- macron
  ['\198'] = 'ăaĂAğgĞGŭuŬU', -- breve
  ['\199'] = 'ċcĊCėeĖEġgĠGıiżzŻZ', -- dot above
  ['\200'] = 'äaÄAëeËEïiÏIöoÖOüuÜUÿyŸY', -- diaeresis (\201 = umlaut is discouraged)
  ['\202'] = 'åaÅAůuŮU', -- ring
  ['\203'] = 'çcÇCĢGķkĶKļlĻLņnŅNŗrŖRşsŞSţtŢT', -- cedilla
  -- \204 = underscore is not supported here
  ['\205'] = 'őoŐOűuŰU', -- double accute accent
  ['\206'] = 'ąaĄAęeĘEįiĮIųuŲU', -- ogonek
  ['\207'] = 'čcČCďdĎDěeĚEľlĽLňnŇNřrŘRšsŠsťtŤTžzŽZ' -- caron
} do
  assert('' == char_pairs:gsub('([%z\1-\128\194-\244][\128-\191]*)(%a)',
    function (utf8_char, alpha_char)
      UTF8_TO_T61[utf8_char] = diacritical_char .. alpha_char
      return ''
    end))
end
local T61_TO_UTF8 = {}
for c in ('\t\n\f\r !"%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ'.. 
  '[]_abcdefghijklmnopqrstuvwxyz|'):gmatch '.' do UTF8_TO_T61[c] = c end
for utf8_char, t61_char in pairs(UTF8_TO_T61) do T61_TO_UTF8[t61_char] = utf8_char end
T61_TO_UTF8['#'] = '#'
T61_TO_UTF8['$'] = '¤'

function T61String:_encode(res, value)
  assert(type(value) == 'string', 'T61String values must be strings')
  if not self.raw then
    local codes = {}
    local invalid_utf8 = value:gsub('[%z\1-\128\194-\244][\128-\191]*', function (char)
      codes[#codes + 1] = assert(UTF8_TO_T61[char], 'character not supported in T.61')
      return ''
    end)
    if invalid_utf8 ~= '' then
      error(('invalid utf-8 bytes given to T61String: %q'):format(invalid_utf8))
    end
    value = table.concat(codes)
  end
  assert(self.minlen <= #value and #value <= self.maxlen, 'invalid T61String string length')
  self:_encode_tlv(res, value)
end


-- IA5 is basically the same as ASCII, where only the chars U+0000 to U+007F are allowed
local IA5String = oo.class(Node):_pre_init {
  type_name = 'IA5String',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 22,
  constructed = false,  -- It's always primitive on DER
  supports_primitive_and_constructed = true,
}

function IA5String:_init(options)
  self.minlen = options.minlen or 0
  self.maxlen = options.maxlen or math.huge
  Node._init(self, options)
end

function IA5String:_encode(res, value)
  assert(type(value) == 'string', 'IA5String values must be strings')
  assert(self.minlen <= #value and #value <= self.maxlen, 'invalid IA5String string length')
  assert(value:find "^[%z\1-\127]*$", 'illegal character')
  self:_encode_tlv(res, value)
end


-- UTCTime, a string with format: "YYMMDDhhmm(ss)?(Z|[+-]hhmm)"
local UTCTime = oo.class(Node):_pre_init {
  type_name = 'UTCTime',
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 23,
  constructed = false,  -- It's always primitive on DER
  supports_primitive_and_constructed = true,
}

function UTCTime:_init(options)
  self.minlen = options.minlen or 0
  self.maxlen = options.maxlen or math.huge
  Node._init(self, options)
end

function UTCTime:_encode(res, value)
  if type(value) == 'table' then
    --[[ if you pass a table it will be considered as local time, if you need to convert from a utc
         table use this, which as far as I know, should work:
    function utc_table_to_unix_time(value)
      local value_unix_time = os.time(value)
      local d1 = os.date('*t',  value_unix_time)
      local d2 = os.date('!*t', value_unix_time)
      d1.isdst = false
      local zone_diff = os.difftime(os.time(d1), os.time(d2))

      return os.time(setmetatable({sec=value.sec + zone_diff}, {__index=value}))
    end
    ]]
    value = os.time(value)
  end
  assert(type(value) == 'number', 'UTCTime values should be int seconds from epoch or "!*t" date table')

  -- We might be generating second number "60" on leap seconds, and that might break some implementations.
  -- So instead we convert it to second "59" which is better than breaking them.
  --   It's incredible the ITU folks decided to use this mess of encoding instead of the simple UNIX
  -- time inside an Integer.  Which btw reintroduces the Y2K problem by discarding the century. 🤦
  value = os.date('!%y%m%d%H%M%SZ', value):gsub('60Z', '59Z')
  self:_encode_tlv(res, value)
end


return {
  TAG_CLASS = TAG_CLASS,
  Node = Node,
  Boolean = Boolean,  -- [1]
  Integer = Integer,  -- [2]
  BigInteger = BigInteger,  -- [2]
  BitString = BitString,    -- [3]
  OctetString = OctetString,  -- [4]
  Null = Null,  -- [5]
  Oid = Oid,    -- [6]
  Choice = Choice,
  Sequence = Sequence,  -- [16]
  PrintableString = PrintableString,  -- [19]
  T61String = T61String,  -- [20]
  IA5String = IA5String,  -- [22]
  UTCTime = UTCTime,  -- [23]
}
