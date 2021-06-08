local record rc4
  record Rc4
    -- Returns a string of the same length, encrypting or decrypting the text.
    encrypt: function(self: Rc4, text: string): string

    -- Overwrites res[1..n] with bytes generated from the cipher, returning it.
    -- If res is missing a new table is used instead.
    bytes: function(self: Rc4, n: integer, res: {integer} | nil): {integer}
  end

  record rc4_options
    key: string
  end

  new: function(cls: Rc4, opts: rc4_options): Rc4
end

return rc4
