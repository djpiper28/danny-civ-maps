------------------------------------------------------------------------------
--	FILE:	 RorkesDrift.lua
--	AUTHOR:  Danny Pipper, Bob Thomas
--	PURPOSE: A modded four corners map to pit 3+ players in the middle of an
--	         "inverse" four corners map that is plus shaped. There are four
--	         "loot" islands in the corners for fun with hilly land bridges for
--	         the ai to use. See README.md
------------------------------------------------------------------------------
--	Copyright (c) 2022 Danny Piper, AGPL3
------------------------------------------------------------------------------

include("MapGenerator");
include("MultilayeredFractal");
include("FeatureGenerator");
include("TerrainGenerator");
include("HBMapGenerator");
include("HBFeatureGenerator");
include("HBTerrainGenerator");

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "RorkesDrift",
		Description = "See danny-civ-maps README.md",
		SupportsMultiplayer = true,
		IconIndex = 8,
		CustomOptions = {world_age, temperature, rainfall,
			{
				Name = "TXT_KEY_MAP_OPTION_RESOURCES",	-- Customizing the Resource setting to Default to Strategic Balance.
				Values = {
					"TXT_KEY_MAP_OPTION_SPARSE",
					"TXT_KEY_MAP_OPTION_STANDARD",
					"TXT_KEY_MAP_OPTION_ABUNDANT",
					"TXT_KEY_MAP_OPTION_LEGENDARY_START",
					"TXT_KEY_MAP_OPTION_STRATEGIC_BALANCE",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 5,
				SortPriority = -95,
			},
			{
				Name = "TXT_KEY_MAP_OPTION_BUFFER_ZONES",
				Values = {
					"TXT_KEY_MAP_OPTION_OCEAN",
					"TXT_KEY_MAP_OPTION_MOUNTAINS",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 1,
				SortPriority = 1,
			},
			{
				Name = "TXT_KEY_MAP_OPTION_TEAM_SETTING",
				Values = {
					"TXT_KEY_MAP_OPTION_START_TOGETHER",
					"TXT_KEY_MAP_OPTION_START_SEPERATED",
					"TXT_KEY_MAP_OPTION_START_ANYWHERE",
				},
				DefaultValue = 1,
				SortPriority = 2,
			},
		},
	}
end
------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	-- This function can reset map grid sizes or world wrap settings.
	--
	-- North vs South is an extremely compact multiplayer map type.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {56, 56},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {56, 56},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {56, 56},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {56, 56},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {56, 56},
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {56, 56}
		}
	local grid_size = worldsizes[worldSize];
	--
	local world = GameInfo.Worlds[worldSize];
	if(world ~= nil) then
	return {
		Width = grid_size[1],
		Height = grid_size[2],
		WrapX = false,
	};
     end
end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function MultilayeredFractal:GeneratePlotsByRegion()
	-- Sirian's MultilayeredFractal controlling function.
	-- You -MUST- customize this function for each script using MultilayeredFractal.
	--
	-- This implementation is specific to Four Corners.
	local iW, iH = Map.GetGridSize();
	local fracFlags = {};
  local offset = 7;
  local islandSize = offset + 5;
  local xMin = (iW / 2) - offset;
  local xMax = (iW / 2) + offset;
  local yMin = (iH / 2) - offset;
  local yMax = (iH / 2) + offset;

	-- Fill all rows with land plots.
	self.wholeworldPlotTypes = table.fill(PlotTypes.PLOT_LAND, iW * iH);

  -- Add water to the four corners
  print("Adding water (with a t).");
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
      if x < xMin or x > xMax then
        if y < yMin or y > yMax then
          -- Do not plot the land bridges as ocean
          if x > 0 and x < iW - 1 and y > 0 and y < iH - 1 then
      			local plotIndex = y * iW + x + 1;
    			  self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_OCEAN;
          end
        end
      end
		end
	end

  -- Add loot islands
  print("Adding loot island tm.");
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
      if x < 2 * islandSize or x > iW - islandSize then
        if y < 2 * islandSize or y > iH - islandSize then
    			local plotIndex = y * iW + x + 1;
  			  self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_LAND;
        end
      end
		end
	end

	-- Land and water are set. Now apply hills and mountains.
	local world_age = Map.GetCustomOption(1)
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end
	local args = {world_age = world_age};
	self:ApplyTectonics(args)

	-- If buffer zones are set to Mountains, add those now. (Must come after Tectonics layer to avoid being overwritten.)
	local buffer_setting = Map.GetCustomOption(5)
	if buffer_setting == 3 then
		buffer_setting = 1 + Map.Rand(2, "Random Buffer Zone Type - Four Corners, Lua");
	end
	if buffer_setting == 2 then -- Apply mountains.
		for y = 0, iH - 1 do
			for x = math.floor(iW / 2) - 2, math.floor(iW / 2) + 1 do
				local plotIndex = y * iW + x + 1;
				self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_MOUNTAIN;
			end
		end
		for x = 0, iW - 1 do
			for y = math.floor(iH / 2) - 2, math.floor(iH / 2) + 1 do
				local plotIndex = y * iW + x + 1;
				self.wholeworldPlotTypes[plotIndex] = PlotTypes.PLOT_MOUNTAIN;
			end
		end
	end

	-- Plot Type generation completed. Return global plot array.
	return self.wholeworldPlotTypes
end
------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Four Corners) ...");

	local layered_world = MultilayeredFractal.Create();
	local plot_list = layered_world:GeneratePlotsByRegion();

	SetPlotTypes(plot_list);

	local args = {bExpandCoasts = false};
	GenerateCoasts(args);
end
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
function TerrainGenerator:GetLatitudeAtPlot(iX, iY)
	local lat = math.abs((self.iHeight / 2) - iY) / (self.iHeight / 2);
	lat = lat + (128 - self.variation:GetHeight(iX, iY))/(255.0 * 5.0);
	lat = 0.8 * (math.clamp(lat, 0, 1));
	return lat;
end
----------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Four Corners) ...");

	-- Get Temperature setting input by user.
	local temp = Map.GetCustomOption(2)
	if temp == 4 then
		temp = 1 + Map.Rand(3, "Random Temperature - Lua");
	end

	local args = {temperature = temp};
	local terraingen = TerrainGenerator.Create(args);

	terrainTypes = terraingen:GenerateTerrain();

	SetTerrainTypes(terrainTypes);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GetRiverValueAtPlot(plot)
	local numPlots = PlotTypes.NUM_PLOT_TYPES;
	local sum = (numPlots - plot:GetPlotType()) * 20;
	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1, 1 do
		local adjacentPlot = Map.PlotDirection(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			sum = sum + (numPlots - adjacentPlot:GetPlotType());
		else
			sum = 0 -- Custom, prevents rivers avoiding running off the map edge.
		end
	end
	sum = sum + Map.Rand(10, "River Rand");
	return sum;
end
------------------------------------------------------------------------------
function DoRiver(startPlot, thisFlowDirection, originalFlowDirection, riverID)
	-- Customizing to handle problems in top row of the map. Only this aspect has been altered.

	local iW, iH = Map.GetGridSize()
	thisFlowDirection = thisFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;
	originalFlowDirection = originalFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;

	-- pStartPlot = the plot at whose SE corner the river is starting
	if (riverID == nil) then
		riverID = nextRiverID;
		nextRiverID = nextRiverID + 1;
	end

	local otherRiverID = _rivers[startPlot]
	if (otherRiverID ~= nil and otherRiverID ~= riverID and originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
		return; -- Another river already exists here; can't branch off of an existing river!
	end

	local riverPlot;

	local bestFlowDirection = FlowDirectionTypes.NO_FLOWDIRECTION;
	if (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH) then

		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if ( adjacentPlot == nil or riverPlot:IsWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater() ) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetWOfRiver(true, thisFlowDirection);
		riverPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_NORTHEAST);

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST) then

		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if ( adjacentPlot == nil or riverPlot:IsNWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater() ) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNWOfRiver(true, thisFlowDirection);
		-- riverPlot does not change

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST) then

		riverPlot = Map.PlotDirection(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (riverPlot == nil) then
			return;
		end

		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (adjacentPlot == nil or riverPlot:IsNEOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNEOfRiver(true, thisFlowDirection);
		-- riverPlot does not change

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH) then

		riverPlot = Map.PlotDirection(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (riverPlot == nil) then
			return;
		end

		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (adjacentPlot == nil or riverPlot:IsWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetWOfRiver(true, thisFlowDirection);
		-- riverPlot does not change

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST) then

		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if (adjacentPlot == nil or riverPlot:IsNWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNWOfRiver(true, thisFlowDirection);
		-- riverPlot does not change

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST) then

		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);

		if ( adjacentPlot == nil or riverPlot:IsNEOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNEOfRiver(true, thisFlowDirection);
		riverPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_WEST);

	else
		-- River is starting here, set the direction in the next step
		riverPlot = startPlot;
	end

	if (riverPlot == nil or riverPlot:IsWater()) then
		-- The river has flowed off the edge of the map or into the ocean. All is well.
		return;
	end

	-- Storing X,Y positions as locals to prevent redundant function calls.
	local riverPlotX = riverPlot:GetX();
	local riverPlotY = riverPlot:GetY();

	-- Table of methods used to determine the adjacent plot.
	local adjacentPlotFunctions = {
		[FlowDirectionTypes.FLOWDIRECTION_NORTH] = function()
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST);
		end,

		[FlowDirectionTypes.FLOWDIRECTION_NORTHEAST] = function()
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHEAST);
		end,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST] = function()
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_EAST);
		end,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTH] = function()
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_SOUTHWEST);
		end,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST] = function()
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_WEST);
		end,

		[FlowDirectionTypes.FLOWDIRECTION_NORTHWEST] = function()
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST);
		end
	}

	if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then

		-- Attempt to calculate the best flow direction.
		local bestValue = math.huge;
		for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do

			if (GetOppositeFlowDirection(flowDirection) ~= originalFlowDirection) then

				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then

					local adjacentPlot = getAdjacentPlot();

					if (adjacentPlot ~= nil) then

						local value = GetRiverValueAtPlot(adjacentPlot);
						if (flowDirection == originalFlowDirection) then
							value = (value * 3) / 4;
						end

						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end

					-- Custom addition to fix river problems in top row of the map. Any other all-land map may need similar special casing.
					elseif adjacentPlot == nil and riverPlotY == iH - 1 then -- Top row of map, needs special handling
						if flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST then

							local value = Map.Rand(5, "River Rand");
							if (flowDirection == originalFlowDirection) then
								value = (value * 3) / 4;
							end
							if (value < bestValue) then
								bestValue = value;
								bestFlowDirection = flowDirection;
							end
						end

					-- Custom addition to fix river problems in left column of the map. Any other all-land map may need similar special casing.
					elseif adjacentPlot == nil and riverPlotX == 0 then -- Left column of map, needs special handling
						if flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST then

							local value = Map.Rand(5, "River Rand");
							if (flowDirection == originalFlowDirection) then
								value = (value * 3) / 4;
							end
							if (value < bestValue) then
								bestValue = value;
								bestFlowDirection = flowDirection;
							end
						end
					end
				end
			end
		end

		-- Try a second pass allowing the river to "flow backwards".
		if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then

			local bestValue = math.huge;
			for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do

				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then

					local adjacentPlot = getAdjacentPlot();

					if (adjacentPlot ~= nil) then

						local value = GetRiverValueAtPlot(adjacentPlot);
						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end
					end
				end
			end
		end
	end

	--Recursively generate river.
	if (bestFlowDirection ~= FlowDirectionTypes.NO_FLOWDIRECTION) then
		if  (originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
			originalFlowDirection = bestFlowDirection;
		end

		DoRiver(riverPlot, bestFlowDirection, originalFlowDirection, riverID);
	end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function FeatureGenerator:GetLatitudeAtPlot(iX, iY)
	local lat = math.abs((self.iGridH/2) - iY)/(self.iGridH/2);
	local adjusted_lat = 0.8 * lat;
	return adjusted_lat
end
------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
	return
end
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Four Corners) ...");

	-- Get Rainfall setting input by user.
	local rain = Map.GetCustomOption(3)
	if rain == 4 then
		rain = 1 + Map.Rand(3, "Random Rainfall - Lua");
	end

	local args = {rainfall = rain}
	local featuregen = FeatureGenerator.Create(args);

	featuregen:AddFeatures();
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function AssignStartingPlots:CanPlaceCityStateAt(x, y, area_ID, force_it, ignore_collisions)
	-- Overriding default city state placement to prevent city states from being placed too close to map edges.
	local iW, iH = Map.GetGridSize();
	local plot = Map.GetPlot(x, y)
	local area = plot:GetArea()

	-- Adding this check for Four Corners
	if x < 1 or x >= iW - 1 or y < 1 or y >= iH - 1 then
		return false
	end

  -- Do not plot in the middle
  local offset = 7;
  if x > (iW / 2) - offset and x < (iW / 2) + offset and y > (iH / 2) - offset or x < (iH / 2) + offset then
    return false
  end

	if area ~= area_ID and area_ID ~= -1 then
		return false
	end
	local plotType = plot:GetPlotType()
	if plotType == PlotTypes.PLOT_OCEAN or plotType == PlotTypes.PLOT_MOUNTAIN then
		return false
	end
	local terrainType = plot:GetTerrainType()
	if terrainType == TerrainTypes.TERRAIN_SNOW then
		return false
	end
	local plotIndex = y * iW + x + 1;
	if self.cityStateData[plotIndex] > 0 and force_it == false then
		return false
	end
	local plotIndex = y * iW + x + 1;
	if self.playerCollisionData[plotIndex] == true and ignore_collisions == false then
		return false
	end
	return true
end
------------------------------------------------------------------------------
function AssignStartingPlots:BalanceAndAssign()
	-- This function determines what level of Bonus Resource support a location
	-- may need, identifies compatibility with civ-specific biases, and places starts.
  local offset = 7;
	local iW, iH = Map.GetGridSize();
  local xMin = (iW / 2) - offset;
  local xMax = (iW / 2) + offset;
  local yMin = (iH / 2) - offset;
  local yMax = (iH / 2) + offset;

	-- Normalize each start plot location.
	local iNumStarts = table.maxn(self.startingPlots);
	for region_number = 1, iNumStarts do
		self:NormalizeStartLocation(region_number)
	end

	-- Assign Civs to start plots.
  local teamMiddleID = 0;
  -- Place the lowest team in the middle, scatter the rest on the main island, at least 2 offset aw
  print("-"); print("This is a team game with two teams, place one in the middle, then scatter the rest."); print("-");
  local outerList, middleList = {}, {};
  local middleLen = 0;
  for loop = 1, self.iNumCivs do
    local player_ID = self.player_ID_list[loop];
    local player = Players[player_ID];
    local team_ID = player:GetTeam()
    if team_ID == teamMiddleID then
      print("Player #", player_ID, "belongs to Team #", team_ID, "and will be placed in the middle.");
      table.insert(middleList, player_ID);
      middleLen = middleLen + 1;
    else
      print("Player #", player_ID, "belongs to Team #", team_ID, "and will be placed in the outer.");
      table.insert(outerList, player_ID);
    end
  end

  local outerListShuffled = GetShuffledCopyOfTable(outerList)
  local middleListShuffled = GetShuffledCopyOfTable(middleList)

  local i = 1
  for region_number, player_ID in ipairs(middleListShuffled) do
    -- Scatter the players in team 1 around the middle in a circle
    local x = math.floor((iW / 2.0) + (offset * math.cos((math.pi * 2.0 * i) / middleLen)))
    local y = math.floor((iH / 2.0) + (offset * math.sin((math.pi * 2.0 * i) / middleLen)))
    assert(x >= xMin and x <= xMax, "Illegal x");
    assert(y >= yMin and y <= yMax, "Illegal y");

    local start_plot = Map.GetPlot(x, y)
    local player = Players[player_ID]
    player:SetStartingPlot(start_plot)
    i = i + 1;
  end

  local outer_offset_x = (iW / 2) - (2 * offset);
  local outer_offset_y = (iH / 2) - (2 * offset);
  local j = 1;
  for loop, player_ID in ipairs(outerListShuffled) do
    local x = self.startingPlots[loop + i][1];
    local y = self.startingPlots[loop + i][2];
    if j <= 4 then
      x = math.floor((iW / 2.0) + (outer_offset_x * math.cos((math.pi * 2.0 * j) / 4)))
      y = math.floor((iH / 2.0) + (outer_offset_y * math.sin((math.pi * 2.0 * j) / 4)))
      assert(not (x >= xMin and x <= xMax and y >= yMin and y <= yMax), "Illegal coords");
    end

    -- Clip enemies to outside the middle
    if x > xMin and x < xMax and y > yMin and y < yMax then
      x = xMin - (loop + 2 * offset);
      y = iH / 2;
      print("Clipped a player to stop them being in the wrong place");
    end;
    assert(x >= 0 and x < iW, "Illegal x");
    assert(y >= 0 and y < iW, "Illegal y");

    local start_plot = Map.GetPlot(x, y)
    local player = Players[player_ID]
    player:SetStartingPlot(start_plot)
    j = j + 1;
  end
end
------------------------------------------------------------------------------
function StartPlotSystem()
	-- Get Resources setting input by user.
	local res = Map.GetCustomOption(4)
	if res == 6 then
		res = 1 + Map.Rand(3, "Random Resources Option - Lua");
	end

	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()

	print("Dividing the map in to Regions.");
	-- Regional Division Method 2: Continental
	local args = {
		method = 2,
		resources = res,
		};
	start_plot_database:GenerateRegions()

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()

	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()

	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Placing Natural Wonders.");
	start_plot_database:PlaceNaturalWonders()

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()
end
------------------------------------------------------------------------------
