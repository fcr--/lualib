local oo = require 'lualib.oo'

local LruCache = oo.class()


function LruCache:_init(maxsize)
  assert(maxsize > 0)
  self.maxsize = maxsize
  self.keys = {}
  self._count = 0
end

function LruCache:count()
  return self._count
end

LruCache.__len = LruCache.count

function LruCache:eviction()
  while self._count > self.maxsize and self.oldest do
    self:del(self.oldest.key)
  end
end

function LruCache:set(key, value, ttl, privdata)
  if value == nil then return self:del(key) end

  local item = self.keys[key]
  if item then
    self:_refresh(item)
    item.value = value
  elseif self._count >= self.maxsize then
    -- steal the oldest item instead of evicting it and creating a new one:
    item = self.oldest
    self:_refresh(item)
    self.keys[item.key] = nil
    self.keys[key] = item

    item.key = key
    item.value = value
  else -- fresh new item:
    local oldnewest = self.newest
    item = {key=key, value=value, next=oldnewest}
    self.keys[key] = item
    if oldnewest then
      oldnewest.prev = item
    else
      self.oldest = item  -- it was empty, so the newest is also the oldest
    end
    self.newest = item
    self._count = self._count + 1
  end

  if ttl then item.expiration = os.time() + ttl end
  item.privdata = privdata
end

function LruCache:_refresh(item)
  if item == self.newest then return end
  -- We now know that
  --  * there are at least 2 elements (at least one newer than item),
  --  * item is not the newest one, and
  --  * item.prev is then not nil:
  item.prev.next = item.next
  if item.next then  -- item wasn't the last one:
    item.next.prev = item.prev
  else  -- item was the last one
    self.oldest = item.prev
  end
  item.prev = nil
  item.next = self.newest
  self.newest.prev = item
  self.newest = item
end

function LruCache:peek(key)
  local item = self.keys[key]
  if not item then return end

  local expiration = item.expiration
  if expiration and expiration < os.time() then
    self:del(key)
    return nil, item.value, item.privdata
  end

  return item.value, nil, item.privdata
end

function LruCache:get(key)
  local item = self.keys[key]
  if item then
    self:_refresh(item)
  end
  
  return self:peek(key)
end

function LruCache:has(key)
  return self.keys[key] ~= nil
end

function LruCache:del(key)
  local item = self.keys[key]
  if not item then return end
  
  self.keys[item.key] = nil
  if item.next then item.next.prev = item.prev end
  if item.prev then item.prev.next = item.next end
  if self.oldest == item then
    self.oldest = item.prev
  end
  if self.newest == item then
    self.newest = item.next
  end
  self._count = self._count - 1
end

return LruCache
