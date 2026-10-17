
local PANEL = {}

local colorsEnabled = {
	Top = Color( 0, 136, 204 ),
	Bottom = Color( 0, 85, 204 ),
	HoverTop = Color( 34, 170, 238 ),
	HoverBottom = Color( 34, 119, 238 ),
	Border = Color( 0, 85, 204 ),
	BorderBottom = Color( 0, 53, 128 )
}

local colorsDisabled = {
	Top = Color( 136, 136, 136 ),
	Bottom = Color( 85, 85, 85 ),
	Border = Color( 66, 66, 66 ),
	BorderBottom = Color( 66, 66, 66 )
}

function PANEL:Init()

	self:SetText( "" )

	self.Label = ""
	self.FontSize = 20

end

function PANEL:Setup( label, fontSize )

	self.Label = language.GetPhrase( label )
	self.FontSize = fontSize

end

function PANEL:DoClick()

	self:OnClick()

end

function PANEL:OnClick()
end

function PANEL:Paint( w, h )

	local bEnabled = self:IsEnabled()
	local colors = bEnabled and colorsEnabled or colorsDisabled

	MainMenu.DrawGradientBox( 0, 0, w, h, MainMenu.Scale( 6 ), colors, bEnabled and self:IsHovered() )

	local font = MainMenu.Font( self.FontSize )
	local textW, textH = MainMenu.TextSize( self.Label, font )
	local x, y = math.floor( ( w - textW ) / 2 ), math.floor( ( h - textH ) / 2 )

	MainMenu.DrawText( self.Label, font, x, y - 1, MainMenu.BlendColor( colors.Top, color_black, 0.25 ) )
	MainMenu.DrawText( self.Label, font, x, y, color_white )

end

vgui.Register( "MainMenuButton", PANEL, "DButton" )
