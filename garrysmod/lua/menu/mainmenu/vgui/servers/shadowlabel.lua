
local PANEL = {}

AccessorFunc( PANEL, "m_Color", "Color" )

function PANEL:Init()

	self:SetMouseInputEnabled( false )
	self:NoClipping( true )
	self:SetText( "" )
	self:SetColor( color_white )
	self:SetFontSize( 16 )

end

function PANEL:SetText( text )

	self.Text = language.GetPhrase( text or "" )

end

function PANEL:GetText()

	return self.Text

end

function PANEL:SetFontSize( size )

	self.Font = MainMenu.Font( size, 700 )
	self.ShadowFont = MainMenu.Font( size, 700, 1 )
	self:SetTall( MainMenu.LineHeight( size ) + MainMenu.Scale( 1 ) )

end

function PANEL:GetTextWidth()

	return MainMenu.TextSize( self:GetText(), self.Font )

end

function PANEL:Paint( w, h )

	MainMenu.DrawShadowText( self:GetText(), self.Font, self.ShadowFont, 0, 0, self:GetColor(), MainMenu.Scale( 2 ) )

end

vgui.Register( "MainMenuShadowLabel", PANEL, "Panel" )
