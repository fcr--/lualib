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

-- One characteristic of adding the metamethod __call to the metatables is
-- that when Lua calls it, it passes the table being "called" as the first
-- parameter to the function, so the Grammar's (and Power's) children have
-- to be called with, for instance:
--   local peg = require 'lualib.peg'
--   local grammar = peg.String' x'
-- Grammar's direct children metatables are the Grammar table itself:
Grammar.__call = Grammar.new
Power.__call = Grammar.new


function Grammar:_init()
  assert(getmetatable(self) ~= Grammar, 'Grammar is an abstract class')
end

-- returns an AST or (false and an error table with message:string, pos:int),
-- the AST has the following attributes:
--   1..n: Children AST nodes.
--   "pos": (int 1..#parsed_string) position where the text was parsed.
--   "len": (int 0..#parsed_string) length for the matched text.
--   "grammar": Grammar instance that produced the AST node.
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


-- `match` first calls the `parse` method to obtain the parsed AST, then that
-- tree will be converted on a "response tree" built from tags and visitors
-- responses.
function Grammar:match(str)
   local function visit(node, res)
      local grammar = node.grammar
      local tagname, visitor = grammar.tagname, grammar.visitor
      -- We reuse the same res if there's no visitor at the current node because we
      -- want to be able collect returns at multiple node levels:
      local subres = visitor and {} or res
      for i = 1, #node do
         visit(node[i], subres)
      end
      if not tagname then return end

      local value = (not visitor) and str:sub(node.pos, node.len) or visitor(subres, str, node)
      if grammar.multiple_matches then
         local values = res[tagname]
         if not values then
            values = {}
            res[tagname] = values
         end
         values[#values + 1] = value
      elseif res[tagname] then
         error(('tag %s value redefined at %d'):format(tagname, node.pos))
      end
   end
   local ast, err = self:parse(str)
   if err then error(('%s at %d'):format(err.message, err.pos)) end
   local res = {}
   visit(ast, res)
   return res
end


-- When `match` is executed (after parsing), this will set on the resulting object the
-- given tagname with the result of the visitor or the parsed text if no visitor is provided.
--   If the grammar matches more than once within the same response object an error will be thrown,
-- use `mtag` instead and then the tagname will be associated to a list of the captures.
--   The visitor will receive three arguments, a table containing the associations for the
-- tagnames of children nodes, the whole string being parsed (not just the captured part)
-- and its AST node.
function Grammar:tag(tagname, visitor)
   self.tagname = tagname
   self.visitor = visitor
   return self
end
function Grammar:mtag(tagname, visitor)
   self.tagname = tagname
   self.visitor = visitor
   self.multiple_matches = true
   return self
end


function Concat:_init(...)
  self.children = {...}
  for _, child in ipairs(self.children) do
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


function EOF:parse_impl(str, pos)  -- luacheck: ignore self
   if pos == #str + 1 then return 0 end
   return false
end


Any.error_msg = 'expected any character'


function Any:parse_impl(str, pos)  -- luacheck: ignore self
   if pos <= #str then return 1 end
   return false
end


function Set:_init(text)
  self.text = text
  self.error_msg = ('expected any character in ranges %q'):format(text)
  assert(type(text) == 'string')
  assert(#text % 2 == 0 and #text > 0)
  local bytes = {}
  for i = 1, #text, 2 do
    local f, t = text:byte(i, i+1)
    assert(f <= t)
    for b = f, t do
      assert(not bytes[b], 'duplicated char in set')
      bytes[b] = true
    end
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
  assert(min >= 0)
  assert(min <= max)
  assert(oo.isinstance(child, Grammar))
  self.min, self.max, self.child = min, max, child
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
  for _, child in ipairs(self.children) do
    assert(oo.isinstance(child, Grammar))
  end
end


function Choice:parse_impl(str, pos, context)
  for _, child in ipairs(self.children) do
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
  local res = self.child:parse(str, pos, context)
  if res then return {res, len=0} else return false end
end


function NegLA:_init(child)
  self.child = child
  assert(oo.isinstance(child, Grammar))
end


function NegLA:parse_impl(str, pos, context)
  local last_report_errors = context.report_errors
  context.report_errors = false
  local res = self.child:parse(str, pos, context)
  context.report_errors = last_report_errors
  if res then return false else return 0 end
end

return {
  Grammar=Grammar, Concat=Concat, String=String, EOF=EOF, Any=Any, Set=Set,
  Power=Power, Optional=Optional, ZeroOrMore=ZeroOrMore, OneOrMore=OneOrMore,
  Choice=Choice, PosLA=PosLA, NegLA=NegLA,
}
