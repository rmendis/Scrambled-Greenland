-- Greenland.lua
-- Author: blkbutterfly74
-- DateCreated: 5/10/2017 6:25:20 PM
-- Creates a Standard map shaped like real-world Greenland 
-- based off Scrambled Australia map script
-- Thanks to Firaxis
-----------------------------------------------------------------------------

include "MapEnums"
include "MapUtilities"
include "MountainsCliffs"
include "RiversLakes"
include "FeatureGenerator"
include "TerrainGenerator"
include "NaturalWonderGenerator"
include "ResourceGenerator"
include "AssignStartingPlots"

local g_iW, g_iH;
local g_iFlags = {};
local g_continentsFrac = nil;
local g_iNumTotalLandTiles = 0; 
local g_CenterX = 18;
local g_CenterY = 35;

-------------------------------------------------------------------------------
function GenerateMap()
	print("Generating Greenland Map");
	local pPlot;

	-- Set globals
	g_iW, g_iH = Map.GetGridSize();
	g_iFlags = TerrainBuilder.GetFractalFlags();
	local temperature = 0;
	
	plotTypes = GeneratePlotTypes();
	terrainTypes = GenerateTerrainTypesGreenland(plotTypes, g_iW, g_iH, g_iFlags, true);

	for i = 0, (g_iW * g_iH) - 1, 1 do
		pPlot = Map.GetPlotByIndex(i);
		if (plotTypes[i] == g_PLOT_TYPE_HILLS) then
			terrainTypes[i] = terrainTypes[i] + 1;
		end
		TerrainBuilder.SetTerrainType(pPlot, terrainTypes[i]);
	end

	-- Temp
	AreaBuilder.Recalculate();
	local biggest_area = Areas.FindBiggestArea(false);
	print("After Adding Hills: ", biggest_area:GetPlotCount());

	-- Place lakes before rivers to allow them to act as river sources
	AddLakes();

	-- River generation is affected by plot types, originating from highlands and preferring to traverse lowlands.
	AddRivers();

	AddFeatures();
	
	print("Adding cliffs");
	AddCliffs(plotTypes, terrainTypes);
	
	local args = {
		numberToPlace = GameInfo.Maps[Map.GetMapSize()].NumNaturalWonders,
	};

	local nwGen = NaturalWonderGenerator.Create(args);

	AreaBuilder.Recalculate();
	TerrainBuilder.AnalyzeChokepoints();
	TerrainBuilder.StampContinents();
	
	local resourcesConfig = MapConfiguration.GetValue("resources");
	local startConfig = MapConfiguration.GetValue("start");-- Get the start config
	local args = {
		resources = resourcesConfig,
		iWaterLux = 4,
		START_CONFIG = startConfig,
	}
	local resGen = ResourceGenerator.Create(args);

	print("Creating start plot database.");
	-- START_MIN_Y and START_MAX_Y is the percent of the map ignored for major civs' starting positions.
	local args = {
		MIN_MAJOR_CIV_FERTILITY = 200,
		MIN_MINOR_CIV_FERTILITY = 50, 
		MIN_BARBARIAN_FERTILITY = 1,
		START_MIN_Y = 15,
		START_MAX_Y = 15,
		START_CONFIG = startConfig,
	};
	local start_plot_database = AssignStartingPlots.Create(args)

	local GoodyGen = AddGoodies(g_iW, g_iH);
end

-- Input a Hash; Export width, height, and wrapX
function GetMapInitData(MapSize)
	local Width = 48;
	local Height = 64;
	local WrapX = false;
	return {Width = Width, Height = Height, WrapX = WrapX,}
end
-------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Generating Plot Types");
	local plotTypes = {};

	-- Start with it all as water
	for x = 0, g_iW - 1 do
		for y = 0, g_iH - 1 do
			local i = y * g_iW + x;
			local pPlot = Map.GetPlotByIndex(i);
			plotTypes[i] = g_PLOT_TYPE_OCEAN;
			TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
		end
	end

	-- Each land strip is defined by: Y, X Start, X End
	local xOffset = 1;
	local yOffset = 1;
	local landStrips = {
		{1, 14, 15},
		{2, 13, 15},
		{3, 13, 16},
		{4, 10, 16},
		{5, 9, 16},
		{6, 9, 16},
		{7, 8, 16},
		{8, 7, 17},
		{9, 7, 18},
		{10, 6, 18},
		{11, 6, 18},
		{12, 6, 19},
		{13, 6, 19},
		{14, 6, 19},
		{15, 6, 22},
		{15, 39, 42},
		{16, 5, 23},
		{16, 38, 43},
		{17, 6, 24},
		{17, 38, 44},
		{18, 5, 25},
		{18, 37, 44},
		{19, 5, 25},
		{19, 38, 45},
		{20, 5, 25},
		{20, 39, 45},
		{21, 6, 14}, 
		{21, 16, 26}, 
		{21, 40, 45},
		{22, 6, 12}, 
		{22, 16, 27},
		{22, 42, 44},
		{23, 7, 12}, 
		{23, 19, 29},
		{23, 42, 43},
		{24, 8, 14},
		{24, 19, 30},
		{25, 6, 14},
		{25, 18, 31},
		{26, 5, 15},
		{26, 20, 32},
		{27, 6, 17},
		{27, 21, 32},
		{28, 6, 17},
		{28, 21, 33},
		{29, 7, 17},
		{29, 21, 33},
		{30, 7, 18},
		{30, 20, 33},
		{31, 6, 16},
		{31, 20, 33},
		{32, 6, 15},
		{32, 20, 33},
		{33, 7, 16},
		{33, 18, 32},
		{34, 6, 15},
		{34, 17, 32},
		{35, 6, 15},
		{35, 17, 32},
		{36, 7, 15},
		{36, 18, 31},
		{37, 6, 15}, 
		{37, 19, 31},
		{38, 6, 15},
		{38, 20, 32},
		{39, 6, 15},
		{39, 20, 31},
		{40, 6, 15},
		{40, 20, 32},
		{41, 6, 14},
		{41, 20, 32},
		{42, 6, 14},
		{42, 18, 32},
		{43, 5, 14},
		{43, 18, 31},
		{44, 2, 13},
		{44, 19, 30},
		{45, 1, 11},
		{45, 19, 30},
		{46, 1, 11},
		{46, 20, 30},
		{47, 1, 10},
		{47, 18, 18},
		{47, 21, 29},
		{48, 1, 10},
		{48, 19, 28},
		{49, 2, 10},
		{49, 18, 29},
		{50, 1, 13},
		{50, 20, 28},
		{51, 2, 16},
		{51, 19, 28},
		{52, 4, 28},
		{53, 5, 27},
		{54, 6, 26},
		{55, 7, 26},
		{56, 9, 26},
		{57, 10, 26},
		{58, 13, 22},
		{58, 25, 26},
		{59, 15, 22},
		{60, 18, 20}};
		
	for i, v in ipairs(landStrips) do
		local y = v[1] + yOffset; 
		local xStart = v[2] + xOffset;
		local xEnd = v[3] + xOffset; 
		for x = xStart, xEnd do
			local i = y * g_iW + x;
			local pPlot = Map.GetPlotByIndex(i);
			plotTypes[i] = g_PLOT_TYPE_LAND;
			TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_SNOW);  -- temporary setting so can calculate areas
			g_iNumTotalLandTiles = g_iNumTotalLandTiles + 1;
		end
	end
		
	AreaBuilder.Recalculate();

	--	world_age
	local world_age_new = 5;
	local world_age_normal = 3;
	local world_age_old = 2;

	local world_age = MapConfiguration.GetValue("world_age");
	if (world_age == 1) then
		world_age = world_age_new;
	elseif (world_age == 3) then
		world_age = world_age_old;
	else
		world_age = world_age_normal;	-- default
	end
	
	local args = {};
	args.world_age = world_age;
	args.iW = g_iW;
	args.iH = g_iH
	args.iFlags = g_iFlags;
	args.blendRidge = 10;
	args.blendFract = 1;
	args.extra_mountains = 4;
	plotTypes = ApplyTectonics(args, plotTypes);

	return plotTypes;
end

function InitFractal(args)

	if(args == nil) then args = {}; end

	local continent_grain = args.continent_grain or 2;
	local rift_grain = args.rift_grain or -1; -- Default no rifts. Set grain to between 1 and 3 to add rifts. - Bob
	local invert_heights = args.invert_heights or false;
	local polar = args.polar or true;
	local ridge_flags = args.ridge_flags or g_iFlags;

	local fracFlags = {};
	
	if(invert_heights) then
		fracFlags.FRAC_INVERT_HEIGHTS = true;
	end
	
	if(polar) then
		fracFlags.FRAC_POLAR = true;
	end
	
	if(rift_grain > 0 and rift_grain < 4) then
		local riftsFrac = Fractal.Create(g_iW, g_iH, rift_grain, {}, 6, 5);
		g_continentsFrac = Fractal.CreateRifts(g_iW, g_iH, continent_grain, fracFlags, riftsFrac, 6, 5);
	else
		g_continentsFrac = Fractal.Create(g_iW, g_iH, continent_grain, fracFlags, 6, 5);	
	end

	-- Use Brian's tectonics method to weave ridgelines in to the continental fractal.
	-- Without fractal variation, the tectonics come out too regular.
	--
	--[[ "The principle of the RidgeBuilder code is a modified Voronoi diagram. I 
	added some minor randomness and the slope might be a little tricky. It was 
	intended as a 'whole world' modifier to the fractal class. You can modify 
	the number of plates, but that is about it." ]]-- Brian Wade - May 23, 2009
	--
	local MapSizeTypes = {};
	for row in GameInfo.Maps() do
		MapSizeTypes[row.MapSizeType] = row.PlateValue;
	end
	local sizekey = Map.GetMapSize();

	local numPlates = MapSizeTypes[sizekey] or 4

	-- Blend a bit of ridge into the fractal.
	-- This will do things like roughen the coastlines and build inland seas. - Brian

	g_continentsFrac:BuildRidges(numPlates, {}, 1, 2);
end

function AddFeatures()
	print("Adding Features");

	-- Get Rainfall setting input by user.
	local rainfall = MapConfiguration.GetValue("rainfall");
	if rainfall == 4 then
		rainfall = 1 + TerrainBuilder.GetRandomNumber(3, "Random Rainfall - Lua");
	end
	
	local args = {rainfall = rainfall, iJunglePercent = 0, iReefPercent = 2}	-- no rainforest
	local featuregen = FeatureGenerator.Create(args);

	featuregen:AddFeatures();
end
------------------------------------------------------------------------------
function GenerateTerrainTypesGreenland(plotTypes, iW, iH, iFlags, bNoCoastalMountains)
	print("Generating Terrain Types");
	local terrainTypes = {};

	local fracXExp = -1;
	local fracYExp = -1;
	local grain_amount = 3;

	snow = Fractal.Create(iW, iH, 
									grain_amount, iFlags, 
									fracXExp, fracYExp);
									
	iSnowTop = snow:GetHeight(85);

	tundra = Fractal.Create(iW, iH, 
									grain_amount, iFlags, 
									fracXExp, fracYExp);
																		
	iTundraTop = tundra:GetHeight(100);
	iTundraBottom = tundra:GetHeight(35);

	plains = Fractal.Create(iW, iH, 
									grain_amount, iFlags, 
									fracXExp, fracYExp);
																		
	iPlainsTop = plains:GetHeight(90);
	iPlainsBottom = plains:GetHeight(45);

	grass = Fractal.Create(iW, iH, 
									grain_amount, iFlags, 
									fracXExp, fracYExp);
																		
	iGrassTop = plains:GetHeight(95);
	iGrassBottom = plains:GetHeight(35);

	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;
			if (plotTypes[index] == g_PLOT_TYPE_OCEAN) then
				if (IsAdjacentToLand(plotTypes, iX, iY)) then
					terrainTypes[index] = g_TERRAIN_TYPE_COAST;
				else
					terrainTypes[index] = g_TERRAIN_TYPE_OCEAN;
				end
			end
		end
	end

	if (bNoCoastalMountains == true) then
		plotTypes = RemoveCoastalMountains(plotTypes, terrainTypes);
	end

	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;

			local lat = (iY - iH/2)/(iH/2);
			local long = (iX - iW/2)/(iW/2);

			local iDistanceFromCenter = Map.GetPlotDistance (iX, iY, g_CenterX, g_CenterY);

			local snowVal = snow:GetHeight(iX, iY);
			local tundraVal = tundra:GetHeight(iX, iY);
			local plainsVal = plains:GetHeight(iX, iY);
			local grassVal = grass:GetHeight(iX, iY);

			-- Iceland
			if (long > 0.5 and lat < -0.25) then
				local iSnowBottom = snow:GetHeight(80);

				if (plotTypes[index] == g_PLOT_TYPE_MOUNTAIN) then
					terrainTypes[index] = g_TERRAIN_TYPE_TUNDRA_MOUNTAIN;

					if ((grassVal >= iGrassBottom) and (grassVal <= iGrassTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_GRASS_MOUNTAIN;
					elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_PLAINS_MOUNTAIN;
					elseif ((snowVal >= iSnowBottom) and (snowVal <= iSnowTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_SNOW_MOUNTAIN;
					end

				elseif (plotTypes[index] ~= g_PLOT_TYPE_OCEAN) then
					terrainTypes[index] = g_TERRAIN_TYPE_TUNDRA;

					if ((grassVal >= iGrassBottom) and (grassVal <= iGrassTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_GRASS;
					elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_PLAINS;
					elseif ((snowVal >= iSnowBottom) and (snowVal <= iSnowTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_SNOW;
					end
				end

			-- Greenland
			else
				local iSnowBottom = snow:GetHeight(iDistanceFromCenter/iH * 100);

				if (plotTypes[index] == g_PLOT_TYPE_MOUNTAIN) then
					terrainTypes[index] = g_TERRAIN_TYPE_GRASS_MOUNTAIN;

					if ((snowVal >= iSnowBottom) and (snowVal <= iSnowTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_SNOW_MOUNTAIN;
					elseif ((tundraVal >= iTundraBottom) and (tundraVal <= iTundraTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_TUNDRA_MOUNTAIN;
					elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_PLAINS_MOUNTAIN;
					end

				elseif (plotTypes[index] ~= g_PLOT_TYPE_OCEAN) then
					terrainTypes[index] = g_TERRAIN_TYPE_GRASS;
				
					if ((snowVal >= iSnowBottom) and (snowVal <= iSnowTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_SNOW;
					elseif ((tundraVal >= iTundraBottom) and (tundraVal <= iTundraTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_TUNDRA;
					elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_PLAINS;
					end
				end
			end
		end
	end

	local bExpandCoasts = true;

	if bExpandCoasts == false then
		return
	end

	print("Expanding coasts");
	for iI = 0, 2 do
		local shallowWaterPlots = {};
		for iX = 0, iW - 1 do
			for iY = 0, iH - 1 do
				local index = (iY * iW) + iX;
				if (terrainTypes[index] == g_TERRAIN_TYPE_OCEAN) then
					-- Chance for each eligible plot to become an expansion is 1 / iExpansionDiceroll.
					-- Default is two passes at 1/4 chance per eligible plot on each pass.
					if (IsAdjacentToShallowWater(terrainTypes, iX, iY) and TerrainBuilder.GetRandomNumber(4, "add shallows") == 0) then
						table.insert(shallowWaterPlots, index);
					end
				end
			end
		end
		for i, index in ipairs(shallowWaterPlots) do
			terrainTypes[index] = g_TERRAIN_TYPE_COAST;
		end
	end
	
	return terrainTypes; 
end

------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY)

	-- internal ice shelf
	if ((iY > 19 and iY < 53) and (iX > 9 and iX < 22)) then
		TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
	end 

	-- arctic ice shelf
	local iV = TerrainBuilder.GetRandomNumber(12, "Random variance");
	lat = (iY - self.iGridH/2 + iV)/(self.iGridH/2);	-- variance to make a more natural looking ice shelf
	
	if (lat > 0.78) then
		local iScore = TerrainBuilder.GetRandomNumber(100, "Resource Placement Score Adjust");

		iScore = iScore + lat * 100;

		if(IsAdjacentToLandPlot(iX,iY) == true) then
			iScore = iScore / 2.0;
		end

		local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_ICE);
		iScore = iScore + 10.0 * iAdjacent;

		if(iScore > 130) then
			TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
		end

		return true;
	end
end

------------------------------------------------------------------------------