---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [OnAppPermissionChanged]: appRevoked:true
--
-- Description:
-- In case the app is currently registered and in any
-- HMILevel and in result of PTU gets "null" policies,
-- SDL must send OnAppPermissionChanged (appRevoked: true) to HMI
--
-- Used preconditions:
-- appID="123abc" is registered to SDL
-- any PolicyTableUpdate trigger happens
--
-- Performed steps:
-- PTU is valid -> application with appID=123abc gets "null" policy
--
-- Expected result:
-- SDL -> HMI: OnAppPermissionChanged (<appID>, appRevoked=true, params)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local testCasesForPolicyAppIdManagament = require("user_modules/shared_testcases/testCasesForPolicyAppIdManagament")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")

-- TODO (dtrunov): Should be removed when issue: "ATF does not stop HB timers by closing session and connection is fixed"
config.defaultProtocolVersion = 2
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")
local mobile_session = require("mobile_session")

--[[ Local Variables ]]
local HMIAppID

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Pecondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

function Test:UpdatePolicy()
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_23511_1.json")
end

function Test:Pre_StartNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RegisterNewApp()
  config.application1.registerAppInterfaceParams.appName = "App_test"
  config.application1.registerAppInterfaceParams.appID = "123abc"
  local correlationId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      HMIAppID = data.params.application.appID
      self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID
    end)

  self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
  self.mobileSession2:ExpectResponse(correlationId, { success = true })
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:PerformPTU_Check_OnAppPermissionChanged()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_23511.json")
  EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", { appRevoked = true, appID = HMIAppID})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test:Postcondition_SDLForceStop()
  commonFunctions:SDLForceStop(self)
end

return Test