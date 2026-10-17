
local PANEL = {}

local colorChecked = Color( 0, 117, 255 )
local colorCheckedHovered = Color( 0, 92, 200 )
local colorBorder = Color( 118, 118, 118 )
local colorBorderHovered = Color( 79, 79, 79 )
local colorDisabledBorder = Color( 208, 208, 208 )
local colorDisabled = Color( 247, 247, 247 )

local tick = {
	{ { 74, 285 }, { 131, 229 }, { 200, 295 }, { 206, 422 } },
	{ { 200, 295 }, { 377, 77 }, { 442, 129 }, { 206, 422 } }
}

AccessorFunc( PANEL, "m_bChecked", "Checked", FORCE_BOOL )

PANEL.MarginLeft = 4

function PANEL:Init()

	self:SetText( "" )
	self:SetSize( MainMenu.Scale( 13 ), MainMenu.Scale( 13 ) )

end

function PANEL:DoClick()

	self:SetChecked( !self:GetChecked() )
	self:OnChange( self:GetChecked() )

end

function PANEL:OnChange( bChecked )
end

function PANEL:Paint( w, h )

	local radius = MainMenu.Scale( 2 )

	if ( !self:IsEnabled() ) then
		draw.RoundedBox( radius, 0, 0, w, h, colorDisabledBorder )
		if ( !self:GetChecked() ) then draw.RoundedBox( radius, 1, 1, w - 2, h - 2, colorDisabled ) end

		return
	end

	if ( !self:GetChecked() ) then
		draw.RoundedBox( radius, 0, 0, w, h, self:IsHovered() and colorBorderHovered or colorBorder )
		draw.RoundedBox( radius, 1, 1, w - 2, h - 2, color_white )

		return
	end

	draw.RoundedBox( radius, 0, 0, w, h, self:IsHovered() and colorCheckedHovered or colorChecked )

	draw.NoTexture()
	surface.SetDrawColor( 255, 255, 255 )

	for _, quad in ipairs( tick ) do
		local poly = {}
		for i, point in ipairs( quad ) do
			poly[ i ] = { x = point[ 1 ] * w / 512, y = point[ 2 ] * h / 512 }
		end

		surface.DrawPoly( poly )
	end

end

vgui.Register( "MainMenuCheckBox", PANEL, "DButton" )

PANEL = {}

PANEL.MarginLeft = 5

function PANEL:DoClick()

	self:OnChange( true )

end

function PANEL:Paint( w, h )

	local radius = math.floor( w / 2 )
	local bHovered = self:IsHovered()

	if ( !self:GetChecked() ) then
		draw.RoundedBox( radius, 0, 0, w, h, bHovered and colorBorderHovered or colorBorder )
		draw.RoundedBox( radius - 1, 1, 1, w - 2, h - 2, color_white )

		return
	end

	local color = bHovered and colorCheckedHovered or colorChecked
	local dot = math.Round( w * 328 / 512 )
	local dotPos = math.floor( ( w - dot ) / 2 )

	draw.RoundedBox( radius, 0, 0, w, h, color )
	draw.RoundedBox( radius - 1, 1, 1, w - 2, h - 2, color_white )
	draw.RoundedBox( math.floor( dot / 2 ), dotPos, dotPos, dot, dot, color )

end

vgui.Register( "MainMenuRadioButton", PANEL, "MainMenuCheckBox" )
