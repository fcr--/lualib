local record BigInt
  record bigint
    -- internal representation with the number broken into atoms
    -- where 0 <= atom < atombase, with least significant atom first:
    {integer}
    sign: integer

    metamethod __add: function(bigint, bigint): bigint
    metamethod __div: function(bigint, bigint): bigint
    metamethod __eq: function(bigint, bigint): boolean
    metamethod __le: function(bigint, bigint): boolean
    metamethod __lt: function(bigint, bigint): boolean
    metamethod __mod: function(bigint, bigint): bigint
    metamethod __mul: function(bigint, bigint): bigint
    metamethod __pow: function(bigint, integer): bigint
    metamethod __sub: function(bigint, bigint): bigint
    metamethod __tostring: function(bigint): string
    metamethod __unm: function(bigint): bigint

    -- returns the absolute value
    abs: function(bigint): bigint

    -- returns the same as: x:abs():cmp(y:abs())
    abscmp: function(x: bigint, y: bigint): integer

    -- bitwise 'and' of the two numbers:
    band: function(bigint, bigint): bigint

    -- bitwise 'or' of the two numbers:
    bor: function(bigint, bigint): bigint

    -- bitwise 'xor' of the two numbers:
    bxor: function(bigint, bigint): bigint

    -- returns -1, 0, 1 depending on whether x is <, == or > than y:
    cmp: function(x: bigint, y: bigint): integer

    -- gcd followed by bézout coefficients
    gcd: function(bigint, bigint): bigint, bigint, bigint
    
    -- returns true if the number is a multiple of 2
    iseven: function(bigint): boolean

    -- returns true if the number is not a multiple of 2
    isodd: function(bigint): boolean

    -- returns the number of bits needed to represent it
    lenbits: function(bigint): integer

    -- shifts offset bits to the left
    lshift: function(bigint, offset: integer): bigint

    -- fast equivalent alternative to (x^power%mod)
    powmod: function(x: bigint, power: bigint, mod: bigint): bigint

    -- arithmetic shift offset bits to the right
    rshift: function(bigint, offset: integer): bigint
  
    enum TostringFormat
      "hex"  -- base 16
      "dec"  -- base 10
      "raw"  -- 2's complement byte array
    end
    record TostringOptions
      zero: string  -- return value when the number is zero
      plus_sign: string  -- placed before the prefix for positive numbers
      minus_sign: string  -- placed after the prefix for negative numbers
      prefix: string  -- placed just before the number
    end
    tostring: function(bigint, TostringFormat, TostringOptions): string
  end

  atombase: integer  -- 2^atombits
  atombits: integer  -- 16 by default
  atommask: integer  -- atombase-1

  -- uses the chinese remainder theorem to return a bigint x: 0<=x<min{ns},
  -- such that: x % ns[i] == as[i] for all 1<=i<=#ns
  crt: function(ns: {bigint}, as: {bigint}): bigint

  mt: metatable<bigint>  -- the metatable used here

  -- constructs a new bigint:
  new: function(n: integer): bigint

  one: bigint
  zero: bigint
end

return BigInt
