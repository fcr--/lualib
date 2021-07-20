local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'


local Tests = oo.class(BaseTest)
  :link_class(require 'test.crypto.aes')
  :link_class(require 'test.crypto.rsa')
  :link_class(require 'test.crypto.sha1')


Tests:run_if_main()


return Tests
