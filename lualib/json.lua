local json = {}

-- Used as metatables to help identify empty cases:
json.Array = {}
json.Object = {}

-- sentinel value that can be used if you want to encode a null value
json.Nil = setmetatable({}, {__tostring=function()return 'null'end})

local invalid_numeric_strings = {nan=true, inf=true, ['-inf']=true}
local replacement_code = 0xfffd -- '�'
local replacement_char = ('\\u%04x'):format(replacement_code)
local control_chars = {
  [0] = '\\u0000', '\\u0001', '\\u0002', '\\u0003',
  '\\u0004', '\\u0005', '\\u0006', '\\u0007',
  '\\b',     '\\t',     '\\n',     '\\u000b',
  '\\f',     '\\r',     '\\u000e', '\\u000f',
  '\\u0010', '\\u0011', '\\u0012', '\\u0013',
  '\\u0014', '\\u0015', '\\u0016', '\\u0017',
  '\\u0018', '\\u0019', '\\u001a', '\\u001b',
  '\\u001c', '\\u001d', '\\u001e', '\\u001f',
  [34] = '\\"', [92] = '\\\\'
}

-- default is_array implementation
function json.is_array(value)
  local mt = getmetatable(value)
  if mt == json.Array then
    return true
  elseif mt == json.Object then
    return false
  elseif value[1] then
    return true
  else
    return false
  end
end


local function encode_array(arr, opts, path, visiting, buffer)
  local depth = #path + 1
  buffer[#buffer+1] = "["
  for k, v in ipairs(arr) do
    path[depth] = k
    if k > 1 then buffer[#buffer+1] = "," end
    json.encode(v, opts, path, visiting, buffer)
  end
  path[depth] = nil
  if not opts.skip_invalid_keys then
    for k, v in pairs(arr) do
      if type(k) ~= 'number' or k < 1 or k > #arr or k ~= math.floor(k) then
        error(('invalid key %s found at %s'):format(k, table.concat(path, '.')))
      end
    end
  end
  buffer[#buffer+1] = "]"
end


local function encode_object(obj, opts, path, visiting, buffer)
  local depth = #path + 1
  local first = true
  buffer[#buffer + 1] = "{"
  for k, v in pairs(obj) do
    path[depth] = k
    if type(k) == 'string' then
      if first then first=false else buffer[#buffer+1] = "," end
      buffer[#buffer+1] = json.encode_string(k, opts)
      buffer[#buffer+1] = ':'
      json.encode(v, opts, path, visiting, buffer)
    elseif not opts.skip_invalid_keys then
      path[depth] = nil
      error(('invalid key %s found at %s'):format(k, table.concat(path, '.')))
    end
  end
  path[depth] = nil
  buffer[#buffer + 1] = "}"
end


local utf8_ranges = {
  {maxb1=0xdf, offset=0x3080, minc=0x80},
  {maxb1=0xef, offset=0xe2080, minc=0x800},
  {maxb1=0xf7, offset=0x3c82080, minc=0x10000},
}

local function utf8_decoder(str, i)
  local b1 = str:byte(i)
  local c = b1

  if b1 < 0xc0 or b1 >= 0xf8 then -- invalid non-ascii first byte
    return i+1, replacement_code
  end
  
  for j, x in ipairs(utf8_ranges) do
    local b = str:byte(i+j)
    if not b or b < 0x80 or b > 0xbf then return i+j+1, replacement_code end
    c = c * 64 + b
    --error(('%x %x %x'):format(b1, b, c))
    if b1 <= x.maxb1 then
      c = c - x.offset
      return i+j+1, (c >= x.minc and c or replacement_code)
    end
  end
  return i+#utf8_ranges+1, replacement_code
end

function json.encode_string(str, opts)
  local res = {'"'}
  local i = 1
  while i <= #str do
    local b = str:byte(i)
    local c = control_chars[b]
    if c then
      res[#res + 1] = c
      i = i + 1
    elseif b < 128 then
      local start = i
      while i <= #str and not control_chars[b] and b < 128 do
        i = i + 1
        b = str:byte(i)
      end
      res[#res + 1] = str:sub(start, i-1)
    else
      i, b = (opts.charset_decoder or utf8_decoder)(str, i)
      if b >= 0x80 and b < 0xd800 then
        res[#res + 1] = ('\\u%04x'):format(b)
      elseif b < 0xe000 then
        res[#res + 1] = replacement_char
      elseif b < 0x10000 then
        res[#res + 1] = ('\\u%04x'):format(b)
      elseif b < 0x110000 then
        b = b - 0x10000
        res[#res + 1] = ('\\u%04x\\u%04x'):format(math.floor(b / 1024) + 0xd800, b % 1024 + 0xdc00)
      else
        res[#res + 1] = replacement_char
      end
    end
  end
  res[#res + 1] = '"'
  return table.concat(res)
end


function json.encode(value, opts, path, visiting, buffer)
  -- Encodes value in JSON format returning a string.
  --   opts: table with the optional values:
  --     allow_invalid_numbers: boolean (default false) allow inf, -inf and nan
  --     skip_invalid_keys: boolean (default false) skip non-string keys instead of erroring
  --     is_array: function[value:table, path:List[string|number] -> boolean]
  --               can be used to specify when to encode a table as an array,
  --     charset_decoder: function[string, startpos:number -> nextpos:number, charcode:number]
  --               can be overriden if the original strings don't have utf-8 valid text
  -- Parameters you shouldn't be passing from outside code:
  --   path: List[string|number] (default {}) path of the node currently visiting
  --   visiting: Set[table] (default {}) nodes currently visiting, used for circular reference detection
  --   buffer: List[string] (default {}) place where strings get stored
  local t = type(value)
  if path == nil then
    opts = opts or {}
    path = {}
    visiting = {} -- set of visited objects
    buffer = {}
  end

  local res
  if value == json.Nil then
    buffer[#buffer+1] = 'null'
  elseif t == 'table' then
    if visiting[value] then
      error 'circular reference found'
    else
      visiting[value] = true
    end
    if (opts.is_array or json.is_array)(value, path) then
      encode_array(value, opts, path, visiting, buffer)
    else
      encode_object(value, opts, path, visiting, buffer)
    end
    visiting[value] = nil
  elseif t == 'string' then
    buffer[#buffer+1] = json.encode_string(value, opts)
  elseif t == 'boolean' or t == 'nil' then
    buffer[#buffer+1] = ({[false]='false', [true]='true'})[value] or 'null'
  elseif t == 'number' then
    res = tostring(value)
    if invalid_numeric_strings[res] and not opts.allow_invalid_numbers then
      error 'trying to encode invalid number'
    end
    buffer[#buffer+1] = res
  else
    error('trying to encode ilegal type '..t)
  end
  if #path == 0 then
    -- lua already optimizes the single string in buffer concat case
    return table.concat(buffer)
  end
end

local key_mt = {}
-- we build objects and arrays as postscript does with "<<"
local open_object_mark = {}
local open_array_mark = {}

local state_machine = {
  default = {
    {
      pattern = '^{',
      op = function(_, stack) stack[#stack+1] = open_object_mark end
    }, {
      pattern = '^%[',
      op = function(_, stack) stack[#stack+1] = open_array_mark end
    }, {
      pattern = '^[0-9+%.-][0-9+%.eE-]*',
      next_state = 'after_expression',
      op = function(n, stack) stack[#stack+1] = tonumber(n) end
    }, {
      pattern = '^"',
      next_state = 'in_string',
      op = function(_, stack) stack[#stack+1] = {} end
    }, {
      pattern = '^]',
      next_state = 'after_expression',
      op = function(_, st)
        assert(st[#st] == open_array_mark, 'unexpected close bracket')
        st[#st] = setmetatable({}, json.Array)
      end
    }, {
      pattern = '^}',
      next_state = 'after_expression',
      op = function(_, st)
        assert(st[#st] == open_object_mark, 'unexpected close brace (spurious comma?)')
        st[#st] = setmetatable({}, json.Object)
      end
    }, {
      pattern = '^true',
      next_state = 'after_expression',
      op = function(_, stack) stack[#stack+1] = true end
    }, {
      pattern = '^false',
      next_state = 'after_expression',
      op = function(_, stack) stack[#stack+1] = false end
    }, {
      pattern = '^null',
      next_state = 'after_expression',
      op = function(_, stack) stack[#stack+1] = json.Nil end
    }, {
      pattern = '^%s+'
    }
  },
  in_string = {
    {
      pattern = '^"',
      next_state = 'after_expression',
      op = function(_, st) st[#st] = table.concat(st[#st]) end
    }, {
      pattern = '^[^"\\]+',
      op = function(s, st) local b = st[#st]; b[#b+1] = s end
    }, {
      pattern = '^\\["\\/bfnrt]',
      op = function(s, st)
        local b, c = st[#st], s:sub(2)
        b[#b+1] = ({b='\b', f='\f', n='\n', r='\r', t='\t'})[c] or c
      end
    }, {
      pattern = '^\\u[Dd][89ABab]%x%x\\u[Dd][CDEFcdef]%x%x',
      op = function(s, st) -- utf-16 SMP
        local code = 1024*(tonumber(s:sub(3,6),16)-0xd800) + tonumber(s:sub(9,12),16)-0xdc00 + 0x10000
        local b = st[#st]
        b[#b+1] = string.char(
          0xf0 + math.floor(code/0x40000),
          0x80 + math.floor(code/0x1000)%64,
          0x80 + math.floor(code/0x40)%64,
          0x80 + code%64)
      end
    }, {
      pattern = '^\\u[Dd][0-7]%x%x',
      op = function(s, st) -- utf-16 0xD### part of BMP
        local code = tonumber(s:sub(3,6),16)
        local b = st[#st]
        b[#b+1] = string.char(
          0xe0 + math.floor(code/0x1000)%64,
          0x80 + math.floor(code/0x40)%64,
          0x80 + code%64)
      end
    }, {
      pattern = '^\\u[0-9ABCEFabcef]%x%x%x',
      op = function(s, st) -- utf-16 rest of BMP
        local code = tonumber(s:sub(3,6),16)
        local b = st[#st]
        if code >= 0x800 then
          b[#b+1] = string.char(
            0xe0 + math.floor(code/0x1000)%64,
            0x80 + math.floor(code/0x40)%64,
            0x80 + code%64)
        elseif code >= 0x80 then
          b[#b+1] = string.char(0xc0 + math.floor(code/0x40)%64, 0x80 + code%64)
        else
          b[#b+1] = string.char(code)
        end
      end
    }
  },
  after_expression = {
    final = true,
    {
      pattern = '^:',
      next_state = 'default',
      op = function(_, st)
        assert(type(st[#st]) == 'string', 'keys must be strings')
        st[#st] = setmetatable({key=st[#st]}, key_mt) -- wrap object tagging it with key_mt
      end
    }, {
      pattern = '^,',
      next_state = 'default'
    }, {
      pattern = '^]',
      op = function(_, st)
        local container = setmetatable({}, json.Array)
        local base = #st
        while base >= 2 and st[base] ~= open_array_mark do
          assert(getmetatable(st[base]) ~= key_mt, 'keys are not allowed in arrays')
          assert(st[base] ~= open_object_mark, 'missing object close brace')
          base = base - 1
        end
        assert(st[base] == open_array_mark, 'unexpected close bracket')
        for i = base + 1, #st do
          container[#container + 1], st[i] = st[i], nil
        end
        st[base] = container
      end
    }, {
      pattern = '^}',
      op = function(_, st)
        local container = setmetatable({}, json.Object)
        local base = #st
        while base >= 3 and st[base] ~= open_object_mark do
          assert(st[base] ~= open_array_mark, 'missing array close bracket')
          assert(getmetatable(st[base-1]) == key_mt, 'value with missing key in object')
          base = base - 2
        end
        assert(st[base] == open_object_mark, 'unexpected close brace')
        for i = base + 1, #st, 2 do
          container[st[i].key] = st[i+1]
          st[i], st[i+1] = nil, nil
        end
        st[base] = container
      end
    }, {
      pattern = '^%s+'
    }
  }
}


function json.parse(str)
  local stack = {}
  local state = state_machine.default
  local state_name = 'default'
  local i = 1
  while i <= #str do
    local matched = false
    --print(('i=%d, state_name=%s'):format(i, state_name))
    for _, transition in ipairs(state) do
      local start, finish = str:find(transition.pattern, i)
      if start then
        --print(('matched range %d..%d'):format(start,finish))
        assert(start == i, 'patterns should start with ^')
        i = finish + 1
        if transition.op then
          transition.op(str:sub(start, finish), stack)
        end
        if transition.next_state then
          state = state_machine[transition.next_state]
          state_name = transition.next_state
        end
        matched = true
        break
      end
    end
    if not matched then
      error(('unexpected input at %d in state %s'):format(i, state_name))
    end
  end
  if #stack ~= 1 then error 'unexpected eof' end
  if not state.final then error 'invalid end state' end
  return stack[1]
end


function json.pp(value, indent, maxline, buffer)
  local buff = buffer
  if not buffer then
    indent = indent or '\n'
    maxline = maxline or 100
    buff = {}
  end
  local function linesize(value, max)
    if type(value) == 'string' then
      return #('%q'):format(value)
    elseif type(value) == 'table' then
      local len, first = 2, true
      for k, v in pairs(value) do
        if not first then len = len + 2 end -- for the ', '
        first = false
        if type(k) == 'string' then len = len + 2 + linesize(k, max-len) end
        len = len + linesize(v, max-len)
        if len > max then return max + 1 end
      end
      return len 
    else
      return #tostring(value)
    end
  end
  if type(value) == 'string' then
    buff[#buff+1] = ('%q'):format(value)
  elseif type(value) == 'table' and value ~= json.Nil then
    local is_array = json.is_array(value)
    buff[#buff+1] = is_array and '[' or '{'
    local first = true
    local max = maxline - #indent + 1
    local keys = {}
    for k in pairs(value) do keys[#keys+1] = k end
    table.sort(keys)
    if maxline < 0 or linesize(value, max) <= max then
      for i, k in ipairs(keys) do
        if first then first = false else buff[#buff+1] = ', ' end
        if not is_array then buff[#buff+1] = ('%q: '):format(k) end
        json.pp(value[k], indent, -1, buff)
      end
    else -- not inline:
      local subindent = indent .. '  '
      for i, k in ipairs(keys) do
        if first then first = false else buff[#buff+1] = ',' end
        buff[#buff+1] = subindent
        if not is_array then buff[#buff+1] = ('%q: '):format(k) end
        json.pp(value[k], subindent, maxline - (is_array and 2 or #buff[#buff]) - 1, buff)
      end
      buff[#buff+1] = indent
    end
    buff[#buff+1] = is_array and ']' or '}'
  else
    buff[#buff+1] = tostring(value)
  end
  if not buffer then return table.concat(buff) end
end


return json
