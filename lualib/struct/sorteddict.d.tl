local record SortedDict<K, V>
   record Options
      -- Override this option to have a custom sort order, as each of the the
      -- keys in this dict will be mapped with this function and their results
      -- will be compared instead:
      key: function(K): any
   end
   -- eg: local sd = require 'lualib.struct.sorteddict':new()
   new: function(SortedDict<K, V>, Options): SortedDict

   -- instance methods:
   get: function(SortedDict<K, V>, K): V
   has: function(SortedDict<K, V>, K): boolean
   min: function(SortedDict<K, V>): K, V
   max: function(SortedDict<K, V>): K, V
   del: function(SortedDict<K, V>, K): V  -- returs old value
   set: function(SortedDict<K, V>, K, V): V  -- returs old value

   visit: function(SortedDict<K, V>, visitor: function(K, V), from: K, to: K)
   keys: function(SortedDict<K, V>, from: K, to: K): {K}
   values: function(SortedDict<K, V>, from: K, to: K): {V}
   record KeyValue
      k: K
      v: V
   end
   -- KeyValue items are not shared with the SortedDict instance
   items: function(SortedDict<K, V>, from: K, to: K): {KeyValue}
   pairs: function(SortedDict<K, V>, from: K, to: K): (function(): K, V)

   clone: function(SortedDict<K, V>): SortedDict<K, V>
end

return SortedDict
