package = "lualib"
version = "scm-1"
source = {
   url = "git+https://github.com/fcr--/lualib.git"
}
description = {
   summary = "A collection of Lua utility libraries",
   detailed = [[
      Random assortment of libraries fully written in Lua:
      - OO system
      - Cryptography (AES, RSA, SHA1, SHA3, RC4)
      - Data structures (Tree23, SortedDict, LRU Cache, SSLattice)
      - PEG parser and metagrammar
      - Encoding (Base64, Base45, ASN.1)
      - Utilities (JSON, UTF-8, Diff, UUID, BigInt, CRC32)
      - Testing framework (BaseTest)

      I wrote these Lua (luajit, 5.3, ...) libraries, gradually as I was needing them in order to share them between projects.
      Expect more miscellaneous stuff randomly appearing here in the future.
   ]],
   homepage = "https://github.com/fcr--/lualib",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["lualib.asn1"] = "lualib/asn1.lua",
      ["lualib.base45"] = "lualib/base45.lua",
      ["lualib.base64"] = "lualib/base64.lua",
      ["lualib.basetest"] = "lualib/basetest.lua",
      ["lualib.bigint"] = "lualib/bigint.lua",
      ["lualib.bigint_"] = "lualib/bigint_.lua",
      ["lualib.crc.crc32"] = "lualib/crc/crc32.lua",
      ["lualib.crypto.aes"] = "lualib/crypto/aes.lua",
      ["lualib.crypto.rc4"] = "lualib/crypto/rc4.lua",
      ["lualib.crypto.rsa"] = "lualib/crypto/rsa.lua",
      ["lualib.crypto.sha1"] = "lualib/crypto/sha1.lua",
      ["lualib.crypto.sha3"] = "lualib/crypto/sha3.lua",
      ["lualib.diff"] = "lualib/diff.lua",
      ["lualib.json"] = "lualib/json.lua",
      ["lualib.oo"] = "lualib/oo.lua",
      ["lualib.peg"] = "lualib/peg.lua",
      ["lualib.peggrammar"] = "lualib/peggrammar.lua",
      ["lualib.struct.lrucache"] = "lualib/struct/lrucache.lua",
      ["lualib.struct.sorteddict"] = "lualib/struct/sorteddict.lua",
      ["lualib.struct.sslattice"] = "lualib/struct/sslattice.lua",
      ["lualib.struct.tree23"] = "lualib/struct/tree23.lua",
      ["lualib.utf8"] = "lualib/utf8.lua",
      ["lualib.uuid"] = "lualib/uuid.lua"
   }
}
