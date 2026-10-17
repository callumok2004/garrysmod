
MainMenu.Servers = MainMenu.Servers or {
	Types = {},
	RequestNum = {},
	Refreshing = {},
	Count = {},
	GamemodeInfo = {},
	Categories = { "rp", "pvp", "pve", "other", "none" },
	GamemodeSort = "order",
	GamemodeFilterTags = {},
	GamemodeSearch = "",
	Filters = { HasPlayers = false, NotFull = false, HidePassword = false, HideOutdated = false, MaxPing = 2000, MinPlayers = 0, MaxPlayers = 128 },
	FilterVersion = 0,
	Version = 0
}

function MainMenu.Servers:Changed()

	self.Version = self.Version + 1

end

local stripRanges = {
	{ 0x1400, 0x16FF }, { 0x2100, 0x23FF }, { 0x2580, 0x27BF }, { 0x2900, 0x297F },
	{ 0x2A00, 0x2BFF }, { 0x3000, 0x303F }
}

local function IsWeirdSymbol( codepoint )

	if ( codepoint > 0xFFFF or codepoint == 0x3299 ) then return true end

	for _, range in ipairs( stripRanges ) do
		if ( codepoint >= range[ 1 ] and codepoint <= range[ 2 ] ) then return true end
	end

	return false

end

local function StripWeirdSymbols( str )

	if ( !utf8.len( str ) ) then return str end

	local out = {}
	for _, codepoint in utf8.codes( str ) do
		if ( !IsWeirdSymbol( codepoint ) ) then table.insert( out, utf8.char( codepoint ) ) end
	end

	return table.concat( out )

end

local function FormatVersion( version )

	if ( version == 0 ) then return "Unknown version" end

	local year = math.floor( version / 10000 )
	local month = math.floor( version / 100 ) % 100
	local day = version % 100

	return string.format( year > 99 and "%02d.%02d.%02d" or "20%02d.%02d.%02d", year, month, day )

end

local function CalculateRank( server )

	local rank = server.ping

	if ( server.players == 0 ) then rank = rank + 75 end
	if ( server.pass or server.versionCompare < 0 ) then rank = rank + 300 end
	if ( server.isAnon ) then rank = rank + 1000 end

	if ( server.players >= 4 ) then rank = rank - 10 end
	if ( server.players >= 8 ) then rank = rank - 15 end
	if ( server.players >= 16 ) then rank = rank - 15 end
	if ( server.players >= 32 ) then rank = rank - 10 end
	if ( server.players >= 64 ) then rank = rank - 10 end

	return rank

end

local function MostCommon( counts )

	local best, bestCount = "", 0

	for key, count in pairs( counts ) do
		if ( bestCount == 0 or count > bestCount ) then best, bestCount = key, count end
	end

	return best

end

local function ToBool( value )

	return value == true or value == "true" or value == "1"

end

function MainMenu.Servers:Rank( server )

	if ( server.recommended < 50 ) then return 5 end
	if ( server.recommended < 100 ) then return 4 end
	if ( server.recommended < 200 ) then return 3 end
	if ( server.recommended < 300 ) then return 2 end

	return 1

end

function MainMenu.Servers:HasMap( map )

	if ( !self.MapIndex ) then
		self.MapIndex = {}

		for _, maps in pairs( GetMapList() or {} ) do
			for _, name in ipairs( maps ) do self.MapIndex[ name:lower():Trim() ] = true end
		end
	end

	return self.MapIndex[ map:lower() ] or false

end

function MainMenu.Servers:ResetMapIndex()

	self.MapIndex = nil

end

function MainMenu.Servers:GetGamemodeInfo( name )

	local key = name:lower()

	if ( !self.GamemodeInfo[ key ] ) then
		self.GamemodeInfo[ key ] = { title = name, name = key, titles = {}, categories = {}, workshopIds = {} }
	end

	return self.GamemodeInfo[ key ]

end

function MainMenu.Servers:GetGamemode( name, type )

	local list = self.Types[ type ]
	if ( list.gamemodes[ name ] ) then return list.gamemodes[ name ] end

	local gm = {
		name = name,
		servers = {},
		numServers = 0,
		numPlayers = 0,
		sortPlayers = 0,
		order = 0,
		orderBy = { "recommended", "ping", "address" },
		orderReverse = false,
		info = self:GetGamemodeInfo( name ),
		flags = {},
		hasFlags = false,
		filterFlags = {},
		hasPreferredFlags = false,
		search = "",
		bDirty = true
	}

	list.gamemodes[ name ] = gm
	table.insert( list.list, gm )

	return gm

end

function MainMenu.Servers:GetGamemodeName( gm )

	return StripWeirdSymbols( gm.info.title or gm.name )

end

function MainMenu.Servers:UpdateGamemodeInfo( server, type )

	local info = self:GetGamemodeInfo( server.gamemode )

	if ( server.desc == server.gamemode:lower() ) then
		for title in pairs( info.titles ) do
			if ( title != title:lower() and title:lower() == server.desc ) then
				server.desc = title
				break
			end
		end
	end

	info.titles[ server.desc ] = ( info.titles[ server.desc ] or 0 ) + math.min( server.players, 10 )
	if ( server.desc == server.gamemode ) then info.titles[ server.desc ] = 0 end
	info.title = MostCommon( info.titles )

	if ( server.category != "" ) then
		info.categories[ server.category ] = ( info.categories[ server.category ] or 0 ) + 1
		info.tag = MostCommon( info.categories )
		if ( info.tag != "" ) then info.bTagSet = true end
	end

	if ( !info.bTagSet ) then
		local title = info.title
		local bRoleplay = title:lower():find( "roleplay", 1, true ) or title:find( " RP", 1, true ) or title:find( "RP ", 1, true ) or title:sub( -2 ) == "RP"

		info.tag = bRoleplay and "rp" or ""
	end

	if ( server.workshopid != "" and server.workshopid != "0" ) then
		info.workshopIds[ server.workshopid ] = ( info.workshopIds[ server.workshopid ] or 0 ) + 1
		info.workshopid = MostCommon( info.workshopIds )
	end

	if ( server.flag != "" ) then
		local gm = self:GetGamemode( server.gamemode, type )
		gm.flags[ server.flag ] = true
		gm.hasFlags = true
	end

end

function MainMenu.Servers:AddServer( type, id, ping, name, desc, map, players, maxplayers, botplayers, pass, lastplayed, address, gamemode, workshopid, isAnon, version, loc, category )

	if ( tostring( id ) != tostring( self.RequestNum[ type ] ) ) then return end

	maxplayers = tonumber( maxplayers ) or 0
	if ( maxplayers <= 1 ) then return end

	if ( !gamemode or gamemode == "" ) then gamemode = desc end
	if ( !table.HasValue( self.Categories, category ) ) then category = "" end

	loc = loc or ""
	if ( !loc:match( "^[a-zA-Z]*$" ) ) then loc = "" end

	botplayers = tonumber( botplayers ) or 0
	version = tonumber( version ) or 0

	local gmodVersion = tonumber( ( string.Replace( NETVERSIONSTR, ".", "" ) ) ) or 0

	local server = {
		ping = tonumber( ping ) or 0,
		name = StripWeirdSymbols( ( name or "" ):Trim() ),
		desc = desc or "",
		map = map or "",
		players = ( tonumber( players ) or 0 ) - botplayers,
		maxplayers = maxplayers - botplayers,
		botplayers = botplayers,
		pass = ToBool( pass ),
		lastplayed = tonumber( lastplayed ) or 0,
		address = address,
		flag = loc:lower(),
		category = category or "",
		gamemode = gamemode,
		password = "",
		workshopid = tostring( workshopid or "" ),
		isAnon = ToBool( isAnon ),
		version = FormatVersion( version ),
		versionCompare = version > gmodVersion and 1 or ( version == gmodVersion and 0 or -1 ),
		favorite = serverlist.IsServerFavorite( address )
	}

	if ( server.flag == "eu" ) then server.flag = "europeanunion" end
	if ( server.desc:find( "[L]", 1, true ) ) then server.desc = server.desc:sub( 5 ) end

	server.hasMap = self:HasMap( server.map )
	server.recommended = CalculateRank( server )

	if ( server.lastplayed > 0 ) then
		server.lastPlayedText = os.date( "%d.%m.%Y %H:%M", server.lastplayed )
	end

	local gm = self:GetGamemode( server.gamemode, type )
	table.insert( gm.servers, server )
	gm.bDirty = true

	self:UpdateGamemodeInfo( server, type )

	gm.numServers = gm.numServers + 1
	gm.numPlayers = gm.numPlayers + server.players
	if ( !server.isAnon ) then gm.sortPlayers = gm.sortPlayers + server.players end
	gm.order = gm.sortPlayers

	self.Count[ type ] = ( self.Count[ type ] or 0 ) + 1

	self:Changed()

end

function MainMenu.Servers:FinishedServers( type )

	self.Refreshing[ type ] = false
	self:Changed()

end

function MainMenu.Servers:UpdateServer( address, ping, name, map, players, maxplayers, botplayers, pass )

	local server = self:GetSelectedServer()
	if ( !server or server.address != address ) then return end

	botplayers = tonumber( botplayers ) or 0

	server.ping = tonumber( ping ) or server.ping
	server.name = StripWeirdSymbols( ( name or "" ):Trim() )
	server.map = map
	server.players = ( tonumber( players ) or 0 ) - botplayers
	server.maxplayers = ( tonumber( maxplayers ) or 0 ) - botplayers
	server.botplayers = botplayers
	server.pass = ToBool( pass )

	if ( self.JoinWhenNotFull and server.players < server.maxplayers ) then
		self:Join( server )
	end

	self:Changed()

end

function MainMenu.Servers:SetPlayerList( address, players )

	local server = self:GetSelectedServer()
	if ( !server or server.address != address ) then return end

	local list = table.ClearKeys( players or {} )
	table.sort( list, function( a, b ) return ( a.time or 0 ) < ( b.time or 0 ) end )

	server.playerList = list

	self:Changed()

end

function MainMenu.Servers:SetFoundServers( servers )

	self.FoundServers = servers
	self:Changed()

end

function MainMenu.Servers:StopRefresh()

	if ( !self.Type ) then return end

	DoStopServers( self.Type )

end

function MainMenu.Servers:Refresh()

	local type = self.Type
	if ( !type ) then return end

	self.RequestNum[ type ] = ( self.RequestNum[ type ] or 0 ) + 1
	self.Types[ type ] = { gamemodes = {}, list = {} }
	self.GamemodeInfo = {}
	self.Refreshing[ type ] = true
	self.Count[ type ] = 0
	self:ResetMapIndex()

	GetServers( type, tostring( self.RequestNum[ type ] ) )

	self:Changed()

end

function MainMenu.Servers:SwitchType( type )

	if ( self.Type == type ) then return end

	self:StopRefresh()

	self.Type = type
	self.Gamemode = nil

	if ( !self.Types[ type ] ) then
		self.Types[ type ] = { gamemodes = {}, list = {} }
		self:Refresh()
	end

	self:Changed()

end

function MainMenu.Servers:GetGamemodes()

	return self.Type and self.Types[ self.Type ].list or {}

end

function MainMenu.Servers:GetSelectedServer()

	return self.Gamemode and self.Gamemode.selected

end

function MainMenu.Servers:SelectGamemode( gm )

	self.Gamemode = gm
	self:StopUpdating()
	self:Changed()

end

function MainMenu.Servers:StopUpdating()

	timer.Remove( "MainMenu.ServerInfo" )

end

function MainMenu.Servers:SelectServer( server )

	local gm = self.Gamemode
	if ( !gm ) then return end

	self:StopUpdating()
	self.JoinWhenNotFull = false

	gm.selected = server
	self:Changed()

	if ( !server ) then return end

	GetPlayerList( server.address )

	timer.Create( "MainMenu.ServerInfo", 10, 0, function()
		GetPlayerList( server.address )
		PingServer( server.address )
	end )

end

function MainMenu.Servers:Join( server )

	self:StopUpdating()
	self.JoinWhenNotFull = false

	if ( server.password != "" ) then
		RunConsoleCommand( "password", server.password )
	end

	JoinServer( server.address )

	self:StopRefresh()

end

function MainMenu.Servers:ToggleFavorite( server )

	server.favorite = !server.favorite

	if ( server.favorite ) then
		serverlist.AddServerToFavorites( server.address )
	else
		serverlist.RemoveServerFromFavorites( server.address )
	end

	self:Changed()

end

function MainMenu.Servers:ChangeOrder( gm, order )

	if ( gm.orderBy[ 1 ] == order ) then
		gm.orderReverse = !gm.orderReverse
	else
		gm.orderBy = { order, "recommended", "ping", "address" }
		gm.orderReverse = false
	end

	gm.bDirty = true
	self:Changed()

end

function MainMenu.Servers:ShouldShowInstall( gm )

	local workshopid = gm.info.workshopid
	if ( !workshopid or workshopid == "" ) then return false end

	for _, addon in ipairs( engine.GetAddons() ) do
		if ( tostring( addon.wsid ) == workshopid ) then return false end
	end

	return true

end

function MainMenu.Servers:InstallGamemode( gm )

	steamworks.Subscribe( gm.info.workshopid )

end

function MainMenu.Servers:IsServerVisible( gm, server )

	local filters = self.Filters

	if ( gm.search != "" ) then
		local search = gm.search:lower()
		local bFound = server.name:lower():find( search, 1, true ) or server.address:find( gm.search, 1, true ) or server.map:lower():find( search, 1, true )

		if ( !bFound ) then return false end
	end

	if ( filters.HasPlayers and server.players < 1 ) then return false end
	if ( filters.NotFull and server.players >= server.maxplayers ) then return false end
	if ( filters.HidePassword and server.pass ) then return false end
	if ( filters.HideOutdated and server.versionCompare < 0 ) then return false end
	if ( server.ping > filters.MaxPing ) then return false end
	if ( server.players < filters.MinPlayers or server.players > filters.MaxPlayers ) then return false end
	if ( server.flag != "" and gm.filterFlags[ server.flag ] == false ) then return false end
	if ( gm.hasPreferredFlags and gm.filterFlags[ server.flag ] != true ) then return false end

	return true

end

local function CompareServers( a, b, keys )

	for _, key in ipairs( keys ) do
		local bDescending = key:sub( 1, 1 ) == "-"
		if ( bDescending ) then key = key:sub( 2 ) end

		local valueA, valueB = a[ key ], b[ key ]

		if ( isstring( valueA ) ) then valueA, valueB = valueA:lower(), valueB:lower() end
		if ( isbool( valueA ) ) then valueA, valueB = valueA and 1 or 0, valueB and 1 or 0 end

		if ( valueA != valueB ) then
			if ( bDescending ) then return valueA > valueB end
			return valueA < valueB
		end
	end

	return false

end

function MainMenu.Servers:GetSortedServers( gm )

	if ( !gm.bDirty and gm.sortedFilterVersion == self.FilterVersion ) then return gm.sorted end

	local list = {}
	for _, server in ipairs( gm.servers ) do
		if ( self:IsServerVisible( gm, server ) ) then table.insert( list, server ) end
	end

	table.sort( list, function( a, b )
		if ( gm.orderReverse ) then return CompareServers( b, a, gm.orderBy ) end
		return CompareServers( a, b, gm.orderBy )
	end )

	gm.sorted = list
	gm.sortedFilterVersion = self.FilterVersion
	gm.bDirty = false

	return list

end

function MainMenu.Servers:FiltersChanged()

	self.FilterVersion = self.FilterVersion + 1
	self:Changed()

end

function MainMenu.Servers:IsGamemodeVisible( gm )

	if ( self.GamemodeSearch != "" ) then
		local search = self.GamemodeSearch:lower()
		if ( !gm.name:lower():find( search, 1, true ) and !gm.info.title:lower():find( search, 1, true ) ) then return false end
	end

	if ( table.IsEmpty( self.GamemodeFilterTags ) ) then return true end

	local tag = gm.info.tag
	if ( !tag or tag == "" ) then tag = "none" end

	return self.GamemodeFilterTags[ tag ] == true

end

function MainMenu.Servers:GetSortedGamemodes()

	local list = {}
	for _, gm in ipairs( self:GetGamemodes() ) do
		if ( self:IsGamemodeVisible( gm ) ) then table.insert( list, gm ) end
	end

	local sort = self.GamemodeSort

	table.sort( list, function( a, b )
		if ( sort == "order" and a.order != b.order ) then return a.order > b.order end
		if ( sort == "numServers" and a.numServers != b.numServers ) then return a.numServers > b.numServers end

		if ( sort == "title" ) then
			local titleA, titleB = a.info.title:lower(), b.info.title:lower()
			if ( titleA != titleB ) then return titleA < titleB end
		end

		if ( a.numPlayers != b.numPlayers ) then return a.numPlayers > b.numPlayers end

		return a.name < b.name
	end )

	return list

end

function MainMenu.Servers:SetCategoryFiltered( category, bFiltered )

	self.GamemodeFilterTags[ category ] = bFiltered or nil
	self:Changed()

end

function MainMenu.Servers:FilterAllCategoriesExcept( category )

	for _, name in ipairs( self.Categories ) do
		self.GamemodeFilterTags[ name ] = name != category or nil
	end

	self:Changed()

end

function MainMenu.Servers:ToggleFlagFilter( gm, flag )

	if ( gm.filterFlags[ flag ] == false ) then
		gm.filterFlags[ flag ] = nil
	else
		gm.filterFlags[ flag ] = !gm.filterFlags[ flag ]
	end

	gm.hasPreferredFlags = table.HasValue( gm.filterFlags, true )
	gm.bDirty = true

	self:Changed()

end
