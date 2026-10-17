
local PANEL = {}

local colorNormal = Color( 35, 135, 237 )
local colorHovered = Color( 79, 157, 237 )

AccessorFunc( PANEL, "m_iRadius", "Radius", FORCE_NUMBER )

function PANEL:Init()

	self:SetText( "" )
	self:SetRadius( 4 )

end

function PANEL:SetIcon( path )

	self.Icon = MainMenu.Material( path )

end

function PANEL:SetLabel( label, fontSize )

	self.Label = language.GetPhrase( label )
	self.Font = MainMenu.Font( fontSize )

end

function PANEL:GetLabelWidth()

	return MainMenu.TextSize( self.Label, self.Font )

end

function PANEL:Paint( w, h )

	draw.RoundedBox( MainMenu.Scale( self:GetRadius() ), 0, 0, w, h, self:IsHovered() and colorHovered or colorNormal )

	if ( self.Icon ) then
		local iconW, iconH = MainMenu.MaterialSize( self.Icon )
		MainMenu.DrawImage( self.Icon, math.floor( ( w - iconW ) / 2 ), math.floor( ( h - iconH ) / 2 ), iconW, iconH )
	end

	if ( self.Label ) then
		local textW, textH = MainMenu.TextSize( self.Label, self.Font )
		MainMenu.DrawText( self.Label, self.Font, ( w - textW ) / 2, ( h - textH ) / 2, color_white )
	end

end

vgui.Register( "MainMenuBlueButton", PANEL, "DButton" )
