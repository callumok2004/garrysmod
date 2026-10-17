
local PANEL = {}

local colorPlayers = Color( 238, 238, 238 )
local colorPlayersHeader = Color( 153, 153, 153 )

local function FormatTime( seconds )

	seconds = tonumber( seconds ) or 0

	if ( seconds < 60 ) then return math.floor( seconds ) .. " sec" end
	if ( seconds < 3600 ) then return math.floor( seconds / 60 ) .. " min" end
	if ( seconds < 86400 ) then return math.floor( seconds / 3600 ) .. " hr" end

	return "a long time"

end

local function GetLayoutKey( server )

	return server.name .. "|" .. tostring( server.pass ) .. "|" .. tostring( server.players >= server.maxplayers )

end

function PANEL:SetServer( server, bJoinWhenNotFull )

	self.Server = server
	self.bJoinWhenNotFull = bJoinWhenNotFull
	self:Rebuild()

end

function PANEL:OnJoin()
end

function PANEL:OnPasswordChanged( password )
end

function PANEL:OnJoinWhenNotFullChanged( bJoin )
end

function PANEL:Think()

	if ( GetLayoutKey( self.Server ) != self.LayoutKey ) then
		self:Rebuild()
	end

end

function PANEL:Rebuild()

	self:Clear()

	local server = self.Server
	local bSmall = MainMenu.ViewportWidth() <= 1000
	local paddingX = MainMenu.Scale( bSmall and 5 or 15 )
	local paddingY = MainMenu.Scale( bSmall and 5 or 10 )
	local bFull = server.players >= server.maxplayers

	self.LayoutKey = GetLayoutKey( server )
	self:DockPadding( paddingX, paddingY, paddingX, paddingY )

	local nameFont = MainMenu.Font( 16, 700 )
	local nameLines = MainMenu.WrapText( server.name, nameFont, self:GetWide() - paddingX * 2 - MainMenu.Scale( 8 ) )

	local header = self:Add( "Panel" )
	header:SetTall( #nameLines * MainMenu.LineHeight( 16 ) + MainMenu.LineHeight( 12 ) + MainMenu.Scale( 5 ) )
	header:Dock( TOP )
	header.Paint = function()
		local y = 0

		for _, line in ipairs( nameLines ) do
			MainMenu.DrawText( line, nameFont, 0, y, color_black )
			y = y + MainMenu.LineHeight( 16 )
		end

		MainMenu.DrawText( server.address, MainMenu.Font( 12 ), 0, y, color_black )
	end

	local join = self:Add( "MainMenuButton" )
	join:Setup( bFull and "servers_join_server_full" or "servers_join_server", 30 )
	join:SetEnabled( !bFull )
	join:SetTall( MainMenu.LineHeight( 30 ) + MainMenu.Scale( 4 ) )
	join:Dock( BOTTOM )
	join.OnClick = function() self:OnJoin() end

	if ( bFull ) then
		local joinWhenNotFull = self:Add( "MainMenuToggleLabel" )
		joinWhenNotFull:Setup( "MainMenuCheckBox", "sv_join_if_not_full", 12, color_black )
		joinWhenNotFull:SetChecked( self.bJoinWhenNotFull )
		joinWhenNotFull:SetTall( MainMenu.Scale( 17 ) )
		joinWhenNotFull:Dock( BOTTOM )
		joinWhenNotFull.OnChange = function( s, bChecked ) self:OnJoinWhenNotFullChanged( bChecked ) end
	end

	if ( server.pass ) then
		local password = self:Add( "MainMenuTextEntry" )
		password:SetTall( MainMenu.LineHeight( 12 ) + MainMenu.Scale( 8 ) + 2 )
		password:Dock( BOTTOM )
		password:DockMargin( 0, 0, 0, MainMenu.Scale( 5 ) )
		password:SetPaddingX( 5 )
		password:SetPassword( true )
		password:SetPlaceholder( "password" )
		password:SetValue( server.password )
		password.OnValueChange = function( s, value ) self:OnPasswordChanged( value ) end
		password.OnEnter = function() self:OnJoin() end
	end

	local players = self:Add( "DScrollPanel" )
	players:Dock( FILL )
	players:DockMargin( 0, 0, 0, MainMenu.Scale( 5 ) )
	players.Paint = function( s, pw, ph ) draw.RoundedBox( MainMenu.Scale( 4 ), 0, 0, pw, ph, colorPlayers ) end
	MainMenu.StyleScrollBar( players:GetVBar() )

	local rowH = MainMenu.LineHeight( 12 ) + MainMenu.Scale( 4 )

	local playerTable = players:Add( "Panel" )
	playerTable:Dock( TOP )
	playerTable.Think = function( s )
		local tableH = MainMenu.Scale( 16 ) + rowH * ( #( server.playerList or {} ) + 1 )
		if ( s:GetTall() != tableH ) then s:SetTall( tableH ) end
	end
	playerTable.Paint = function( s, tw )
		local left, right = MainMenu.Scale( 11 ), tw - MainMenu.Scale( 11 )
		local middle = math.floor( ( left + right ) / 2 )

		local function DrawRow( rowY, name, score, time, font, color )
			MainMenu.StartClip( s, left, rowY, math.min( MainMenu.Scale( 170 ), middle - left ), rowH )
			MainMenu.DrawText( name, font, left, rowY + MainMenu.Scale( 2 ), color )
			MainMenu.EndClip()

			MainMenu.DrawText( score, font, middle - math.floor( MainMenu.TextSize( score, font ) / 2 ), rowY + MainMenu.Scale( 2 ), color )
			MainMenu.DrawText( time, font, right - MainMenu.TextSize( time, font ), rowY + MainMenu.Scale( 2 ), color )
		end

		DrawRow( MainMenu.Scale( 8 ), language.GetPhrase( "playerlist_name" ), language.GetPhrase( "playerlist_score" ), language.GetPhrase( "playerlist_time" ), MainMenu.Font( 12, 700 ), colorPlayersHeader )

		for i, player in ipairs( server.playerList or {} ) do
			DrawRow( MainMenu.Scale( 8 ) + i * rowH, player.name or "", tostring( player.score or 0 ), FormatTime( player.time ), MainMenu.Font( 12 ), color_black )
		end
	end

end

function PANEL:Paint( w, h )

	draw.RoundedBox( MainMenu.Scale( 4 ), 0, 0, w, h, color_white )

end

vgui.Register( "MainMenuServerInfo", PANEL, "Panel" )
