local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local bigint = require 'lualib.bigint'


local BigIntTest = oo.class(BaseTest)


local new = bigint.new
local function m(t) return setmetatable(t, bigint.mt) end


-- A few useful numbers (with ~500 words, ~8kbit):
local n1 = new(
  '0x3679351039741ac3b9d17c3758d296d5594e59439b0b8b34a6cdad07a69012d' ..
  'df85185ce627527b55df5411a196aa9a82c06f18e07bd5f17b6ab8207ac927ef1ac' ..
  '18e86da0ba5947eafc9cb507570a43eaabbcd2995170c9da29c756092e39040783d' ..
  'b2cadb3f4d418ee321e17092c23ea7ebfa597aa30f3a3d8ead59196b35b59f35a3f' ..
  '3f720fa856448de7278048d8466812b31f8f7287391fd63275a92d5b34a31eb0a79' ..
  '552434bd27cc30ae274657b330c20abb41cd0f9f53b46f5d64cdb34363716782245' ..
  '5866c6d53fb9af5bb7fefa8370e67ec261f45dcd634de2ae5ddcd9c658296334dbf' ..
  '2bb8a83e9e8f1258f431fc331d9277494b75ccd74165c17e37aee738e80513af5f8' ..
  'f39eeb366050dc809ddc3247c760463a789526b88b0b97544364d8e7a14297f422c' ..
  '913668b73935973babad5bd4b60787da558435a7a9c1c041e75052152f5f5cfd1d4' ..
  '1aaaa9eb2af4bb31d157dd7c2e3a1fb783527747d1c3119f8bb2ddae826d3c31af2' ..
  '04cef95a7f2d0e50c1f3f8458a8b4ce235400ddc2c0f314c5cb9fcaff857f448e25' ..
  '632b289802680112240758d3591113554006b8c29d58baee8ae30f86e52d10439ce' ..
  'ba88683692f53a0b515ed008994c36db839d88e4e4b4ddec9fd4eb337679b7dc76b' ..
  '488ca483aec2317be63342847b333ec9a7023f3505539d570527997f71a7e4fec1a' ..
  '349db1579a8a0564b0b2f3dea01fc5ba9e7042945d8542a3f357f8ac6529e3337c3' ..
  '7fcb5bbf969c61a271c84d45628bfc30f8946e45eda2faa54918514b93645c405d6' ..
  'ca147e49e7fe535635393079fe71c103841b004814c2a0889699d77246a24fa5ce6' ..
  '8dd89f703ea8bc3a682c64fcec4dba23fe0d625d0d7c3d28a55e0ce28af521ed04f' ..
  '1620c7e5a5bd5bca3e25f14275a1943d8bd2219522acbaee79656769f042eb39121' ..
  '41ae110e316914613cc3829d2f8aa0dbbf1fcf0cf0dca0be70737a3a6317c3653c0' ..
  '74064334be377d99ab59d769bb83500a1cef5e3ebef5df386f2bd1664882edc7eda' ..
  'a76edeb7f45ecff8a1d609aac237cc34771d569e02b58784c0a68472b61afa994ce' ..
  '167156658447f9471a18a696079f3c2289a47b08d0069b268a9cdf9d57b14c9c826' ..
  'e02a15696a46f773405cb853a1221c0cf55407a17b818355a2312407b145c189e54' ..
  '7627b1c5b614c5acf704a37a7c62be9aa84432e1c6ee2cce09d83323f8ba2af9d71' ..
  '58f3cf547bc1ce5b4030cac9bd06922be2fce496d27938de458b143f44852f7e1c8' ..
  '62959388e2aa9a67ad035109839b93d87080ea80f2f73dcdd994d3bab0c188a2fed' ..
  'd0b9ba677ea477ac542641bdbb95a8e048eba507f2e3ce27c29a6cd8ea4d452ffac' ..
  'c8d55c5dda71782574d4113a05f9da08e10')
local n2 = new(
  '0x91f58ef4284c48978b263e72d8df46ff507855b987a7d0a45f66fcada1b33da' ..
  '5f4db48c7eaf7f757ccbc975d53ccc85285db1e8381ab0f6b0db63c9167c8be1e46' ..
  'aa55aaf0fbb72cb2abd4cc3ac1377ac8a82b76139b2521f69859449d3076328f9e6' ..
  'b8784d67a63b65c1a9f34571a7cb0361bcb56db80e04abc0051566a1a1dd95b14cf' ..
  'f894af30912916b4e3dc34589c9cfa84f6a27397eda62eddefedbfc8891dbe3309c' ..
  'c21503298004bdc40c5bdaacc162fb2c5b05252504828d2fff4d386bbbdbf5d2d2e' ..
  '4017e42ca4d800e05418d543011b06cdfb515bd4560b8b91f41f738dad36f9f7971' ..
  'f721166e67d891a598b8ec5bffd4e510194e835df9cfce8711f4f417e52c2217d0b' ..
  '6c4608ce339f355182a6c3811e5b465ef709fa52e7daa94da31850c790e653d37bf' ..
  '51125429d412a8362934b46a7e378a9e2e26b05eda69dd2ea231042fb889aec0c8b' ..
  'a181fe8ca64a2506c1bd98fc1ffeb9b775e1bfd587ac345c349a7bdbaf526ca1095' ..
  'beb33abbea3a7ee29247ca3f7b139809e841b744877f21e94137934a6606611f967' ..
  '7902c7f245688b504dce9c37e5ef62455404566d8323fcf0d9d1ae1be13a814d534' ..
  '77b3488c5115631b7def96785debc55a4b1a427e4315a1b462e987bcef3cd3130d5' ..
  '5566d4f44f02146cdbc214142d6a603cde2b0c4bc1a3f1d1b1b40a97c15338aa887' ..
  '37cfc94214d0bb20158e7aafa3dddea83afacfe52cc1278bdf04bd672538c8f7f6a' ..
  '98aa3c7c4c58429d8f414d0b8900f368ced9e9453093d509b76494a66e2b8a956f9' ..
  '9689eee11df997b875eb6d4125b13b72abd0f19a71808c398d4caced0147519896e' ..
  'c2ae991f89228e705c939bf3452466912f0567fe97bb57144318653e9eb52eab764' ..
  '64c9cb5488813c2d7f1e626a2e9b45aa118286beea51664ddbdde9a965188b3eb7a' ..
  'f2729c1c457b352b9d3484c603a873374a73326b0c2cae0f48b2c958b58b5087f06' ..
  '6fb617fbaec7d8745e25012f5c7dff9346224a490b530b24a1239a8927ea1caf204' ..
  'a1d05ba872733b41114a136f657978e1b4557c51221ecb18c7396e54f66eca2c5ad' ..
  'db4c34b47bd2c07d9ddb47a78f535c5e38d83a22d4c8e164df5f95738fbcb4ebb1b' ..
  'edd99bada8961d5cfa2417ef0d31348915999a0bc4ef17c4d451976fe8c34730569' ..
  '056d7bc22fa6d96e0912fdb7ea392cea2049c7e5e51c5636535c53664ec4969d1cb' ..
  '2173300bc4068607404e8168e6b6a2be592613a3bfee217bf049ad7a21d94c69e12' ..
  'b5675a57c626e0846ade58e759d66fc4dfd211bff3cdd4a3ba961e5a25d9e2ae534' ..
  '09b15a6422b1864dab78916be271e72e59b8ff412738341f7918c0c5a23bad8ea85' ..
  '34fd1c7c595c4fc21b06263805985fc5eaf7509')
-- n1n2 is the multiplication of n1 and n2:
local n1n2 = new(
    '0x1f0ee779289a7e5442e492ef159304ac0b107e131b55d8e97981bee803bb4' ..
    '29662e42e6a5a1fdc7f9443e7c5d2d7e08b7aa85c8c4c6f4cbd72e73968daa52943' ..
    '75b656aa4f9f007d838db64c9ceec01e35695e20b0ed4e3aa035bc14ca3920f32f5' ..
    '58fedee078b51d1c5ab2cea48e06b4a6d3f2385a9eadae615e8a54eb9a48c359d41' ..
    'f09e02ac095c983d0f379f36554329ae360dca20cc38a026f8bf75b005d728c811c' ..
    '917d4aaf82deba1985f1f35864cf26555c2d4308f848cf84e64dd71da22a1d5d5b3' ..
    'ebd951b6b4bde2b10d1b6bd309a28ea110976671efc7361cbe68bef8d6d9de0e452' ..
    'e87afa8c6142c944fadb9fc534527853b771c7b173d2035902451abe51a13aa2666' ..
    '5f70cb1fe68a3b4b362345d9c565bc1142f7f442a7a8798d0abd00cd8c06e7274c4' ..
    '6a157c537a22dac77f37be6a2a69e75de94fff7867563bfdd0f65b1de99e3145c1c' ..
    'fc7d61ae3191b1daf8ca4da9d0d1c73337e3b29e499b857497e277cc89a2e47ed03' ..
    '5246084cfb1decebeec262796f7dce5afaa09591e6afa57ece752bae61c99ef01d7' ..
    'f2540d382ef84fdaa88b646f54c5211f0c05b7c5751d9fa72800e57e20b12830dcd' ..
    '6672e7824617e73d07ba0cf1ebbb959adce5bf32d7786edc93e4dced2e4cbf77a16' ..
    '600653e9a40c50b70014506622c4eb7e8a81a7f581321a5870b6ea009ebd1f5accf' ..
    'b723f3559951cb1a081551897e832eae58fe2fb8d47331a10fa4f97b56e9a9ea159' ..
    '65dfc0548d31c783de004fc53fc7f87e2ac0fe778c1a491165a208d490a53e45fbb' ..
    'c1f2da517a83367ece11a2edea2f71f31467cfff55ded07aa735dcbf228374cc716' ..
    '6c1e2a4c4d7536965374534aa7ef6a152702fd3f55c9b840d87ca952d931a78b446' ..
    '1f1242db46ce11fcc479273820b4145bc802d39f0e65b6d66dc6749784118c7561f' ..
    '2a7c528e1872e92cdb258fad1607b936737969276d81fbf047ff3f2c3329fd9e7f3' ..
    '39d552b135537a95b342a02d3b8c4bad16ea46bdd7c41f815b1dd4edc248bfbb524' ..
    'f97139fa6893ee88e86de1fd028cbc9b91771915e9b79884f2fb86e29184156b14f' ..
    '3cc44275181677e95cfc91af5d32e2585bef4f02b64ea9abfd7976edef5446a1e03' ..
    'c01cbc42ba8fb81eaf02ab5f92a4368832639f73fbf29e6a97fae1afd22a6db9f42' ..
    '87850377d29edf80463d1f72b675b66d303442cbf765953223c60460331f5296254' ..
    '1e3aa23b9ad80013cf03a1b71997a90df7ea2fc91a4ffe40a0a42b5624ca8df6abf' ..
    'f67a40253c480fd3c52fef07f2cf16f27f4da86f19c4c68384649847c697840b3a4' ..
    'a4d755b64555987e4c01f1d23559df7c81240cfd20902ef33ecc26bc91506e278d5' ..
    '0e1e1d7aa9b0340cd8e0520d4f29e9ce0f626f9a64f3a8f47c302f3a0c6fc2e3733' ..
    'ea1ff87681bf76f45e63f7524dea51c8f91c49722c65af899ce10b198580a4b7a7f' ..
    'cd6c86a2f1849009eb5605aedf28373299f1a109a5bea8eea9fa019e0292e2dbbde' ..
    'ef22ec02f9cd1bc4bd6767b6778e443e24cd4bac47a20208dc023713d6df95f2d0c' ..
    'a99766b6ec7ee9b33a459c5a41855579fed2409ab0fa6cde50f7e4dab4440105b4e' ..
    '251ff2d4661d748ed765b7f25e1bff7dc8215326f0a086504830523c87cbde9673d' ..
    '808b35cdf3cb8021ad349d1b0cf35dbd47d32f5713166750354084d19b8f55a6ad0' ..
    '477acebe7802bab386561a5f32e86f01e0af3bce9d1643aa600b9ab9180fbe982e3' ..
    '29bf630474ef6bc3bfe95b9765110b5edd9133ad166de6018720511621579eace69' ..
    'a6e6d7e666a6e24268b5d52d538594bd5bb6a214ae1015d629f6e0c32acd9834bdb' ..
    '72afdf149e08508f960ff24386310432ae7a4f1a60621e1a3265b3fdff2799fe769' ..
    '834f907a299a1eae40f46c5406d4b62a105054b5c9c010593962f7b7fa74ecfd6c9' ..
    'f8264d955f84dc0999bd2d4e007b1fa597084cbc952b945b3ac9b744e0ee7cbb5cf' ..
    'd00249d5fc212d8154e406edd19a3857576dcf5c2a57cf77ba37c30e64704eca400' ..
    '2fdc254f4abfc38494b215d0c2dbb673f8ddc1c85fb13b1435195965ec38b8fda28' ..
    '485a6647b3da34ca64989c23ab2a1b6833bfa3b03fc639bd959fa7c7414f100480d' ..
    'e50c55a8941f62b62aa87b1f42b7b1e19cc7d8713d70b89c1b312d36537cf6344c0' ..
    'ec99db119125ee6dfc84ff4cc703d9a7e897833d680a64137daaff07d8c67a8c6e0' ..
    '69cd915ee974879dbfa932f19ee65d6257e62913b4de8cfc32bb66008699d2d0409' ..
    '9cddb243fbe9db08b95fde84873c294723808cf81fec78671b8158d52a1855ab5be' ..
    '7560d95127008fb18ab3ef690388542ddd6b6fdad5c55aea90c6597411b350e8539' ..
    'd7a07ac18b70a2674e50d42a7446f84b1dcd543062ada73e93478a9086a5e2fb557' ..
    '0f66175461fe697bfc11db1d08e9121c5b61bdc24e3ea18197c884203ffe34c60b0' ..
    '580b40456ee585c1f6b07b2cb7807c9c86bc8e473a358826cc087fcd655e4b9551d' ..
    '05a04763142bda56d604debedfa458b9b6f0386bcd7b82ba300dce8f88f27ab7b61' ..
    '5c15c12095185385734c212d017ab2dfbe56c2f12f835c2b4715c39f8ee06b1c5e0' ..
    '2d748345a46c9d6b6ef6fb0c64a4d054644bdb5902bb037cdc7f870879829e5a9a4' ..
    '8f94033a754df418d1290a0496041b6ababd46edcc2b0ff547e9a3c997753ec0bbe' ..
    '0a5ee7a21de1880f622b747b396fd3c79e28be3ae1f9c6a9de73706fef1ac4cdea7' ..
    '086f21d0e5bfb84288e0c36892e100867b4be27181556167695ac0cff6a43311e88' ..
    '24e90')
local p1 = new '0x44145cdc85a07da9b'
local p2 = new '0x17af663a3b84710a1'  -- luacheck: ignore


function BigIntTest:common_test_mul(op)
  self:assert_equal(op(new(42), bigint.zero), bigint.zero)
  self:assert_equal(op(bigint.zero, new(42)), bigint.zero)
  self:assert_equal(op(new(0x10002), new(-0x30004)), new(-0x3000a0008))
  self:assert_equal(op(new(-2), new(-3)), new(6))
  self:assert_equal(
    op(new'0x78431badc0ffee876', new'0xc1f7e493209a577ef5a'),
    new'0x5b1f0bfe95a6b35bc8dd508d17c4b77de37c')
  self:assert_equal(op(n1, n2), n1n2)
end


function BigIntTest:test_new()
  self:assert_deep_equal(new(7), m{7, sign=1})
  self:assert_deep_equal(new(-4), m{4, sign=-1})
  self:assert_deep_equal(new(0), m{sign=0})
  self:assert_deep_equal(new(0x10002), m{2, 1, sign=1})
  self:assert_deep_equal(new'0', bigint.zero)
  self:assert_deep_equal(new'00', bigint.zero)
  self:assert_deep_equal(new'5', new(5))
  self:assert_deep_equal(new'00000000000000000000001', bigint.one)
  self:assert_deep_equal(new'1234567', m{54919, 18, sign=1})
  self:assert_deep_equal(new'-1234567', m{54919, 18, sign=-1})
  self:assert_deep_equal(new'12345678', m{24910, 188, sign=1})
  self:assert_deep_equal(new'0x414f69a371947399bad117e0ffcd08e',
    m{0xd08e, 0xffc, 0x117e, 0x9bad, 0x4739, 0x3719, 0xf69a, 0x414, sign=1})
  self:assert_deep_equal(new'0x0', bigint.zero)
  self:assert_deep_equal(new'0x1', bigint.one)
  self:assert_deep_equal(new'0x12', m{0x12, sign=1})
  self:assert_deep_equal(new'0x123', m{0x123, sign=1})
  self:assert_deep_equal(new'0x1234', m{0x1234, sign=1})
  self:assert_deep_equal(new'0x12345', m{0x2345, 0x1, sign=1})
  self:assert_deep_equal(new'0x123456', m{0x3456, 0x12, sign=1})
  self:assert_deep_equal(new'0x1234567', m{0x4567, 0x123, sign=1})
  self:assert_deep_equal(new'0x12345678', m{0x5678, 0x1234, sign=1})
  self:assert_deep_equal(new'0x123456789', m{0x6789, 0x2345, 1, sign=1})
  self:assert_deep_equal(new'-0x1', -bigint.one)
  self:assert_deep_equal(new'-0x12', m{0x12, sign=-1})
  self:assert_deep_equal(new'-0x123', m{0x123, sign=-1})
  self:assert_deep_equal(new'-0x1234', m{0x1234, sign=-1})
  self:assert_deep_equal(new'-0x12345', m{0x2345, 0x1, sign=-1})
  self:assert_deep_equal(new'-0x123456', m{0x3456, 0x12, sign=-1})
  self:assert_deep_equal(new'-0x1234567', m{0x4567, 0x123, sign=-1})
  self:assert_deep_equal(new'-0x12345678', m{0x5678, 0x1234, sign=-1})
  self:assert_deep_equal(new'-0x123456789', m{0x6789, 0x2345, 1, sign=-1})
end


-- luacheck: ignore
function BigIntTest:test_randombits()
    local old_open = io.open
    local function mock_function()
        local mock = {call_count = 0, args_list = {}}
        return setmetatable(mock, {
            __call = function(_obj, ...)
                mock.args = {...}
                mock.args_list[#mock.args_list + 1] = mock.args
                mock.call_count = mock.call_count + 1
                return mock.res
            end
        })
    end
    local function reset_mock()
        io.open = mock_function()
        io.open.res = {
            read = mock_function(),
            close = mock_function(),
        }
    end
    reset_mock()
    local mock_fd = io.open.res
    mock_fd.read.res = 'Hello'
    self:assert_equal(bigint.randombits(36), bigint.fromstring('raw', '\015lleH'))
    self:assert_deep_equal(io.open.args_list, {{'/dev/urandom', 'rb'}})
    self:assert_deep_equal(mock_fd.read.args_list, {{mock_fd, 5}})
    self:assert_deep_equal(mock_fd.close.args_list, {{mock_fd}})
    io.open = old_open
end


function BigIntTest:test___add()
  self:assert_equal(new(2) + new(5), new(7))
  self:assert_equal(new(2) + new(-5), new(-3))
  self:assert_equal(new(-2) + new(5), new(3))
  self:assert_equal(new(5) + new(-2), new(3))
  self:assert_equal(new(-5) + new(2), new(-3))
  self:assert_equal(new(-3) + new(-3), new(-6))
  self:assert_equal(new(3) + new(-3), new(0))

  self:assert_equal(new(0x10002) + new(0), new(0x10002))
  self:assert_equal(new(0) + new(0x10002), new(0x10002))
  self:assert_equal(new(-0x10002) + new(0), new(-0x10002))
  self:assert_equal(new(0) + new(-0x10002), new(-0x10002))
  
  self:assert_equal(new(0x10000) + new(2), new(0x10002))
  self:assert_equal(new(2) + new(0x10000), new(0x10002))
  self:assert_equal(new(0x10000) + new(-2), new(0xfffe))
  self:assert_equal(new(-2) + new(0x10000), new(0xfffe))
  self:assert_equal(new(-0x10000) + new(2), new(-0xfffe))
  self:assert_equal(new(2) + new(-0x10000), new(-0xfffe))
  self:assert_equal(new(-0x10000) + new(-2), new(-0x10002))
  self:assert_equal(new(-2) + new(-0x10000), new(-0x10002))
end


function BigIntTest:test___eq()
  self:assert_equal(new(7) == new(7), true)
  self:assert_equal(new(7) == new(-7), false)
  self:assert_equal(new(-7) == new(-7), true)
  self:assert_equal(new(0x10002) == new(0x10002), true)
  self:assert_equal(new(0x10001) == new(0x10002), false)
  self:assert_equal(new(1) == new(0x10001), false)
  self:assert_equal(new(1) == bigint.one, true)
  -- should break with non-normalized values
  self:assert_equal(new(1) == m{sign=1, 1, 0}, false)
end


function BigIntTest:test___mul()
  self:common_test_mul(function(a, b)return a*b end)
end


function BigIntTest:test___sub()
  self:assert_equal(bigint.one - bigint.one, bigint.zero)
  self:assert_equal(new(-1) - new(-1), bigint.zero)
  self:assert_equal(bigint.one - new(-1), new(2))
  self:assert_equal(new(-1) - bigint.one, new(-2))
  self:assert_equal(bigint.zero - bigint.one, new(-1))
end


function BigIntTest:test___tostring()
  self:assert_equal(tostring(new(0)), '0')
  self:assert_equal(tostring(new(0x10000789a)), '0x10000789a')
  self:assert_equal(tostring(new(-0x3ffff)), '-0x3ffff')
end


function BigIntTest:test___unm()
  self:assert_equal(-new(0x30004), new(-0x30004))
  self:assert_equal(-new(-0x30004), new(0x30004))
  self:assert_equal(-bigint.zero, bigint.zero)
end


function BigIntTest:test_band()
  self:assert_equal(new(1+2):band(new(2+4)), new(2))
  self:assert_equal(new(1):band(bigint.zero), new(0))
  self:assert_equal(new(0x10006):band(new(3)), new(2))
  self:assert_equal(new(1+2):band(-new(2+4)), new(2))
  self:assert_equal((-new(1+2)):band(new(2+4)), new(2))
  self:assert_equal((-new(1+2)):band(-new(2+4)), new(-2))
end


function BigIntTest:test_bcount()
  self:assert_equal(bigint.zero:bcount(), 0)
  self:assert_equal(bigint.one:bcount(), 1)
  self:assert_equal(new(0xffff):bcount(), 16)
  self:assert_equal(new(0xffffffff):bcount(), 32)
  self:assert_equal(new'0x123456789abcdef':bcount(), 32)
  self:assert_equal(new'0x5a':bcount(), 4)
  self:assert_equal(n1:bcount(), 3935)
  self:assert_equal(new'0xad066a5d29f3f2a2a1c7c17dd082a79':bcount(), 62)
end


function BigIntTest:test_bmul()
  self:common_test_mul(bigint.zero.bmul)
end


function BigIntTest:test_bor()
  self:assert_equal(new(3):bor(new(6)), new(7))
  self:assert_equal(bigint.one:bor(bigint.zero), bigint.one)
  self:assert_equal(bigint.zero:bor(new(-5)), new(-5))
  self:assert_equal(new(0x10003):bor(new(6)), new(0x10007))
  self:assert_equal(new(3):bor(-new(6)), new(-7))
  self:assert_equal((-new(3)):bor(new(6)), new(-7))
  self:assert_equal((-new(3)):bor(-new(6)), new(-7))
end


function BigIntTest:test_bxor()
  self:assert_equal(new(3):bxor(new(6)), new(5))
  self:assert_equal(bigint.one:bxor(bigint.zero), bigint.one)
  self:assert_equal(bigint.zero:bxor(new(-5)), new(-5))
  self:assert_equal(new(0x10003):bxor(new(6)), new(0x10005))
  self:assert_equal(new(3):bxor(-new(6)), new(-5))
  self:assert_equal((-new(3)):bxor(new(6)), new(-5))
  self:assert_equal((-new(3)):bxor(-new(6)), new(5))
end


function BigIntTest:test_copy()
  local n = new(42)
  local m = n:copy()
  self:assert_equal(n, m)
  m:mutable_unsigned_add(bigint.one)
  self:assert_equal(n, new '42')
  self:assert_equal(m, new '43')
  self:assert_not_equal(n, m)
  self:assert_equal(bigint.zero:copy(), bigint.zero)
  self:assert_equal(new(-42), new(-42):copy())
end


function BigIntTest:test_divmod()
  for _, pair in ipairs{{8, 7}, {8, -7}, {-8, 7}, {-8, -7},
    {80000, 70000}, {80000, -70000}, {-80000, 70000}, {-80000, -70000}
  } do
    -- let's ensure consistency with lua's (IEEE-754) default behavior:
    local x, y = pair[1], pair[2]
    self:assert_deep_equal({new(x):divmod(new(y))}, {new(math.floor(x/y)), new(x%y)})
  end
end


function BigIntTest:test_divqr()
  self:assert_deep_equal({new(100):divqr(new(30))}, {new(3), new(10)})
  self:assert_deep_equal({new(1000000):divqr(new(1))}, {new(1000000), bigint.zero})
  self:assert_deep_equal({new(1000000):divqr(new(1000))}, {new(1000), bigint.zero})
  self:assert_deep_equal({new(1000000):divqr(new(100000))}, {new(10), bigint.zero})
  self:assert_deep_equal(
    {new'0x798a9b789c7578ef076a86b890c675de52534f1':divqr(new'0xdeadcafe1234')},
    {new'0x8bba855615feb83ca0a4d876ee0', new'0xac95dd96ef71'})
end


function BigIntTest:test_gcd()
  self:assert_deep_equal({n1:gcd(n1)}, {n1, bigint.one, bigint.zero})
  self:assert_deep_equal({new(718):gcd(new(1079))}, {bigint.one, new(269), new(-179)})
  self:assert_deep_equal({new(83):gcd(new(25))}, {bigint.one, new(-3), new(10)})
  self:assert_deep_equal({new(1899781485):gcd(new(333719637))}, {new(3), new(-4389797), new(24990004)})
end


function BigIntTest:test_invmod()
  self:assert_equal(new(718):invmod(new(1079)), new(269))
  self:assert_equal(new(83):invmod(new(25)), new(22))
  local a = new'7842361786148370890735160'
  -- both assertions hold true for prime numbers:
  self:assert_equal(a:invmod(p1), a:powmod(p1-new(2), p1))
  self:assert_equal(p1:invmod(a) * p1 % a, bigint.one)
end


function BigIntTest:test_kmul()
  self:common_test_mul(function(a, b)return a:kmul(b, 400) end)
  --n1, n2 = n1*n1, n2*n2  -- if you wanna test with bigger numbers
  local measure_kmul = nil
  -- local measure_kmul = bigint.zero.kmul
  -- local measure_kmul = bigint.zero.kmul_unrolled
  -- local measure_kmul = bigint.zero.kmul_unrolled2
  if measure_kmul then
    local min_ratio, min_at = 100, -1
    for threshold = 30, 800 do
      --collectgarbage()
      --collectgarbage()
      local start_base = os.clock()
      for _=1, 100 do local _=n1:bmul(n2) end
      local start_kmul = os.clock()
      for _=1, 100 do local _=measure_kmul(n1, n2, threshold) end
      local now = os.clock()
      local ratio = 100*(now - start_kmul) / (start_kmul - start_base)
      print(('%5d: k=%-10g b=%-10g ratio=%-5g%%'):format(
        threshold, now - start_kmul, start_kmul - start_base, ratio))
      if ratio < min_ratio then
        min_ratio = ratio
        min_at = threshold
      end
    end
    print('min_ratio', min_ratio, 'at', min_at)
  end
end


function BigIntTest:test_kmul_unrolled()
  self:common_test_mul(function(a, b)return a:kmul_unrolled(b, 185) end)
end


function BigIntTest:test_kmul_unrolled2()
  self:common_test_mul(function(a, b)return a:kmul_unrolled2(b, 185) end)
end


function BigIntTest:test_lenbits()
  self:assert_equal(bigint.one:lenbits(), 1)
  self:assert_equal(new(-4):lenbits(), 3)
  self:assert_equal(new(0):lenbits(), 0)
  self:assert_equal(new(1000):lenbits(), 10)
  self:assert_equal(new(0xffff):lenbits(), 16)
  self:assert_equal(new(0x10002):lenbits(), 17)
end


function BigIntTest:test_lshift()
  self:assert_equal(new(0xffff):lshift(1), new(0x1fffe))
  self:assert_equal(bigint.one:lshift(1), new(2))
  self:assert_equal(new(0x1234):lshift(0), new(0x1234))
  self:assert_equal(new(0x12345678):lshift(0), new(0x12345678))
  self:assert_equal(new'0x123456789abc':lshift(0), new'0x123456789abc')
  self:assert_equal(new(0x1234):lshift(4), new(0x12340))
  self:assert_equal(new(0x12345678):lshift(4), new'0x123456780')
  self:assert_equal(new'0x123456789abc':lshift(4), new'0x123456789abc0')
  self:assert_equal(new(0x1234):lshift(16), new(0x12340000))
  self:assert_equal(new(0x12345678):lshift(16), new'0x123456780000')
  self:assert_equal(new'0x123456789abc':lshift(16), new'0x123456789abc0000')
  self:assert_equal(new(0x1234):lshift(20), new'0x123400000')
  self:assert_equal(new(0x12345678):lshift(20), new'0x1234567800000')
  self:assert_equal(new'0x123456789abc':lshift(20), new'0x123456789abc00000')
end


function BigIntTest:test_mutable_lshift()
  local n = new(0x12345678)
  n:mutable_lshift(1)
  self:assert_equal(n, new(0x2468acf0))
  n:mutable_lshift(3)
  self:assert_equal(n, new'0x123456780')
  n:mutable_lshift(0)
  self:assert_equal(n, new'0x123456780')
  n:mutable_lshift(12)
  self:assert_equal(n, new'0x123456780000')
  n = n + new(0x9abc)
  n:mutable_lshift(16)
  self:assert_equal(n, new'0x123456789abc0000')
  n:mutable_lshift(20)
  self:assert_equal(n, new'0x123456789abc000000000')
  n = -n
  n:mutable_lshift(4)
  self:assert_equal(n, new'-0x123456789abc0000000000')
end


function BigIntTest:test_mutable_unsigned_add()
  local n = new(0xfffffffe)
  n:mutable_unsigned_add(new(2))
  self:assert_equal(n, new(0x100000000))
  n:mutable_unsigned_add(-bigint.one)
  self:assert_equal(n, new(0x100000001))
  n = -n
  n:mutable_unsigned_add(bigint.one)
  self:assert_equal(n, new(-0x100000002))
  n:mutable_unsigned_add(new(0xfffffffe))
  self:assert_equal(n, new(-0x200000000))
  n:mutable_unsigned_add(bigint.one:lshift(64))
  self:assert_equal(n, new'-0x10000000200000000')
end


function BigIntTest:test_mutable_unsigned_add_atom()
  local n = new'0x12345ffff6789'
  n:mutable_unsigned_add_atom(7)
  self:assert_equal(n, new'0x12345ffff6790')
  n:mutable_unsigned_add_atom(0x9870)
  self:assert_equal(n, new'0x1234600000000')
  n = new(-32)
  n:mutable_unsigned_add_atom(1)
  self:assert_equal(n, new(-33))
  self:assert_error(n.mutable_unsigned_add_atom, n, -1)
  self:assert_error(n.mutable_unsigned_add_atom, n, 65536)
  self:assert_error(n.mutable_unsigned_add_atom, n, 3.14159)
end


function BigIntTest:test_pow()
  self:assert_equal(bigint.one:pow(bigint.zero), bigint.one)
  self:assert_equal(bigint.zero:pow(bigint.zero), bigint.one)
  self:assert_equal(new(3):pow(new(3)), new(27))
  self:assert_equal(new(10):pow(new(3)), new(1000))
  self:assert_equal(new(2):pow(new(10)), new(1024))
  self:assert_equal(new(2):pow(new(70000)), bigint.one:lshift(70000))
  self:assert_equal(new(-0x30001):pow(new(2)), new'0x900060001')
  self:assert_equal(new(-0x30001):pow(new(3)), new'-0x1b001b00090001')
end


function BigIntTest:test_powmod()
  self:assert_equal(new(672):powmod(new(815), new(517)), new(56))
  self:assert_equal(new(0x78496217):powmod(new(0x67867891), new(2)), bigint.one)
  self:assert_equal(new(725403256838):powmod(new(429322590726), new(17034810993)), new(14853464623))
  self:assert_equal(new(-2):powmod(new(3), new(7)), new(6))
  local err = self:assert_error(bigint.one.powmod, bigint.one, bigint.one, bigint.zero)
  self:assert_pattern(err, 'division by zero')
  --self:assert_equal(n1:powmod(n2, new(17034810993)), new(9253199997))
  --self:assert_equal(n1:powmod(n2, n1+n2), new(9253199997)) -- quite slow,
end


function BigIntTest:test_rshift()
  self:assert_equal(bigint.zero:rshift(0), bigint.zero)
  self:assert_equal(new'0x12345678':rshift(0), new'0x12345678')
  self:assert_equal(new(0xffff0000):rshift(1), new(0x7fff8000))
  self:assert_equal(new'0x123456789abc':rshift(1), new'0x91a2b3c4d5e')
  self:assert_equal(new'0x123456789abc':rshift(4), new'0x123456789ab')
  self:assert_equal(new'0x123456789abc':rshift(12), new'0x123456789')
  self:assert_equal(new'0x123456789abc':rshift(16), new'0x12345678')
  self:assert_equal(new'0x123456789abc':rshift(20), new'0x1234567')
  self:assert_equal(new'0x123456789abc':rshift(741), bigint.zero)
end


function BigIntTest:test_sqrt()
  local err = self:assert_error(bigint.one.sqrt, -bigint.one)
  self:assert_pattern(err, 'not supported')
  self:assert_equal(bigint.zero:sqrt(), bigint.zero)
  self:assert_equal(bigint.one:sqrt(), bigint.one)
  self:assert_equal(new(2):sqrt(), bigint.one)
  self:assert_equal(new(3):sqrt(), bigint.one)
  self:assert_equal(new(4):sqrt(), new(2))
  self:assert_equal(new(5):sqrt(), new(2))
  self:assert_equal(new(80):sqrt(), new(8))
  self:assert_equal(new(81):sqrt(), new(9))
  local n1sqrt = n1:sqrt()
  local n1sqrtup = n1sqrt + bigint.one
  self:assert_less_or_equal(n1sqrt * n1sqrt, n1)
  self:assert_less_or_equal(n1, n1sqrtup * n1sqrtup)
end


function BigIntTest:test_tonumber()
  self:assert_equal(bigint.zero:tonumber(), 0)
  self:assert_equal(new(438912):tonumber(), 438912)
  self:assert_equal(new(-1234567890):tonumber(), -1234567890)
end


function BigIntTest:test_tostring()
  -- hex format:
  self:assert_equal(bigint.zero:tostring'hex', '0')
  self:assert_equal(new(0x10000789a):tostring'hex', '0x10000789a')
  self:assert_equal(new(-0x3ffff):tostring'hex', '-0x3ffff')
  self:assert_equal(bigint.zero:tostring('hex', {zero='0x0'}), '0x0')
  self:assert_equal(new(9):tostring('hex', {plus_sign='¿'}), '¿0x9')
  self:assert_equal(new(-1):tostring('hex', {minus_sign='¬'}), '¬0x1')
  self:assert_equal(new(-1):tostring('hex', {prefix='!'}), '-!1')
  -- dec format:
  self:assert_equal(bigint.zero:tostring'dec', '0')
  self:assert_equal(new(1234567890):tostring'dec', '1234567890')
  self:assert_equal(new(-1234567890):tostring'dec', '-1234567890')
  self:assert_equal(m{0, 1, sign=1}:tostring'dec', '65536')
  self:assert_equal(
    m{0,0,0,0, 0,0,0,0, 0,0,1, sign=1}:tostring'dec',
    '1461501637330902918203684832716283019655932542976')
  -- raw format:
  self:assert_equal(bigint.zero:tostring'raw', '\0')
  self:assert_equal(bigint.zero:tostring('raw', {zero='?'}), '?')
  self:assert_equal(new(42):tostring'raw', '\42')
  self:assert_equal(new(127):tostring'raw', '\127')
  self:assert_equal(new(128):tostring'raw', '\0\128')
  self:assert_equal(new(0x0102):tostring'raw', '\1\2')
  self:assert_equal(new(0x7fff):tostring'raw', '\127\255')
  self:assert_equal(new(0x8000):tostring'raw', '\0\128\0')
  self:assert_equal(new(-1):tostring'raw', '\255')
  self:assert_equal(new(-2):tostring'raw', '\254')
  self:assert_equal(new(-128):tostring'raw', '\128')
  self:assert_equal(new(-129):tostring'raw', '\255\127')
  self:assert_equal(new(-0x0103):tostring'raw', '\254\253')
  self:assert_equal(new(-0x8000):tostring'raw', '\128\0')
  self:assert_equal(new(1234567890):tostring'raw', 'I\150\2\210')
  self:assert_equal(new(-1234567890):tostring'raw', '\182i\253.')
end


BigIntTest:run_if_main()


return BigIntTest
