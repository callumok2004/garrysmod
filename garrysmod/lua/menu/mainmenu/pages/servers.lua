
local colorBlue = Color( 35, 135, 237 )
local colorBlueHovered = Color( 79, 157, 237 )
local colorClose = Color( 26, 140, 255 )
local colorSeparatorShadow = Color( 0, 0, 0, 200 )

local function CreateBlueButton( parent, paint, onClick )

	local button = vgui.Create( "DButton", parent )
	button:SetText( "" )
	button.Paint = function( s, w, h )
		paint( w, h, s:IsHovered() and colorBlueHovered or colorBlue )
	end
	button.DoClick = onClick

	return button

end

local function GetOptionsKey( servers )

	local gm = servers.Gamemode

	return table.concat( { servers.Type, tostring( servers.Refreshing[ servers.Type ] ), tostring( gm ), gm and table.Count( gm.flags ) or 0 }, "|" )

end

local function GetInnerKey( servers )

	local gm = servers.Gamemode

	return table.concat( { tostring( gm ), tostring( gm and gm.selected ), servers.Type, tostring( servers.FoundServers ) }, "|" )

end

MainMenu.AddPage( "servers", function( pnl, menu )

	local servers = MainMenu.Servers
	local viewportW = MainMenu.ViewportWidth()
	local bNarrow = viewportW <= 1366
	local optionsW = MainMenu.Scale( bNarrow and 250 or 320 )
	local optionsX = MainMenu.Scale( bNarrow and 21 or 86 )
	local filtersW = MainMenu.Scale( 206 )
	local rowH = MainMenu.LineHeight( 23 ) + MainMenu.Scale( 1 )

	local options, inner, gamemodeList, serverList, countLabels

	local function AddFilterRow( class, phrase, bChecked )
		local row = options:Add( "MainMenuToggleLabel" )
		row:Setup( class, phrase, 16, color_white, true )
		row:SetChecked( bChecked )
		row:SetTall( MainMenu.LineHeight( 16 ) + MainMenu.Scale( 1 ) )
		row:Dock( TOP )

		return row
	end

	local function AddLabel( parent, text, size )
		local label = parent:Add( "MainMenuShadowLabel" )
		label:SetFontSize( size or 16 )
		label:SetText( text )
		label:Dock( TOP )

		return label
	end

	local function AddLink( phrase, onClick, type, gap )
		local link = options:Add( "MainMenuLink" )
		link:Setup( phrase )
		link:SetActive( type != nil and servers.Type == type )
		link:Dock( TOP )
		link:DockMargin( 0, gap or 0, filtersW - link:GetWide(), rowH - link:GetTall() )
		link.OnClick = onClick
	end

	local function BuildGamemodeFilters()
		AddLabel( options, "addons.sort_by" )

		local radios = {}
		for _, sort in ipairs( { { "gmsort_players", "order" }, { "gmsort_servers", "numServers" }, { "gmsort_name", "title" } } ) do
			local row = AddFilterRow( "MainMenuRadioButton", sort[ 1 ], servers.GamemodeSort == sort[ 2 ] )
			row.OnChange = function()
				servers.GamemodeSort = sort[ 2 ]
				for _, other in ipairs( radios ) do other:SetChecked( other == row ) end
				servers:Changed()
			end

			table.insert( radios, row )
		end

		AddLabel( options, "addons.filter_by" )

		local checkboxes = {}
		local remove = MainMenu.Material( "html/img/remove.png" )

		for _, category in ipairs( servers.Categories ) do
			local row = AddFilterRow( "MainMenuCheckBox", "gmfltr_hide_" .. category, servers.GamemodeFilterTags[ category ] == true )
			row.OnChange = function( s, bChecked ) servers:SetCategoryFiltered( category, bChecked ) end
			checkboxes[ category ] = row

			local only = vgui.Create( "DButton", row )
			only:SetText( "" )
			only:SetSize( MainMenu.Scale( 16 ), MainMenu.Scale( 16 ) )
			only:SetPos( row:GetTextEnd() + MainMenu.TextSize( " ", MainMenu.Font( 16, 700 ) ) + MainMenu.Scale( 3 ), math.floor( ( row:GetTall() - only:GetTall() ) / 2 ) )
			only.Paint = function( s, bw, bh )
				if ( remove ) then MainMenu.DrawImage( remove, 0, 0, bw, bh ) end
			end
			only.DoClick = function()
				servers:FilterAllCategoriesExcept( category )
				for name, other in pairs( checkboxes ) do other:SetChecked( servers.GamemodeFilterTags[ name ] == true ) end
			end
		end

		local search = options:Add( "MainMenuTextEntry" )
		search:SetTall( MainMenu.Scale( 34 ) )
		search:Dock( TOP )
		search:DockMargin( 0, MainMenu.Scale( 6 ), -MainMenu.Scale( 10 ), 0 )
		search:SetRadius( 3 )
		search:SetPaddingX( 5 )
		search:SetPlaceholder( "gmsearch_placeholder" )
		search:SetValue( servers.GamemodeSearch )
		search.OnValueChange = function( s, value )
			servers.GamemodeSearch = value
			servers:Changed()
		end
	end

	local function BuildServerFilters()
		local filters = servers.Filters

		local function AddNumberRow( label )
			AddLabel( options, label )

			local row = options:Add( "Panel" )
			row:SetTall( MainMenu.LineHeight( 12 ) + MainMenu.Scale( 4 ) + 2 )
			row:Dock( TOP )
			row:DockMargin( 0, 0, 0, MainMenu.Scale( 2 ) )

			return row
		end

		local function AddNumber( row, key, placeholder )
			local entry = row:Add( "MainMenuTextEntry" )
			entry:SetWide( MainMenu.Scale( 92 ) )
			entry:Dock( LEFT )
			entry:SetNumeric( true )
			entry:SetCenterText( true )
			entry:SetPlaceholder( placeholder )
			entry:SetValue( tostring( filters[ key ] ) )
			entry.OnValueChange = function( s, value )
				filters[ key ] = tonumber( value ) or tonumber( placeholder )
				servers:FiltersChanged()
			end
		end

		local players = AddNumberRow( "svfltr_ply_limit" )
		AddNumber( players, "MinPlayers", "0" )

		local dash = AddLabel( players, " - " )
		dash:SetWide( dash:GetTextWidth() )
		dash:Dock( LEFT )

		AddNumber( players, "MaxPlayers", "128" )
		AddNumber( AddNumberRow( "svfltr_ping_limit" ), "MaxPing", "2000" )

		for _, filter in ipairs( { { "svfltr_not_full", "NotFull" }, { "svfltr_has_players", "HasPlayers" }, { "svfltr_no_password", "HidePassword", "html/img/server-passworded.png" }, { "svfltr_outdated", "HideOutdated" } } ) do
			local row = AddFilterRow( "MainMenuCheckBox", filter[ 1 ], filters[ filter[ 2 ] ] )
			row.OnChange = function( s, bChecked )
				filters[ filter[ 2 ] ] = bChecked
				servers:FiltersChanged()
			end

			local icon = filter[ 3 ] and MainMenu.Material( filter[ 3 ] )
			if ( icon ) then
				local image = vgui.Create( "Panel", row )
				image:SetPos( row:GetTextEnd() + MainMenu.TextSize( " ", MainMenu.Font( 16, 700 ) ), 0 )
				image:SetSize( MainMenu.Scale( 16 ), MainMenu.Scale( 16 ) )
				image:SetMouseInputEnabled( false )
				image.Paint = function( s, iw, ih ) MainMenu.DrawImage( icon, 0, 0, iw, ih ) end
			end
		end

		local gm = servers.Gamemode
		if ( !gm.hasFlags ) then return end

		local flags = table.GetKeys( gm.flags )
		table.sort( flags )

		local flagFilter = options:Add( "MainMenuFlagFilter" )
		flagFilter:SetWide( filtersW )
		flagFilter:SetFlags( flags, gm.filterFlags )
		flagFilter:Dock( TOP )
		flagFilter:DockMargin( 0, MainMenu.Scale( 5 ), 0, 0 )
		flagFilter.OnToggle = function( s, flag ) servers:ToggleFlagFilter( gm, flag ) end
	end

	local function BuildOptions()
		if ( IsValid( options ) ) then options:Remove() end

		options = pnl:Add( "Panel" )
		options:SetWide( optionsW )
		options:Dock( LEFT )
		options:DockPadding( optionsX, MainMenu.Scale( 75 ), optionsW - optionsX - filtersW, 0 )
		options.Key = GetOptionsKey( servers )

		AddLabel( options, "server_list", 34.5 ):DockMargin( 0, 0, 0, MainMenu.Scale( 4 ) )

		countLabels = { servers = AddLabel( options ), gamemodes = AddLabel( options ) }
		countLabels.gamemodes:DockMargin( 0, 0, 0, rowH )

		for _, type in ipairs( { { "servers_internet", "internet" }, { "servers_favorites", "favorite" }, { "servers_history", "history" }, { "servers_local", "lan" } } ) do
			AddLink( type[ 1 ], function() servers:SwitchType( type[ 2 ] ) end, type[ 2 ] )
		end

		if ( servers.Refreshing[ servers.Type ] ) then
			AddLink( "servers_stoprefresh", function() servers:StopRefresh() end, nil, rowH )
		elseif ( !servers.Gamemode ) then
			AddLink( "servers_refresh", function() servers:Refresh() end, nil, rowH )
		end

		AddLink( "legacy_browser", function() RunGameUICommand( "OpenServerBrowser" ) end, nil, rowH )

		local separator = options:Add( "Panel" )
		separator:SetTall( MainMenu.Scale( 3 ) )
		separator:Dock( TOP )
		separator:DockMargin( -MainMenu.Scale( 16 ), rowH, -MainMenu.Scale( 16 ), 1 + MainMenu.Scale( 21 ) )
		separator.Paint = function( s, sw )
			surface.SetDrawColor( colorSeparatorShadow )
			surface.DrawRect( MainMenu.Scale( 1 ), MainMenu.Scale( 1 ), sw, MainMenu.Scale( 1 ) )
			surface.SetDrawColor( color_white )
			surface.DrawRect( 0, 0, sw, 1 )
		end

		if ( servers.Gamemode ) then
			BuildServerFilters()
		else
			BuildGamemodeFilters()
		end
	end

	local function AddHeader( title, subtitle )
		local header = inner:Add( "MainMenuHeader" )
		header:Dock( TOP )
		header:DockMargin( MainMenu.Scale( 16 ), MainMenu.Scale( 16 ), MainMenu.Scale( 16 ), 0 )
		header:Setup( title, subtitle )
	end

	local function AddBox( x, y, w, h, padding )
		local box = inner:Add( "Panel" )
		box:SetPos( x, y )
		box:SetSize( w, h )
		box:DockPadding( padding, padding, padding, padding )
		box.Paint = function( s, bw, bh ) draw.RoundedBox( MainMenu.Scale( 4 ), 0, 0, bw, bh, color_white ) end

		return box
	end

	local function BuildGamemodes()
		AddHeader( "servers_gamemodes", "servers_gamemodes.subtitle" )

		local boxW = inner:GetWide()
		if ( viewportW >= 1280 ) then boxW = math.min( math.floor( boxW * 0.8 ), MainMenu.Scale( 1000 ) ) + MainMenu.Scale( 10 ) end

		local box = AddBox( math.floor( ( inner:GetWide() - boxW ) / 2 ), MainMenu.Scale( 64 ), boxW, inner:GetTall() - MainMenu.Scale( 64 ), MainMenu.Scale( 5 ) )

		if ( servers.Type == "favorite" ) then
			local find = box:Add( "MainMenuFindServer" )
			find:SetWide( boxW - MainMenu.Scale( 10 ) )
			find:SetAddress( servers.FindAddress or "" )
			find:SetServers( servers.FoundServers or {} )
			find:Dock( BOTTOM )
			find.OnFind = function( s, address )
				servers.FindAddress = address
				servers:SetFoundServers( {} )
				if ( address != "" ) then FindServersAtAddress( address ) end
			end
			find.OnToggleFavorite = function( s, server )
				servers:ToggleFavorite( server )
				servers:Refresh()
			end
		end

		gamemodeList = box:Add( "MainMenuGamemodeList" )
		gamemodeList:Dock( FILL )
		box:InvalidateLayout( true )

		gamemodeList:SetItems( servers:GetSortedGamemodes() )
		gamemodeList.ShouldShowInstall = function( s, gm ) return servers:ShouldShowInstall( gm ) end
		gamemodeList.OnInstall = function( s, gm ) servers:InstallGamemode( gm ) end
		gamemodeList.OnSelect = function( s, gm ) servers:SelectGamemode( gm ) end
	end

	local function BuildServers()
		local gm = servers.Gamemode
		local selected = gm.selected
		local w, h = inner:GetSize()

		AddHeader( servers:GetGamemodeName( gm ), "join_a_server" )

		if ( servers:ShouldShowInstall( gm ) ) then
			local text = language.GetPhrase( "servers_install_gamemode" )
			local font = MainMenu.Font( 24, 700 )
			local icon = MainMenu.Material( "html/img/gm_install32.png" )

			local install = CreateBlueButton( inner, function( bw, bh, color )
				draw.RoundedBox( MainMenu.Scale( 5 ), 0, 0, bw, bh, color_white )
				draw.RoundedBox( MainMenu.Scale( 4 ), MainMenu.Scale( 2 ), MainMenu.Scale( 2 ), bw - MainMenu.Scale( 4 ), bh - MainMenu.Scale( 4 ), color )
				if ( icon ) then
					local iconW, iconH = MainMenu.MaterialSize( icon )
					MainMenu.DrawImage( icon, MainMenu.Scale( 8 ), math.floor( ( bh - iconH ) / 2 ), iconW, iconH )
				end
				MainMenu.DrawText( text, font, MainMenu.Scale( 38 ), math.floor( ( bh - MainMenu.LineHeight( 24 ) ) / 2 ), color_white )
			end, function() servers:InstallGamemode( gm ) end )

			install:SetSize( MainMenu.Scale( 45 ) + MainMenu.TextSize( text, font ), MainMenu.Scale( 39 ) )
			install:SetPos( w - install:GetWide(), MainMenu.Scale( 10 ) )
		end

		local controlsY = MainMenu.Scale( 20 ) + MainMenu.LineHeight( 24 ) + MainMenu.Scale( 5 )
		local backText = language.GetPhrase( "return_to_gamemodes" )
		local backFont = MainMenu.Font( 14, 700 )
		local arrow = MainMenu.Material( "html/img/bg_arrow_left.png" )
		local space = MainMenu.TextSize( " ", backFont )

		local back = CreateBlueButton( inner, function( bw, bh, color )
			draw.RoundedBox( MainMenu.Scale( 3 ), 0, 0, bw, bh, color )
			if ( arrow ) then MainMenu.DrawImage( arrow, MainMenu.Scale( 10 ), math.floor( ( bh - MainMenu.Scale( 12 ) ) / 2 ), MainMenu.Scale( 12 ), MainMenu.Scale( 12 ) ) end
			MainMenu.DrawText( backText, backFont, MainMenu.Scale( 22 ) + space, MainMenu.Scale( 8 ), color_white )
		end, function() servers:SelectGamemode( nil ) end )

		back:SetSize( MainMenu.Scale( 32 ) + space + MainMenu.TextSize( backText, backFont ), MainMenu.Scale( 16 ) + MainMenu.LineHeight( 14 ) )
		back:SetPos( MainMenu.Scale( 16 ), controlsY )

		local searchW = math.max( math.floor( w * 0.15 ), MainMenu.Scale( 150 ) ) + MainMenu.Scale( 20 ) + 2

		local search = vgui.Create( "MainMenuTextEntry", inner )
		search:SetSize( searchW, MainMenu.LineHeight( 12 ) + MainMenu.Scale( 14 ) + 2 )
		search:SetPos( w - searchW, controlsY )
		search:SetPaddingX( 10 )
		search:SetPlaceholder( "svsearch_placeholder" )
		search:SetValue( gm.search )
		search.OnValueChange = function( s, value )
			gm.search = value
			gm.bDirty = true
			servers:Changed()
		end

		local bSmall = viewportW <= 1000
		local listY = MainMenu.Scale( 90 )
		local infoW = selected and MainMenu.Scale( bSmall and 150 or ( viewportW <= 1366 and 215 or 280 ) ) or 0
		local listW = w - ( selected and infoW + MainMenu.Scale( 10 ) or 0 )
		local inset = MainMenu.Scale( bSmall and 3 or 8 )

		local box = AddBox( 0, listY, listW, h - listY, inset )

		local listHeader = box:Add( "MainMenuServerListHeader" )
		listHeader:SetTall( MainMenu.Scale( 24 ) )
		listHeader:Dock( TOP )
		listHeader.OnSort = function( s, key ) servers:ChangeOrder( gm, key ) end

		serverList = box:Add( "MainMenuServerList" )
		serverList:Dock( FILL )
		serverList:DockMargin( 0, MainMenu.Scale( bSmall and 25 or 32 ) - inset - MainMenu.Scale( 24 ), 0, 0 )
		box:InvalidateLayout( true )

		serverList:SetItems( servers:GetSortedServers( gm ) )
		serverList:SetSelected( selected )
		serverList.OnSelect = function( s, server ) servers:SelectServer( server ) end
		serverList.OnJoin = function( s, server ) servers:Join( server ) end
		serverList.OnToggleFavorite = function( s, server ) servers:ToggleFavorite( server ) end

		if ( !selected ) then return end

		local info = vgui.Create( "MainMenuServerInfo", inner )
		info:SetPos( listW + MainMenu.Scale( 10 ), listY )
		info:SetSize( infoW, h - listY )
		info:SetServer( selected, servers.JoinWhenNotFull )
		info.OnJoin = function() servers:Join( selected ) end
		info.OnPasswordChanged = function( s, password ) selected.password = password end
		info.OnJoinWhenNotFullChanged = function( s, bJoin ) servers.JoinWhenNotFull = bJoin end

		local cross = MainMenu.Material( "html/img/cross.png" )

		local close = vgui.Create( "DButton", inner )
		close:SetText( "" )
		close:SetSize( MainMenu.Scale( 21 ), MainMenu.Scale( 21 ) )
		close:SetPos( w - MainMenu.Scale( 22 ), listY + MainMenu.Scale( 1 ) )
		close.Paint = function( s, bw, bh )
			draw.RoundedBox( MainMenu.Scale( 4 ), 0, 0, bw, bh, s:IsHovered() and colorBlueHovered or colorClose )
			if ( cross ) then MainMenu.DrawImage( cross, MainMenu.Scale( 3 ), MainMenu.Scale( 3 ), MainMenu.Scale( 15 ), MainMenu.Scale( 15 ) ) end
		end
		close.DoClick = function() servers:SelectServer( nil ) end
	end

	local function BuildInner()
		local scroll
		if ( IsValid( inner ) ) then
			local list = gamemodeList or serverList
			if ( IsValid( list ) and inner.Gamemode == servers.Gamemode ) then scroll = list:GetScroll() end

			inner:Remove()
		end

		gamemodeList, serverList = nil, nil

		local margin = viewportW >= 1367 and MainMenu.Scale( 50 ) or 0

		inner = pnl:Add( "Panel" )
		inner:Dock( FILL )
		inner:DockMargin( 0, MainMenu.Scale( 16 ), margin + MainMenu.Scale( bNarrow and 5 or 16 ), MainMenu.Scale( 16 ) )
		inner.Key = GetInnerKey( servers )
		inner.Gamemode = servers.Gamemode
		pnl:InvalidateLayout( true )

		if ( servers.Gamemode ) then
			BuildServers()
		else
			BuildGamemodes()
		end

		if ( scroll ) then ( gamemodeList or serverList ):SetScroll( scroll ) end
	end

	local function UpdateCounts()
		countLabels.servers:SetText( ( servers.Count[ servers.Type ] or 0 ) .. " " .. language.GetPhrase( "servers_servercount" ) )
		countLabels.gamemodes:SetText( #servers:GetGamemodes() .. " " .. language.GetPhrase( "servers_gmcount" ) )
	end

	local seenVersion
	local nextUpdate = 0

	pnl.Think = function()
		if ( servers.Version == seenVersion or SysTime() < nextUpdate ) then return end

		seenVersion = servers.Version
		nextUpdate = SysTime() + 0.25

		if ( GetOptionsKey( servers ) != options.Key ) then BuildOptions() end
		if ( GetInnerKey( servers ) != inner.Key ) then BuildInner() end

		UpdateCounts()

		if ( IsValid( gamemodeList ) ) then gamemodeList:SetItems( servers:GetSortedGamemodes() ) end
		if ( IsValid( serverList ) ) then serverList:SetItems( servers:GetSortedServers( servers.Gamemode ) ) end
	end

	pnl.OnRemove = function()
		servers:StopRefresh()
		servers:StopUpdating()
	end

	if ( !servers.Type ) then servers:SwitchType( "internet" ) end

	BuildOptions()
	BuildInner()
	UpdateCounts()

	seenVersion = servers.Version

end )
