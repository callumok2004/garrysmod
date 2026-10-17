
MainMenu.WorkshopBrowsers = MainMenu.WorkshopBrowsers or {}

local BROWSER = {}
BROWSER.__index = BROWSER

function MainMenu.GetWorkshopBrowser( name, category, tag )

	if ( !MainMenu.WorkshopBrowsers[ name ] ) then
		MainMenu.WorkshopBrowsers[ name ] = setmetatable( {
			Category = category,
			Tag = tag or "",
			Offset = 0,
			PerPage = 1,
			TotalResults = 0,
			NumResults = 0,
			Files = {},
			FilesOther = {},
			Loading = true,
			Search = "",
			Filter = "",
			Sort = "subscribed"
		}, BROWSER )
	end

	return MainMenu.WorkshopBrowsers[ name ]

end

function MainMenu.FormatSize( size )

	if ( !size or size <= 0 ) then return "0 Bytes" end
	if ( size < 1000 ) then return size .. " Bytes" end
	if ( size < 1000 ^ 2 ) then return math.Round( size / 1000 ) .. " KB" end
	if ( size < 1000 ^ 3 ) then return math.Round( size / 1000 ^ 2 ) .. " MB" end

	return math.Round( size / 1000 ^ 3 ) .. " GB"

end

local previews = {}

function MainMenu.GetWorkshopPreview( path )

	if ( !path ) then return end

	if ( previews[ path ] == nil ) then
		local mat

		if ( path:StartsWith( "html/" ) ) then
			mat = Material( path, "smooth" )
		elseif ( file.Exists( path, "MOD" ) and !path:EndsWith( ".cache" ) ) then
			mat = Material( "../" .. path, "smooth" )
		else
			mat = AddonMaterial( path )
		end

		previews[ path ] = ( mat and !mat:IsError() ) and mat or false
	end

	return previews[ path ] or nil

end

function BROWSER:Attach( library )

	self.Library = library
	library.Receiver = self

end

function BROWSER:Detach()

	if ( self.Library and self.Library.Receiver == self ) then
		self.Library.Receiver = nil
	end

end

function BROWSER:Fetch()

	self.Loading = true

	self.Library:Fetch( self.Category, self.Offset, self.PerPage, string.Split( self.Tag, "," ), self.Search, self.Filter, self.Sort )

end

function BROWSER:Switch( category, offset, tag )

	tag = tag or ""

	if ( self.Category != category or self.Tag != tag ) then self.TotalResults = 0 end

	self.Category = category
	self.Tag = tag
	self.Offset = offset

	self:Fetch()

end

function BROWSER:Refresh()

	self:Switch( self.Category, self.Offset, self.Tag )

end

function BROWSER:Go( delta )

	local offset = self.Offset + delta
	if ( offset < 0 or offset >= self.TotalResults ) then return end

	self:Switch( self.Category, offset, self.Tag )

end

function BROWSER:GetPage()

	return math.floor( self.Offset / self.PerPage ) + 1

end

function BROWSER:GetPageCount()

	return math.ceil( self.TotalResults / self.PerPage )

end

function BROWSER:ReceiveLocal( data )

	self.Loading = false
	self.TotalResults = math.max( self.TotalResults, data.totalresults )
	self.NumResults = #data.results
	self.Files = {}

	for _, result in ipairs( data.results ) do
		table.insert( self.Files, {
			bLocal = true,
			background = result.preview,
			info = { title = result.name, file = result.file, description = result.description }
		} )
	end

end

function BROWSER:ReceiveIndex( data )

	self.Loading = false
	self.TotalResults = math.max( self.TotalResults, data.totalresults )
	self.NumResults = data.numresults or #data.results
	self.Files = {}
	self.FilesOther = data.otherresults and table.ClearKeys( data.otherresults ) or {}

	for k, id in pairs( data.results ) do
		table.insert( self.Files, { id = id, info = {}, extra = data.extraresults and data.extraresults[ k ] or {} } )
	end

end

function BROWSER:ForEachFile( id, func )

	for _, entry in ipairs( self.Files ) do
		if ( entry.id == id ) then func( entry ) end
	end

end

function BROWSER:ReceiveFileInfo( id, info )

	self:ForEachFile( id, function( entry ) entry.info = info end )

end

function BROWSER:ReceiveFileUserInfo( id, info )

	self:ForEachFile( id, function( entry )
		entry.info.favorite = info.favorite
		entry.info.voted_up = info.voted_up
		entry.info.voted_down = info.voted_down
	end )

end

function BROWSER:ReceiveUserName( steamid, name )

	for _, entry in ipairs( self.Files ) do
		if ( entry.info.owner == steamid ) then entry.info.ownername = name end
	end

end

function BROWSER:ReceiveImage( id, path )

	self:ForEachFile( id, function( entry ) entry.background = path end )

end

function BROWSER:Rate( entry, bUp )

	if ( bUp and entry.info.voted_up or !bUp and entry.info.voted_down ) then return end

	steamworks.Vote( entry.id, bUp )

	entry.info.voted_up = bUp
	entry.info.voted_down = !bUp

	if ( bUp ) then
		entry.info.up = ( entry.info.up or 0 ) + 1
		surface.PlaySound( "npc/roller/mine/rmine_chirp_answer1.wav" )
	else
		entry.info.down = ( entry.info.down or 0 ) + 1
		surface.PlaySound( "buttons/button10.wav" )
	end

end

function BROWSER:Favorite( entry, bFavorite )

	steamworks.SetFavorite( entry.id, bFavorite )
	entry.info.favorite = bFavorite

	surface.PlaySound( bFavorite and "npc/roller/mine/rmine_chirp_answer1.wav" or "buttons/button10.wav" )

end

function BROWSER:PublishLocal( entry )

	self.Library:Publish( entry.info.file, entry.background )

end

function BROWSER:DeleteLocal( entry )

	file.Delete( entry.info.file, "MOD" )
	file.Delete( entry.background, "MOD" )

	self:Refresh()

end
