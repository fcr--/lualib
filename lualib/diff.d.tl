local record diff
    record instruction
        enum instruction_type
            "FROM_LEFT"
            "FROM_RIGHT"
            "EQUALS"
        end

        T: instruction_type
        left_line: integer
        right_line: integer
    end

    type patch = {instruction}

    diff: function(xs: {string}, ys: {string}): patch
    invert: function(instructions: patch): patch
    gen_simple_patch: function(xs: {string}, ys: {string}, instructions: patch): {string}
    apply_simple_patch: function(xs: {string}, simple_patch: {string}): {string}
end

return diff
