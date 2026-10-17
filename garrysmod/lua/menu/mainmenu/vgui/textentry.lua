
local PANEL = {}

local colorBorder = Color( 171, 173, 179 )
local colorFocus = Color( 0, 136, 255 )
local colorPlaceholder = Color( 117, 117, 117 )
local colorHighlight = Color( 51, 153, 255 )

AccessorFunc( PANEL, "m_iRadius", "Radius", FORCE_NUMBER )
AccessorFunc( PANEL, "m_iPaddingX", "PaddingX", FORCE_NUMBER )
AccessorFunc( PANEL, "m_bCenterText", "CenterText", FORCE_BOOL )
AccessorFunc( PANEL, "m_bPassword", "Password", FORCE_BOOL )

function PANEL:Init()

	self:SetPaintBackground( false )
	self:SetDrawLanguageID( false )
	self:SetCursor( "beam" )
	self:SetUpdateOnType( true )
	self:SetFontSize( 12 )
	self:SetPlaceholder( "" )
	self:SetRadius( 2 )
	self:SetPaddingX( 4 )

end

function PANEL:SetPlaceholder( text )

	self.Placeholder = language.GetPhrase( text )

end

function PANEL:SetFontSize( size )

	self.FontSize = size
	self:SetFont( MainMenu.Font( size ) )

end

function PANEL:DrawLine( text, color )

	local font = MainMenu.Font( self.FontSize )
	local textW, textH = MainMenu.TextSize( text, font )
	local x = self:GetCenterText() and ( self:GetWide() - textW ) / 2 or MainMenu.Scale( self:GetPaddingX() )

	MainMenu.DrawText( text, font, x, ( self:GetTall() - textH ) / 2, color )

end

function PANEL:Paint( w, h )

	local radius = MainMenu.Scale( self:GetRadius() )
	local bFocused = self:HasFocus()

	draw.RoundedBox( radius, 0, 0, w, h, bFocused and colorFocus or colorBorder )

	if ( bFocused ) then
		draw.RoundedBox( radius, 2, 2, w - 4, h - 4, color_white )
	else
		draw.RoundedBox( radius, 1, 1, w - 2, h - 2, color_white )
	end

	local text = self:GetText()

	if ( text == "" ) then
		self:DrawLine( self.Placeholder, colorPlaceholder )
	elseif ( self:GetPassword() ) then
		self:DrawLine( string.rep( "\xE2\x80\xA2", utf8.len( text ) or #text ), color_black )
		return
	end

	self:DrawTextEntryText( color_black, colorHighlight, color_black )

end

vgui.Register( "MainMenuTextEntry", PANEL, "DTextEntry" )
