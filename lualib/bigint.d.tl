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

    -- hamming weight of the number:
    bcount: function(bigint): integer

    -- basic school multiplication implementation
    bmul: function(bigint, bigint): bigint

    -- bitwise 'or' of the two numbers:
    bor: function(bigint, bigint): bigint

    -- bitwise 'xor' of the two numbers:
    bxor: function(bigint, bigint): bigint

    -- returns -1, 0, 1 depending on whether x is <, == or > than y:
    cmp: function(x: bigint, y: bigint): integer

    -- returns a copy of the number (that can be mutated safely)
    copy: function(bigint): bigint

    -- Division functions: the difference between divmod and divqr is the sign
    -- of the second return value (modulus or remainder).
    -- * In divqr the remainder has the sign of the dividend or 0,
    --   and the quotiend is truncated.
    -- * In divmod the remainder has the sign of the divisor or 0,
    --   and the quotient is rounded down.
    --   This is the behavior of: math.floor(x/y), x%y
    divmod: function(bigint, bigint): bigint, bigint
    divmod_atom: function(bigint, integer): bigint, integer
    divqr: function(bigint, bigint): bigint, bigint

    -- decompose into a list of prime integers
    factor: function(bigint): {bigint}

    -- gcd followed by bézout coefficients
    gcd: function(bigint, bigint): bigint, bigint, bigint

    -- modular inverse, x such that x*self % mod = 1
    invmod: function(bigint, mod: bigint): bigint

    -- returns true if the number is a multiple of 2
    iseven: function(bigint): boolean

    -- returns true if the number is not a multiple of 2
    isodd: function(bigint): boolean

    -- you probably don't need this method, it's the karatsuba multiplication
    kmod: function(bigint, bigint, threshold: integer): bigint
    -- neither these (a few unrolled versions):
    kmod_unrolled: function(bigint, bigint, threshold: integer): bigint
    kmod_unrolled2: function(bigint, bigint, threshold: integer): bigint

    -- returns the number of bits needed to represent it
    lenbits: function(bigint): integer

    -- shifts offset bits to the left
    lshift: function(bigint, offset: integer): bigint

    -- BE CAREFUL WHEN WORKING WITH MUTABLE METHODS, AS SOME OPERATIONS RETURN
    -- REFERENCES TO ARGUMENTS OR SHARED SINGLETONS LIKE zero OR one.
    -- In case of doubt, use :copy() to create safe mutable bigints.

    -- add ignoring signs:
    mutable_unsigned_add: function(bigint, other: bigint)
    mutable_unsigned_add_atom: function(bigint, atom: integer)

    -- returns self raised to the power of p
    pow: function(bigint, p: bigint): bigint

    -- fast equivalent alternative to (x^power%mod)
    powmod: function(x: bigint, power: bigint, mod: bigint): bigint

    -- arithmetic shift offset bits to the right
    rshift: function(bigint, offset: integer): bigint
  
    -- convert to a normal lua number, precision may be lost
    tonumber: function(bigint): number

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
  new: function(n: integer | string): bigint

  -- returns a number between 0 and 2^bits-1,
  -- if safe is true data is read from /dev/random, otherwise urandom is used.
  randombits: function(bits: integer, safe: nil | boolean): bigint

  one: bigint
  zero: bigint
end

return BigInt
