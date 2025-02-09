local record LruCache
   record lrucache<K, V, P>
      count: function(self: lrucache<K, V, P>): integer
      eviction: function(self: lrucache<K, V, P>)
      set: function(self: lrucache<K, V, P>, key: K, value: V, ttl?: number, privdata?: P)
      peek: function(self: lrucache<K, V, P>, key: K): V | nil, V | nil, P
      get: function(self: lrucache<K, V, P>, key: K): V | nil, V | nil, P
      has: function(self: lrucache<K, V, P>, key: K): boolean
      del: function(self: lrucache<K, V, P>, key: K)
   end

   new: function<K, V, P>(self: LruCache, maxsize: integer): lrucache<K, V, P>
end

return LruCache
