--[[
The "2-3 tree" implementation provided in this module has the characteristic
of being a persistent (immutable) data structure.
]]

local oo = require 'lualib.oo'

local Tree23 = oo.class()
local EmptyTree = oo.class(Tree23)
local TwoTree = oo.class(Tree23)
local ThreeTree = oo.class(Tree23)

local empty = EmptyTree:new()
empty.height = 0

-- If true, it can make deletions slightly faster at O(log n) vs O((log n)²)
-- since we reuse maxk; however these extra attributes consume some memory.
local VALIDATE = true

function TwoTree:_init(ak, av, p, q)
   p = p or empty
   q = q or empty
   self.ak = ak
   self.av = av
   self.p = p
   self.q = q
   if VALIDATE then
      assert(p.height == q.height)
      assert(p.maxk == nil or ak > p.maxk)
      assert(q.mink == nil or ak < q.mink)
      if p.mink ~= nil then self.mink = p.mink else self.mink = ak end
      if p.maxk ~= nil then self.maxk = q.maxk else self.maxk = ak end
      self.height = p.height + 1
   end
end

function ThreeTree:_init(ak, av, bk, bv, p, q, r)
   p = p or empty
   q = q or empty
   r = r or empty
   self.ak = ak
   self.av = av
   self.bk = bk
   self.bv = bv
   self.p = p
   self.q = q
   self.r = r
   if VALIDATE then
      assert(p.height == q.height and q.height == r.height)
      assert(ak < bk)
      assert(p.maxk == nil or ak > p.maxk)
      assert(q.maxk == nil or ak < q.maxk)
      assert(q.mink == nil or bk > q.mink)
      assert(r.mink == nil or bk < r.mink)
      if p.mink ~= nil then self.mink = p.mink else self.mink = ak end
      if r.maxk ~= nil then self.maxk = r.maxk else self.maxk = bk end
      self.height = p.height + 1
   end
end

function EmptyTree:getkv(_key) end

function TwoTree:getkv(key)
   local ak = self.ak
   if key <= ak then
      if key == ak then return ak, self.av end
      return self.p:getkv(key)
   else
      return self.q:getkv(key)
   end
end

function ThreeTree:getkv(key)
   local ak, bk = self.ak, self.bk
   if key <= ak then
      if key == ak then return ak, self.av end
      return self.p:getkv(key)
   elseif key <= bk then
      if key == bk then return bk, self.bv end
      return self.q:getkv(key)
   else
      return self.r:getkv(key)
   end
end


function Tree23:get(key)
   return select(2, self:getkv(key))
end


function Tree23:has(key)
   return self:getkv(key) ~= nil
end


function EmptyTree:min() end

function TwoTree:min()
   if rawequal(self.p, empty) then
      return self.ak, self.av
   end
   return self.p:min()
end

ThreeTree.min = TwoTree.min


function EmptyTree:max() end

function TwoTree:max()
   if rawequal(self.q, empty) then
      return self.ak, self.av
   end
   return self.q:max()
end

function ThreeTree:max()
   if rawequal(self.r, empty) then
      return self.bk, self.bv
   end
   return self.r:max()
end


function EmptyTree:set(key, value)
   assert(key ~= nil, 'Trying to insert nil key')
   return TwoTree:new(key, value, empty, empty), true
end

function TwoTree:set(key, value)
   assert(key ~= nil, 'Trying to insert nil key')
   local p, q, ak, av, incr = self.p, self.q, self.ak, self.av
   if key <= ak then
      if key == ak then return TwoTree:new(key, value, p, q), false end
      p, incr = p:set(key, value)
      if incr then
         return ThreeTree:new(p.ak, p.av, ak, av, p.p, p.q, q), false
      end
   else
      q, incr = q:set(key, value)
      if incr then
         return ThreeTree:new(ak, av, q.ak, q.av, p, q.p, q.q), false
      end
   end
   return TwoTree:new(ak, av, p, q), false
end

function ThreeTree:set(key, value)
   assert(key ~= nil, 'Trying to insert nil key')
   local p, q, r, ak, av, bk, bv, incr = self.p, self.q, self.r, self.ak, self.av, self.bk, self.bv
   if key <= ak then
      if key == ak then return ThreeTree:new(key, value, bk, bv, p, q, r), false end
      p, incr = p:set(key, value)
      if incr then
         return TwoTree:new(ak, av, p, TwoTree:new(bk, bv, q, r)), true
      end
   elseif key <= bk then
      if key == bk then return ThreeTree:new(ak, av, key, value, p, q, r), false end
      q, incr = q:set(key, value)
      if incr then
         local newp, newq = TwoTree:new(ak, av, p, q.p), TwoTree:new(bk, bv, q.q, r)
         return TwoTree:new(q.ak, q.av, newp, newq), true
      end
   else
      r, incr = r:set(key, value)
      if incr then
         return TwoTree:new(bk, bv, TwoTree:new(ak, av, p, q), r), true
      end
   end
   return ThreeTree:new(ak, av, bk, bv, p, q, r), false
end


function EmptyTree:del()
   return empty, nil, false
end

function TwoTree:del(key)
   local p, q, ak, av = self.p, self.q, self.ak, self.av
   if rawequal(self.p, empty) then
      if key == ak then return empty, av, true end
      return self, nil, false
   end
   local val, decr
   if key <= ak then
      if key == ak then
         local maxk = p.maxk or p:max()
         p, val, decr = p:del(maxk)
         ak, av, val = maxk, val, av
      else
         p, val, decr = p:del(key)
      end
      if decr then
         if oo.isinstance(q, TwoTree) then
            --     X            ()
            --  ()    Y   =>    XY
            --  l    m r       l m r
            return ThreeTree:new(ak, av, q.ak, q.av, p, q.p, q.q), val, true
         end
         --     X                 Y
         --  ()    YZ    =>    X     Z
         --  a    b c d       a b   c d
         local newp = TwoTree:new(ak, av, p, q.p)
         local newq = TwoTree:new(q.bk, q.bv, q.q, q.r)
         return TwoTree:new(q.ak, q.av, newp, newq), val, false
      end
   else
      q, val, decr = q:del(key)
      if decr then
         if oo.isinstance(p, TwoTree) then
            --     X             ()
            --   Y    ()   =>    XY
            --  l m    r        l m r
            return ThreeTree:new(p.ak, p.av, ak, av, p.p, p.q, q), val, true
         end
         --      Z                  Y
         --   XY    ()    =>     X     Z
         -- a b c    d          a b   c d
         local newp = TwoTree:new(p.ak, p.av, p.p, p.q)
         local newq = TwoTree:new(ak, av, p.r, q)
         return TwoTree:new(p.bk, p.bv, newp, newq), val, false
      end
   end
   return TwoTree:new(ak, av, p, q), val, false
end

function ThreeTree:del(key)
   local ak, av, bk, bv = self.ak, self.av, self.bk, self.bv
   local p = self.p
   if rawequal(p, empty) then
      if key == ak then return TwoTree:new(bk, bv), av, false end
      if key == bk then return TwoTree:new(ak, av), bv, false end
      return self, nil, false
   end
   local q, r, val, decr = self.q, self.r
   if key <= ak then
      if key == ak then
         local maxk = p.maxk or p:max()
         p, val, decr = p:del(maxk)
         ak, av, val = maxk, val, av
      else
         p, val, decr = p:del(key)
      end
      if decr then
         if oo.isinstance(q, TwoTree) then
            --      XZ                 Z
            --  ()   Y   d   =>    XY     d
            --  a   b c           a b c
            local newp = ThreeTree:new(ak, av, q.ak, q.av, p, q.p, q.q)
            return TwoTree:new(bk, bv, newp, r), val, false
         end
         --      WZ                  XZ
         -- ()   XY    e   =>    W    Y   e
         -- a   b c d           a b  c d
         local newp = TwoTree:new(ak, av, p, q.p)
         local newq = TwoTree:new(q.bk, q.bv, q.q, q.r)
         return ThreeTree:new(q.ak, q.av, bk, bv, newp, newq, r), val, false
      end
   elseif key <= bk then
      if key == bk then
         local maxk = q.maxk or q:max()
         q, val, decr = q:del(maxk)
         bk, bv, val = maxk, val, bv
      else
         q, val, decr = q:del(key)
      end
      if decr then
         -- Here we took the arbitrary decision to rebalance to the right.
         if oo.isinstance(r, TwoTree) then
            --      XY             X
            --  a   ()   Z  =>  a    YZ
            --      b   c d         b c d
            local newq = ThreeTree:new(bk, bv, r.ak, r.av, q, r.p, r.q)
            return TwoTree:new(ak, av, p, newq), val, false
         end
         --     WX                  WY
         -- a   ()   YZ    =>   a   X    Z
         --     b   c d e          b c  d e
         local newq = TwoTree:new(bk, bv, q, r.p)
         local newr = TwoTree:new(r.bk, r.bv, r.q, r.r)
         return ThreeTree:new(ak, av, r.ak, r.av, p, newq, newr), val, false
      end
   else
      r, val, decr = r:del(key)
      if decr then
         if oo.isinstance(q, TwoTree) then
            --     XZ             X
            --  a   Y  ()  =>  a    YZ
            --     b c  d          b c d
            local newq = ThreeTree:new(q.ak, q.av, bk, bv, q.p, q.q, r)
            return TwoTree:new(ak, av, p, newq), val, false
         end
         --      WZ                  WY
         -- a    XY   ()    =>   a   X    Z
         --    b c d   e            b c  d e
         local newq = TwoTree:new(q.ak, q.av, q.p, q.q)
         local newr = TwoTree:new(bk, bv, q.r, r)
         return ThreeTree:new(ak, av, q.bk, q.bv, p, newq, newr), val, false
      end
   end
   return ThreeTree:new(ak, av, bk, bv, p, q, r), val, false
end


function EmptyTree:visit(_callback, _from, _to) end

function TwoTree:visit(callback, from, to)
   local ak = self.ak
   if from == nil or from < self.ak then
      self.p:visit(callback, from, to)
   end
   if (from == nil or from <= ak) and (to == nil or ak <= to) then
      callback(ak, self.av)
   end
   if to == nil or ak < to then
      return self.q:visit(callback, from, to)
   end
end

function ThreeTree:visit(callback, from, to)
   local ak, bk = self.ak, self.bk
   if from == nil or from < self.ak then
      self.p:visit(callback, from, to)
   end
   if (from == nil or from <= ak) and (to == nil or ak <= to) then
      callback(ak, self.av)
   end
   if (from == nil or from < bk) and (to == nil or ak < to) then
      self.q:visit(callback, from, to)
   end
   if (from == nil or from <= bk) and (to == nil or bk <= to) then
      callback(bk, self.bv)
   end
   if to == nil or bk < to then
      return self.r:visit(callback, from, to)
   end
end


function Tree23:keys(from, to)
   local res = {}
   self:visit(function(key) res[#res+1] = key end, from, to)
   return res
end


function Tree23:values(from, to)
   local res = {}
   self:visit(function(_k, value) res[#res+1] = value end, from, to)
   return res
end


function Tree23:items(from, to)
   local res = {}
   self:visit(function(k, v) res[#res+1] = {k=k, v=v} end, from, to)
   return res
end


function Tree23:pairs(from, to)
   -- iterates in-order the specified range (defaulting to start, finish if nil) of the tree,
   -- yielding (k, v) at each step
   return coroutine.wrap(function()
      self:visit(coroutine.yield, from, to)
   end)
end


function Tree23:totable(from, to)
   local res = {}
   self:visit(function(k, v) res[k] = v end, from, to)
   return res
end


function Tree23:setsorteditems(items, from, to)
   local prevk
   for i = from or 1, to or #items do
      local k = items[i].k
      assert(prevk == nil or k > prevk)
      prevk = k
      self = self:set(k, items[i].v)
   end
   return self
end

function EmptyTree:setsorteditems(items, from, to)
   -- Example valid trees:
   -- 1   12    2     3     3      24         26        4
   --          1 3  12 4  12 45  1 3 5  .. 12 45 78   2   6
   --                                                1 3 5 7
   -- (h=1) 1..2, (h=2) 3..8, (h=3) 7..26, ..., h^2-1..h^3-1
   -- Goals:
   --    Try to make the tree as shallow as possible.
   --    Greedly (if possible) try to use 3-Trees from the root.
   -- Valid ranges for 2-Trees and 3-Trees:
   --    h=1:  1..1,   2..2
   --    h=2:  3..5,   5..8
   --    h=3:  7..17, 11..26
   --    h=4: 15..53, 23..80
   local function rec(h, f, t)
      local len = t-f+1
      if h==0 then
         assert(len == 0)
         return empty
      elseif len >= 3*2^(h-1) - 1 then
         local i = f + math.floor((len-2)/3)
         local j = f + math.floor((len-2)*2/3) + 1
         local p = rec(h-1, f, i-1)
         local q = rec(h-1, i+1, j-1)
         local r = rec(h-1, j+1, t)
         return ThreeTree:new(items[i].k, items[i].v, items[j].k, items[j].v, p, q, r)
      else
         local i = f + math.floor((len-1)/2)
         local p = rec(h-1, f, i-1)
         local q = rec(h-1, i+1, t)
         return TwoTree:new(items[i].k, items[i].v, p, q)
      end
   end
   from = from or 1
   to = to or #items
   local len = to - from + 1
   local prevk = items[from].k
   for i = from + 1, to do
      local k = items[i].k
      assert(k > prevk)
      prevk = k
   end
   local h = 1 + math.floor(math.log(len+.5) / math.log(3))
   return rec(h, from, to)
end


function Tree23:settable(t)
   local items = {}
   for k, v in pairs(t) do
      items[#items+1] = {k=k, v=v}
   end
   table.sort(items, function(x, y) return x.k < y.k end)
   return self:setsorteditems(items)
end


function EmptyTree:__tostring()
   return '{}'
end

function TwoTree:__tostring()
   return ('{%s, %s=%s, %s}'):format(self.p, self.ak, self.av, self.q)
end

function ThreeTree:__tostring()
   return ('{%s, %s=%s, %s, %s=%s, %s}'):format(
      self.p, self.ak, self.av, self.q, self.bk, self.bv, self.r
   )
end


return empty
