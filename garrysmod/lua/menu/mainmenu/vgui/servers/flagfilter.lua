
local PANEL = {}

local colorBackground = Color( 156, 156, 156 )
local colorPreferred = Color( 78, 218, 108 )
local colorHidden = Color( 218, 78, 78 )

function PANEL:SetFlags( flags, states )

	self:Clear()

	local cellW = MainMenu.Scale( 26 )
	local rowH = MainMenu.Scale( 21 )
	local padding = MainMenu.Scale( 4 )
	local perRow = math.max( 1, math.floor( ( self:GetWide() - MainMenu.Scale( 8 ) ) / cellW ) )

	for i, flag in ipairs( flags ) do
		local row = math.floor( ( i - 1 ) / perRow )
		local column = ( i - 1 ) % perRow
		local inRow = math.min( perRow, #flags - row * perRow )
		local rowX = math.floor( ( self:GetWide() - inRow * cellW ) / 2 )
		local mat = MainMenu.Material( "flags16/" .. flag .. ".png" ) or MainMenu.Material( "html/img/unk_flag.png" )

		local button = vgui.Create( "DButton", self )
		button:SetText( "" )
		button:SetPos( rowX + column * cellW + MainMenu.Scale( 2 ), padding + row * rowH )
		button:SetSize( MainMenu.Scale( 22 ), MainMenu.Scale( 17 ) )
		button.Paint = function( s, w, h )
			local background = color_white
			if ( states[ flag ] == true ) then background = colorPreferred end
			if ( states[ flag ] == false ) then background = colorHidden end

			draw.RoundedBox( MainMenu.Scale( 4 ), 0, 0, w, h, background )
			if ( mat ) then MainMenu.DrawImage( mat, MainMenu.Scale( 3 ), MainMenu.Scale( 3 ), MainMenu.Scale( 16 ), MainMenu.Scale( 11 ) ) end
		end
		button.DoClick = function() self:OnToggle( flag ) end
	end

	self:SetTall( padding + math.ceil( #flags / perRow ) * rowH )

end

function PANEL:OnToggle( flag )
end

function PANEL:Paint( w, h )

	draw.RoundedBox( MainMenu.Scale( 4 ), 0, 0, w, h, colorBackground )

end

vgui.Register( "MainMenuFlagFilter", PANEL, "Panel" )
