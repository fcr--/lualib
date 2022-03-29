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
   self:assert_equal(asn1.Null:new{}:encode(), '\5\0')
   self:assert_equal(asn1.Oid:new{}:encode '2.100.3', '\6\3\129\52\3')
   self:assert_equal(asn1.Oid:new{}:encode{1, 2, 840, 113549}, '\6\6\42\134\72\134\247\13')
end


Asn1Test:run_if_main()


return Asn1Test
