local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local aes = require 'lualib.crypto.aes'
local bit = bit or require 'bit32'

local AesTest = oo.class(BaseTest)


local function normalize(t)
  local res = {}
  for k, v in pairs(t) do res[k] = bit.bor(v, 0) end
  return res
end


function AesTest:test_keyschedule()
  -- test vectors from: https://www.samiam.org/key-schedule.html
  self:assert_deep_equal(aes.keyschedule(('\0'):rep(16)), normalize {
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x62636363, 0x62636363, 0x62636363, 0x62636363,
    0x9b9898c9, 0xf9fbfbaa, 0x9b9898c9, 0xf9fbfbaa,
    0x90973450, 0x696ccffa, 0xf2f45733, 0x0b0fac99,
    0xee06da7b, 0x876a1581, 0x759e42b2, 0x7e91ee2b,
    0x7f2e2b88, 0xf8443e09, 0x8dda7cbb, 0xf34b9290,
    0xec614b85, 0x1425758c, 0x99ff0937, 0x6ab49ba7,
    0x21751787, 0x3550620b, 0xacaf6b3c, 0xc61bf09b,
    0x0ef90333, 0x3ba96138, 0x97060a04, 0x511dfa9f,
    0xb1d4d8e2, 0x8a7db9da, 0x1d7bb3de, 0x4c664941,
    0xb4ef5bcb, 0x3e92e211, 0x23e951cf, 0x6f8f188e,
  })
  self:assert_deep_equal(aes.keyschedule(('\255'):rep(16)), normalize {
    0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
    0xe8e9e9e9, 0x17161616, 0xe8e9e9e9, 0x17161616,
    0xadaeae19, 0xbab8b80f, 0x525151e6, 0x454747f0,
    0x090e2277, 0xb3b69a78, 0xe1e7cb9e, 0xa4a08c6e,
    0xe16abd3e, 0x52dc2746, 0xb33becd8, 0x179b60b6,
    0xe5baf3ce, 0xb766d488, 0x045d3850, 0x13c658e6,
    0x71d07db3, 0xc6b6a93b, 0xc2eb916b, 0xd12dc98d,
    0xe90d208d, 0x2fbb89b6, 0xed5018dd, 0x3c7dd150,
    0x96337366, 0xb988fad0, 0x54d8e20d, 0x68a5335d,
    0x8bf03f23, 0x3278c5f3, 0x66a027fe, 0x0e0514a3,
    0xd60a3588, 0xe472f07b, 0x82d2d785, 0x8cd7c326,
  })
  local key = string.char(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31)
  -- for AES-192
  self:assert_deep_equal(aes.keyschedule(key:sub(1, 24)), normalize {
    0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f,
    0x10111213, 0x14151617, 0x5846f2f9, 0x5c43f4fe,
    0x544afef5, 0x5847f0fa, 0x4856e2e9, 0x5c43f4fe,
    0x40f949b3, 0x1cbabd4d, 0x48f043b8, 0x10b7b342,
    0x58e151ab, 0x04a2a555, 0x7effb541, 0x6245080c,
    0x2ab54bb4, 0x3a02f8f6, 0x62e3a95d, 0x66410c08,
    0xf5018572, 0x97448d7e, 0xbdf1c6ca, 0x87f33e3c,
    0xe5109761, 0x83519b69, 0x34157c9e, 0xa351f1e0,
    0x1ea0372a, 0x99530916, 0x7c439e77, 0xff12051e,
    0xdd7e0e88, 0x7e2fff68, 0x608fc842, 0xf9dcc154,
    0x859f5f23, 0x7a8d5a3d, 0xc0c02952, 0xbeefd63a,
    0xde601e78, 0x27bcdf2c, 0xa223800f, 0xd8aeda32,
    0xa4970a33, 0x1a78dc09, 0xc418c271, 0xe3a41d5d,
  })
  -- 32 bytes key for AES-256:
  self:assert_deep_equal(aes.keyschedule(key), normalize {
    0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f,
    0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f,
    0xa573c29f, 0xa176c498, 0xa97fce93, 0xa572c09c,
    0x1651a8cd, 0x0244beda, 0x1a5da4c1, 0x0640bade,
    0xae87dff0, 0x0ff11b68, 0xa68ed5fb, 0x03fc1567,
    0x6de1f148, 0x6fa54f92, 0x75f8eb53, 0x73b8518d,
    0xc656827f, 0xc9a79917, 0x6f294cec, 0x6cd5598b,
    0x3de23a75, 0x524775e7, 0x27bf9eb4, 0x5407cf39,
    0x0bdc905f, 0xc27b0948, 0xad5245a4, 0xc1871c2f,
    0x45f5a660, 0x17b2d387, 0x300d4d33, 0x640a820a,
    0x7ccff71c, 0xbeb4fe54, 0x13e6bbf0, 0xd261a7df,
    0xf01afafe, 0xe7a82979, 0xd7a5644a, 0xb3afe640,
    0x2541fe71, 0x9bf50025, 0x8813bbd5, 0x5a721c0a,
    0x4e5a6699, 0xa9f24fe0, 0x7e572baa, 0xcdf8cdea,
    0x24fc79cc, 0xbf0979e9, 0x371ac23c, 0x6d68de36,
  })
end


function AesTest:test_cipher()
  -- examples from NIST.FIPS.197:
  local W = aes.keyschedule(('2b7e151628aed2a6abf7158809cf4f3c')
    :gsub('..', function(h)return string.char(tonumber(h, 16)) end))
  self:assert_deep_equal({aes.cipher(W, 0x3243f6a8, 0x885a308d, 0x313198a2, 0xe0370734)},
    normalize {0x3925841d, 0x02dc09fb, 0xdc118597, 0x196a0b32})
  self:assert_deep_equal({aes.cipher_inv(W, 0x3925841d, 0x02dc09fb, 0xdc118597, 0x196a0b32)},
    normalize {0x3243f6a8, 0x885a308d, 0x313198a2, 0xe0370734})

  W = aes.keyschedule(('000102030405060708090a0b0c0d0e0f')
    :gsub('..', function(h)return string.char(tonumber(h, 16)) end))
  self:assert_deep_equal({aes.cipher(W, 0x00112233, 0x44556677, 0x8899aabb, 0xccddeeff)},
    normalize {0x69c4e0d8, 0x6a7b0430, 0xd8cdb780, 0x70b4c55a})
  self:assert_deep_equal({aes.cipher_inv(W, 0x69c4e0d8, 0x6a7b0430, 0xd8cdb780, 0x70b4c55a)},
    normalize {0x00112233, 0x44556677, 0x8899aabb, 0xccddeeff})

  W = aes.keyschedule(('000102030405060708090a0b0c0d0e0f1011121314151617')
    :gsub('..', function(h)return string.char(tonumber(h, 16)) end))
  self:assert_deep_equal({aes.cipher(W, 0x00112233, 0x44556677, 0x8899aabb, 0xccddeeff)},
    normalize {0xdda97ca4, 0x864cdfe0, 0x6eaf70a0, 0xec0d7191})
  self:assert_deep_equal({aes.cipher_inv(W, 0xdda97ca4, 0x864cdfe0, 0x6eaf70a0, 0xec0d7191)},
    normalize {0x00112233, 0x44556677, 0x8899aabb, 0xccddeeff})

  W = aes.keyschedule(('000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f')
    :gsub('..', function(h)return string.char(tonumber(h, 16)) end))
  self:assert_deep_equal({aes.cipher(W, 0x00112233, 0x44556677, 0x8899aabb, 0xccddeeff)},
    normalize {0x8ea2b7ca, 0x516745bf, 0xeafc4990, 0x4b496089})
  self:assert_deep_equal({aes.cipher_inv(W, 0x8ea2b7ca, 0x516745bf, 0xeafc4990, 0x4b496089)},
    normalize {0x00112233, 0x44556677, 0x8899aabb, 0xccddeeff})
end


AesTest:run_if_main()


return AesTest
