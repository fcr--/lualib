local function diff(xs, ys)
    -- Let LCS[i][j] be the length of the longest common subsequence for the first i lines of the first file and the first j lines of the second file. 
    local lcs_memo = {}
    local function lcs(i, j)
        local res
        local g = lcs_memo[i]
        if g then
            res = g[j]
            if res then return res end
        end

        if i < 1 or j < 1 then return 0 end
        if xs[i] == ys[j] then
            res = 1 + lcs(i-1, j-1)
        else
            res = math.max(lcs(i-1, j), lcs(i, j-1))
        end
        g = lcs_memo[i]
        if not g then
            g = {}
            lcs_memo[i] = g
        end
        g[j] = res
        return res
    end

    local function build_instructions()
        local instructions = {}
        local i, j = #xs, #ys
        while i >= 1 or j >= 1 do
            if xs[i] == ys[j] then
                instructions[#instructions+1] = {T='EQUALS', left_line=i, right_line=j}
                i = i - 1
                j = j - 1
            elseif lcs(i-1, j) >= lcs(i, j-1) and i >= 1 or j == 0 then
                instructions[#instructions+1] = {T='FROM_LEFT', left_line=i}
                i = i - 1
            else
                instructions[#instructions+1] = {T='FROM_RIGHT', right_line=j}
                j = j - 1
            end
        end
        return instructions
    end

    local function reversed(list)
        local ret, len = {}, #list
        for i = 1, len do
            ret[i] = list[len - i + 1]
        end
        return ret
    end

    lcs(#xs, #ys)

    return reversed(build_instructions())
end

local inverted_instructions_type = {
    FROM_LEFT='FROM_RIGHT', FROM_RIGHT='FROM_LEFT', EQUALS='EQUALS'
}
local function invert(instructions)
    local res = {}
    for i, ins in ipairs(instructions) do
        res[i] = {
            left_line = ins.right_line,
            right_line = ins.left_line,
            T = inverted_instructions_type[ins.T],
        }
    end
    return res
end

local function gen_simple_patch(xs, ys, instructions)
    local res, res_i = {}, 1
    local equals_count = 0
    for i, ins in ipairs(instructions) do
        if ins.T == 'EQUALS' then
            equals_count = equals_count + 1
        else
            if equals_count > 0 then
                res[res_i] = '=' .. equals_count
                res_i = res_i + 1
                equals_count = 0
            end
            if ins.T == 'FROM_LEFT' then
                res[res_i] = '-' .. xs[ins.left_line]
                res_i = res_i + 1
            else
                res[res_i] = '+' .. ys[ins.right_line]
                res_i = res_i + 1
            end
        end
    end
    return res
end

local function apply_simple_patch(xs, simple_patch)
    local ys, xs_i = {}, 1
    for i, line in ipairs(simple_patch) do
        local c, text = line:match '(.)(.*)'
        if c == '+' then
            ys[#ys+1] = text
        elseif c == '-' then
            assert(xs[xs_i] == text, 'patch failed when removing line')
            xs_i = xs_i + 1
        elseif c == '=' then
            local n = assert(tonumber(text), 'invalid number at "=" command')
            for j = 1, n do
                ys[#ys+1] = xs[xs_i]
                xs_i = xs_i + 1
            end
        else
            error 'wrong simple patch command'
        end
    end
    return ys
end

return {
    diff = diff,
    invert = invert,
    gen_simple_patch = gen_simple_patch,
    apply_simple_patch = apply_simple_patch,
}
-- vi: et sw=4
