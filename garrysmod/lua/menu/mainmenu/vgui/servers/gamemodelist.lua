
local PANEL = {}

local colorGradient = { Color( 240, 240, 240 ), Color( 230, 230, 230 ) }
local colorGradientHovered = { Color( 250, 250, 150 ), Color( 250, 230, 150 ) }
local colorInstall = Color( 35, 135, 237 )
local colorInstallHovered = Color( 79, 157, 237 )
local colorStats = Color( 85, 85, 85 )

local function Fade( color, bEmpty )

	return bEmpty and MainMenu.BlendColor( color, color_white, 0.6 ) or color

end

function PANEL:Init()

	self:SetRowHeight( MainMenu.Scale( 49 ) )

end

function PANEL:ShouldShowInstall( gm )

	return false

end

function PANEL:OnSelect( gm )
end

function PANEL:OnInstall( gm )
end

function PANEL:IsOverInstall( x, y, w )

	return x >= w - MainMenu.Scale( 47 ) and x < w - MainMenu.Scale( 5 ) and y < MainMenu.Scale( 44 )

end

function PANEL:OnRowClicked( index, code, x, y )

	if ( code != MOUSE_LEFT ) then return end

	local gm = self.Items[ index ]

	if ( self:ShouldShowInstall( gm ) and self:IsOverInstall( x, y, self:GetRowWidth() ) ) then
		self:OnInstall( gm )
		return
	end

	self:OnSelect( gm )

end

function PANEL:PaintRow( index, x, y, w, h, bHovered )

	local gm = self.Items[ index ]
	local bEmpty = gm.numPlayers == 0

	w = w - MainMenu.Scale( 5 )
	h = MainMenu.Scale( 44 )

	local gradient = bHovered and colorGradientHovered or colorGradient
	MainMenu.DrawGradient( x, y, w, h, MainMenu.Scale( 3 ), Fade( gradient[ 1 ], bEmpty ), Fade( gradient[ 2 ], bEmpty ) )

	local icon = MainMenu.Material( "gamemodes/" .. gm.name .. "/icon24.png" ) or MainMenu.Material( "gamemodes/base/icon24.png" )
	if ( icon ) then MainMenu.DrawImage( icon, x + MainMenu.Scale( 5 ), y + MainMenu.Scale( 9 ), MainMenu.Scale( 24 ), MainMenu.Scale( 24 ), bEmpty and 75 or 255 ) end

	local name = MainMenu.Servers:GetGamemodeName( gm )
	local nameFont = MainMenu.Font( 20, 700 )
	MainMenu.DrawText( name, nameFont, x + MainMenu.Scale( 40 ), y + MainMenu.Scale( 5 ), Fade( color_black, bEmpty ) )

	local tag = gm.info.tag
	if ( tag and tag != "" ) then
		local tagFont = MainMenu.Font( 11 )
		local tagText = language.GetPhrase( "gmfltr_hide_" .. tag )
		local tagX = x + MainMenu.Scale( 50 ) + MainMenu.TextSize( name, nameFont )
		local tagY = y + MainMenu.Ascent( 20 ) - MainMenu.Ascent( 11 )

		surface.SetDrawColor( Fade( colorInstall, bEmpty ) )
		surface.DrawRect( tagX, tagY, MainMenu.TextSize( tagText, tagFont ) + MainMenu.Scale( 24 ), MainMenu.LineHeight( 11 ) + MainMenu.Scale( 3 ) )
		MainMenu.DrawText( tagText, tagFont, tagX + MainMenu.Scale( 12 ), tagY + MainMenu.Scale( 1 ), Fade( color_white, bEmpty ) )
	end

	local stats = gm.numPlayers .. " " .. language.GetPhrase( gm.numPlayers == 1 and "servers_player_on" or "servers_players_on" ) .. " " ..
		gm.numServers .. " " .. language.GetPhrase( gm.numServers == 1 and "servers_server" or "servers_servers" )
	MainMenu.DrawText( stats, MainMenu.Font( 11 ), x + MainMenu.Scale( 43 ), y + h - MainMenu.Scale( 3 ) - MainMenu.LineHeight( 11 ), Fade( colorStats, bEmpty ) )

	if ( self:ShouldShowInstall( gm ) ) then
		local installX = x + w - MainMenu.Scale( 42 )
		local bOver = false

		if ( bHovered ) then
			local mouseX, mouseY = self:LocalCursorPos()
			bOver = self:IsOverInstall( mouseX, mouseY - y, self:GetRowWidth() )
		end

		draw.RoundedBoxEx( MainMenu.Scale( 4 ), installX, y, MainMenu.Scale( 42 ), h, Fade( bOver and colorInstallHovered or colorInstall, bEmpty ), false, true, false, true )

		local mat = MainMenu.Material( "html/img/gm_install16.png" )
		if ( mat ) then MainMenu.DrawImage( mat, installX + MainMenu.Scale( 13 ), y + math.floor( ( h - MainMenu.Scale( 16 ) ) / 2 ), MainMenu.Scale( 16 ), MainMenu.Scale( 16 ) ) end
	end

end

vgui.Register( "MainMenuGamemodeList", PANEL, "MainMenuVirtualList" )
