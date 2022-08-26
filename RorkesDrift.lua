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

include("HBMapGenerator");
include("HBFeatureGenerator");
include("HBTerrainGenerator");
include("MultilayeredFractal");
include("IslandMaker");

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "RorkesDrift",
		Description = "See danny-civ-maps README.md",
		SupportsMultiplayer = true,
		IconIndex = 8,
    CustomOptions = {
			{
				Name = "TXT_KEY_MAP_OPTION_WORLD_AGE", -- 1
				Values = {
					"TXT_KEY_MAP_OPTION_THREE_BILLION_YEARS",
					"TXT_KEY_MAP_OPTION_FOUR_BILLION_YEARS",
					"TXT_KEY_MAP_OPTION_FIVE_BILLION_YEARS",
					"No Mountains",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -99,
			},

			{
				Name = "TXT_KEY_MAP_OPTION_TEMPERATURE",	-- 2 add temperature defaults to random
				Values = {
					"TXT_KEY_MAP_OPTION_COOL",
					"TXT_KEY_MAP_OPTION_TEMPERATE",
					"TXT_KEY_MAP_OPTION_HOT",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -98,
			},

			{
				Name = "TXT_KEY_MAP_OPTION_RAINFALL",	-- 3 add rainfall defaults to random
				Values = {
					"TXT_KEY_MAP_OPTION_ARID",
					"TXT_KEY_MAP_OPTION_NORMAL",
					"TXT_KEY_MAP_OPTION_WET",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -97,
			},

			{
				Name = "TXT_KEY_MAP_OPTION_SEA_LEVEL",	-- 4 add sea level defaults to random.
				Values = {
					"TXT_KEY_MAP_OPTION_LOW",
					"TXT_KEY_MAP_OPTION_MEDIUM",
					"TXT_KEY_MAP_OPTION_HIGH",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -96,
			},

			{
				Name = "Start Quality",	-- 5 add resources defaults to random
				Values = {
					"Legendary Start - Strat Balance",
					"Legendary - Strat Balance + Uranium",
					"TXT_KEY_MAP_OPTION_STRATEGIC_BALANCE",
					"Strategic Balance With Coal",
					"Strategic Balance With Aluminum",
					"Strategic Balance With Coal & Aluminum",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -95,
			},

			{
				Name = "Start Distance",	-- 6 add resources defaults to random
				Values = {
					"Close",
					"Normal",
					"Far - Warning: May sometimes crash during map generation",
				},
				DefaultValue = 2,
				SortPriority = -94,
			},

			{
				Name = "Natural Wonders", -- 7 number of natural wonders to spawn
				Values = {
					"0",
					"1",
					"2",
					"3",
					"4",
					"5",
					"6",
					"7",
					"8",
					"9",
					"10",
					"11",
					"12",
					"Random",
					"Default",
				},
				DefaultValue = 15,
				SortPriority = -93,
			},

			{
				Name = "Grass Moisture",	-- add setting for grassland mositure (8)
				Values = {
					"Wet",
					"Normal",
					"Dry",
				},

				DefaultValue = 2,
				SortPriority = -92,
			},

			{
				Name = "Rivers",	-- add setting for rivers (9)
				Values = {
					"Sparse",
					"Average",
					"Plentiful",
				},

				DefaultValue = 2,
				SortPriority = -91,
			},

			{
				Name = "Tundra",	-- add setting for tundra (10)
				Values = {
					"Sparse",
					"Average",
					"Plentiful",
				},

				DefaultValue = 2,
				SortPriority = -90,
			},
	  }
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
function MultilayeredFractal:GeneratePlotsByRegion(args)
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
      if x < islandSize or x > iW - islandSize then
        if y < islandSize or y > iH - islandSize then
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

  local outer_offset_x = (iW / 2) - offset;
  local outer_offset_y = (iH / 2) - offset;
  local j = 1;
  for loop, player_ID in ipairs(outerListShuffled) do
    local x = self.startingPlots[loop + i - 1][1];
    local y = self.startingPlots[loop + i - 1][2];
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
	local args = {
		method = 2,
		resources = res,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()

	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()

	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Placing Natural Wonders.");
	local wonders = Map.GetCustomOption(7)
	if wonders == 14 then
		wonders = Map.Rand(13, "Number of Wonders To Spawn - Lua");
	else
		wonders = wonders - 1;
	end

	print("Natural Wonders To Place: ", wonders);
	local wonderargs = {
		wonderamt = wonders,
	};
	start_plot_database:PlaceNaturalWonders(wonderargs);

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()

	-- tell the AI that we should treat this as a naval expansion map
	Map.ChangeAIMapHint(1+4);
	if (PreGame.IsMultiplayerGame()) then
    	Network.SendChat("[COLOR_POSITIVE_TEXT]Lekmap v3.3[ENDCOLOR]", -1, -1);
      Network.SendChat("[COLOR_POSITIVE_TEXT]Danny Map v1.0[ENDCOLOR]", -1, -1);
	end
end
------------------------------------------------------------------------------

