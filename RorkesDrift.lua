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
include("HBFractalWorld");
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
				DefaultValue = 1,
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
function AssignStartingPlots:GenerateRegions(args)
	print("Map Generation - Dividing the map in to Regions");
	-- This is a customized version for West vs East.
	-- This version is tailored for handling two-teams play.
	local args = args or {};
	local iW, iH = Map.GetGridSize();
	local res = Map.GetCustomOption(13)
	if res == 9 then
		res = 1 + Map.Rand(3, "Random Resources Option - Lua");
	end

	local setback = Map.GetCustomOption(15)-1;

	local setforward = Map.GetCustomOption(16)-1;

	local setrange = setforward + setback;

	print("Moveback: ", setback);

	self.resource_setting = res; -- Each map script has to pass in parameter for Resource setting chosen by user.
	self.method = 3; -- Flag the map as using a Rectangular division method.
	
	-- Determine number of civilizations and city states present in this game.
	self.iNumCivs, self.iNumCityStates, self.player_ID_list, self.bTeamGame, self.teams_with_major_civs, self.number_civs_per_team = GetPlayerAndTeamInfo()
	self.iNumCityStatesUnassigned = self.iNumCityStates;
	print("-"); print("Civs:", self.iNumCivs); print("City States:", self.iNumCityStates);

	-- Determine number of teams (of Major Civs only, not City States) present in this game.
	iNumTeams = table.maxn(self.teams_with_major_civs);				-- GLOBAL
	print("-"); print("Teams:", iNumTeams);

	-- If four teams are present, use team-oriented handling of start points, one team in each corner.
	if iNumTeams == 4 then
		print("-"); print("Number of Teams present is four! Using custom team start placement for DefianceCorners."); print("-");
		
		-- ToDo: Correctly identify team IDs and how many Civs are on each team.
		-- Also need to shuffle the teams so its random who starts on which half.
		iNumDivisions = 2

		-- Process the bottom left corner.
		self.inhabited_WestX = 0 + setforward;
		self.inhabited_SouthY = 0 + setforward;
		self.inhabited_Width = (math.floor(iW / 2)) - setrange;
		self.inhabited_Height = (math.floor(iH / 2)) - setrange;
		-- Obtain "Start Placement Fertility" inside the rectangle.
		-- Data returned is: fertility table, sum of all fertility, plot count.
		local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
		                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
		-- Assemble the Rectangle data table:
		local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
		                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
		-- Divide the rectangle.
		self:DivideIntoRegions(iNumDivisions, fert_table, rect_table)

		-- Process the bottom right corner.
		self.inhabited_WestX = (math.floor(iW / 2)) + setback;
		self.inhabited_SouthY = 0 + setforward;
		self.inhabited_Width = (math.floor(iW / 2)) - setrange;
		self.inhabited_Height = (math.floor(iH / 2)) - setrange;
		-- Obtain "Start Placement Fertility" inside the rectangle.
		-- Data returned is: fertility table, sum of all fertility, plot count.
		local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
		                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
		-- Assemble the Rectangle data table:
		local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
		                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
		-- Divide the rectangle.
		self:DivideIntoRegions(iNumDivisions, fert_table, rect_table)
		
		-- Process the top left corner.
		self.inhabited_WestX = 0 + setforward;
		self.inhabited_SouthY = (math.floor(iH / 2)) + setback;
		self.inhabited_Width = (math.floor(iW / 2)) - setrange;
		self.inhabited_Height = (math.floor(iH / 2)) - setrange;
		-- Obtain "Start Placement Fertility" inside the rectangle.
		-- Data returned is: fertility table, sum of all fertility, plot count.
		local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
		                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
		-- Assemble the Rectangle data table:
		local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
		                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
		-- Divide the rectangle.
		self:DivideIntoRegions(iNumDivisions, fert_table, rect_table)

		-- Process the top right corner.
		self.inhabited_WestX = (math.floor(iW / 2)) + setback;
		self.inhabited_SouthY = (math.floor(iH / 2)) + setback;
		self.inhabited_Width = (math.floor(iW / 2)) - setrange;
		self.inhabited_Height = (math.floor(iH / 2)) - setrange;
		-- Obtain "Start Placement Fertility" inside the rectangle.
		-- Data returned is: fertility table, sum of all fertility, plot count.
		local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
		                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
		-- Assemble the Rectangle data table:
		local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
		                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
		-- Divide the rectangle.
		self:DivideIntoRegions(iNumDivisions, fert_table, rect_table)
		-- The regions have been defined.

	-- If number of teams is any number other than two, use standard division.
	else	
		print("-"); print("Dividing the map at random."); print("-");
		self.method = 2;	
		local best_areas = {};
		local globalFertilityOfLands = {};

		-- Obtain info on all landmasses for comparision purposes.
		local iGlobalFertilityOfLands = 0;
		local iNumLandPlots = 0;
		local iNumLandAreas = 0;
		local land_area_IDs = {};
		local land_area_plots = {};
		local land_area_fert = {};
		-- Cycle through all plots in the world, checking their Start Placement Fertility and AreaID.
		for x = 0, iW - 1 do
			for y = 0, iH - 1 do
				local i = y * iW + x + 1;
				local plot = Map.GetPlot(x, y);
				if not plot:IsWater() then -- Land plot, process it.
					iNumLandPlots = iNumLandPlots + 1;
					local iArea = plot:GetArea();
					local plotFertility = self:MeasureStartPlacementFertilityOfPlot(x, y, true); -- Check for coastal land is enabled.
					iGlobalFertilityOfLands = iGlobalFertilityOfLands + plotFertility;
					--
					if TestMembership(land_area_IDs, iArea) == false then -- This plot is the first detected in its AreaID.
						iNumLandAreas = iNumLandAreas + 1;
						table.insert(land_area_IDs, iArea);
						land_area_plots[iArea] = 1;
						land_area_fert[iArea] = plotFertility;
					else -- This AreaID already known.
						land_area_plots[iArea] = land_area_plots[iArea] + 1;
						land_area_fert[iArea] = land_area_fert[iArea] + plotFertility;
					end
				end
			end
		end
		
		-- Sort areas, achieving a list of AreaIDs with best areas first.
		--
		-- Fertility data in land_area_fert is stored with areaID index keys.
		-- Need to generate a version of this table with indices of 1 to n, where n is number of land areas.
		local interim_table = {};
		for loop_index, data_entry in pairs(land_area_fert) do
			table.insert(interim_table, data_entry);
		end
		-- Sort the fertility values stored in the interim table. Sort order in Lua is lowest to highest.
		table.sort(interim_table);
		-- If less players than landmasses, we will ignore the extra landmasses.
		local iNumRelevantLandAreas = math.min(iNumLandAreas, self.iNumCivs);
		-- Now re-match the AreaID numbers with their corresponding fertility values
		-- by comparing the original fertility table with the sorted interim table.
		-- During this comparison, best_areas will be constructed from sorted AreaIDs, richest stored first.
		local best_areas = {};
		-- Currently, the best yields are at the end of the interim table. We need to step backward from there.
		local end_of_interim_table = table.maxn(interim_table);
		-- We may not need all entries in the table. Process only iNumRelevantLandAreas worth of table entries.
		for areaTestLoop = end_of_interim_table, (end_of_interim_table - iNumRelevantLandAreas + 1), -1 do
			for loop_index, AreaID in ipairs(land_area_IDs) do
				if interim_table[areaTestLoop] == land_area_fert[land_area_IDs[loop_index]] then
					table.insert(best_areas, AreaID);
					table.remove(land_area_IDs, landLoop);
					break
				end
			end
		end

		-- Assign continents to receive start plots. Record number of civs assigned to each landmass.
		local inhabitedAreaIDs = {};
		local numberOfCivsPerArea = table.fill(0, iNumRelevantLandAreas); -- Indexed in synch with best_areas. Use same index to match values from each table.
		for civToAssign = 1, self.iNumCivs do
			local bestRemainingArea;
			local bestRemainingFertility = 0;
			local bestAreaTableIndex;
			-- Loop through areas, find the one with the best remaining fertility (civs added 
			-- to a landmass reduces its fertility rating for subsequent civs).
			for area_loop, AreaID in ipairs(best_areas) do
				local thisLandmassCurrentFertility = land_area_fert[AreaID] / (1 + numberOfCivsPerArea[area_loop]);
				if thisLandmassCurrentFertility > bestRemainingFertility then
					bestRemainingArea = AreaID;
					bestRemainingFertility = thisLandmassCurrentFertility;
					bestAreaTableIndex = area_loop;
				end
			end
			-- Record results for this pass. (A landmass has been assigned to receive one more start point than it previously had).
			numberOfCivsPerArea[bestAreaTableIndex] = numberOfCivsPerArea[bestAreaTableIndex] + 1;
			if TestMembership(inhabitedAreaIDs, bestRemainingArea) == false then
				table.insert(inhabitedAreaIDs, bestRemainingArea);
			end
		end
				
		-- Loop through the list of inhabited landmasses, dividing each landmass in to regions.
		-- Note that it is OK to divide a continent with one civ on it: this will assign the whole
		-- of the landmass to a single region, and is the easiest method of recording such a region.
		local iNumInhabitedLandmasses = table.maxn(inhabitedAreaIDs);
		for loop, currentLandmassID in ipairs(inhabitedAreaIDs) do
			-- Obtain the boundaries of and data for this landmass.
			local landmass_data = ObtainLandmassBoundaries(currentLandmassID);
			local iWestX = landmass_data[1];
			local iSouthY = landmass_data[2];
			local iEastX = landmass_data[3];
			local iNorthY = landmass_data[4];
			local iWidth = landmass_data[5];
			local iHeight = landmass_data[6];
			local wrapsX = landmass_data[7];
			local wrapsY = landmass_data[8];
			-- Obtain "Start Placement Fertility" of the current landmass. (Necessary to do this
			-- again because the fert_table can't be built prior to finding boundaries, and we had
			-- to ID the proper landmasses via fertility to be able to figure out their boundaries.
			local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityOfLandmass(currentLandmassID, 
		  	                                         iWestX, iEastX, iSouthY, iNorthY, wrapsX, wrapsY);
			-- Assemble the rectangle data for this landmass.
			local rect_table = {iWestX, iSouthY, iWidth, iHeight, currentLandmassID, fertCount, plotCount};
			-- Divide this landmass in to number of regions equal to civs assigned here.
			iNumCivsOnThisLandmass = numberOfCivsPerArea[loop];
			if iNumCivsOnThisLandmass > 0 and iNumCivsOnThisLandmass <= 22 then -- valid number of civs.
				self:DivideIntoRegions(iNumCivsOnThisLandmass, fert_table, rect_table)
			else
				print("Invalid number of civs assigned to a landmass: ", iNumCivsOnThisLandmass);
			end
		end
	end
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
	
  local RegionalMethod = 3;

	-- Get Resources setting input by user.
	local res = Map.GetCustomOption(13)
	local starts = Map.GetCustomOption(5)
	--if starts == 7 then
		--starts = 1 + Map.Rand(8, "Random Resources Option - Lua");
	--end

	-- Handle coastal spawns and start bias
	MixedBias = false;
	BalancedCoastal = false;
	OnlyCoastal = false;
	CoastLux = false;

	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()

	print("Dividing the map in to Regions.");
	local args = {
		method = 2,
		start_locations = starts,
		resources = res,
		CoastLux = CoastLux,
		NoCoastInland = OnlyCoastal,
		BalancedCoastal = BalancedCoastal,
		MixedBias = MixedBias;
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

