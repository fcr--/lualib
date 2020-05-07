local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'


local Tests = oo.class(BaseTest)
  :link_class(require 'test.oo')
  :link_class(require 'test.peg')
  :link_class(require 'test.json')
  :link_class(require 'test.struct.sorteddict')


Tests:run_if_main(...)


return Tests
