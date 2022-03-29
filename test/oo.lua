local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'


local OoTest = oo.class(BaseTest)


function OoTest:test_basic_sanity()
  local cls = oo.class()
  self:assert_type(cls, 'table')
  self:assert_type(cls.new, 'function')

  local instance = cls:new()
  self:assert_type(instance, 'table')
  self:assert_equal(getmetatable(instance), cls)
  
  self:assert_type(instance.x, 'nil')
  cls.x = 42
  self:assert_equal(instance.x, 42)
  instance.x = 43
  self:assert_equal(cls.x, 42)
  self:assert_equal(instance.x, 43)
end


function OoTest:test_constructor()
  local cls = oo.class()
  local constructor_called_with = nil
  function cls:_init(arg1, arg2)
    constructor_called_with = {self, arg1, arg2}
  end
  local instance = cls:new(42, 'e')
  instance.x = 'value'
  self:assert_deep_equal({instance, 42, 'e'}, constructor_called_with)
end


function OoTest:test_inheritance()
  local parent = oo.class()
  function parent:method(x)
    return x+10
  end
  local child = oo.class(parent)
  self:assert_equal(child:new():method(7), 17)

  function child:method(x)
    return parent.method(self, x) + 100
  end
  self:assert_equal(child:new():method(7), 117)
end


OoTest:run_if_main()


return OoTest
