local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local sha1 = require 'lualib.crypto.sha1'

local Sha1Test = oo.class(BaseTest)


function Sha1Test:test_empty()
  self:assert_equal(sha1 '', 'da39a3ee5e6b4b0d3255bfef95601890afd80709')
  self:assert_equal(
    sha1('', true),
    ('da39a3ee5e6b4b0d3255bfef95601890afd80709'):gsub('..', function(h)
      return string.char(tonumber(h, 16))
    end)
  )
end

function Sha1Test:test_basic()
  self:assert_equal(
    sha1 'The quick brown fox jumps over the lazy dog',
    '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12'
  )
end

function Sha1Test:test_lens()
  -- #message is 128, which will be broken into 1 to 3 blocks
  local message = 'To have several k1nds of bytes, この文章は日本語で書いてある！'
    .. '\nThis allows us to test encoding several blocks... '
  local sha1s = {
    'c2c53d66948214258a26ca9ca845d7ac0c17f8e7',
    'ae79ea1e9c6391a9ed83a2e18a031b835feec0c9',
    '19e9dab67c02bab4688de70c41dc4f7dd9551d58',
    '0be4dcf4ecd0051a95cb8a90703de32a6abd4645',
    '2cf27ab706b334808bdb0eb43f30ca484960e041',
    'fcedd3da6329c233e3d0ef865b0a8629a19f3032',
    '5f0d103274be3f18461266884ec6c0f37e70a47a',
    '11969e037aacca45a547eaf9fb99251cd0dc7fe7',
    'a4fb4c0d72b755af9fcd76a26282cd1c6346b935',
    '714796892a533401f148030670dc679ad903ae36',
    '3c931f6a56684b5aadbbccfe4b257d562254b0bd',
    '423f02d7e8cadc0a5265758baf14f9fb6beb6ef8',
    'f88182415ca22da7ebbd932e24d9b69f3aa42044',
    '9b476446f0fe8fa024ea28c46aaebf6ace19afec',
    '93b9233bb45353c36dc7d0c1d97d170e2dfc4955',
    '85c0f1bd1a0ef6f30a7e1b35168614adaa21c5d5',
    '3edebd6522359fe12a22babe3801f541b7a1ff9d',
    'c5810fed2ede788bceb275fe741570a54857b526',
    '9e029131e1800d4c22dac5f35a04d638b98ebeb4',
    '898e0befa10d5bebeaa43fb3f7f00de0494e8f70',
    '8d87d8d14ba3881074de53a97ec573034f39ed0b',
    '3d921af2dc047246264bdcf70ba402960f125504',
    'cca63a7bce262a1145cde006198a04d50dc9ce2f',
    '510c64f8a154232054f424ec318ae8108929f073',
    'ce86aac9bd8baadd1524d8b50a0cfb52c5c204f2',
    '26637b31e690ad295f86e43e892f40f1e36209e5',
    '3f96a0f71253ae2e993a40e7d95f2f73b01a9b2b',
    '46fc5d7966954d41cd3a57d88aa4685760e2ada1',
    '896c825990dd2f38399a5d6dc8c8a032c9442970',
    'fd43a9e793e8f883fb946da3a32aa8a88e0de8f4',
    '8cb94a17ae120dc483f2e8febcbc8cfecbeb2f1a',
    'a63612d64f70ab513cf7b334dbabbe3597ade4c6',
    '9652172eaeeef5836f5960d08a252e121ce76238',
    'ae5eae7e3800adc26910ef223b371c3c1259ff20',
    '585a2bd2e85cccf7b3501efc58cdf59bbdabaa84',
    'eb5c898fb2dd83cebb6a06a6d4150ce6dbae976f',
    '66d846e419c12b8e4eb60b64855b194ccfb18c43',
    '88f4037206a0eda06e4911cf91549c7390419cc6',
    '9fba8b8e27325fe48b0e67ead99628765f535038',
    'b463eb3b4b363f7e0f27a7e2c2a57a6fc8c2f783',
    'ad130cc8c1148c47173bb8b3b8c8b7e8b215982a',
    'f1f6eb8ba81463ca86d2d1b4a19cbfad6900e5e1',
    '5c31b0a8125f7b99fdb45acb9e6b977b935b8544',
    '4beb471e5fd5d648d857ab0cca29051cb3f65c1f',
    '3caf49edd3587c1dcfd438409ee284b3aa695d52',
    'e65fb0e359ef1653c4048cace3fbe20baa8e40a7',
    '24c834ea3d2df2734c7719d948d8585565abe83a',
    '4b735f1cbfea66f95ba78d6fb272e362247b8ffa',
    '300d534b2afe2e8d7395fadeea600b6170136c6f',
    '62879ef331e57844c027d9dd825a426f67fb865a',
    '0d12a6a10e21086b367dfa79950290150294d0f9',
    '4cf9a7071ed4bf38b55411a94d78593100e4c383',
    'b0177cc8b408b811a8708856efd1dc73227e2d0a',
    'c8297ec385a1d958851af626d1e0a0cc582eff17',
    '1da0a29006bc3d8d57ca295aa3c5e14ad9b5a5f7',
    '238ce4a90c14be2ea65aed922cf79bd7b15245eb',
    '11e72b5d0cedc1ec04aebad44abc5c472a394dfa',
    '65ddc4f1f09604ac6b99039e4ec5947f9e384a71',
    '33a020e95b5b9b0e4c87d391cee95daee0c1600b',
    'b52892a14e66e88cfc0f83d71b20c0ad93a12fb1',
    '0a66e5e5449b4573ec8b66a64627bb9189787437',
    'a880810c14517c24064ca2eb3ef0b8f8ef1cdaaf',
    '499e6c0625ec5bc195e7dd994162010f068e3e45',
    'b891eaea6c967e86f1579704ab59df0513021f10',
    'f052a8c1752d2a8c7d84c7bb14790962679b2f76',
    'c4a66e64a26e1c46991361815c17a21674b5f55e',
    '7d1f5934f564518724b1d886f50d8d0853239892',
    'a058db9f4273a9eec0db064aa40f95625209a4bd',
    'e1922b9728915f108625a011838a1ccdb055c480',
    '45ce807dd141fcc6c64dda3d55abdc902ba1cb79',
    'd0079b83e8f1c98190968fdc35b6595ea2bea937',
    '6ae246c69677afdadd5e20a43b0549385b9d1041',
    'd4199fd21e8202f80403e6e712c5da215859b5e5',
    'd477d1a59e42d1ae1ad02f931fa8fdb9480c5155',
    'd6deae32141f82658d5a02ccb1240874e151703d',
    'afbaeca63b165eda8cdb5eb42d654b109f52f51a',
    'b122b10de41ae6cc99971d7de5e7b4bbb9d5d2fe',
    '2a88f7ea8c4eb72f49128655d88df66c170d099b',
    '1c91ba39649720aee1b6f2000015e543eeb88aae',
    '67e492b77fbf874dabb857b348086d464e2bd9fb',
    '6bd28af856c8e33ac01940e42080033c7d9fa393',
    'ba1f2caac97c32c17c959c1167a1b327b3528d55',
    '45c323790a285fbd521d18ed6302fc4cdb57aa97',
    'f167359516785df58adb79fada6e629270156c16',
    '44f1d8b872708831b161f2a9ed3e900f76b16961',
    '75da5dee8869507c6b393522fcd4363803024eaa',
    '6f0f3cbe4f9bedd46379dbfc8b12ad0c2cfcd52e',
    'eebe8262462c09cd808cad1e475efb63118a7b7b',
    '33d600b7ff0e1796a86136f565d3036b519ab417',
    '10c6772b08cc3e7c3dad379699d2c441877a8da7',
    '4b6f737369e349e5cb3b60b0aab331472b8af2dc',
    'cd20f1dd57d8701436e457196aec2730017ff77a',
    '6e6b1851802e00d837196a67c4f4e5945dae3b08',
    '57184a9748e6d28afa106ec72715c08d6e1be890',
    'c604d845fd609c7b34f0ce5304c404060bbde71f',
    'cd89783effc008200a5aeb05db326d56a6747b2e',
    'ef01c46aad1167226a33a0fe0dca85f17732b9d8',
    '406b98edad5218f5e844f8c5af8684e632de5914',
    '8948228ff820ece1ecfb908e268f84a685f3590a',
    '8679f22e5428a36c2390e00f634369ec675941d5',
    '7ff180362417fff6fc7b617e29a3d0fba86c75d2',
    'd63cf8d29efa0d31f8a3abbc79f0d6c8009855ac',
    '6b72f58d3ae5dbfdf81d7bb44e514ff033b9c5af',
    '1dc17d0144e2df47e8a7ffea6dd8f452ebef27db',
    'd243cda8f707790d4209e0e17eab7322b087e325',
    '5e4ddf1b39d0846b14ac2156e78ae69b5717e9ac',
    'e6a8a38e3746852e232b115fb398df11e07027b4',
    'fdfcf7be5f8ed71c957f6c92d0bdfc213d2ca65f',
    '48a79019a6776aca4ea327dc296f659cb4952421',
    'ece6ab30d43a1c476aa9c0fa86bf28bab6aa1778',
    '5075310587362bdc67685094905b5dac02521b6f',
    '9396e3ff8777e5b28975a9d1773530e1de5521f1',
    'da4d72941cf97a24aabe68a683d6a553bd3e1668',
    '56c6f7218977f2e15ea462e227a2883a2c94d021',
    'a779507ade23af696b453b0cd256399778b15b14',
    '62142172f07fc626f3c2aa700ae20e13aa569180',
    '48989992ac5e62a57ad2f21b37ec81fbddb92515',
    '89b13536c4ee9496d0586b298874077f14c6e91e',
    '8d244af598510aaab21e740878d0505d064ea7fe',
    '70095d7caa4da109dec5ae911aeb1ebe26a8a60a',
    '8aacf2875cb2ff15b3079a22cde2467911a1faa6',
    '48bd1f2e7cb8f8caecefbedba773453d16a8edb5',
    '22a974062d405e318b96caad6d2acf41e637bb63',
    '9302850d4c5eebc6b267ac4e53ca8d1b00719d4e',
    '83c2fa83ef7dbd538931eb10c0f536a428475291',
    '5c618cc7a90db6b0d8add12278ec8c08c313e06e',
    '190eff24807faf76e1047bf021ae4b1b85cdfeba',
    '79b7d69f3e6db9d114b300f45472643ff847aa14',
  }
  for i = 1, #message do
    self:assert_equal(sha1(message:sub(1, i)), sha1s[i])
  end
end


Sha1Test:run_if_main()


return Sha1Test
