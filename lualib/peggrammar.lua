local peg = require 'lualib.peg'
local oo = require 'lualib.oo'
local unpack = unpack or table.unpack

local blanks = peg.ZeroOrMore(peg.Set '\0 ')

-- examples:
--  0 parenthesis: (grammar expression)
--  1 literal string: 'hello'
--  1 non-terminal: ref
--  1 eof: $
--  1 any character: .
--  1 set: [az09__]
--  2 power: atom{min,max} or atom{num}
--  2 optional: atom?
--  2 zero or more: atom*
--  2 one or more: atom+
--  2 negative lookahead: !atom
--  2 positive lookahead: &atom
--  3 concat: atom1 atom2
--  4 choice: atom / atom / ...

local grammar_ref = peg.Ref()

-- helpers

local function match_text(str, node)
   return str:sub(node.pos, node.pos + node.len - 1)
end

local function unwrap(subres)
   assert(#subres.g == 1, 'expected exactly one capture')
   return subres.g[1]
end

local function resolve_references(start_node, rules)
   local seen = {}
   local function resolve(p)
      if type(p) ~= 'table' or seen[p] then return end
      seen[p] = true

      if oo.isinstance(p, peg.Ref) and not p.child then
         local def = rules[p.name]
         if not def then error('undefined non-terminal: ' .. p.name) end
         p:resolve(def)
         resolve(def)
      end
      if p.child then resolve(p.child) end
      if p.children then
         for _, child in ipairs(p.children) do
            resolve(child)
         end
      end
   end
   resolve(start_node)
end

-- #############################################################################
-- # Precedence 0: Parenthesized Expression
-- #############################################################################

local parens = peg.Concat(
   peg.String '(', blanks, grammar_ref, blanks, peg.String ')'
)

-- #############################################################################
-- # Precedence 1: Atoms
-- #############################################################################

local string = peg.Concat(
   peg.String "'",
   peg.ZeroOrMore(
      peg.Choice(
         peg.String "''",
         peg.Concat(peg.NegLA(peg.String "'"), peg.Any())
      )
   ),
   peg.String "'"
):mtag('g', function(_, str, node)
   local s = match_text(str, node)
   return peg.String((s:sub(2, #s-1):gsub("''", "'")))
end)


local nonterminal = peg.Concat(
   peg.Set 'azAZ__',
   peg.ZeroOrMore(peg.Set 'azAZ09__')
):mtag('g', function(_, str, node)
   local name = match_text(str, node)
   local ref = peg.Ref()
   ref.name = name
   return ref
end)

local eof = peg.String '$':mtag('g', function() return peg.EOF() end)

local any = peg.String '.':mtag('g', function() return peg.Any() end)

local set = peg.Concat(
   peg.String '[',
   peg.ZeroOrMore(
      peg.Choice(
         peg.Concat(peg.NegLA(peg.String ']'), peg.Any(), peg.Any()),
         peg.String ']]'
      )
   ),
   peg.String ']'
):mtag('g', function(_, str, node)
   local s = match_text(str, node)
   return peg.Set(s:sub(2, #s-1):gsub(']]', ']'))
end)


local atom = peg.Choice(parens, string, nonterminal, eof, any, set)

grammar_ref:resolve(atom)

-- #############################################################################
-- # Precedence 2: Post-operands and Lookaheads
-- #############################################################################

local post = peg.Concat(
   atom,
   peg.Optional(
      peg.Concat(
         blanks,
         peg.Choice(
            peg.String '?':tag('op', function() return peg.Optional end),
            peg.String '*':tag('op', function() return peg.ZeroOrMore end),
            peg.String '+':tag('op', function() return peg.OneOrMore end),
            peg.Concat(
               peg.String '{',
               blanks,
               peg.OneOrMore(peg.Set '09'):tag('min', function(_, str, node)
                  return tonumber(match_text(str, node))
               end),
               blanks,
               peg.Optional(
                  peg.Concat(
                     peg.String ',',
                     blanks,
                     peg.OneOrMore(peg.Set '09'):tag('max', function(_, str, node)
                        return tonumber(match_text(str, node))
                     end)
                  )
               ),
               blanks,
               peg.String '}'
            ):tag('op', function(subres)
               return function(child)
                  return peg.Power(subres.min, subres.max or subres.min, child)
               end
            end)
         )
      )
   )
):mtag('g', function(subres)
   if #subres.g ~= 1 then
      error('internal error on number of "post" children: '..#subres.g)
   end
   if subres.op then
      return subres.op(subres.g[1])
   end
   return subres.g[1]
end)

-- precendence 2: look-aheads

local posla = peg.Concat(
   peg.String '&', blanks, atom
):mtag('g', function(subres) return peg.PosLA(subres.g[1]) end)

local negla = peg.Concat(
   peg.String '!', blanks, atom
):mtag('g', function(subres) return peg.NegLA(subres.g[1]) end)

local pre = peg.Choice(posla, negla, post)

-- #############################################################################
-- # Precedence 3: Concatenation
-- #############################################################################

local concat = peg.Concat(
   pre,
   peg.ZeroOrMore(
      peg.Concat(blanks, pre)
   )
):mtag('g', function(subres)
   if #subres.g == 1 then return subres.g[1] end
   return peg.Concat(unpack(subres.g))
end)

-- #############################################################################
-- # Precedence 4: Choice
-- #############################################################################

local choice = peg.Concat(
   concat,
   peg.ZeroOrMore(
      peg.Concat(
         blanks,
         peg.String '/',
         blanks,
         concat
      )
   )
):mtag('g', function(subres)
   if #subres.g == 1 then return subres.g[1] end
   return peg.Choice(unpack(subres.g))
end)

grammar_ref:resolve(choice)

-- #############################################################################
-- # Rule Definitions and Full Grammar
-- #############################################################################

local rule_sep = peg.Concat(
   peg.String ';', blanks
)

local rule = peg.Concat(
   peg.Concat(nonterminal):tag('name', unwrap),
   blanks,
   peg.String '<-',
   blanks,
   peg.Concat(choice):tag('defn', unwrap)
):mtag('rules', function(subres)
   return {name = subres.name.name, defn = subres.defn}
end)

-- grammar: rule1 rule2 ...

local full_grammar = peg.Concat(
   blanks,
   peg.Concat(choice):tag('start', unwrap),
   blanks,
   peg.ZeroOrMore(
      peg.Concat(
         rule_sep,
         rule,
         blanks
      )
   ),
   peg.EOF()
):mtag('grammar', function(subres)
   local rules = {}
   if subres.rules then
      for _, entry in ipairs(subres.rules) do
         rules[entry.name] = entry.defn
      end
   end

   resolve_references(subres.start, rules)

   return subres.start
end)


return {
  internals = {
    parens = parens,
    string = string,
    nonterminal = nonterminal,
    eof = eof,
    any = any,
    set = set,
    atom = atom,
    post = post,
    pre = pre,
    concat = concat,
    choice = choice,
  },
  parse = function(str)
     local ok, res = pcall(full_grammar.match, full_grammar, str)
     if not ok then
        error('PEG syntax error: ' .. tostring(res))
     end
     return res.grammar[1]
  end
}
