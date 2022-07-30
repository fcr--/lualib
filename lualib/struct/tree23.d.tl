local record Tree23<K, V>
   metamethod __tostring: function(Tree23<K, V>): string

   getkv: function(Tree23<K, V>, K): K, V
   get: function(Tree23<K, V>, K): V
   has: function(Tree23<K, V>, K): boolean
   set: function(Tree23<K, V>, K, V): Tree23<K, V>, boolean
   min: function(Tree23<K, V>): K, V
   max: function(Tree23<K, V>): K, V
   del: function(Tree23<K, V>, K): Tree23<K, V>, V, boolean

   visit: function(Tree23<K, V>, visitor: function(K, V), from: K, to: K)
   keys: function(Tree23<K, V>, from: K, to: K): {K}
   values: function(Tree23<K, V>, from: K, to: K): {V}
   record KeyValue
      k: K
      v: V
   end
   -- KeyValue items are not shared with the SortedDict instance
   items: function(Tree23<K, V>, from: K, to: K): {KeyValue}
   pairs: function(Tree23<K, V>, from: K, to: K): (function(): K, V)
   totable: function(Tree23<K, V>, from: K, to: K): {K: V}
   setsorteditems: function(Tree23<K, V>, {KeyValue}, from: integer, to:integer): Tree23<K, V>
   settable: function(Tree23<K, V>, {K, V}): Tree23<K, V>
end

local empty = Tree23

return empty
