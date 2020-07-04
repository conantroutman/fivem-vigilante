local isOnMission = false
local veh
local timer = 0
local crimeSceneLocation
local criminals = {}
local target

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		if IsPedInAnyVehicle(PlayerPedId(), false) then
			veh = GetVehiclePedIsIn(PlayerPedId(), false)
			-- The player is in a cop car and is standing still
			if IsPedInAnyPoliceVehicle(PlayerPedId()) and GetVehicleClass(veh) == 18 and GetEntitySpeed(veh) == 0 and not isOnMission then
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

function DrawMissionStartText(location)
	local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(location.x, location.y, location.z))
	BeginTextCommandPrint("STRING")
	if #criminals > 1 then
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
	AddTextComponentString("You are at the crime scene. Take out any ~r~criminals~r~ ~s~in this precinct.~s~")
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

function CreateCriminal(coords)
	local pedHash = "g_m_y_lost_01"
	
	if not HasModelLoaded( pedHash ) then
        RequestModel( pedHash )
        --Wait 200ms to load the model into memory
        Wait(200)
    end

	local criminal = CreatePed(23, pedHash, coords.x, coords.y, coords.z, true, false)
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

function CreateCriminalInCar(vehicle, seat)
	local pedHash = "g_m_y_lost_01"

	if not HasModelLoaded( pedHash ) then
        RequestModel(pedHash)
        --Wait 200ms to load the model into memory
        Wait(200)
	end

	local criminal = CreatePedInsideVehicle(vehicle, 23, pedHash, seat, true, false)
	SetPedAsEnemy(criminal, true)
	GiveWeaponToPed(criminal, "weapon_pistol", 999, false, true)

	if seat == -1 then
		TaskVehicleDriveWander(criminal, vehicle, 60.0, 786603)
	end

	local blip = AddBlipForEntity(criminal)
	SetBlipAsFriendly(blip, false)

	return criminal
end

function CreateCriminalCar(location)
	local playerCoords = GetEntityCoords(PlayerPedId())
	local bool, spawnLocation, heading = GetNthClosestVehicleNodeWithHeading(playerCoords.x, playerCoords.y, playerCoords.z, 60, 9, 3.0, 2.5)
	crimeSceneLocation = vector3(spawnLocation.x, spawnLocation.y, spawnLocation.z)

	local vehicles = {"emperor", "schafter", "asea", "asetrope", "cognoscenti", "cog55", "fugitive", "glendale", "ingot", "intruder", "premier", "primo", "regina", "stanier", "stratum", "surge", "warrener", "washington", "baller", "baller2", "cavalcade", "cavalcade2", "dubsta", "fq2", "granger", "gresley", "habanero", "huntley", "landstalker", "mesa", "patriot", "radius", "rocoto", "seminole", "serrano", "felon", "jackal", "oracle", "oracle2", "sultan"}
	local vehicleHash = vehicles[math.random(#vehicles)]

	if not HasModelLoaded(vehicleHash) then
        RequestModel(vehicleHash)
        --Wait 200ms to load the model into memory
        Wait(200)
	end

	local vehicles = CreateVehicle(vehicleHash, spawnLocation.x, spawnLocation.y, spawnLocation.z, heading, true, false)
	return vehicles
end

function AggroCriminals()
	for _,v in pairs(criminals) do
		if GetPedInVehicleSeat(GetVehiclePedIsIn(v), -1) == v then
			TaskVehicleMissionPedTarget(v, GetVehiclePedIsIn(v), PlayerPedId(), 8, 999.0, 524845, 600)
		else
			TaskVehicleShootAtPed(v, PlayerPedId())
		end
	end
end

function GenerateLocation()
	local playerCoords = GetEntityCoords(PlayerPedId())
	local isVehicleNode, randomNode = GetNthClosestVehicleNode(playerCoords.x, playerCoords.y, playerCoords.z, 600)
	return randomNode
end

function IsCriminalsDead()
	local totalHealth = 0
	for _,v in pairs(criminals) do
		if GetEntityHealth(v) == 0 then
			RemoveBlip(GetBlipFromEntity(v))
		end
		totalHealth = totalHealth + GetEntityHealth(v)
	end

	if totalHealth == 0 then
		return true
	else
		return false
	end
end

function ClearCriminalBlips()
	for _,v in pairs(criminals) do
		RemoveBlip(GetBlipFromEntity(v))
	end
end

function IsPlayerNearCrimeScene()
	local playerCoords = GetEntityCoords(PlayerPedId())
	local criminalCoords = GetEntityCoords(criminals[1])

	if Vdist(playerCoords.x, playerCoords.y, playerCoords.z, criminalCoords.x, criminalCoords.y, criminalCoords.z) < 50 then
		return true
	else
		return false
	end
end

function MissionOverSuccess()
	DrawMissionCompleteText("Crime scene cleaned up.")
	SetMaxWantedLevel(5)
	criminals = {}
	isOnMission = false
end

function MissionOverFail()
	if #criminals > 1 then
		DrawMissionCompleteText("The ~r~criminals~r~ ~s~got away.~s~")
	else
		DrawMissionCompleteText("The ~r~criminal~r~ ~s~got away.~s~")
	end
	SetMaxWantedLevel(5)
	ClearAllBlipRoutes()
	ClearCriminalBlips()
	criminals = {}
	isOnMission = false
end

function SetTargetRoute()
	local blip = GetBlipFromEntity(criminals[1])
	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 1)
end

function StartMission()
	Citizen.CreateThread(function()
		local isAtCrimeScene = false
		--local location = GenerateLocation()
		StartMissionStolenCar()
		SetTargetRoute()
		SetMaxWantedLevel(0)
		DisplayShardMessage()
		DrawMissionStartText(crimeSceneLocation)
		timer = 60
		StartTimer()

		while true do
			Citizen.Wait(0)
			if IsPlayerNearCrimeScene() and not isAtCrimeScene then
				-- Stop timer
				timer = 0
				DrawArrivedAtCrimeSceneText()
				ClearAllBlipRoutes()
				AggroCriminals()
				isAtCrimeScene = true
			end

			-- Criminal is killed
			if IsCriminalsDead() then
				MissionOverSuccess()
				break
			end

			-- Player died
			if GetEntityHealth(PlayerPedId()) == 0 then
				MissionOverFail()
				break
			end

			-- Time is up
			if timer == 0 and not isAtCrimeScene then
				MissionOverFail()
				break
			end
		end
	end)
end

function StartMissionStolenCar()
	PlayPoliceReport("SCRIPTED_SCANNER_REPORT_CAR_STEAL_4_01", 0.0)
	local vehicle = CreateCriminalCar()
	target = vehicle
	-- Create random number of criminals
	local random = math.random(4)
	for i = 1, random, 1 do 
		criminals[i] = CreateCriminalInCar(vehicle, i-2)
	end
end

function StartMissionGangActivity()

end

function StartMissionSuspectOnFoot()

end

function StartTimer()
	Citizen.CreateThread(function()
		while isOnMission and timer > 0 do
			Citizen.Wait(1000)
			timer = timer - 1
			--print(timer)
			if timer < 5 and timer > 0 then
				PlaySoundFrontend(-1, "MP_5_SECOND_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
			elseif timer == 0 then
				PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 1)
			end
		end
	end)
end