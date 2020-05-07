local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local json = require 'lualib.json'


local JsonTest = oo.class(BaseTest)


function JsonTest:test_number()
  self:assert_equal('42', json.encode(42))
  self:assert_equal('4.2', json.encode(4.2))
  self:assert_equal('-1', json.encode(-1))
  self:assert_equal('-1.42e-37', json.encode(-1.42e-37))

  self:assert_equal(false, (pcall(json.encode, 1/0)))
  self:assert_equal(false, (pcall(json.encode, -1/0)))
  self:assert_equal(false, (pcall(json.encode, 0/0)))

  self:assert_equal('inf', json.encode(1/0, {allow_invalid_numbers=true}))
  self:assert_equal('-inf', json.encode(-1/0, {allow_invalid_numbers=true}))
  self:assert_equal('nan', json.encode(0/0, {allow_invalid_numbers=true}))
end


function JsonTest:test_boolean_and_nil()
  self:assert_equal('true', json.encode(true))
  self:assert_equal('false', json.encode(false))
  self:assert_equal('null', json.encode(nil))
  self:assert_equal('null', json.encode(json.Nil))
end


function JsonTest:test_strings()
  self:assert_equal('""', json.encode '')
  self:assert_equal('"ascii"', json.encode 'ascii')
  self:assert_equal('"\\"quotes\\" and \\\\s"', json.encode '"quotes" and \\s')
  self:assert_equal('"\\t\\n\\u001b"', json.encode '\t\n\27')
  self:assert_equal('"\\u00f1"', json.encode 'ñ')
  self:assert_equal('"\\u30c6\\u30b9\\u30c8!"', json.encode 'テスト!')
  self:assert_equal('"\\ud800\\udf48"', json.encode '\240\144\141\136') -- hwair
  
  self:assert_equal('"-\\ufffd-\\ufffd-"', json.encode '-\128-\248-') -- invalid first bytes
  self:assert_equal('"-\\ufffd-"', json.encode '-\192\128-') --mutf-8 is forbidden
end


function JsonTest:test_array()
  self:assert_equal('[42,"e"]', json.encode{42, 'e'})
  local function a(t) return setmetatable(t, json.Array) end
  self:assert_equal('[]', json.encode(a{}))
  self:assert_equal('[[],[[]],[[[]]]]', json.encode{a{}, {a{}}, {{a{}}}})
  local t = {'infinite', {'loop'}}
  t[2][2] = t
  self:assert_equal(false, (pcall(json.encode, t)))
  self:assert_equal(false, (pcall(json.encode, {42, string_key='error'})))
  self:assert_equal(false, (pcall(json.encode, {1, nil, 3})))
  self:assert_equal('[1,null,3]', json.encode{1, json.Nil, 3})
end


function JsonTest:test_object()
  self:assert_equal('{}', json.encode{})
  self:assert_equal('{"a":"b","c":42}', json.encode{a='b', c=42})
  self:assert_equal('{"a":[2,"b",{"c":3}],"d":{"e":{}}}', json.encode{a={2,'b',{c=3}}, d={e={}}})

  local t = {infinite={}}
  t.infinite.loop = t
  self:assert_equal(false, (pcall(json.encode, t)))
  self:assert_equal(false, (pcall(json.encode, {a=1,[42]=3})))
end


function JsonTest:test_parse()
  local function a(t) return setmetatable(t, json.Array) end
  local function o(t) return setmetatable(t, json.Object) end
  self:assert_equal(-42.25, json.parse '-42.25')
  self:assert_equal(true, json.parse 'true')
  self:assert_equal(false, json.parse 'false')
  self:assert_equal('x', json.parse '"x"')
  self:assert_equal('a\bb\fc\nd\re\tf"g\\h/i', json.parse '"a\bb\fc\nd\re\tf\\"g\\\\h\\/i"')
  self:assert_equal(
    '\240\144\141\136テスト!ñ', -- hwair + test! + ñ
    json.parse '"\\ud800\\udf48\\u30c6\\u30b9\\u30c8\\u0021\\u00f1"')
  self:assert_equal(json.Nil, json.parse 'null')
  self:assert_deep_equal(a{}, json.parse '[]')
  self:assert_deep_equal(o{}, json.parse '{}')
  self:assert_deep_equal(a{3}, json.parse '[3]')
  self:assert_deep_equal(a{1,a{2},a{3,4}}, json.parse '[1,[2],[3,4]]')
  self:assert_deep_equal(o{a=42}, json.parse '{"a":42}')
  self:assert_deep_equal(o{a=a{42,'x'}}, json.parse '{"a":[42,"x"]}')
  self:assert_deep_equal(o{e=3, f=a{'x',true}}, json.parse ' { "e" : 3, "f": [ "x" , true ] } ')
  for _, text in ipairs{
    '', 'true,42', '[][]', '["":3]', '{{}', '{}}', '[[]', '[]]',
    '[}', '{]', '{true:32}', '{"a":}', '{"a",2}', '{"a"}', '{"a":}',
    '[', '[3', '[4,', '{', '{"a"', '{"a":', '}', ']', '5]', '1,', ',4',
    '[4,]', '{"a":4,}', 'true false', '"a', '"\\ud800"', '"\\udf48"',
    '"\\udf48\\ud800"'
  } do
    self:assert_equal(false, (pcall(json.parse, text)))
  end
end


return JsonTest
