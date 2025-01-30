local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'


local Tests = oo.class(BaseTest)
  :link_class(require 'test.asn1')
  :link_class(require 'test.base45')
  :link_class(require 'test.base64')
  :link_class(require 'test.basetest')
  :link_class(require 'test.bigint')
  :link_class(require 'test.crc.tests')
  :link_class(require 'test.crypto.tests')
  :link_class(require 'test.json')
  :link_class(require 'test.oo')
  :link_class(require 'test.peg')
  :link_class(require 'test.struct.lrucache')
  :link_class(require 'test.struct.sorteddict')
  :link_class(require 'test.struct.sslattice')
  :link_class(require 'test.struct.tree23')
  :link_class(require 'test.uuid')


Tests:run_if_main()


return Tests
