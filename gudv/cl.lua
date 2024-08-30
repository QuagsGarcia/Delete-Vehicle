local max = 100.0
RegisterNetEvent('GUDeleteVehicle:handler')
AddEventHandler('GUDeleteVehicle:handler', function(tbl)

		deleteVehicleHandler(tbl)
		--[[lib.notify({
					    title = 'GU Life Control',
					    iconAnimation = "shake",
					    description = 'You have been revived.',
					    position = 'top',
					    type = 'inform'
		})]]
end)
RegisterCommand("dv", function(src, args)
	if not tonumber(args[1]) then
		local tbl = {}
		tbl.Coords = GetEntityCoords(GetPlayerPed(-1))
		tbl.User = GetPlayerServerId(PlayerId())
		tbl.Radius = 5.0
		tbl.Single = true
		tbl.Staff = false
		TriggerServerEvent("GUDeleteVehicle:handler-sv", tbl)
	else
		if isStaff() then
			local tbl = {}
			local rad = tonumber(args[1])
			tbl.Coords = GetEntityCoords(GetPlayerPed(-1))
			tbl.User = GetPlayerServerId(PlayerId())
			if rad >= max then
				rad = max
			end
			tbl.Radius = rad
			tbl.Single = false
			tbl.Staff = false
			TriggerServerEvent("GUDeleteVehicle:handler-sv", tbl)
		else
			lib.notify({
						    title = 'GU DV',
						    iconAnimation = "shake",
						    description = 'Permission Denied.',
						    position = 'top',
						    type = 'inform'
				})
		end
	end
end)
RegisterCommand("staffdv", function(src, args)
	if isStaff() then
		if not tonumber(args[1]) then
			local tbl = {}
			tbl.Coords = GetEntityCoords(GetPlayerPed(-1))
			tbl.User = GetPlayerServerId(PlayerId())
			tbl.Radius = 5.0
			tbl.Single = true
			tbl.Staff = true
			TriggerServerEvent("GUDeleteVehicle:handler-sv", tbl)
		else
			
				local tbl = {}
				local rad = tonumber(args[1])
				tbl.Coords = GetEntityCoords(GetPlayerPed(-1))
				tbl.User = GetPlayerServerId(PlayerId())
				if rad >= max then
					rad = max
				end
				tbl.Radius = rad
				tbl.Single = false
				tbl.Staff = true
				TriggerServerEvent("GUDeleteVehicle:handler-sv", tbl)
		end
	else
		lib.notify({
							    title = 'GU DV',
							    iconAnimation = "shake",
							    description = 'Permission Denied.',
							    position = 'top',
							type = 'inform'
		})
	end
end)
function isStaff()
	return lib.callback.await('GU:IsStaff', GetPlayerServerId(PlayerId()))
end
function deleteVehicleHandler(tbl)
	local coords = tbl.Coords
	if tbl.Single then
		local vehs = surveyVehicles(tbl.Radius, tbl.Coords)
		local closest = 0
		if json.encode(vehs) ~= "[]" then
			for _, i in pairs(vehs) do
		        local dist1 = #(GetEntityCoords(i.ent) - coords)
		        local dist2 = #(GetEntityCoords(closest) - coords)
		        if dist1 < dist2 then
		        	closest = i.ent
		        end
			end
			local canDelete = true
			for seat = -1, (GetVehicleMaxNumberOfPassengers(closest) - 1), 1 do
				if IsPedAPlayer(GetPedInVehicleSeat(closest, seat)) and not tbl.Staff and GetPedInVehicleSeat(closest, seat) ~= GetPlayerPed(-1) then
					canDelete = false
				end
			end
			if canDelete then
				NetworkDelete(closest)
				if GetPlayerServerId(PlayerId()) == tbl.User then
					lib.notify({
							    title = 'GU DV',
							    iconAnimation = "shake",
							    description = 'Vehicle Deleted.',
							    position = 'top',
							    type = 'inform'
					})
				end
			else
				if GetPlayerServerId(PlayerId()) == tbl.User then
					lib.notify({
							    title = 'GU DV',
							    iconAnimation = "shake",
							    description = 'Vehicle Occupied.',
							    position = 'top',
							    type = 'inform'
					})
				end
			end
		else
			if GetPlayerServerId(PlayerId()) == tbl.User then
				lib.notify({
						    title = 'GU DV',
						    iconAnimation = "shake",
						    description = 'No Vehicles Found.',
						    position = 'top',
						    type = 'inform'
				})
			end
		end
	else
		local vehs = surveyVehicles(tbl.Radius, tbl.Coords)
		if json.encode(vehs) ~= "[]" then
			local amount = 0
			for _, i in pairs(vehs) do
				local canDelete = true
				
				for seat = -1, (GetVehicleMaxNumberOfPassengers(i.ent) - 1), 1 do
					if IsPedAPlayer(GetPedInVehicleSeat(i.ent, seat)) and not tbl.Staff then
						canDelete = false
					end
				end
				if canDelete then
					NetworkDelete(i.ent)
					amount = amount + 1
				end
			end
			if amount > 1 then
				if GetPlayerServerId(PlayerId()) == tbl.User then
					lib.notify({
							    title = 'GU DV',
							    iconAnimation = "shake",
							    description = 'Deleted '..amount..' Vehicles.',
							    position = 'top',
							    type = 'inform'
					})
				end
			else
				if GetPlayerServerId(PlayerId()) == tbl.User then
					lib.notify({
							    title = 'GU DV',
							    iconAnimation = "shake",
							    description = 'Vehicle Deleted.',
							    position = 'top',
							    type = 'inform'
					})
				end
			end
		else
			if GetPlayerServerId(PlayerId()) == tbl.User then
				lib.notify({
						    title = 'GU DV',
						    iconAnimation = "shake",
						    description = 'No Vehicles Found.',
						    position = 'top',
						    type = 'inform'
				})
			end
		end
	end
end
function surveyVehicles(radius, entcoords)
	local tbl = {}
	for i in EnumerateVehicles() do
        local c1 = GetEntityCoords(i)
        local c2 = entcoords
        local dist = #(c1 - c2)
        if dist <= radius then
        	table.insert(tbl, {ent=i, dist=dist})
        end
    end
	return tbl
end
local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end

        enum.destructor = nil
        enum.handle = nil
    end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()
        if not id or id == 0 then
            disposeFunc(iter)
            return
        end

        local enum = {handle = iter, destructor = disposeFunc}
        setmetatable(enum, entityEnumerator)

        local next = true
        repeat
        coroutine.yield(id)
        next, id = moveFunc(iter)
        until not next

        enum.destructor, enum.handle = nil, nil
        disposeFunc(iter)
    end)
end
function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end
function NetworkDelete(entity)
  Citizen.CreateThread(function()
        if DoesEntityExist(entity) and not IsPedAPlayer(entity) then
            DetachEntity(entity, 0, false)
            SetEntityCollision(entity, false, false)
            SetEntityAlpha(entity, 0.0, true)
            SetEntityAsMissionEntity(entity, true, true)
            SetEntityAsNoLongerNeeded(entity)
            DeleteEntity(entity)
        end
    end)
end