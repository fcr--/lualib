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

TAG_CLASS_TO_NAME = {}
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

local function encode_length(valuelen)
  -- encoding the length:
  if valuelen < 128 then
    return string.char(valuelen)
  end

  local lenbytes = {}
  repeat
    lenbytes[#lenbytes+1] = string.char(valuelen % 256)
    valuelen = math.floor(valuelen / 256)
  until valuelen == 0
  lenbytes[#lenbytes+1] = string.char(128 + #lenbytes)
  return table.concat(valuelen):reverse()
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


local Boolean = oo.class(Node):_pre_init {
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 1,
  constructed = false,
}

function Boolean:_encode(res, value)
  assert(type(value) == 'boolean')
  self:_encode_tlv(res, value and '\1' or '\0')
end


local Integer = oo.class(Node):_pre_init {
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


local BigInteger = oo.class(Node):_pre_init {
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 2,
  constructed = false,
}

function BigInteger:_encode(res, value)
  local raw_big_endian_representation = value:tostring 'raw'
  self:_encode_tlv(res, raw_big_endian_representation)
end


local OctetString = oo.class(Node):_pre_init {
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
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 5,
  constructed = false,
}

function Null:_init(options)
  self.null = options.null
  Node._init(self, options)
end

function Null:_encode(res, value)
  assert(value == self.null)
  self:_encode_tlv(res, '')
end


local Oid = oo.class(Node):_pre_init {
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


local Sequence = oo.class(Node):_pre_init {
  tag_class = TAG_CLASS.UNIVERSAL,
  tag = 16,
  constructed = true,
}

function Sequence:_init(options)
  assert(options.of == nil or options[1] == nil, 'Sequence cannot be both a record and SEQUENCE OF')
  self.of = options.of
  if self.of ~= nil and not oo.isinstance(self.of, Node) then
    error 'Sequence "of" elements must be Nodes'
  end
  for i = 1, #options do
    self[i] = options[i]
    assert(oo.isinstance(self[i], Node), 'Sequence children must be Nodes')
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


-- IA5 is basically the same as ASCII, where only the chars U+0000 to U+007F are allowed
local IA5String = oo.class(Node):_pre_init {
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


return {
  TAG_CLASS = TAG_CLASS,
  Node = Node,
  Boolean = Boolean,
  Integer = Integer,
  BigInteger = BigInteger,
  OctetString = OctetString,
  Null = Null,
  Oid = Oid,
  Sequence = Sequence,
  PrintableString = PrintableString,
  IA5String = IA5String,
}
