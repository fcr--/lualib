local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local asn1 = require 'lualib.asn1'
local bigint = require 'lualib.bigint'

local Asn1Test = oo.class(BaseTest)


function Asn1Test:test_encode()
   self:assert_equal(asn1.Boolean:new{}:encode(false), '\1\1\0')
   self:assert_equal(asn1.Boolean:new{}:encode(true), '\1\1\1')
   for num, encoded in pairs {[0]='\2\1\0', [127]='\2\1\127', [128]='\2\2\0\128', [256]='\2\2\1\0',
         [-128]='\2\1\128', [-129]='\2\2\255\127'} do
      self:assert_equal(asn1.Integer:new{}:encode(num), encoded)
      self:assert_equal(asn1.BigInteger:new{}:encode(bigint.new(num)), encoded)
   end
   self:assert_equal(asn1.OctetString:new{}:encode 'Hello, World!', '\4\13Hello, World!')
   self:assert_equal(asn1.Null:new{}:encode(), '\5\0')
   self:assert_equal(asn1.Oid:new{}:encode '2.100.3', '\6\3\129\52\3')
   self:assert_equal(asn1.Oid:new{}:encode{1, 2, 840, 113549}, '\6\6\42\134\72\134\247\13')
   local schema = asn1.Sequence:new {
      asn1.IA5String:new {name='name'},
      asn1.Boolean:new {name='ok'},
   }
   self:assert_equal(schema:encode{name='Smith', ok=true}, '\48\10\22\5Smith\1\1\1')
   self:assert_equal(asn1.PrintableString:new{}:encode 'Hello, World1 \'()+,-./:=?', '\19\25Hello, World1 \'()+,-./:=?')
end


Asn1Test:run_if_main()


return Asn1Test
