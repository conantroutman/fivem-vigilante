local isOnMission = false
local veh
local timer = 0
local crimeSceneLocation
local criminals = {}
local target
local missionType = 1

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		if IsPedInAnyVehicle(PlayerPedId(), false) then
			veh = GetVehiclePedIsIn(PlayerPedId(), false)
			-- The player is in a cop car and is standing still
			if IsPedInAnyPoliceVehicle(PlayerPedId()) and GetVehicleClass(veh) == 18 and GetEntitySpeed(veh) == 0 and not isOnMission then
				SetHornEnabled(veh, false)
				-- Disable headlight and horn controls (E and right d-pad)
				DisableControlAction(8, 74, true)
				DisableControlAction(0, 86, true)
				if GetPlayerWantedLevel(PlayerId()) == 0 then
					SetTextComponentFormat("STRING")
					AddTextComponentString("Press ~INPUT_CONTEXT~ when stopped to start vigilante missions.")
					DisplayHelpTextFromStringLabel(0, 0, 1, -1)
				else
					SetTextComponentFormat("STRING")
					AddTextComponentString("Clear your wanted level to start vigilante missions.")
					DisplayHelpTextFromStringLabel(0, 0, 1, -1)
				end

				if IsControlJustReleased(13, 51) and GetPlayerWantedLevel(PlayerId()) == 0 and not isOnMission then
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

function CreateCriminal(coords)
	local pedHash = "g_m_y_lost_01"
	
	if not HasModelLoaded( pedHash ) then
        RequestModel( pedHash )
        --Wait 200ms to load the model into memory
        Wait(200)
    end

	local criminal = CreatePed(23, pedHash, coords.x, coords.y, coords.z, true, false)
	SetPedRelationshipGroupHash(criminal, GetHashKey("HATES_PLAYER"))
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
	SetPedRelationshipGroupHash(criminal, GetHashKey("HATES_PLAYER"))
	SetBlockingOfNonTemporaryEvents(criminal, true)
	SetPedCombatAttributes(criminal, 1, true)
	SetPedCombatAttributes(criminal, 2, true)
	SetPedCombatAttributes(criminal, 3, false)
	--SetPedAsEnemy(criminal, true)
	GiveWeaponToPed(criminal, "weapon_microsmg", 999, false, true)

	if seat == -1 then
		TaskVehicleDriveWander(criminal, vehicle, 15.0, 537657515)
	end

	local blip = AddBlipForEntity(criminal)
	SetBlipAsFriendly(blip, false)

	AddEntityIcon(criminal, "MP_Arrow")
	SetEntityIconColor(criminal, 255, 0, 0, 190)
	SetEntityIconVisibility(criminal, true)

	return criminal
end

function CreateCriminalCar(spawnLocation, heading)
	local playerCoords = GetEntityCoords(PlayerPedId())
	--local bool, spawnLocation, heading = GetNthClosestVehicleNodeWithHeading(playerCoords.x, playerCoords.y, playerCoords.z, 200, 9, 3.0, 2.5)
	--crimeSceneLocation = vector3(spawnLocation.x, spawnLocation.y, spawnLocation.z)

	local vehicles = {"emperor", "schafter", "asea", "asetrope", "cognoscenti", "cog55", "fugitive", "glendale", "ingot", "intruder", "premier", "primo", "regina", "stanier", "stratum", "surge", "warrener", "washington", "baller", "baller2", "cavalcade", "cavalcade2", "dubsta", "fq2", "granger", "gresley", "habanero", "huntley", "landstalker", "mesa", "patriot", "radius", "rocoto", "seminole", "serrano", "felon", "jackal", "oracle", "oracle2", "sultan", "buffalo", "buffalo2", "kuruma", "raiden", "v-str", "sugoi", "burrito3", "bison", "minivan", "rumpo", "speedo", "surfer", "youga"}
	local vehicleHash = vehicles[math.random(#vehicles)]
	while GetDisplayNameFromVehicleModel(GetHashKey(vehicleHash)) == "CARNOTFOUND" do
		print(vehicleHash .. " is an invalid vehicle model")
		vehicleHash = vehicles[math.random(#vehicles)]
	end

	if not HasModelLoaded(vehicleHash) then
        RequestModel(vehicleHash)
        --Wait 200ms to load the model into memory
        Wait(200)
	end

	local vehicle = CreateVehicle(vehicleHash, spawnLocation.x, spawnLocation.y, spawnLocation.z, heading, true, false)
	print("Stolen vehicle: " .. GetDisplayNameFromVehicleModel(GetHashKey(vehicleHash)))
	return vehicle
end

function AggroCriminals()
	if missionType == 1 then
		for _,v in pairs(criminals) do
			if GetPedInVehicleSeat(GetVehiclePedIsIn(v), -1) == v then
				TaskVehicleMissionPedTarget(v, GetVehiclePedIsIn(v), PlayerPedId(), 8, 999.0, 786988, 600)
			else
				TaskVehicleShootAtPed(v, PlayerPedId())
			end
		end
	elseif missionType == 2 then

	elseif missionType == 3 then
		TaskCombatPed(criminals[1], PlayerPedId(), 0, 16)
	end
end

function GenerateLocation()
	local playerCoords = GetEntityCoords(PlayerPedId())
	local isValidLocation, coords, heading = GetNthClosestVehicleNodeWithHeading(playerCoords.x, playerCoords.y, playerCoords.z, 200, 0, 3.0, 2.5)
	while not isValidLocation do
		isValidLocation, coords, heading = GetNthClosestVehicleNodeWithHeading(playerCoords.x, playerCoords.y, playerCoords.z, 200, 0, 3.0, 2.5)
	end
	--print(GetNameOfZone(coords))
	crimeSceneLocation = coords
	return coords, heading
end

-- Checks if all spawned criminal NPCs are dead
function IsCriminalsDead()
	local totalHealth = 0
	for _,v in pairs(criminals) do
		if GetEntityHealth(v) == 0 then
			RemoveBlip(GetBlipFromEntity(v))
		end
		totalHealth = totalHealth + GetEntityHealth(v)
	end

	if totalHealth == 0 then
		print("All criminals dead")
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

function IsGeneratedLocationCountryside(location)
	local result = false
	local countrysideZones = {"TONGVAH", "TONGVAV", "WINDF", "RTRAK", "SANCHIA", "MTCHIL", "LACT", "HUMLAB", "MTGORDO", "MTJOSE"}
	for _,v in pairs(countrysideZones) do
		if GetNameOfZone(location) == v then
			result = true
			break
		end
	end
	return result
end

function MissionOverSuccess()
	SetVehicleSiren(GetVehiclePedIsIn(PlayerPedId(), false), false)
	DrawMissionCompleteText("Crime scene cleaned up.")
	SetMaxWantedLevel(5)
	criminals = {}
	isOnMission = false
end

function MissionOverFail()
	SetVehicleSiren(GetVehiclePedIsIn(PlayerPedId(), false), false)
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

-- Set GPS route to crime scene
function SetTargetRoute()
	local blip = GetBlipFromEntity(criminals[1])
	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 1)
end

function StartMission()
	Citizen.CreateThread(function()
		local isAtCrimeScene = false
		--local location = GenerateLocation()
		StartRandomMission()
		SetTargetRoute()
		SetMaxWantedLevel(0)
		SetVehicleSiren(GetVehiclePedIsIn(PlayerPedId(), false), true)
		DisplayShardMessage()
		DrawMissionStartText(crimeSceneLocation)
		timer = SetTimer()
		StartTimer()
		CreateTimerBars()

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
	missionType = 1
	local vehicle = CreateCriminalCar(GenerateLocation())
	target = vehicle
	-- Create random number of criminals
	local random = math.random(4)
	for i = 1, random, 1 do 
		criminals[i] = CreateCriminalInCar(vehicle, i-2)
	end
end

function StartMissionGangActivity()
	local gangs = {
		{
			gang = 1,
			x = 0,
			y = 0,
			z = 0
		}
	}
end

function StartMissionSuspectOnFoot()
	print("Suspect on foot")
	missionType = 3
	GenerateLocation()
	local bool, location = GetSafeCoordForPed(crimeSceneLocation.x, crimeSceneLocation.y, crimeSceneLocation.z, true, 16)
	if not bool then
		StartRandomMission()
		return
	end
	--print(coords)
	--local isValidLocation, location = GetPointOnRoadSide(crimeSceneLocation.x, crimeSceneLocation.y, crimeSceneLocation.z)
	--while not bool do
	--	Citizen.Wait(1)
	--	print("Not valid location")
	--	bool, location = GetSafeCoordForPed(crimeSceneLocation.x, crimeSceneLocation.y, crimeSceneLocation.z, true, 16)
	--end
	criminals[1] = CreateCriminal(location)
end

function StartRandomMission()
	local random = math.random(2)
	if random == 1 then
		StartMissionStolenCar()
	elseif random == 2 then
		StartMissionSuspectOnFoot()
	end
end

function StartTimer()
	Citizen.CreateThread(function()
		while isOnMission and timer > 0 do
			Citizen.Wait(1000)
			timer = timer - 1
			--print(timer)
			if timer <= 5 and timer > 0 then
				PlaySoundFrontend(-1, "MP_5_SECOND_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
			elseif timer == 0 then
				PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 1)
			end
		end
	end)
end

-- Create UI element for mission timer
function CreateTimerBars()
	local _timerBarPool = NativeUI.TimerBarPool()

	local timerItem = NativeUI.CreateTimerBar("TIME LEFT")
	timerItem:SetTextColor(255, 255, 255, 255)
	--Item:SetTextTimerBarColor(0, 255, 255, 255) --You can define a text color
	_timerBarPool:Add(timerItem)

	Citizen.CreateThread(function()
		while isOnMission and timer > 0 do
			Citizen.Wait(1)
			if timer <= 5 then
				timerItem:SetTextColor(255, 0, 0, 255)
				timerItem:SetTextTimerBarColor(255, 0, 0, 255)
			end
			timerItem:SetTextTimerBar(FormatTime())
			_timerBarPool:Draw()
		end
	end)
end

-- Convert timer to MM:SS format
function FormatTime()
	local minutes = math.floor(math.fmod(timer,3600)/60)
	local seconds = math.floor(math.fmod(timer,60))
	return string.format("%02d:%02d",minutes,seconds)
end

function PlayPoliceRadio()
	PlayPoliceReport("SCRIPTED_SCANNER_REPORT_CAR_STEAL_2_01", 0.0)
end

-- Calculate the mission timer based on distance to crime scene and vehicle speed
function SetTimer()
	local distance = CalculateTravelDistanceBetweenPoints(GetEntityCoords(PlayerPedId()), crimeSceneLocation)
	local topSpeed = GetVehicleMaxSpeed(GetVehiclePedIsIn(PlayerPedId()))
	--print(distance)
	--print(topSpeed)
	return math.floor(distance/topSpeed * 5)
end