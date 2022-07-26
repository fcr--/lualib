local function class(super)
  local mt = setmetatable({}, super)
  mt.__index = mt

  if not mt.new then
    function mt:new(...)
      local obj = setmetatable({}, self)
      if obj._init then obj:_init(...) end
      return obj
    end
  end

  return mt
end


-- goes through the __index chain looking for mt, returning true if its found
local function isinstance(obj, mt)
  obj = getmetatable(obj)
  while type(obj) == 'table' do
    if obj == mt or obj.__index == mt then return true end
    obj = getmetatable(obj.__index)
  end
  return false
end


return {
  class = class,
  isinstance = isinstance,
}
