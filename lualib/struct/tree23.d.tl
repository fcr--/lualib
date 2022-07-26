local record Tree23<K, V>
   getkv: function(Tree23<K, V>, K): K, V
   get: function(Tree23<K, V>, K): V
   has: function(Tree23<K, V>, K): boolean
   set: function(Tree23<K, V>, K, V): Tree23<K, V>, boolean
   min: function(Tree23<K, V>): K, V
   max: function(Tree23<K, V>): K, V
   -- TODO: del: function(Tree23<K, V>, K): V

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
end

local empty = Tree23

return empty
