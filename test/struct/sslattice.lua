local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local empty = require 'lualib.struct.sslattice'

local SSLatticeTest = oo.class(BaseTest)


function SSLatticeTest:test_basic()
  local st = empty:add'ball$':add'basic$':add'bea$'
  self:assert_equal(tostring(st), ([[
    1, b-2
    2, a-3, ea-4
    3, ll-4, sic-4
    4, $-5
    5
  ]]):gsub(' ', ''):gsub('^%s*(.-)%s*$', '%1'))
end

function SSLatticeTest:test_cache()
  repeat
    -- add a random tree, the GC will eventually have to kick in:
    empty:add(tostring(math.random()))
    local old = empty.cache_stats().trees
    collectgarbage()
    local trees = empty.cache_stats().trees
  until trees == 1 or trees < old
  local _ = empty:add 'bb':add 'b'
  self:assert_greater_or_equal(empty.cache_stats().trees, 3)
  collectgarbage()
  -- {}, {b={}}, {b={b={}}}, ...
  self:assert_greater_or_equal(empty.cache_stats().trees, 3)
end


SSLatticeTest:run_if_main()


return SSLatticeTest
