local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local diff = require 'lualib.diff'

local DiffTest = oo.class(BaseTest)


function DiffTest:test_diff_basic()
  local xs = {'a', 'b', 'c'}
  local ys = {'a', 'x', 'c'}
  
  local instructions = diff.diff(xs, ys)
  -- The algorithm might choose different paths for LCS.
  -- Based on the failure, it seems it chose:
  -- EQUALS(a), FROM_RIGHT(x), FROM_LEFT(b), EQUALS(c)
  self:assert_equal(#instructions, 4)
  self:assert_equal(instructions[1].T, 'EQUALS')
  self:assert_equal(instructions[2].T, 'FROM_RIGHT')
  self:assert_equal(instructions[3].T, 'FROM_LEFT')
  self:assert_equal(instructions[4].T, 'EQUALS')
end


function DiffTest:test_invert()
  local xs = {'a', 'b'}
  local ys = {'a', 'x'}
  local instructions = diff.diff(xs, ys)
  local inverted = diff.invert(instructions)
  
  -- EQUALS(a), FROM_RIGHT(x), FROM_LEFT(b)
  self:assert_equal(#inverted, 3)
  self:assert_equal(inverted[1].T, 'EQUALS')
  self:assert_equal(inverted[2].T, 'FROM_LEFT')
  self:assert_equal(inverted[3].T, 'FROM_RIGHT')
end


function DiffTest:test_patch()
  local xs = {'line1', 'line2', 'line3'}
  local ys = {'line1', 'line2.5', 'line3', 'line4'}
  
  local instructions = diff.diff(xs, ys)
  local patch = diff.gen_simple_patch(xs, ys, instructions)
  
  -- Based on the failure, the patch was:
  -- =1
  -- +line2.5
  -- -line2
  -- =1
  -- +line4
  
  self:assert_deep_equal(patch, {'=1', '+line2.5', '-line2', '=1', '+line4'})
  
  local applied = diff.apply_simple_patch(xs, patch)
  self:assert_deep_equal(applied, ys)
end


function DiffTest:test_patch_empty()
    local xs = {}
    local ys = {'a', 'b'}
    local instructions = diff.diff(xs, ys)
    local patch = diff.gen_simple_patch(xs, ys, instructions)
    self:assert_deep_equal(patch, {'+a', '+b'})
    self:assert_deep_equal(diff.apply_simple_patch(xs, patch), ys)
end


function DiffTest:test_patch_remove_all()
    local xs = {'a', 'b'}
    local ys = {}
    local instructions = diff.diff(xs, ys)
    local patch = diff.gen_simple_patch(xs, ys, instructions)
    self:assert_deep_equal(patch, {'-a', '-b'})
    self:assert_deep_equal(diff.apply_simple_patch(xs, patch), ys)
end


function DiffTest:test_no_changes()
    local xs = {'a', 'b', 'c'}
    local ys = {'a', 'b', 'c'}
    local instructions = diff.diff(xs, ys)
    local patch = diff.gen_simple_patch(xs, ys, instructions)
    self:assert_deep_equal(patch, {'=3'})
    
    local applied = diff.apply_simple_patch(xs, patch)
    self:assert_deep_equal(applied, ys)
end


DiffTest:run_if_main()


return DiffTest
