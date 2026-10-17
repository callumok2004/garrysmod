
local PANEL = {}

local colorBackground = Color( 221, 221, 221 )
local colorRowEven = Color( 231, 240, 255 )
local colorRowOdd = Color( 241, 246, 255 )
local colorRowHovered = Color( 183, 221, 253 )
local colorText = Color( 68, 68, 68 )

function PANEL:Init()

	self.Find = vgui.Create( "MainMenuBlueButton", self )
	self.Find:SetLabel( "servers_find", 13 )
	self.Find.DoClick = function() self:OnFind( self.Entry:GetValue():Trim() ) end

	self.Entry = vgui.Create( "MainMenuTextEntry", self )
	self.Entry:SetRadius( 3 )
	self.Entry:SetPlaceholder( "127.0.0.1:27015" )
	self.Entry.OnEnter = function() self.Find:DoClick() end

	self.Rows = {}

end

function PANEL:SetAddress( address )

	self.Entry:SetValue( address )

end

function PANEL:SetServers( servers )

	for _, row in ipairs( self.Rows ) do row:Remove() end
	self.Rows = {}

	local rowH = MainMenu.Scale( 22 )
	local top = MainMenu.Scale( 45 )

	for i, server in ipairs( servers ) do
		local row = vgui.Create( "DButton", self )
		row:SetText( "" )
		row:SetPos( MainMenu.Scale( 1 ), top + ( i - 1 ) * rowH )
		row:SetSize( self:GetWide() - MainMenu.Scale( 2 ), rowH )
		row.Paint = function( s, w, h ) self:PaintServer( s, server, i, w, h ) end
		row.DoClick = function( s )
			if ( s:LocalCursorPos() < MainMenu.Scale( 20 ) ) then self:OnToggleFavorite( server ) end
		end

		table.insert( self.Rows, row )
	end

	self:SetTall( MainMenu.Scale( 44 ) + ( #servers > 0 and ( MainMenu.Scale( 7 ) + #servers * rowH ) or 0 ) )

end

function PANEL:OnFind( address )
end

function PANEL:OnToggleFavorite( server )
end

function PANEL:PerformLayout( w, h )

	local findW = MainMenu.Scale( 16 ) + self.Find:GetLabelWidth()

	self.Find:SetSize( findW, MainMenu.Scale( 24 ) )
	self.Find:SetPos( w - MainMenu.Scale( 10 ) - findW, MainMenu.Scale( 10 ) )

	self.Entry:SetSize( MainMenu.Scale( 210 ), MainMenu.Scale( 34 ) )
	self.Entry:SetPos( self.Find:GetX() - MainMenu.Scale( 215 ), MainMenu.Scale( 5 ) )

end

function PANEL:PaintServer( row, server, index, w, h )

	local background = index % 2 == 1 and colorRowEven or colorRowOdd
	if ( row:IsHovered() ) then background = colorRowHovered end

	surface.SetDrawColor( background )
	surface.DrawRect( 0, 0, w, h )

	local star = MainMenu.Material( server.favorite and "html/img/favourite.png" or "html/img/notfavourite.png" )
	if ( star ) then MainMenu.DrawImage( star, MainMenu.Scale( 4 ), MainMenu.Scale( 3 ), MainMenu.Scale( 16 ), MainMenu.Scale( 16 ) ) end

	MainMenu.DrawText( server.name, MainMenu.Font( 13, 700 ), MainMenu.Scale( 24 ), MainMenu.Scale( 3 ), colorText )

	local font = MainMenu.Font( 11 )
	local textY = MainMenu.Scale( 4 )
	local right = w - MainMenu.Scale( 4 )

	right = right - MainMenu.Scale( 130 )
	MainMenu.DrawText( server.map, font, right, textY, colorText )

	for _, column in ipairs( { { server.players .. " / " .. server.maxplayers, 48 }, { tostring( server.ping ), 32 } } ) do
		local width = MainMenu.Scale( column[ 2 ] )
		right = right - width
		MainMenu.DrawText( column[ 1 ], font, right + math.floor( ( width - MainMenu.TextSize( column[ 1 ], font ) ) / 2 ), textY, colorText )
	end

end

function PANEL:Paint( w, h )

	surface.SetDrawColor( colorBackground )
	surface.DrawRect( 0, 0, w, h )

	local font = MainMenu.Font( 12 )
	MainMenu.DrawText( language.GetPhrase( "servers_find_title" ), font, MainMenu.Scale( 10 ), MainMenu.Scale( 5 ) + math.floor( ( MainMenu.Scale( 34 ) - MainMenu.LineHeight( 12 ) ) / 2 ), color_black )

end

vgui.Register( "MainMenuFindServer", PANEL, "Panel" )
