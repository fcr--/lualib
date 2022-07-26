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

function TwoTree:_init(ak, av, p, q)
   self.ak = ak
   self.av = av
   self.p = p or empty
   self.q = q or empty
end

function ThreeTree:_init(ak, av, bk, bv, p, q, r)
   self.ak = ak
   self.av = av
   self.bk = bk
   self.bv = bv
   self.p = p or empty
   self.q = q or empty
   self.r = r or empty
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
         -- since incr is true we know q is a new object, so we can mutate it safely:
         q.p, q.q = newp, newq
         return q, true
      end
   else
      r, incr = r:set(key, value)
      if incr then
         return TwoTree:new(bk, bv, TwoTree:new(ak, av, p, q), r), true
      end
   end
   return ThreeTree:new(ak, av, bk, bv, p, q, r), false
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


return empty
