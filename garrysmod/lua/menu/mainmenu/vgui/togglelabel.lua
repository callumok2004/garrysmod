
local PANEL = {}

local colorDisabled = Color( 170, 170, 170 )

function PANEL:Init()

	self:SetCursor( "hand" )
	self:NoClipping( true )

	self.Text = ""
	self.Color = color_black
	self.bDisabled = false

end

function PANEL:Setup( class, text, fontSize, color, bShadow )

	self.Toggle = vgui.Create( class, self )
	self.Toggle.OnChange = function( s, bChecked ) self:OnChange( bChecked ) end
	self.Toggle:SetPos( MainMenu.Scale( self.Toggle.MarginLeft ), MainMenu.Scale( 3 ) )

	self.Text = language.GetPhrase( text )
	self.Color = color
	self.bShadow = bShadow

	if ( bShadow ) then
		self.Font = MainMenu.Font( fontSize, 700 )
		self.ShadowFont = MainMenu.Font( fontSize, 700, 1 )
		self.TextY = 0
	else
		self.Font = MainMenu.Font( fontSize )
	end

	self.TextX = MainMenu.Scale( self.Toggle.MarginLeft + 13 + 3 )

	local textW, textH = MainMenu.TextSize( self.Text, self.Font )

	if ( !bShadow ) then
		self.TextY = self.Toggle:GetY() + math.floor( ( self.Toggle:GetTall() - textH ) / 2 )
	end
	self.TextW = textW

	self:SetSize( self.TextX + textW + MainMenu.Scale( 2 ), math.max( textH, MainMenu.Scale( 16 ) ) )

end

function PANEL:SetChecked( bChecked )

	self.Toggle:SetChecked( bChecked )

end

function PANEL:OnChange( bChecked )
end

function PANEL:GetTextEnd()

	return self.TextX + self.TextW

end

function PANEL:SetDisabled( bDisabled )

	self.bDisabled = bDisabled
	self.Toggle:SetEnabled( !bDisabled )

end

function PANEL:OnMousePressed( code )

	if ( code != MOUSE_LEFT or self.bDisabled ) then return end

	self.Toggle:DoClick()

end

function PANEL:Paint( w, h )

	local color = self.bDisabled and colorDisabled or self.Color

	if ( self.bShadow ) then
		MainMenu.DrawShadowText( self.Text, self.Font, self.ShadowFont, self.TextX, self.TextY, color, MainMenu.Scale( 2 ) )
	else
		MainMenu.DrawText( self.Text, self.Font, self.TextX, self.TextY, color )
	end

end

vgui.Register( "MainMenuToggleLabel", PANEL, "Panel" )
