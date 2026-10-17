
local PANEL = {}

local colorNormal = Color( 255, 255, 255 )
local colorHovered = Color( 255, 255, 170 )
local colorActive = Color( 255, 255, 85 )

AccessorFunc( PANEL, "m_bActive", "Active", FORCE_BOOL )

function PANEL:Init()

	self:SetText( "" )
	self:NoClipping( true )

	self.Label = ""

end

function PANEL:Setup( label, size, bSubmenu )

	self.Label = language.GetPhrase( label )
	self.FontSize = size or 23

	self.ShadowOffset = bSubmenu and 1 or 2

	self:SetSize( MainMenu.TextSize( self.Label, MainMenu.Font( self.FontSize, 700 ) ) )

end

function PANEL:OnCursorEntered()

	MainMenu.PlaySound( "ui_hover" )

end

function PANEL:DoClick()

	MainMenu.PlaySound( "ui_click" )
	self:OnClick()

end

function PANEL:OnClick()
end

function PANEL:Paint( w, h )

	local color = colorNormal
	if ( self:GetActive() ) then
		color = colorActive
	elseif ( self:IsHovered() ) then
		color = colorHovered
	end

	MainMenu.DrawShadowText( self.Label, MainMenu.Font( self.FontSize, 700 ), MainMenu.Font( self.FontSize, 700, 1 ), 0, 0, color, MainMenu.Scale( self.ShadowOffset ) )

end

vgui.Register( "MainMenuLink", PANEL, "DButton" )
