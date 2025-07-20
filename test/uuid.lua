local BaseTest = require 'lualib.basetest'
local oo = require 'lualib.oo'
local uuid = require 'lualib.uuid'
local UUID = uuid.UUID


local UuidTest = oo.class(BaseTest)


function UuidTest:hextobin(hexdata)
  return hexdata:gsub('-', ''):gsub('..', function(b)return string.char(tonumber(b, 16))end)
end

function UuidTest:assert_uuid(uuid, hex)
  self:assert_equal(tostring(uuid), hex)
  self:assert_equal(uuid:bytes(), self:hextobin(hex))
end


function UuidTest:test_v4()
  local function file_mock(bindata)
    return {read=function(fd, n) self:assert_equal(n, 16) return bindata end}
  end
  for _, case in pairs{
    {hex='5a7c6942-e937-bb9b-f8a9-8423fcdeca3e', res='05c379e1-736b-4a38-b3cc-d58cf6384e9e'},
    {hex='35e796ae-de41-1669-bb45-bf6359343c56', res='cf2751f0-2f27-4eaa-a718-0743641653af'},
    {hex='6409345d-cdeb-f7b9-ef44-75a561a076a5', res='12a8cf08-6417-4c4e-b96c-837a7c5fcbca'},
  } do
    UUID.init_state(file_mock(self:hextobin(case.hex)))
    self:assert_uuid(uuid.v4(), case.res)
  end
  self:assert_uuid(uuid.v4(), '2caabe18-6c5f-4073-b6e1-95b0bef0bb54')
end


function UuidTest:test_v5()
  for _, case in pairs {
    {ns='beec419c-ea40-9cc3-cf65-7bcea8e906c5', name='foo!', res='f5258136-5aa9-57c5-8d31-0d6091fc09ab'},
    {ns='0146ab0e-e15e-43a6-8dc3-5a532d79df1d', name='完璧', res='4ff41947-b7da-5173-b4a6-455ffee46534'}
  } do
    local uuid = uuid.v5(UUID:new(case.ns), case.name)
    self:assert_uuid(uuid, case.res)
  end
end


UuidTest:run_if_main()


return UuidTest
