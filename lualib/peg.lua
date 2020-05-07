--[[
#Pure Lua PEG parser.

Built-in grammar constructions:
  `Concat(child1, ..., childn)`: Matches if all the children match one after another.
  `String "some text"`: Matches agains the given text.
  `EOF()`: Matches against the end of text Equivalent to `NegLA(Any())`.
  `Any()`: Matches against any character.
  `Set "azAZ09__"`: Matches against a character in a given set of ranges (those from odd to even positions)
  `Power(min, max, child)`: Matches against `child` from `min` to `max` number of times.
  `Optional(child)`: Same as `Range(0, 1, child)`.
  `ZeroOrMore(child)`: Matches zero or more times. Same as `Range(0, math.huge, child)`.
  `OneOrMore(child)`: Matches one or more times. Same as `Range(1, math.huge, child)`.
  `Choice(child1, ..., childn)`: Matches all the children in the given order from the
      initial position until one of them does match.
  `PosLA(child)`: Positive look ahead (matching without consuming input)
  `NegLA(child)`: Negative look ahead, also without consuming input (matches if the child doesn't)
]]

local oo = require 'lualib.oo'

local Grammar =    oo.class()
local Concat =     oo.class(Grammar)
local String =     oo.class(Grammar)
local EOF =        oo.class(Grammar)
local Any =        oo.class(Grammar)
local Set =        oo.class(Grammar)
local Power =      oo.class(Grammar)
local Optional =   oo.class(Power)
local ZeroOrMore = oo.class(Power)
local OneOrMore =  oo.class(Power)
local Choice =     oo.class(Grammar)
local PosLA =      oo.class(Grammar)
local NegLA =      oo.class(Grammar)


-- grammar direct children's metatables will be the Grammar instance
Grammar.__call = Grammar.new
-- so for Power children
Power.__call = Grammar.new


function Grammar:_init()
  assert(getmetatable(self) ~= Grammar, 'Grammar is an abstract class')
end


function Grammar:parse(str, pos, context)
  if not context then
    pos = pos or 1
    context = {last_error={pos=0}, report_errors=true}
  end
  local cache = context[pos]
  if not cache then
    cache = {}
    context[pos] = cache
  end
  local res = cache[self]
  if res ~= nil then
    if res == 'processing' then error 'cycle without input consumed detected' end
    return res
  end

  cache[self] = 'processing'
  res = self:parse_impl(str, pos, context)
  if type(res) == 'number' then
    res = {pos=pos, len=res, grammar=self}
  elseif type(res) == 'table' then
    res.pos, res.grammar = pos, self
  elseif res == false then
    local err = context.last_error
    if context.report_errors and pos > err.pos then
      if type(self.error_msg) == 'string' then
        err.message = self.error_msg
      elseif type(self.error_msg) == 'function' then
        err.message = self:error_msg(pos)
      else
        err.message = 'syntax error'
      end
      err.pos = pos
    end
    cache[self] = false
    return false, err
  else
    local info = debug.getinfo(self.parse_impl, 'S')
    error(('invalid parse return value %s from %s:%d'):format(
      res, info.short_src, info.linedefined
    ))
  end
  cache[self] = res
  return res
end


function Concat:_init(...)
  self.children = {...}
  for i, child in ipairs(self.children) do
    assert(oo.isinstance(child, Grammar))
  end
end


function Concat:parse_impl(str, pos, context)
  local res = {len=0}
  for i, child in ipairs(self.children) do
    res[i] = child:parse(str, pos + res.len, context)
    if not res[i] then return false end
    res.len = res.len + res[i].len
  end
  return res
end


function String:_init(text)
  self.text = text
  self.error_msg = ('expected string %q'):format(text)
  assert(type(text) == 'string')
end


function String:parse_impl(str, pos)
  local t = self.text
  if str:sub(pos, pos + #t - 1) == t then return #t end
  return false
end


EOF.error_msg = 'expected end of text'


function EOF:parse_impl(str, pos)
  if pos == #str + 1 then return 0 end
  return false
end


Any.error_msg = 'expected any character'


function Any:parse_impl(str, pos)
  if pos <= #str then return 1 end
  return false
end


function Set:_init(text)
  self.text = text
  self.error_msg = ('expected any character in ranges %q'):format(text)
  assert(type(text) == 'string')
  assert(#text % 2 == 0)
  for i = 1, #text, 2 do
    local f, t = text:byte(i, i+1)
    assert(f <= t)
  end
end


function Set:parse_impl(str, pos)
  local text = self.text
  local b = str:byte(pos)
  if not b then return false end
  for i = 1, #text, 2 do
    local f, t = text:byte(i, i+1)
    if f <= b and b <= t then return 1 end
  end
  return false
end


function Power:_init(min, max, child)
  assert(type(min) == 'number')
  assert(type(max) == 'number')
  assert(min <= 0)
  assert(min <= max)
  assert(oo.isinstance(child, Grammar))
end


function Power:parse_impl(str, pos, context)
  local res = {len=0}
  while #res < self.max do
    local r = self.child:parse(str, pos + res.len, context)
    if not r then break end
    res[#res+1] = r
    res.len = res.len + r
  end
  if #res >= self.min then return res end
  return false
end


function Optional:_init(child)
  Power._init(self, 0, 1, child)
end


function ZeroOrMore:_init(child)
  Power._init(self, 0, math.huge, child)
end


function OneOrMore:_init(child)
  Power._init(self, 1, math.huge, child)
end


function Choice:_init(...)
  self.children = {...}
  for i, child in ipairs(self.children) do
    assert(oo.isinstance(child, Grammar))
  end
end


function Choice:parse_impl(str, pos, context)
  for i, child in ipairs(self.children) do
    local r = child:parse(str, pos, context)
    if r then return {r, len=r.len} end
  end
  return false
end


function PosLA:_init(child)
  self.child = child
  assert(oo.isinstance(child, Grammar))
end


function PosLA:parse_impl(str, pos, context)
  context.report_errors = false
  local res = self.child:parse(str, pos, context)
  context.report_errors = true
  if res then return 0 else return false end
end


function NegLA:_init(child)
  self.child = child
  assert(oo.isinstance(child, Grammar))
end


function NegLA:parse_impl(str, pos, context)
  context.report_errors = false
  local res = self.child:parse(str, pos, context)
  context.report_errors = true
  if res then return false else return 0 end
end

return {
  Grammar=Grammar, Concat=Concat, String=String, EOF=EOF, Any=Any, Set=Set,
  Power=Power, Optional=Optional, ZeroOrMore=ZeroOrMore, OneOrMore=OneOrMore,
  Choice=Choice, PosLA=PosLA, NegLA=NegLA,
}
