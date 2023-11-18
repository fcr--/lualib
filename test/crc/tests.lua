local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'


local Tests = oo.class(BaseTest)
  :link_class(require 'test.crc.crc32')


Tests:run_if_main()


return Tests
