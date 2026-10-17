
local colorCategory = Color( 221, 221, 221 )
local colorCategoryHovered = Color( 204, 204, 204 )
local colorCategoryActive = Color( 153, 204, 255 )
local colorCategoryText = Color( 85, 85, 85 )
local colorCategoryTextActive = Color( 51, 51, 51 )
local colorCount = Color( 170, 170, 170 )
local colorTitle = Color( 68, 68, 68 )
local colorTitleCount = Color( 153, 153, 153 )
local colorSettingLabel = Color( 102, 102, 102 )

local playerCounts = { 1, 2, 4, 8, 16, 32, 64, 128 }

MainMenu.NewGame = MainMenu.NewGame or {}

local function GetCategoryTitle( category )

	if ( category == "Favourites" ) then return language.GetPhrase( "newgame_favorite_maps" ) end
	if ( category == "Other" ) then return language.GetPhrase( "spawnmenu.category.other" ) end
	if ( category == "All" ) then return ( language.GetPhrase( "all" ):gsub( "^%l", string.upper ) ) end

	return category

end

local function GetCategories()

	local categories = {}
	local everything = {}

	for name, maps in pairs( GetMapList() ) do
		local order = name
		if ( name == "Favourites" ) then order = "1" end
		if ( name == "Sandbox" ) then order = "2" end

		table.insert( categories, { name = name, maps = maps, order = order } )

		if ( name != "Favourites" ) then table.Add( everything, maps ) end
	end

	table.SortByMember( categories, "order", true )
	table.insert( categories, 1, { name = "All", maps = everything } )

	return categories

end

local function GetCategoryMaps( category )

	local maps = table.Copy( GetMapList()[ category ] or {} )
	table.sort( maps )

	return maps

end

local function FilterMaps( maps, search )

	if ( search == "" ) then return maps end

	search = search:lower()

	local addonMaps = {}
	for title, files in pairs( GetAddonMapList() ) do
		if ( title:lower():find( search, 1, true ) ) then
			for _, filename in ipairs( files ) do addonMaps[ filename ] = true end
		end
	end

	local filtered = {}
	for _, map in ipairs( maps ) do
		if ( addonMaps[ map .. ".bsp" ] or map:lower():find( search, 1, true ) ) then table.insert( filtered, map ) end
	end

	return filtered

end

local function ParseServerSettings( settings )

	local parsed = {
		hostname = settings.hostname or "",
		sv_lan = tonumber( settings.sv_lan ) == 1,
		p2p_enabled = tonumber( settings.p2p_enabled ) == 1,
		p2p_friendsonly = tonumber( settings.p2p_friendsonly ) == 1,
		Text = {},
		Numeric = {},
		CheckBox = {}
	}

	local keys = table.GetKeys( settings.settings or {} )
	table.sort( keys, function( a, b ) return ( tonumber( a ) or 0 ) < ( tonumber( b ) or 0 ) end )

	for _, key in ipairs( keys ) do
		local setting = settings.settings[ key ]
		setting.text = setting.text or setting.name

		if ( setting.type == "CheckBox" ) then
			setting.Value = setting.Value == "1"
			table.insert( parsed.CheckBox, setting )
		elseif ( setting.type == "Numeric" ) then
			table.insert( parsed.Numeric, setting )
		else
			table.insert( parsed.Text, setting )
		end
	end

	return parsed

end

local function LoadDefaults( state )

	if ( !state.Map ) then
		local lastMap = string.Split( cookie.GetString( "lastmap", "" ), "\n" )

		if ( lastMap[ 1 ] != "" and lastMap[ 2 ] and file.Exists( "maps/" .. lastMap[ 1 ] .. ".bsp", "GAME" ) ) then
			state.Map = lastMap[ 1 ]
			state.Category = lastMap[ 2 ]
		end
	end

	if ( !state.Category ) then
		local favourites = GetMapList().Favourites

		if ( favourites and #favourites > 0 ) then
			state.Category = "Favourites"
			state.Map = state.Map or favourites[ 1 ]
		else
			state.Category = "Sandbox"
		end
	end

	state.Map = state.Map or "gm_flatgrass"

	if ( !state.MaxPlayers ) then
		local maxPlayers = cookie.GetNumber( "mainmenu_maxplayers", 1 )
		state.MaxPlayers = table.HasValue( playerCounts, maxPlayers ) and maxPlayers or 1
	end

end

local function StartGame( state, settings )

	local map = state.Map:Trim()
	local maxPlayers = state.MaxPlayers

	SaveLastMap( map, state.Category )

	hook.Run( "StartGame" )
	RunConsoleCommand( "progress_enable" )
	RunConsoleCommand( "disconnect" )
	RunConsoleCommand( "maxplayers", tostring( maxPlayers ) )
	RunConsoleCommand( "sv_cheats", "0" )

	timer.Simple( 0.2, function()
		if ( settings ) then
			for _, list in ipairs( { settings.Numeric, settings.Text } ) do
				for _, setting in ipairs( list ) do RunConsoleCommand( setting.name, tostring( setting.Value ) ) end
			end

			for _, setting in ipairs( settings.CheckBox ) do RunConsoleCommand( setting.name, setting.Value and "1" or "0" ) end
			for _, name in ipairs( { "p2p_enabled", "p2p_friendsonly", "sv_lan" } ) do RunConsoleCommand( name, settings[ name ] and "1" or "0" ) end

			RunConsoleCommand( "hostname", settings.hostname )
		end

		RunConsoleCommand( "maxplayers", tostring( maxPlayers ) )
		RunConsoleCommand( "map", map )
	end )

end

local function PaintCategory( button, w, h )

	local radius = MainMenu.Scale( 3 )
	local padding = MainMenu.Scale( 5 )

	local background = colorCategory
	if ( button.bActive ) then
		background = colorCategoryActive
	elseif ( button:IsHovered() ) then
		background = colorCategoryHovered
	end

	draw.RoundedBox( radius, 0, 0, w, h, background )

	local countFont = MainMenu.Font( 10, 700 )
	local countW = MainMenu.TextSize( button.Count, countFont ) + padding * 2
	local countX = w - padding - countW

	draw.RoundedBox( radius, countX, padding, countW, MainMenu.LineHeight( 10 ) + MainMenu.Scale( 4 ), color_white )
	MainMenu.DrawText( button.Count, countFont, countX + padding, padding + MainMenu.Scale( 2 ), colorCount )

	MainMenu.StartClip( button, MainMenu.Scale( 6 ), 0, w - MainMenu.Scale( 38 ), h )
	MainMenu.DrawText( button.Title, MainMenu.Font( 11, 700 ), MainMenu.Scale( 6 ), MainMenu.Scale( 6 ), button.bActive and colorCategoryTextActive or colorCategoryText )
	MainMenu.EndClip()

end

local function LayoutMapIcons( icons, top, width )

	local iconW = MainMenu.Scale( 144 )
	local perRow = math.max( 1, math.floor( width / iconW ) )
	local y = top

	for rowStart = 1, #icons, perRow do
		local rowEnd = math.min( rowStart + perRow - 1, #icons )
		local rowH = 0

		for i = rowStart, rowEnd do
			rowH = math.max( rowH, MainMenu.Scale( 8 + 128 + 2 + 8 ) + icons[ i ]:GetLineCount() * MainMenu.LineHeight( 10 ) )
		end

		for i = rowStart, rowEnd do
			icons[ i ]:SetPos( MainMenu.Scale( 10 ) + ( i - rowStart ) * iconW, y )
			icons[ i ]:SetSize( iconW, rowH )
		end

		y = y + rowH
	end

	return y + MainMenu.Scale( 10 )

end

MainMenu.AddPage( "newgame", function( pnl, menu )

	local state = MainMenu.NewGame
	LoadDefaults( state )

	local category = state.Category
	local search = ""
	local serverSettings

	local function Start()
		StartGame( state, serverSettings )
		menu:OpenPage( "main" )
	end

	local w, h = pnl:GetSize()
	local margin = MainMenu.Scale( 16 )
	local mapListW, mapListH = w - margin - MainMenu.Scale( 256 ), h - margin * 2
	local settingsX, settingsW, settingsH = w - margin - MainMenu.Scale( 226 ), MainMenu.Scale( 226 ), h - margin * 2

	pnl.Paint = function()
		draw.RoundedBox( MainMenu.Scale( 5 ), margin, margin, mapListW, mapListH, color_white )
		draw.RoundedBox( MainMenu.Scale( 5 ), settingsX, margin, settingsW, settingsH, color_white )
	end

	local controlsX, controlsY = margin + MainMenu.Scale( 10 ), margin + MainMenu.Scale( 10 )
	local controlsW, controlsH = MainMenu.Scale( 190 ), mapListH - MainMenu.Scale( 20 )

	local categories = vgui.Create( "DScrollPanel", pnl )
	categories:SetPos( controlsX, controlsY )
	categories:SetSize( controlsW, controlsH - MainMenu.Scale( 32 ) )
	MainMenu.StyleScrollBar( categories:GetVBar() )

	local mapsX = margin + MainMenu.Scale( 200 )

	local maps = vgui.Create( "DScrollPanel", pnl )
	maps:SetPos( mapsX, margin )
	maps:SetSize( margin + mapListW - mapsX, mapListH )
	MainMenu.StyleScrollBar( maps:GetVBar() )

	local settingsList = vgui.Create( "DScrollPanel", pnl )
	settingsList:SetPos( settingsX + MainMenu.Scale( 10 ), margin + MainMenu.Scale( 42 ) )
	settingsList:SetSize( settingsW - MainMenu.Scale( 10 ), settingsH - MainMenu.Scale( 42 + 90 ) )
	MainMenu.StyleScrollBar( settingsList:GetVBar() )

	local RefreshMaps

	local function RefreshCategories()
		categories:Clear()

		for _, info in ipairs( GetCategories() ) do
			local count = #FilterMaps( info.maps, search )
			if ( count == 0 ) then continue end

			local button = categories:Add( "DButton" )
			button:SetText( "" )
			button:Dock( TOP )
			button:DockMargin( 0, 0, 0, MainMenu.Scale( 5 ) )
			button:SetTall( MainMenu.Scale( 26 ) )
			button.Title = GetCategoryTitle( info.name )
			button.Count = tostring( count )
			button.bActive = info.name == category
			button.Paint = PaintCategory
			button.OnCursorEntered = function() MainMenu.PlaySound( "ui_hover" ) end
			button.DoClick = function()
				MainMenu.PlaySound( "ui_click" )
				category = info.name
				RefreshCategories()
				RefreshMaps()
			end
		end
	end

	local function GetSections()
		if ( category != "All" ) then
			local allMaps = GetCategoryMaps( category )
			if ( #allMaps == 0 ) then return {} end

			return { { name = category, maps = FilterMaps( allMaps, search ), total = #allMaps } }
		end

		local sections = {}

		for _, info in ipairs( GetCategories() ) do
			if ( info.name == "All" or info.name == "Favourites" ) then continue end

			local allMaps = GetCategoryMaps( info.name )
			local filtered = FilterMaps( allMaps, search )

			if ( #filtered > 0 ) then
				table.insert( sections, { name = info.name, maps = filtered, total = #allMaps } )
			end
		end

		return sections
	end

	local function CreateHeader( canvas, section )
		local title = GetCategoryTitle( section.name )
		local count = #section.maps .. " " .. language.GetPhrase( section.total == 1 and "newgame_map" or "newgame_maps" )

		local header = vgui.Create( "Panel", canvas )
		header:SetSize( MainMenu.Scale( 600 ), MainMenu.LineHeight( 32 ) + MainMenu.Scale( 10 ) )
		header.Paint = function()
			local titleFont, countFont = MainMenu.Font( 32 ), MainMenu.Font( 14 )
			local titleW = MainMenu.TextSize( title .. " ", titleFont )

			MainMenu.DrawText( title, titleFont, MainMenu.Scale( 5 ), MainMenu.Scale( 5 ), colorTitle )
			MainMenu.DrawText( count, countFont, MainMenu.Scale( 5 ) + titleW, MainMenu.Scale( 5 ) + MainMenu.Ascent( 32 ) - MainMenu.Ascent( 14 ), colorTitleCount )
		end

		return header
	end

	local function CreateMapIcon( canvas, map, mapCategory )
		local icon = vgui.Create( "MainMenuMapIcon", canvas )
		icon:Setup( map, mapCategory )
		icon.IsSelected = function() return state.Map == map end
		icon.OnSelect = function()
			state.Map = map
			state.Category = mapCategory
		end
		icon.OnStart = Start

		return icon
	end

	local function LayoutSections( sections, width )
		local y = MainMenu.Scale( 10 )

		for _, section in ipairs( sections ) do
			section.header:SetPos( MainMenu.Scale( 10 ), y )
			y = LayoutMapIcons( section.icons, y + section.header:GetTall(), width )
		end

		return y
	end

	RefreshMaps = function( bScrollToSelected )
		maps:Clear()

		local sections = GetSections()
		if ( #sections == 0 ) then return end

		local canvas = maps:GetCanvas()
		local selected

		for _, section in ipairs( sections ) do
			section.header = CreateHeader( canvas, section )
			section.icons = {}

			for _, map in ipairs( section.maps ) do
				local icon = CreateMapIcon( canvas, map, section.name )
				if ( map == state.Map and ( !selected or section.name == state.Category ) ) then selected = icon end

				table.insert( section.icons, icon )
			end
		end

		local width = maps:GetWide() - MainMenu.Scale( 20 )
		local height = LayoutSections( sections, width )

		if ( height > maps:GetTall() ) then
			height = LayoutSections( sections, width - MainMenu.Scale( 8 ) )
		end

		canvas:SetTall( height )
		maps:InvalidateLayout( true )

		if ( bScrollToSelected and IsValid( selected ) ) then
			maps:ScrollToChild( selected )
		end
	end

	local settingY, bFirstSetting
	local settingW = settingsList:GetWide() - MainMenu.Scale( 10 )

	local function AddSettingMargin( size )
		settingY = settingY + MainMenu.Scale( bFirstSetting and 6 or size )
		bFirstSetting = false
	end

	local function AddTextSetting( label, value, onChange )
		AddSettingMargin( 8 )

		label = language.GetPhrase( label )

		local font = MainMenu.Font( 11 )
		local text = vgui.Create( "Panel", settingsList:GetCanvas() )
		text:SetPos( 0, settingY )
		text:SetSize( settingW, MainMenu.LineHeight( 11 ) )
		text.Paint = function() MainMenu.DrawText( label, font, 0, 0, colorSettingLabel ) end

		settingY = settingY + text:GetTall() + MainMenu.Scale( 2 )

		local entry = vgui.Create( "MainMenuTextEntry", settingsList:GetCanvas() )
		entry:SetPos( 0, settingY )
		entry:SetSize( settingW, MainMenu.LineHeight( 12 ) + MainMenu.Scale( 8 ) + 2 )
		entry:SetValue( value or "" )
		entry.OnValueChange = function( s, newValue ) onChange( newValue ) end

		settingY = settingY + entry:GetTall()
	end

	local function AddNumericSetting( label, value, onChange )
		AddSettingMargin( 4 )

		label = language.GetPhrase( label )

		local font = MainMenu.Font( 11 )
		local entryW = MainMenu.Scale( 50 )
		local height = MainMenu.Scale( 24 ) + 2

		local text = vgui.Create( "Panel", settingsList:GetCanvas() )
		text:SetPos( 0, settingY )
		text:SetSize( settingW - entryW, height )
		text.Paint = function() MainMenu.DrawText( label, font, 0, math.floor( ( MainMenu.Scale( 20 ) - MainMenu.LineHeight( 11 ) ) / 2 ), colorSettingLabel ) end

		local entry = vgui.Create( "MainMenuTextEntry", settingsList:GetCanvas() )
		entry:SetPos( settingW - entryW, settingY )
		entry:SetSize( entryW, height )
		entry:SetValue( tostring( value or "" ) )
		entry.OnValueChange = function( s, newValue ) onChange( newValue ) end

		settingY = settingY + height
	end

	local function AddCheckBoxSetting( label, value, onChange, indent, marginTop )
		AddSettingMargin( marginTop or 8 )

		local row = vgui.Create( "MainMenuToggleLabel", settingsList:GetCanvas() )
		row:SetPos( MainMenu.Scale( indent or 0 ), settingY )

		row:Setup( "MainMenuCheckBox", label, 11, colorSettingLabel )
		row:SetChecked( value )
		row.OnChange = function( s, bChecked ) onChange( bChecked ) end

		settingY = settingY + MainMenu.Scale( 17 )

		return row
	end

	local function AddServerSettings( settings )
		AddTextSetting( "server_name", settings.hostname, function( value ) settings.hostname = value end )

		local lan, p2p, friendsOnly

		local function UpdateNetworkSettings()
			lan:SetChecked( settings.sv_lan )
			p2p:SetChecked( settings.p2p_enabled )
			friendsOnly:SetDisabled( !settings.p2p_enabled )
		end

		lan = AddCheckBoxSetting( "lan_server", settings.sv_lan, function( bChecked )
			settings.sv_lan = bChecked
			if ( bChecked ) then settings.p2p_enabled = false end
			UpdateNetworkSettings()
		end )

		p2p = AddCheckBoxSetting( "p2p_server", settings.p2p_enabled, function( bChecked )
			settings.p2p_enabled = bChecked
			if ( bChecked ) then settings.sv_lan = false end
			UpdateNetworkSettings()
		end )

		friendsOnly = AddCheckBoxSetting( "p2p_server_friendsonly", settings.p2p_friendsonly, function( bChecked )
			settings.p2p_friendsonly = bChecked
		end, 18, 4 )

		UpdateNetworkSettings()
	end

	local function RefreshSettings()
		settingsList:Clear()
		if ( !serverSettings ) then return end

		local bMultiplayer = state.MaxPlayers > 1

		settingY = 0
		bFirstSetting = true

		if ( bMultiplayer ) then AddServerSettings( serverSettings ) end

		for _, group in ipairs( { { serverSettings.Text, AddTextSetting }, { serverSettings.Numeric, AddNumericSetting }, { serverSettings.CheckBox, AddCheckBoxSetting } } ) do
			for _, setting in ipairs( group[ 1 ] ) do
				if ( bMultiplayer or setting.Singleplayer ) then
					group[ 2 ]( setting.text, setting.Value, function( value ) setting.Value = value end )
				end
			end
		end

		settingsList:GetCanvas():SetTall( settingY )
		settingsList:InvalidateLayout( true )
	end

	local searchBox = vgui.Create( "MainMenuTextEntry", pnl )
	searchBox:SetPos( controlsX, controlsY + controlsH - MainMenu.Scale( 24 ) )
	searchBox:SetSize( controlsW, MainMenu.Scale( 24 ) )
	searchBox:SetPlaceholder( "searchbar_placeholder" )
	searchBox.OnValueChange = function( s, text )
		search = text
		RefreshCategories()
		RefreshMaps()
	end
	searchBox:RequestFocus()

	local maxPlayers = vgui.Create( "MainMenuDropdown", pnl )
	maxPlayers:SetPos( settingsX + MainMenu.Scale( 10 ), margin + MainMenu.Scale( 10 ) )
	maxPlayers:SetSize( settingsW - MainMenu.Scale( 20 ), MainMenu.Scale( 30 ) )
	maxPlayers:SetValue( state.MaxPlayers )
	maxPlayers.OnSelect = function( s, count )
		state.MaxPlayers = count
		cookie.Set( "mainmenu_maxplayers", tostring( count ) )
		RefreshSettings()
	end

	for _, count in ipairs( playerCounts ) do
		maxPlayers:AddOption( "maxplayers_" .. count, count )
	end

	local startH = MainMenu.LineHeight( 20 ) + MainMenu.Scale( 20 ) + 2

	local start = vgui.Create( "MainMenuButton", pnl )
	start:Setup( "start_game", 20 )
	start:SetPos( settingsX + MainMenu.Scale( 18 ), margin + settingsH - MainMenu.Scale( 18 ) - startH )
	start:SetSize( settingsW - MainMenu.Scale( 36 ), startH )
	start.OnClick = Start

	hook.Add( "MainMenuServerSettings", pnl, function( s, settings )
		serverSettings = ParseServerSettings( settings )
		RefreshSettings()
	end )

	hook.Add( "MainMenuMapListChanged", pnl, function()
		local scroll = maps:GetVBar():GetScroll()

		RefreshCategories()
		RefreshMaps()

		maps:GetVBar():SetScroll( scroll )
	end )

	RefreshCategories()
	RefreshMaps( true )

	UpdateServerSettings()

end )
