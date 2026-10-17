
local PANEL = {}

function PANEL:Init()

	self:SetMouseInputEnabled( false )
	self:NoClipping( true )
	self:SetTall( MainMenu.LineHeight( 24 ) )

	self.Title = ""
	self.Subtitle = ""

end

function PANEL:Setup( title, subtitle )

	self.Title = language.GetPhrase( title )
	self.Subtitle = language.GetPhrase( subtitle )

end

function PANEL:Paint( w, h )

	local titleFont = MainMenu.Font( 24, 700 )
	local titleW = MainMenu.TextSize( self.Title .. " ", titleFont )

	MainMenu.DrawShadowText( self.Title, titleFont, MainMenu.Font( 24, 700, 1 ), 0, 0, color_white, MainMenu.Scale( 2 ) )
	MainMenu.DrawShadowText( self.Subtitle, MainMenu.Font( 12, 700 ), MainMenu.Font( 12, 700, 1 ), titleW + MainMenu.Scale( 8 ), MainMenu.Ascent( 24 ) - MainMenu.Ascent( 12 ), color_white, MainMenu.Scale( 1 ) )

end

vgui.Register( "MainMenuHeader", PANEL, "Panel" )
