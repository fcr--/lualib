local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local asn1 = require 'lualib.asn1'
local bigint = require 'lualib.bigint'

local Asn1Test = oo.class(BaseTest)


function Asn1Test:test_encode()
   self:assert_equal(asn1.BitString:new{}:encode'Hello', '\3\6\0Hello')
   self:assert_equal(asn1.BitString:new{format='bits'}:encode'011011100101110111', '\3\4\6\110\93\192')
   self:assert_equal(asn1.OctetString:new{}:encode 'Hello, World!', '\4\13Hello, World!')
   self:assert_equal(asn1.Null:new{}:encode(), '\5\0')
   self:assert_equal(asn1.Oid:new{}:encode '2.100.3', '\6\3\129\52\3')
   self:assert_equal(asn1.Oid:new{}:encode{1, 2, 840, 113549}, '\6\6\42\134\72\134\247\13')
   local schema = asn1.Choice:new {
      asn1.Integer:new {name='num'},
      asn1.OctetString:new {name='str'},
      asn1.Null:new {name='null', null=asn1.Null},
   }
   self:assert_equal(schema:encode{num=4}, '\2\1\4')
   self:assert_equal(schema:encode{str='fran'}, '\4\4fran')
   self:assert_equal(schema:encode{null=asn1.Null}, '\5\0')
   self:assert_error(schema.encode, schema, {})
   self:assert_error(schema.encode, schema, {num=4, str='e'})
   schema = asn1.Sequence:new {
      asn1.IA5String:new {name='name'},
      asn1.Boolean:new {name='ok'},
   }
   self:assert_equal(asn1.Sequence:new{asn1.Integer:new{name='foo'}}:encode{255}, '\48\4\2\2\0\255')
   self:assert_equal(asn1.Sequence:new{asn1.Integer:new{default=123}}:encode{}, '\48\3\2\1\123')
   self:assert_equal(asn1.Sequence:new{asn1.Integer:new{optional=true}}:encode{}, '\48\0')
   self:assert_equal(asn1.Sequence:new{of=asn1.Integer:new{}}:encode{10, 20, 30}, '\48\9\2\1\10\2\1\20\2\1\30')
   self:assert_equal(schema:encode{name='Smith', ok=true}, '\48\10\22\5Smith\1\1\1')
   self:assert_equal(asn1.PrintableString:new{}:encode 'Hello, World1 \'()+,-./:=?', '\19\25Hello, World1 \'()+,-./:=?')
   self:assert_equal(asn1.UTCTime:new{}:encode(1649135335), '\23\013220405050855Z')
   self:assert_equal(asn1.UTCTime:new{}:encode(1649135340), '\23\013220405050900Z')
end


function Asn1Test:test_boolean()
   local b = asn1.Boolean:new{}
   self:assert_equal(b:encode(false), '\1\1\0')
   self:assert_equal(b:encode(true), '\1\1\1')
   self:assert_equal(b:decode '\1\1\0', false)
   self:assert_equal(b:decode '\1\1\1', true)
   self:assert_equal(b:decode '\1\1\42', true)
   self:assert_error(b.decode, b, '\1\0')
   self:assert_error(b.decode, b, '\1\2\0\0')
end


function Asn1Test:test_integer()
   local i = asn1.Integer:new{}
   self:assert_equal(i:encode(0), '\2\1\0')
   self:assert_equal(i:encode(1), '\2\1\1')
   self:assert_equal(i:encode(-1), '\2\1\255')
   for num, encoded in pairs {[0]='\2\1\0', [127]='\2\1\127', [128]='\2\2\0\128', [256]='\2\2\1\0',
         [-128]='\2\1\128', [-129]='\2\2\255\127', [-1009184543]='\2\4\195\217\16\225'} do
      self:assert_equal(i:encode(num), encoded)
      self:assert_equal(i:decode(encoded), num)
   end
end


function Asn1Test:test_big_integer()
   local b = asn1.BigInteger:new{}
   for num, encoded in pairs {[0]='\2\1\0', [127]='\2\1\127', [128]='\2\2\0\128', [256]='\2\2\1\0',
         [-128]='\2\1\128', [-129]='\2\2\255\127', [-1009184543]='\2\4\195\217\16\225'} do
      self:assert_equal(b:encode(bigint.new(num)), encoded)
   end
end


Asn1Test:run_if_main()


return Asn1Test
