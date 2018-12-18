---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
-- Description:
-- In case:
-- 1) OnDriverDistraction notification is  allowed by Policy for (FULL, LIMITED, BACKGROUND, NONE) HMILevel
-- 2) In Policy "lock_screen_dismissal_enabled" parameter is missing
-- 3) App registered (HMI level NONE)
-- 4) HMI sends OnDriverDistraction notification with all mandatory fields
-- 5) Policy Table update ("lock_screen_dismissal_enabled" = true)
-- 6) HMI sends OnDriverDistraction notification with all mandatory fields
-- SDL does:
-- 1) Send OnDriverDistraction notification to mobile without "lockScreenDismissalEnabled" before PTU
-- 2) Send OnDriverDistraction notification to mobile with "lockScreenDismissalEnabled"=true after PTU
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SDL_Passenger_Mode/commonPassengerMode')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local lockScreenDismissalEnabled = true

--[[ Local Functions ]]
local function ptUpdate(pPT)
  pPT.policy_table.module_config.lock_screen_dismissal_enabled = lockScreenDismissalEnabled
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set LockScreenDismissalEnabled", common.updatePreloadedPT, { nil })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("OnDriverDistraction ON/OFF missing", common.onDriverDistraction, { nil })
runner.Step("Policy Table Update", common.policyTableUpdate, { ptUpdate })
runner.Step("OnDriverDistraction ON/OFF true", common.onDriverDistraction, { lockScreenDismissalEnabled })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
