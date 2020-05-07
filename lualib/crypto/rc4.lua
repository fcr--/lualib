local oo = require 'lualib.oo'


local Rc4 = oo.class()


function Rc4:_init(opts)
    -- opts table with the following fields:
    --   key: string
    local key = opts.key
    local state = {}
    for i = 0, 255 do
        state[i] = i
    end
    local j = 0
    for i = 0, 255 do
        j = (j + state[i] + key:byte(i % #key + 1)) % 256
        state[i], state[j] = state[j], state[i]
    end
    self.state = state
    self.i = 0
    self.j = 0
end


local bxor
do
    local ok, bitop
    for _, package in ipairs{'bit', 'bit32'} do
        ok, bitop = pcall(require, package)
        if ok then bxor = bitop.bxor break end
    end
    if not ok then
        bxor = function(x, y)
            -- slow 8-bit fallback function
            local res = 0
            for i = 1, 8 do
                res = res*2 + ((x>127)==(y>127) and 0 or 1)
                x, y = x*2%256, y*2%256
            end
            return res
        end
    end
end


function Rc4:encrypt(text)
    local bytes = self:bytes(#text)
    for i = 1, #text do
        bytes[i] = bxor(text:byte(i), bytes[i])
    end
    local u = unpack or table.unpack
    if #text <= 1024 then
        return string.char(u(bytes))
    end
    local res = {}
    for base = 1, #text, 1000 do
        res[#res+1] = string.char(u(bytes, base, math.min(base+999, #text)))
    end
    return table.concat(res, '')
end


function Rc4:bytes(n, res)
    -- returns the stream cipher output in a list of n integers in the 0..255 range
    -- if res is passed as a parameter, then it'll be assigned to it as well
    local state, i, j = self.state, self.i, self.j
    res = res or {}
    for idx = 1, n do
        i = (i + 1) % 256
        j = (j + state[i]) % 256
        local si, sj = state[i], state[j]
        state[i], state[j] = sj, si
        res[idx] = state[(si + sj) % 256]
    end
    self.i, self.j = i, j
    return res
end

return Rc4
