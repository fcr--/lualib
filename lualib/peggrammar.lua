local peg = require 'lualib.peg'
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

-- precedence 0: parenthesized expression

local parens = peg.Concat(
   peg.String '(', blanks, grammar_ref, blanks, peg.String ')'
)

-- precedence 1: atoms

local string = peg.Concat(
   peg.String "'",
   peg.ZeroOrMore(
      peg.Choice(
         peg.String "''",
         peg.Concat(peg.NegLA(peg.String "'"), peg.Any())
      ),
      peg.Any()
   ):mtag('g', function(_, str)
      return peg.String((str:gsub("''", "'")))
   end)
   peg.String "'"
)

local nonterminal = peg.Concat(
   peg.Set 'azAZ__',
   peg.ZeroOrMore(peg.Set 'azAZ09__')
):mtag('g', function(_, str)
   local ref = peg.Ref()
   ref.name = str
   return ref
end),

local eof = peg.String '$':mtag('g', function() return peg.EOF() end)

local any = peg.String '.':mtag('g', function() return peg.Any() end)

local set = peg.Concat(
   peg.String '[',
   peg.ZeroOrMore(
      peg.Choice(
         peg.Concat(peg.NegLA(peg.String ']'), peg.Any(), peg.Any()),
         peg.String ']]'
      )
   ):mtag('g', function(_, str)
      return peg.Set(str)
   end),
   peg.String ']'
)

local atom = peg.Choice(string, nonterminal, eof, any, set)

-- precedence 2: post-operands and lookaheads, eg: &foo+ is a syntax error
local post = peg.Concat(
   atom,
   peg.Optional(
      blanks,
      peg.Choice(
         peg.String '?':tag('p', function() return {fn=peg.Optional} end),
         peg.String '*':tag('p', function() return {fn=peg.ZeroOrMore} end),
         peg.String '+':tag('p', function() return {fn=peg.OneOrMore} end),
         peg.Concat(
            peg.String '{',
            blanks,
            peg.OneOrMore(peg.Set '09'):tag('min', function(_, s) return tonumber(s) end),
            blanks,
            peg.String ',',
            blanks,
            peg.OneOrMore(peg.Set '09'):tag('max', function(_, s) return tonumber(s) end),
            blanks,
            peg.String '}'
         ):tag('p', function(subres) return {fn=peg.Power, subres.min, subres.max} end)
      )
   )
):tag('g', function(subres)
   local params = {unpack(subres.p)}
   params[#params+1] = subres.g[1]
   return subres.p.fn(unpack(params))
)

-- precendence 2: look-aheads

local posla = peg.Concat(
   peg.String '&', blanks, atom
):mtag('g', function(subres) return peg.PosLA(subres.g[1]) end)

local negla = peg.Concat(
   peg.String '!', blanks, atom
):mtag('g', function(subres) return peg.NegLA(subres.g[1]) end)
