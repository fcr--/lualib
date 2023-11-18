--[[
#Pure lua String Set Latice implementation.

The main characteristic of this implementation is that SSLattice nodes are
automatically reused to avoid wasting memory (otherwise it would be just a
trie), which simplifies the implementations of dynamic programming algorithms.

In fact calling tree an SSLattice is a mistake, since it really is a latice where
on top we have the referenced node and on bottom we have empty (the node
returned by this module), with the nice property that the sub-SSLattice with the
subset of words that match a given prefix will also be a latice (since we are
moving down through the latice one char at a time)

Keys on an SSLattice instance:
  a..z, '$', ...: pointer to the next node (parent node in the tree)
  hash: 32bit integer with the hash result.
]]

local SSLattice = {}
SSLattice.__index = SSLattice

local ok, bit
for _, package in ipairs{'bit', 'bit32'} do
  ok, bit = pcall(require, package)
  if ok then break end
end
assert(ok, 'bit library required')

local weakmt = {__mode = 'v'}
local cache = setmetatable({}, weakmt) -- :: table<int, set<SSLattice>>

local function unify(t)
  local cent = cache[t.hash]
  if cent then
    local tlen = 0
    for k in pairs(t) do
      if type(k)=='string' and #k==1 then tlen = tlen + 1 end
    end
    for ct in pairs(cent) do
      local ctlen = 0
      for k, subt in pairs(ct) do
        -- we only consider single char keys for equality:
        if type(k)=='string' and #k==1 then
          ctlen = ctlen + 1
          if subt ~= t[k] then ctlen = -1 break end
        end
      end
      if tlen == ctlen then return ct end
    end
    cent[t] = 1
  else
    cache[t.hash] = setmetatable({[t]=1}, weakmt)
  end
  -- to avoid random collection of the cent objects:
  t.cent = cache[t.hash]
  return t
end


-- the empty singleton must be created after __gc is set in the metatable.
SSLattice.empty = setmetatable({
  hash = bit.band(math.random()*2^31, -1)
}, SSLattice)

unify(SSLattice.empty)


function SSLattice:add(word)
  if word == '' then return self end
  local res = setmetatable({}, getmetatable(self))
  for k, v in pairs(self) do res[k] = v end
  local c, cb = word:sub(1,1), word:byte()
  local hash = self.hash
  if self[c] then
    hash = hash - self[c].hash * cb
    res[c] = self[c]:add(word:sub(2))
  else
    res[c] = self.empty:add(word:sub(2))
  end
  res.hash = bit.band(hash + res[c].hash * cb, -1)
  return unify(res)
end


function SSLattice:traverse(prefix, options)
  -- anychar=c: meta character in prefix that matches any character
  -- exact: the effect being true is the same as $ at prefix end on regexs
  -- partial: accept partial match, ie: on prefix FOOBAR, FOO is accepted
  -- final=c: only report strings that end with the c character
  local match
  options = options or {}
  if prefix == '' then
    match = function() return true end
  elseif not options.anychar or not prefix:find(options.anychar, 1, true) then
    match = function(pos, c)
      return prefix:sub(pos, pos) == c
    end
  else
    local anybyte = options.anychar:byte()
    match = function(pos, c)
      local b = prefix:byte(pos)
      return b == anybyte or b == c:byte()
    end
  end
  local function visit(node, k)
    if options.exact and #k > #prefix then return end
    if (#k >= #prefix or options.partial) and
        (not options.final or k:byte(#k) == options.final:byte()) then
      coroutine.yield(k)
    end
    for c, subnode in pairs(node) do
      if type(c)=='string' and #c==1 and (#k>=#prefix or match(#k+1, c)) then
        visit(subnode, k..c)
      end
    end
  end
  return coroutine.wrap(function()
    return visit(self, '')
  end)
end


function SSLattice:persist()
  -- the last directory is the root one, and since this is a tree there are
  -- cyclic references, meaning that when a dictionary is being defined its
  -- references shall have been already loaded.
  -- <TOTAL> := <DICT>*;
  -- <DICT> := <CHILD_REF_COUNT:byte> <CHILD_REF>*;
  -- <CHILD_REF> := <CHAR:byte> <DICT_INDEX:uint16_le>;
  local nextid = 0
  local dicts = {}
  local buffer = {}
  local function visit(t)
    if dicts[t] then return end
    local ccount = 0
    for k, subt in pairs(t) do
      if type(k)=='string' and #k==1 then
        visit(subt)
        ccount = ccount + 1
      end
    end
    dicts[t], nextid = nextid, nextid+1
    buffer[#buffer+1] = string.char(ccount)
    for k, subt in pairs(t) do
      if type(k)=='string' and #k==1 then
        buffer[#buffer+1] = k..string.char(dicts[subt] % 256, math.floor(dicts[subt]/256))
      end
    end
  end
  visit(self)
  return table.concat(buffer)
end


function SSLattice:load(bindata)
  local dicts, cursor = {}, 1
  while cursor <= #bindata do
    local ccount = bindata:byte(cursor)
    cursor = cursor + 1
    local t = setmetatable({}, getmetatable(self))
    t.hash = self.empty.hash
    for _ = 0, ccount - 1 do
      local cb, rl, rh = bindata:byte(cursor, cursor + 2)
      cursor = cursor + 3
      local subt = dicts[1 + rl + rh*256]
      t[string.char(cb)] = subt
      t.hash = bit.band(t.hash + subt.hash * cb, -1)
    end
    dicts[#dicts+1] = unify(t)
  end
  return dicts[#dicts]
end


function SSLattice.cache_stats()
  local trees, empty_entries, non_empty_entries = 0, 0, 0
  for _, cent in pairs(cache) do
    if next(cent) then
      non_empty_entries = non_empty_entries + 1
    else
      empty_entries = empty_entries + 1
    end
    for _ in pairs(cent) do trees = trees + 1 end
  end
  return {trees = trees,
    mean = trees / non_empty_entries,
    entries = empty_entries + non_empty_entries,
    empty_entries = empty_entries,
    non_empty_entries = non_empty_entries,}
end


function SSLattice:__tostring()
  local fifo = {}
  local in_refs = {} --::table<node, int>
  local out_refs = {} --::table<node, int>
  local kv_nodes = {} --::table<node, {k, v}>
  local count = 0
  local function visit(node)
    local n = 0
    for k, v in pairs(node) do if type(k)=='string' and #k==1 then
      n = n + 1
      kv_nodes[node] = {k, v}
      if in_refs[v] then
        in_refs[v] = in_refs[v] + 1
      else
        in_refs[v] = 1
        visit(v)
      end
    end end
    out_refs[node] = n
    fifo[count+1], count = node, count+1
  end
  visit(self)
  -- reverse the list of nodes:
  for i = 1, math.floor(count/2) do
    fifo[i], fifo[count-i+1] = fifo[count-i+1], fifo[i]
  end
  local node_idx = {}
  local idx = 1
  for i, node in ipairs(fifo) do
    if i==1 or in_refs[node]>1 or out_refs[node]~=1 then
      node_idx[node], idx = idx, idx+1
    end
  end
  local lines = {}
  for _, node in ipairs(fifo) do if node_idx[node] then
    local line = {#lines+1}
    for k, v in pairs(node) do if type(k)=='string' and #k==1 then
      local item = {k}
      while not node_idx[v] do
        k, v = kv_nodes[v][1], kv_nodes[v][2]
        item[#item+1] = k
      end
      item[#item+1] = '-'
      item[#item+1] = node_idx[v]
      line[#line+1] = table.concat(item)
    end end
    table.sort(line, function(x, y)
      local tx, ty = type(x), type(y)
      return tx<ty or tx==ty and x<y
    end)
    lines[#lines+1] = table.concat(line, ',')
  end end
  return table.concat(lines, '\n')
end


return SSLattice.empty
