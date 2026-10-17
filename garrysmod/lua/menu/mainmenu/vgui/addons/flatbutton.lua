
local PANEL = {}

local styles = {
	normal = { Color( 221, 221, 221 ), Color( 204, 204, 204 ), color_black },
	create = { Color( 76, 175, 80 ), Color( 99, 187, 102 ), color_white },
	warning = { Color( 202, 30, 18 ), Color( 235, 39, 25 ), color_white },
	disabled = { Color( 177, 177, 177 ), Color( 177, 177, 177 ), Color( 204, 204, 204 ) }
}

function PANEL:Init()

	self:SetText( "" )

	self.Label = ""
	self.Style = "normal"
	self.FontSize = 16
	self.FontWeight = 400

end

function PANEL:Setup( label, style, fontSize, fontWeight )

	self.Label = language.GetPhrase( label )
	self.Style = style or "normal"
	self.FontSize = fontSize or 16
	self.FontWeight = fontWeight or ( self.Style == "normal" and 400 or 700 )

end

function PANEL:SetStyle( style )

	self.Style = style

end

function PANEL:GetContentSize()

	return MainMenu.TextSize( self.Label, MainMenu.Font( self.FontSize, self.FontWeight ) )

end

function PANEL:DoClick()

	if ( self.Style == "disabled" ) then return end

	self:OnClick()

end

function PANEL:OnClick()
end

function PANEL:Paint( w, h )

	local colors = styles[ self.Style ]
	local font = MainMenu.Font( self.FontSize, self.FontWeight )
	local textW, textH = MainMenu.TextSize( self.Label, font )

	draw.RoundedBox( MainMenu.Scale( 4 ), 0, 0, w, h, self:IsHovered() and colors[ 2 ] or colors[ 1 ] )
	MainMenu.DrawText( self.Label, font, math.floor( ( w - textW ) / 2 ), math.floor( ( h - textH ) / 2 ), colors[ 3 ] )

end

vgui.Register( "MainMenuFlatButton", PANEL, "DButton" )
