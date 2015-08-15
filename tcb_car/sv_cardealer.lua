/*---------------------------------------------------------------------------
	
	Creator: TheCodingBeast - TheCodingBeast.com
	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
	
---------------------------------------------------------------------------*/

--[[---------------------------------------------------------
	Include
-----------------------------------------------------------]]
include("sh_config.lua")

--[[---------------------------------------------------------
	Spawn Dealer
-----------------------------------------------------------]]
util.AddNetworkString("TCBDealerMenu")
util.AddNetworkString("TCBDealerSpawn")
util.AddNetworkString("TCBDealerPurchase")
util.AddNetworkString("TCBDealerSell")
util.AddNetworkString("TCBDealerChat")

--[[---------------------------------------------------------
	Database Setup
-----------------------------------------------------------]]
function TCBDealer.databaseSetup()

	local AUTOINCREMENT = MySQLite.isMySQL() and "AUTO_INCREMENT" or "AUTOINCREMENT"

	MySQLite.query([[
		CREATE TABLE IF NOT EXISTS tcb_cardealer (
			id INTEGER NOT NULL PRIMARY KEY ]]..AUTOINCREMENT..[[,
			steamID VARCHAR(50) NOT NULL,
			vehicle VARCHAR(255) NOT NULL
		)
	]])

end
hook.Add("DarkRPDBInitialized", "TCBDealer.databaseSetup", TCBDealer.databaseSetup)

--[[---------------------------------------------------------
	Spawn Dealer
-----------------------------------------------------------]]
function TCBDealer.spawnDealer()

	--> Map Check
	if !TCBDealer.dealerSpawns[game.GetMap()] then
		ErrorNoHalt("Missing car dealer spawn points for map: "..game.GetMap())
		return 
	end

	--> Loop Dealers
	for k,v in pairs(TCBDealer.dealerSpawns[game.GetMap()]) do

		--> Dealer
		local dealer = ents.Create("base_ai")
		dealer:SetPos(v.pos + Vector(0, 0, 10))
		dealer:SetAngles(v.ang)
		dealer:SetModel(v.mdl)
		dealer:SetHullType(HULL_HUMAN)
		dealer:SetHullSizeNormal()
		dealer:SetNPCState(NPC_STATE_SCRIPT)
		dealer:SetSolid(SOLID_BBOX)
		dealer:CapabilitiesAdd(bit.bor(CAP_ANIMATEDFACE, CAP_TURN_HEAD))
		dealer:SetUseType(SIMPLE_USE)
		dealer:Spawn()
		dealer:DropToFloor()
		dealer.id = k

		--> Bubble
		local bubble = ents.Create("base_anim")
		bubble:SetPos(v.pos + Vector(0, 0, 25))
		bubble:SetAngles(v.ang)
		bubble:SetModel("models/extras/info_speech.mdl")
		bubble:SetMoveType(MOVETYPE_NONE)
		bubble:SetSolid(SOLID_NONE)
		bubble:Spawn()

		--> Input
		function dealer:AcceptInput(name, activator, caller)
			if name == "Use" and IsValid(caller) then
				
				--> Variables
				local vehicles = {}

				--> Vehicles
				MySQLite.query(string.format([[SELECT * FROM tcb_cardealer WHERE steamID = %s]], MySQLite.SQLStr(caller:SteamID())), function(data)
					for k, v in pairs(data or {}) do
						table.insert(vehicles, v.vehicle)
					end
				end)

				--> Network
				net.Start("TCBDealerMenu")
					net.WriteTable(vehicles)
					net.WriteInt(dealer.id, 32)
				net.Send(caller)

			end
		end

	end

	--> Precache
	if TCBDealer.settings.precache then
		for k,v in pairs(TCBDealer.vehicleTable) do
			
			util.PrecacheModel(v.mdl)

		end	
	end

	--> Version
	timer.Create("CarDealerFiVersion", 10, 1, function()
		TCBDealer.versionCheck()
	end)

end
hook.Add("InitPostEntity", "TCBDealer.spawnDealer", TCBDealer.spawnDealer)

--[[---------------------------------------------------------
	Version Check
-----------------------------------------------------------]]
local versionCheck = 0
function TCBDealer.versionCheck()

	// Variables
	versionCheck = versionCheck+1;
	local newVersion = nil

	// HTTP
	http.Fetch("https://raw.githubusercontent.com/TheCodingBeast/TCB_CarDealer/master/version.txt",
		function(body, len, headers, code)

			// Variables
			newVersion = tonumber(body)

			// Check
			if TCBDealer.version < newVersion then
				timer.Create("CarDealerVersion", 30, 0, function()
					MsgC(Color(0, 255, 0), "[TCB] There is a new version of 'TCB Car Dealer' available.\n")
				end)
			else
				MsgC(Color(0, 255, 0), "[TCB] Car Dealer is up to date.\n")
			end

		end,
		function(error)

			// Warn
			if versionCheck != 1 then
				MsgC(Color(255, 0, 0), "[TCB] There was an error verifying the version.\n"..error.."\n")
			end

			// Timer
			timer.Create("CarDealerReVersion", 10, 1, function()
				TCBDealer.versionCheck()
			end)

		end
	)

end

--[[---------------------------------------------------------
	Purchase Vehicle
-----------------------------------------------------------]]
function TCBDealer.purchaseVehicle(length, ply)

	--> Vehicle
	local vehID = net.ReadString()
	if !TCBDealer.vehicleTable[vehID] then 
		DarkRP.notify(ply, 1, 4, "The requested vehicle is not for sale.") 
		return 
	end
	vehicle = TCBDealer.vehicleTable[vehID]

	--> CustomCheck
	if vehicle.customCheck and !vehicle.customCheck(ply) then 
		if vehicle.CustomCheckFailMsg then
			DarkRP.notify(ply, 1, 4, vehicle.CustomCheckFailMsg)
		else
			DarkRP.notify(ply, 1, 4, "This vehicle is currently not available for you.")
		end
		return
	end

	--> Money
	if !ply:canAfford(vehicle.price) then
		DarkRP.notify(ply, 1, 4, "The requested vehicle is not for sale.") 
		return
	end
	ply:addMoney(-vehicle.price)

	--> Purchase
	MySQLite.query(string.format([[INSERT INTO tcb_cardealer (steamID, vehicle) VALUES (%s, %s)]], MySQLite.SQLStr(ply:SteamID()), MySQLite.SQLStr(vehID)))

	--> Notify
	DarkRP.notify(ply, 3, 4, "You bought a "..vehicle.name.." for "..DarkRP.formatMoney(vehicle.price).."!")

end
net.Receive("TCBDealerPurchase", TCBDealer.purchaseVehicle)

--[[---------------------------------------------------------
	Sell Vehicle
-----------------------------------------------------------]]
function TCBDealer.sellVehicle(length, ply)

	--> Vehicle
	local vehID = net.ReadString()
	if !TCBDealer.vehicleTable[vehID] then 
		DarkRP.notify(ply, 1, 4, "The requested vehicle can't be sold.") 
		return 
	end
	vehicle = TCBDealer.vehicleTable[vehID]

	--> Own
	local vehOwn = {}
	MySQLite.query(string.format([[SELECT * FROM tcb_cardealer WHERE steamID = %s AND vehicle = %s]], MySQLite.SQLStr(ply:SteamID()), MySQLite.SQLStr(vehID)), function(data)
		vehOwn = data or {}
	end)

	if table.Count(vehOwn) == 0 then
		DarkRP.notify(ply, 1, 4, "The requested vehicle is not in you garage.") 
		return 
	end

	--> Current
	TCBDealer.removeVehicle(ply)

	--> Money
	local amount = vehicle.price*(TCBDealer.settings.salePercentage/100)
	ply:addMoney(amount)

	--> Sell
	MySQLite.query(string.format([[DELETE FROM tcb_cardealer WHERE steamID = %s AND vehicle = %s]], MySQLite.SQLStr(ply:SteamID()), MySQLite.SQLStr(vehID)))

	--> Notify
	DarkRP.notify(ply, 3, 4, "You sold your "..vehicle.name.." for "..DarkRP.formatMoney(amount).."!")

end
net.Receive("TCBDealerSell", TCBDealer.sellVehicle)

--[[---------------------------------------------------------
	Spawn Vehicle
-----------------------------------------------------------]]
function TCBDealer.spawnVehicle(length, ply)

	--> Network
	local vehID = net.ReadString()
	local dealerID = net.ReadInt(32)
	local testDrive = net.ReadBool() or false

	--> Vehicle
	if !TCBDealer.vehicleTable[vehID] then 
		DarkRP.notify(ply, 1, 4, "The requested vehicle can't be spawned.") 
		return 
	end
	vehicle = TCBDealer.vehicleTable[vehID]

	--> Own
	if !testDrive then
		
		local vehOwn = {}
		MySQLite.query(string.format([[SELECT * FROM tcb_cardealer WHERE steamID = %s AND vehicle = %s]], MySQLite.SQLStr(ply:SteamID()), MySQLite.SQLStr(vehID)), function(data)
			vehOwn = data or {}
		end)

		if table.Count(vehOwn) == 0 then
			DarkRP.notify(ply, 1, 4, "The requested vehicle is not in you garage.") 
			return 
		end

	end

	--> Current
	TCBDealer.removeVehicle(ply)

	--> Dealer
	if !TCBDealer.dealerSpawns[game.GetMap()][dealerID] then
		DarkRP.notify(ply, 1, 4, "The car dealer wasn't found.") 
		return 
	end
	local dealer = TCBDealer.dealerSpawns[game.GetMap()][dealerID]
	
	local dealerResult = TCBDealer.dealerRange(ply, dealer)
	if !dealerResult then
		DarkRP.notify(ply, 1, 4, "You are not in range of the car dealer!") 
		return 
	end

	--> Spawns
	local spawnPoint = {}

	for k,v in pairs(dealer.spawns) do
		local entities = ents.FindInBox(Vector(v.pos.x + 100, v.pos.y + 100, v.pos.z - 150), Vector(v.pos.x - 100, v.pos.y - 100, v.pos.z + 150))
		
		local found = 0
		for _,v in pairs(entities) do
			if v:GetClass() != "physgun_beam" then
				found = 1
				break
			end
		end

		if found == 0 then
			spawnPoint = v
			break
		end
	end

	if table.Count(spawnPoint) == 0 then
		DarkRP.notify(ply, 1, 4, "No spawn point was found.") 
		return 
	end

	--> Spawn
	local vehicleList = list.Get("Vehicles")[vehID]
	if !vehicleList then return end

	local spawnedVehicle = ents.Create(vehicleList.Class)
	if !spawnedVehicle then return end

	spawnedVehicle:SetModel(vehicleList.Model)

	if vehicleList.KeyValues then
		for k, v in pairs(vehicleList.KeyValues) do
			spawnedVehicle:SetKeyValue(k, v)
		end
	end

	spawnedVehicle:SetPos(spawnPoint.pos)
	spawnedVehicle:SetAngles(spawnPoint.ang)
	spawnedVehicle:Spawn()
	spawnedVehicle:Activate()

	spawnedVehicle:keysOwn(ply)
	spawnedVehicle:keysLock()

	gamemode.Call(PlayerSpawnedVehicle, ply, spawnedVehicle)
	ply.currentVehicle = spawnedVehicle

	--> Color
	spawnedVehicle:SetColor(Color(math.random(0, 255), math.random(0, 255), math.random(0, 255), 255))

	--> Test Drive
	ply.vehicleTest = false

	if timer.Exists("testDrive_"..ply:UniqueID()) then
		timer.Remove("testDrive_"..ply:UniqueID())
	end

	if testDrive then
		timer.Create("testDrive_"..ply:UniqueID(), TCBDealer.settings.testDriveLength, 1, function()

			if IsValid(ply) then
				ply:ExitVehicle()
				TCBDealer.removeVehicle(ply)
			end

			net.Start("TCBDealerChat")
				net.WriteString("Your test drive ran out!")
			net.Send(ply)

			ply.vehicleTest = false

		end)

		ply.vehicleTest = true

		net.Start("TCBDealerChat")
			net.WriteString("You can test drive this vehicle for the next "..TCBDealer.settings.testDriveLength.." seconds!")
		net.Send(ply)
	end

	--> Enter
	if TCBDealer.settings.autoEnter or testDrive then
		ply:EnterVehicle(spawnedVehicle)
	end

end
net.Receive("TCBDealerSpawn", TCBDealer.spawnVehicle)

--[[---------------------------------------------------------
	Remove Vehicle
-----------------------------------------------------------]]
function TCBDealer.removeVehicle(ply)
	if IsValid(ply.currentVehicle) then
		ply.currentVehicle:Remove()
	end
end
hook.Add("PlayerDisconnected", "TCBDealer.removeVehicle", TCBDealer.removeVehicle)

--[[---------------------------------------------------------
	Leave Vehicle
-----------------------------------------------------------]]
function TCBDealer.leaveVehicle(ply)
	if IsValid(ply.currentVehicle) and ply.vehicleTest == true then
		ply.currentVehicle:Remove()
		ply.vehicleTest = false
	end
end
hook.Add("PlayerLeaveVehicle", "TCBDealer.leaveVehicle", TCBDealer.leaveVehicle)

--[[---------------------------------------------------------
	Dealer Range
-----------------------------------------------------------]]
function TCBDealer.dealerRange(ply, dealer)
	return ply:GetPos():Distance(dealer.pos) <= 200
end