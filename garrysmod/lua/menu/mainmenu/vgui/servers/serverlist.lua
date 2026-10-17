
local colorHeader = Color( 35, 135, 237 )
local colorRowEven = Color( 231, 240, 255 )
local colorRowOdd = Color( 241, 246, 255 )
local colorRowHovered = Color( 183, 221, 253 )
local colorRowSelected = Color( 255, 255, 170 )
local colorText = Color( 68, 68, 68 )
local colorTextEmpty = Color( 119, 119, 119 )
local colorPlayersEmpty = Color( 221, 170, 170 )
local colorMissingMap = Color( 153, 85, 85 )
local colorVersionNew = Color( 230, 230, 230 )
local colorVersionOld = Color( 255, 207, 207 )

local columns = {
	{ "server_name_header", "name" },
	{ "server_mapname", "map" },
	{ "server_players", "-players" },
	{ "server_ping", "ping" },
	{ "server_ranking", "recommended" }
}

local function GetColumnWidths()

	local viewportW = MainMenu.ViewportWidth()
	local bSmall = viewportW <= 1000

	local mapW = 90
	if ( viewportW >= 1650 ) then
		mapW = 170
	elseif ( viewportW >= 1280 ) then
		mapW = 130
	elseif ( bSmall ) then
		mapW = 56
	end

	return {
		map = MainMenu.Scale( mapW ),
		players = MainMenu.Scale( bSmall and 46 or 48 ),
		ping = MainMenu.Scale( bSmall and 18 or 32 ),
		rank = MainMenu.Scale( bSmall and 16 or 64 )
	}

end

local function GetColumnRects( w )

	local widths = GetColumnWidths()
	local x = w - MainMenu.Scale( 4 )
	local rects = {}

	x = x - widths.rank
	rects.recommended = { x, widths.rank }

	x = x - widths.ping
	rects.ping = { x, widths.ping }

	x = x - widths.players
	rects[ "-players" ] = { x, widths.players }

	x = x - widths.map
	rects.map = { x, widths.map }

	rects.name = { MainMenu.Scale( 4 ), x - MainMenu.Scale( 7 ) }

	return rects

end

local PANEL = {}

function PANEL:Init()

	self:SetCursor( "hand" )

end

function PANEL:OnSort( key )
end

function PANEL:OnMousePressed( code )

	local x = self:LocalCursorPos()

	for key, rect in pairs( GetColumnRects( self:GetWide() ) ) do
		if ( x >= rect[ 1 ] and x < rect[ 1 ] + rect[ 2 ] ) then
			self:OnSort( key )
			return
		end
	end

end

function PANEL:Paint( w, h )

	draw.RoundedBoxEx( MainMenu.Scale( 4 ), 0, 0, w, h, colorHeader, true, true, false, false )

	local rects = GetColumnRects( w )
	local font = MainMenu.Font( 11 )
	local y = MainMenu.Scale( 4 ) + math.floor( ( MainMenu.Scale( 16 ) - MainMenu.LineHeight( 11 ) ) / 2 )

	for _, column in ipairs( columns ) do
		local rect = rects[ column[ 2 ] ]
		local text = language.GetPhrase( column[ 1 ] )

		MainMenu.DrawText( text, font, rect[ 1 ] + math.floor( ( rect[ 2 ] - MainMenu.TextSize( text, font ) ) / 2 ), y, color_white )
	end

end

vgui.Register( "MainMenuServerListHeader", PANEL, "Panel" )

PANEL = {}

function PANEL:SetSelected( server )

	self.Selected = server

end

function PANEL:OnSelect( server )
end

function PANEL:OnJoin( server )
end

function PANEL:OnToggleFavorite( server )
end

function PANEL:OnRowClicked( index, code, x, y )

	local server = self.Items[ index ]

	if ( code == MOUSE_RIGHT ) then
		SetClipboardText( server.address )
		return
	end

	if ( code != MOUSE_LEFT ) then return end

	if ( x >= MainMenu.Scale( 4 ) and x < MainMenu.Scale( 20 ) ) then
		self:OnToggleFavorite( server )
		return
	end

	self:OnSelect( server )

end

function PANEL:OnRowDoubleClicked( index )

	self:OnJoin( self.Items[ index ] )

end

function PANEL:PaintRow( index, x, y, w, h, bHovered )

	local server = self.Items[ index ]

	local background = index % 2 == 1 and colorRowEven or colorRowOdd
	if ( server == self.Selected ) then
		background = colorRowSelected
	elseif ( bHovered ) then
		background = colorRowHovered
	end

	surface.SetDrawColor( background )
	surface.DrawRect( x, y, w, h )

	local viewportW = MainMenu.ViewportWidth()
	local widths = GetColumnWidths()
	local bEmpty = server.players == 0
	local textColor = bEmpty and colorTextEmpty or colorText
	local font = MainMenu.Font( 11 )
	local top = y + MainMenu.Scale( 3 )
	local textY = top + math.floor( ( MainMenu.Scale( 16 ) - MainMenu.LineHeight( 11 ) ) / 2 )
	local right = x + w - MainMenu.Scale( 4 )

	right = right - widths.rank
	local rank = MainMenu.Material( ( viewportW <= 1000 and "html/img/ranksmall" or "html/img/rank" ) .. MainMenu.Servers:Rank( server ) .. ".png" )
	if ( rank ) then MainMenu.DrawImage( rank, right, top, widths.rank, MainMenu.Scale( 16 ) ) end

	for _, column in ipairs( { { tostring( server.ping ), widths.ping, textColor }, { server.players .. " / " .. server.maxplayers, widths.players, bEmpty and colorPlayersEmpty or textColor } } ) do
		right = right - column[ 2 ]
		MainMenu.DrawText( column[ 1 ], font, right + math.floor( ( column[ 2 ] - MainMenu.TextSize( column[ 1 ], font ) ) / 2 ), textY, column[ 3 ] )
	end

	right = right - widths.map
	MainMenu.StartClip( self, right, top, widths.map, MainMenu.Scale( 16 ) )
	MainMenu.DrawText( server.map, font, right, textY, server.hasMap and textColor or colorMissingMap )
	MainMenu.EndClip()

	if ( server.lastPlayedText ) then
		local text = server.lastPlayedText
		if ( viewportW > 1650 ) then text = language.GetPhrase( "server_lastvisit" ) .. " " .. text end

		right = right - MainMenu.TextSize( text, font ) - MainMenu.Scale( 5 )
		MainMenu.DrawText( text, font, right, textY, textColor )
	end

	local nameX = x + MainMenu.Scale( 4 )
	local nameFont = MainMenu.Font( 13, viewportW >= 1280 and 700 or 400 )
	local baseline = top + MainMenu.Scale( 1 ) + MainMenu.Ascent( 13 )
	local space = MainMenu.TextSize( " ", nameFont )

	MainMenu.StartClip( self, nameX, top, right - MainMenu.Scale( 3 ) - nameX, MainMenu.Scale( 17 ) )

	local star = server.favorite and "html/img/favourite.png" or "html/img/notfavourite.png"
	if ( bHovered ) then
		local mouseX = self:LocalCursorPos()
		if ( mouseX >= nameX and mouseX < nameX + MainMenu.Scale( 16 ) ) then
			star = server.favorite and "html/img/favourite_remove.png" or "html/img/notfavourite_add.png"
		end
	end

	local starMat = MainMenu.Material( star )
	if ( starMat ) then MainMenu.DrawImage( starMat, nameX, baseline - MainMenu.Scale( 16 ), MainMenu.Scale( 16 ), MainMenu.Scale( 16 ) ) end
	nameX = nameX + MainMenu.Scale( 20 ) + space

	if ( server.flag != "" ) then
		local flag = MainMenu.Material( "flags16/" .. server.flag .. ".png" ) or MainMenu.Material( "html/img/unk_flag.png" )
		if ( flag ) then
			MainMenu.DrawImage( flag, nameX, baseline - MainMenu.Scale( 13 ), MainMenu.Scale( 16 ), MainMenu.Scale( 11 ) )
			nameX = nameX + MainMenu.Scale( 16 ) + space
		end
	end

	if ( server.pass ) then
		local lock = MainMenu.Material( "html/img/server-passworded.png" )
		if ( lock ) then MainMenu.DrawImage( lock, nameX, baseline - MainMenu.Scale( 16 ), MainMenu.Scale( 16 ), MainMenu.Scale( 16 ) ) end
		nameX = nameX + MainMenu.Scale( 20 ) + space
	end

	MainMenu.DrawText( server.name, nameFont, nameX, top + MainMenu.Scale( 1 ), textColor )

	if ( server.versionCompare != 0 ) then
		local versionFont = MainMenu.Font( 10 )
		local text = language.GetPhrase( server.versionCompare > 0 and "server_ver_new" or "server_ver_old" ) .. ": " .. server.version
		local tagX = nameX + MainMenu.TextSize( server.name, nameFont ) + space + MainMenu.Scale( 5 )

		surface.SetDrawColor( server.versionCompare > 0 and colorVersionNew or colorVersionOld )
		surface.DrawRect( tagX, top + MainMenu.Scale( 2 ), MainMenu.TextSize( text, versionFont ) + MainMenu.Scale( 20 ), MainMenu.LineHeight( 10 ) + MainMenu.Scale( 2 ) )
		MainMenu.DrawText( text, versionFont, tagX + MainMenu.Scale( 10 ), top + MainMenu.Scale( 3 ), color_black )
	end

	MainMenu.EndClip()

end

vgui.Register( "MainMenuServerList", PANEL, "MainMenuVirtualList" )
