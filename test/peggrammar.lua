local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local peg = require 'lualib.peg'
local peggrammar = require 'lualib.peggrammar'

local PegGrammarTest = oo.class(BaseTest)


function PegGrammarTest:test_any()
  local g = peggrammar.internals.any:match('.')
  self:assert_equal(oo.isinstance(g.g[1], peg.Any), true)
end


function PegGrammarTest:test_eof()
  local g = peggrammar.internals.eof:match('$')
  self:assert_equal(oo.isinstance(g.g[1], peg.EOF), true)
end


function PegGrammarTest:test_set()
  local g = peggrammar.internals.set:match('[az09]')
  self:assert_equal(oo.isinstance(g.g[1], peg.Set), true)
  self:assert_equal(g.g[1].text, 'az09')
end


function PegGrammarTest:test_nonterminal()
  local g = peggrammar.internals.nonterminal:match('my_rule')
  -- nonterminal is tagged 'g', result is in g.g[1]
  self:assert_equal(oo.isinstance(g.g[1], peg.Ref), true)
  self:assert_equal(g.g[1].name, 'my_rule')
end


function PegGrammarTest:test_string()
  local g = peggrammar.internals.string:match("'hello'")
  self:assert_equal(oo.isinstance(g.g[1], peg.String), true)
  self:assert_equal(g.g[1].text, 'hello')
end


function PegGrammarTest:test_parens()
  local g = peggrammar.internals.parens:match("( . )")
  self:assert_equal(oo.isinstance(g.g[1], peg.Any), true)
end


function PegGrammarTest:test_nested_parens()
  local g = peggrammar.internals.parens:match("((.))")
  self:assert_equal(oo.isinstance(g.g[1], peg.Any), true)
end


function PegGrammarTest:test_post()
  local g
  -- Optional ?
  g = peggrammar.internals.post:match(".?")
  self:assert_equal(oo.isinstance(g.g[1], peg.Optional), true)

  -- ZeroOrMore *
  g = peggrammar.internals.post:match(".*")
  self:assert_equal(oo.isinstance(g.g[1], peg.ZeroOrMore), true)

  -- OneOrMore +
  g = peggrammar.internals.post:match(".+")
  self:assert_equal(oo.isinstance(g.g[1], peg.OneOrMore), true)

  -- Power {n}
  g = peggrammar.internals.post:match(".{3}")
  self:assert_equal(oo.isinstance(g.g[1], peg.Power), true)
  self:assert_equal(g.g[1].min, 3)
  self:assert_equal(g.g[1].max, 3)

  -- Power {min,max}
  g = peggrammar.internals.post:match(".{2,4}")
  self:assert_equal(oo.isinstance(g.g[1], peg.Power), true)
  self:assert_equal(g.g[1].min, 2)
  self:assert_equal(g.g[1].max, 4)
end


function PegGrammarTest:test_pre()
  local g
  -- Positive Lookahead &
  g = peggrammar.internals.pre:match("&.")
  self:assert_equal(oo.isinstance(g.g[1], peg.PosLA), true)

  -- Negative Lookahead !
  g = peggrammar.internals.pre:match("!.")
  self:assert_equal(oo.isinstance(g.g[1], peg.NegLA), true)
end


function PegGrammarTest:test_pre_syntax_error()
  local g = peg.Concat(peggrammar.internals.pre, peg.EOF())
  self:assert_error(function()
    g:match("!.+")
  end)
end


function PegGrammarTest:test_concat()
  local g
  -- Single atom (returns the atom itself, not a Concat)
  g = peggrammar.internals.concat:match(".")
  self:assert_equal(oo.isinstance(g.g[1], peg.Any), true)

  -- Two atoms
  g = peggrammar.internals.concat:match(". .")
  self:assert_equal(oo.isinstance(g.g[1], peg.Concat), true)
  self:assert_equal(#g.g[1].children, 2)

  -- Atom and post-op
  g = peggrammar.internals.concat:match(". .+")
  self:assert_equal(oo.isinstance(g.g[1], peg.Concat), true)
  self:assert_equal(oo.isinstance(g.g[1].children[1], peg.Any), true)
  self:assert_equal(oo.isinstance(g.g[1].children[2], peg.OneOrMore), true)
end


function PegGrammarTest:test_choice()
  local g
  -- Single element (returns element itself)
  g = peggrammar.internals.choice:match(".")
  self:assert_equal(oo.isinstance(g.g[1], peg.Any), true)

  -- Two alternatives
  g = peggrammar.internals.choice:match(". / $")
  self:assert_equal(oo.isinstance(g.g[1], peg.Choice), true)
  self:assert_equal(#g.g[1].children, 2)
  self:assert_equal(oo.isinstance(g.g[1].children[1], peg.Any), true)
  self:assert_equal(oo.isinstance(g.g[1].children[2], peg.EOF), true)
end


function PegGrammarTest:test_full_grammar()
  -- start rule is "sub / .", then rule "sub"
  local grammar_str = "sub / . ; sub <- 'hello'"
  local g = peggrammar.parse(grammar_str)

  self:assert_equal(oo.isinstance(g, peg.Choice), true)
  self:assert_equal(oo.isinstance(g.children[1], peg.Ref), true)
  self:assert_equal(g.children[1].name, "sub")
  -- Verify resolution
  self:assert_equal(oo.isinstance(g.children[1].child, peg.String), true)
  self:assert_equal(g.children[1].child.text, "hello")
end


function PegGrammarTest:test_full_grammar_complex()
  local grammar_str = [[
    (atom (blanks atom)*) / $ ;
    atom   <- [az] / [09] ;
    blanks <- ' '+
  ]]
  local g = peggrammar.parse(grammar_str)
  self:assert_equal(oo.isinstance(g, peg.Choice), true)
end


PegGrammarTest:run_if_main()


return PegGrammarTest
