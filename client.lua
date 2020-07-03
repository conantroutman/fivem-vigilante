local isOnMission = false
local veh
local timer = 0

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		if IsPedInAnyVehicle(PlayerPedId(), false) then
			veh = GetVehiclePedIsIn(PlayerPedId(), false)
			-- The player is in a cop car and is standing still
			if IsPlayerInCopCar() and GetEntitySpeed(veh) == 0 and not isOnMission then
				SetHornEnabled(veh, false)
				if GetPlayerWantedLevel(PlayerId()) == 0 then
					SetTextComponentFormat("STRING")
					AddTextComponentString("Press ~INPUT_PICKUP~ when stopped to start vigilante missions.")
					DisplayHelpTextFromStringLabel(0, 0, 1, -1)
				else
					SetTextComponentFormat("STRING")
					AddTextComponentString("Clear your wanted level to start vigilante missions.")
					DisplayHelpTextFromStringLabel(0, 0, 1, -1)
				end

				if IsControlJustReleased(13, 38) and not isOnMission then
					isOnMission = true
					StartMission()
				end
			else
				SetHornEnabled(veh, true)
			end
		end
	end
end)

-- Check if the player is in a police vehicle
function IsPlayerInCopCar()
	local items = { "police", "police2", "police3", "police4", "policeb", "policet", "sheriff", "sheriff2", "fbi", "fbi2", "riot" }
	local vehicleModel = GetEntityModel(veh)

	for _,v in pairs(items) do
		if IsVehicleModel(veh, v) then
			return true
		end
	end
	--local copCars = {"police", "police2", "police3", "police4", "sheriff", "sheriff2", "fbi", "fbi2"}
	return false
end

function DisplayShardMessage()
	local scaleform = RequestScaleformMovie("MP_BIG_MESSAGE_FREEMODE")
	while not HasScaleformMovieLoaded(scaleform) do
		Citizen.Wait(0)
	end

	PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)

	BeginScaleformMovieMethod(scaleform, "DO_SHARD")
	ScaleformMovieMethodAddParamInt(1)
	ScaleformMovieMethodAddParamBool(false)
	ScaleformMovieMethodAddParamInt(12)
	ScaleformMovieMethodAddParamInt(2)
	ScaleformMovieMethodAddParamBool(false)
	EndScaleformMovieMethod()

	BeginScaleformMovieMethod(scaleform, "SHARD_SET_TEXT")
	ScaleformMovieMethodAddParamTextureNameString("~y~VIGILANTE~y~")
	ScaleformMovieMethodAddParamTextureNameString("")
	EndScaleformMovieMethod()

	BeginScaleformMovieMethod(scaleform, "SHARD_ANIM_DELAY")
	ScaleformMovieMethodAddParamInt(2)
	EndScaleformMovieMethod()

	Citizen.CreateThread(function()
		while isOnMission do -- Draw the scaleform every frame
		  Citizen.Wait(0)
		  DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
		end
	end)  
end

function DrawMissionStartText(location, isGang)
	local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(location.x, location.y, location.z))
	BeginTextCommandPrint("STRING")
	if isGang then
		AddTextComponentString("Go to " .. streetName .. " and take out the ~r~criminals.~r~")
	else
		AddTextComponentString("Go to " .. streetName .. " and take out the ~r~criminal.~r~")
	end
	EndTextCommandPrint(5000, true)
end

function DrawMissionCompleteText(text)
	BeginTextCommandPrint("STRING")
	AddTextComponentString(text)
	EndTextCommandPrint(7000, true)
end

function DrawArrivedAtCrimeSceneText()
	BeginTextCommandPrint("STRING")
	AddTextComponentString("You are at the crime scene. Take out any criminals in this precinct.")
	EndTextCommandPrint(7000, true)
end

function SpawnCriminal(location)
	local isRoadSide, criminalCoords = GetPointOnRoadSide(location.x, location.y, location.z)
	local pedHash = "g_m_y_lost_01"
	
	if not HasModelLoaded( pedHash ) then
        RequestModel( pedHash )
        --Wait 200ms to load the model into memory
        Wait(200)
    end

	local criminal = CreatePed(23, pedHash, criminalCoords.x, criminalCoords.y, criminalCoords.z, true, false)
	SetBlockingOfNonTemporaryEvents(criminal, true)
	GiveWeaponToPed(criminal, "weapon_pistol", 999, false, true)
	TaskCombatPed(criminal, PlayerPedId(), 0, 16)
	TaskWanderStandard(criminal, 10.0, 10)
	local blip = AddBlipForEntity(criminal)
	SetBlipAsFriendly(blip, false)

	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 1)

	return criminal
end

function SpawnCriminalInCar(location, seat)
	local playerCoords = GetEntityCoords(PlayerPedId())
	local bool, spawnLocation, heading = GetNthClosestVehicleNodeWithHeading(playerCoords.x, playerCoords.y, playerCoords.z, 1, 9, 3.0, 2.5)
	local pedHash = "g_m_y_lost_01"
	local criminalVehicles = {"emperor", "schafter", "asea", "asetrope", "cognoscenti", "cog55", "fugitive", "glendale", "ingot", "intruder", "premier", "primo", "regina", "stanier", "stratum", "surge", "warrener", "washington", "baller", "baller2", "cavalcade", "cavalcade2", "dubsta", "fq2", "granger", "gresley", "habanero", "huntley", "landstalker", "mesa", "patriot", "radius", "rocoto", "seminole", "serrano", "felon", "jackal", "oracle", "oracle2", "sultan"}
	local vehicleHash = criminalVehicles[math.random(#criminalVehicles)]

	if not HasModelLoaded( pedHash ) then
        RequestModel(pedHash)
        --Wait 200ms to load the model into memory
        Wait(200)
	end

	if not HasModelLoaded(vehicleHash) then
        RequestModel(vehicleHash)
        --Wait 200ms to load the model into memory
        Wait(200)
	end

	local criminalVehicle = CreateVehicle(vehicleHash, location.x, location.y, location.z, heading, true, false)
	local criminal = CreatePedInsideVehicle(criminalVehicle, 23, pedHash, -1, true, false)
	SetPedAsEnemy(criminal, true)
	GiveWeaponToPed(criminal, "weapon_pistol", 999, false, true)
	TaskVehicleDriveWander(criminal, criminalVehicle, 120.0, 786603)

	local blip = AddBlipForEntity(criminal)
	SetBlipAsFriendly(blip, false)

	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 1)

	return criminal
end

function GenerateLocation()
	local playerCoords = GetEntityCoords(PlayerPedId())
	local isVehicleNode, randomNode = GetNthClosestVehicleNode(playerCoords.x, playerCoords.y, playerCoords.z, 600)
	return randomNode
end

function MissionOverSuccess()
	DrawMissionCompleteText("Crime scene cleaned up.")
	isOnMission = false
end

function MissionOverFail()
	DrawMissionCompleteText("The ~r~criminal~r~ ~s~got away.~s~")
	isOnMission = false
end

function StartMission()
	Citizen.CreateThread(function()
		local location = GenerateLocation()
		local criminal = SpawnCriminalInCar(location)
		SetMaxWantedLevel(0)
		DisplayShardMessage()
		DrawMissionStartText(location, false)
		timer = 60
		StartTimer()

		while true do
			Citizen.Wait(0)

			-- Criminal is killed
			if GetEntityHealth(criminal) == 0 then
				RemoveBlip(GetBlipFromEntity(criminal))
				MissionOverSuccess()
				break
			end

			-- Player died
			if GetEntityHealth(PlayerPedId()) == 0 then
				RemoveBlip(GetBlipFromEntity(criminal))
				MissionOverFail()
				break
			end

			-- Time is up
			if timer == 0 then
				RemoveBlip(GetBlipFromEntity(criminal))
				MissionOverFail()
				break
			end
		end
	end)
end

function StartTimer()
	Citizen.CreateThread(function()
		while isOnMission and timer > 0 do
			Citizen.Wait(1000)
			timer = timer - 1
			print(timer)
		end
	end)
end