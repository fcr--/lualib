--[[
#AA-tree based implementation of a sorted dict.

where a node can be nil or a table with:
  `[1]`: left child
  `[2]`: right child
  `k`: key for the association
  `v`: associated value
  `kk`: the result of calling dict_instance.key with the k.
  `level`: small integer used to detect unbalanced trees (1+distance to smallest subnode+...(other details))

* More info in [its wikipedia page](https://en.wikipedia.org/wiki/AA_tree).
]]

local oo = require 'lualib.oo'

local SortedDict = oo.class()


function SortedDict:_init(opts)
  -- **opts.key**: if provided the output of this function will be used for comparison,
  --   it's called with the k of each association.  If you need a custom sort order then
  --   you may return tables with a common metatable containing `__le` and `__eq` metamethods.
  self.key = opts and opts.key or function(k) return k end
  self.root = nil
end


local function getnode(t, kk)
  -- returns the tree node if the key is found in the dict, nil otherwise
  while t ~= nil do
    if t.kk == kk then return t end
    t = (kk < t.kk) and t[1] or t[2]
  end
end


function SortedDict:get(k)
  -- return the associated value if k is in this dict, nil otherwise
  local node = getnode(self.root, self.key(k))
  return node and node.v
end


function SortedDict:has(k)
  return not not getnode(self.root, self.key(k))
end


function SortedDict:min()
  -- return min key with its value
  local t = self.root
  if not t then return end
  while t[1] do t = t[1] end
  return t.k, t.v
end


function SortedDict:max()
  -- return max key with its value
  local t = self.root
  if not t then return end
  while t[2] do t = t[2] end
  return t.k, t.v
end


local function skew(t)
  if not t then return end
  local left = t[1]
  if left and left.level == t.level then
    t[1], left[2] = left[2], t
    return left
  end
  return t
end


local function split(t)
  if not t then return end
  local right = t[2]
  if not right or not right[2] or t.level ~= right[2].level then
    return t
  end
  t[2], right[1] = right[1], t
  right.level = right.level + 1
  return right
end


local function successor(t)
  -- return node with smallest kk bigger than the root's or nil if it doesn't exist
  if not t or not t[2] then return end
  t = t[2] -- once to the right
  while t[1] do t = t[1] end -- all to the left
  return t
end


local function predecessor(t)
  -- return node with biggest kk smaller than the root's or nil if it doesn't exist
  if not t or not t[1] then return end
  t = t[1] -- once to the left
  while t[2] do t = t[2] end -- all to the right
  return t
end


local function decrease_level(t)
  local correct = math.min(t[1] and t[1].level or math.huge, t[2] and t[2].level or math.huge) + 1
  if correct < t.level then
    t.level = correct
    if t[2] and correct < t[2].level then
      t[2].level = correct
    end
  end
  return t
end


function SortedDict:del(k)
  -- returns the deleted value or nil if it wasn't found
  local function del(kk, t)
    local deleted
    if not t then
      return
    elseif kk < t.kk then
      t[1], deleted = del(kk, t[1])
    elseif kk > t.kk then
      t[2], deleted = del(kk, t[2])
    elseif not t[1] and not t[2] then
      return nil, t.v-- leaf case
    elseif not t[1] then
      deleted = t.v
      local sub = successor(t)
      -- we copy everything but the level and children
      t.kk, t.k, t.v = sub.kk, sub.k, sub.v
      t[2] = del(t.kk, t[2])
    else
      deleted = t.v
      local sub = predecessor(t)
      -- we copy everything but the level and children
      t.kk, t.k, t.v = sub.kk, sub.k, sub.v
      t[1] = del(t.kk, t[1])
    end
    t = skew(decrease_level(t))
    local right = skew(t[2])
    t[2] = right
    if right then right[2] = skew(right[2]) end
    t = split(t)
    t[2] = split(t[2])
    return t, deleted
  end
  do
    local oldvalue
    self.root, oldvalue = del(self.key(k), self.root)
    return oldvalue
  end
end


function SortedDict:set(k, v)
  -- sets the given association returning the old value if present
  local kk = self.key(k)
  local found, oldvalue
  local function insert(t)
    if not t then return {kk=kk, k=k, v=v, level=1} end
    if kk == t.kk then
      found, oldvalue, t.v = true, t.v, v
      return t
    end

    if kk < t.kk then
      t[1] = insert(t[1])
    else
      t[2] = insert(t[2])
    end
    return found and t or split(skew(t))
  end
  self.root = insert(self.root)
  return oldvalue
end


local function visit_range(t, callback, kkf, kkt)
  if not t then return end
  if kkf == nil or kkf < t.kk then
    visit_range(t[1], callback, kkf, kkt)
  end
  if (kkf == nil or kkf <= t.kk) and (kkt == nil or t.kk <= kkt) then
    callback(t)
  end
  if kkt == nil or t.kk < kkt then
    visit_range(t[2], callback, kkf, kkt)
  end
end


function SortedDict:keys(from, to)
  local res = {}
  visit_range(self.root, function(t)
    res[#res+1] = t.k
  end, from and self.key(from) or nil, to and self.key(to) or nil)
  return res
end


function SortedDict:values(from, to)
  local res = {}
  visit_range(self.root, function(t)
    res[#res+1] = t.v
  end, from and self.key(from) or nil, to and self.key(to) or nil)
  return res
end


function SortedDict:items(from, to)
  local res = {}
  visit_range(self.root, function(t)
    res[#res+1] = {k=t.k, v=t.v}
  end, from and self.key(from) or nil, to and self.key(to) or nil)
  return res
end


function SortedDict:pairs(from, to)
  -- iterates in-order the specified range (defaulting to start, finish if nil) of the dict, yielding (k, v) at each step
  return coroutine.wrap(function()
    visit_range(self.root, function(t)
      coroutine.yield(t.k, t.v)
    end, from and self.key(from) or nil, to and self.key(to) or nil)
  end)
end


function SortedDict:clone()
  local function clone(t)
    if not t then return end
    return {clone(t[1]), clone(t[2]), k=t.k, kk=t.kk, v=t.v, level=t.level}
  end
  return {key=self.key, root=clone(self.root)}
end


return SortedDict
