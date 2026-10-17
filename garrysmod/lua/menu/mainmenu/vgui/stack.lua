
local PANEL = {}

AccessorFunc( PANEL, "m_iFontSize", "FontSize", FORCE_NUMBER )
AccessorFunc( PANEL, "m_TextColor", "TextColor" )
AccessorFunc( PANEL, "m_iToggleHeight", "ToggleHeight", FORCE_NUMBER )

function PANEL:Init()

	self:SetFontSize( 16 )
	self:SetTextColor( color_black )
	self:SetToggleHeight( 19 )

	self.Y = 0

end

function PANEL:Add( class, height )

	local child = vgui.Create( class, self )
	child:SetSize( self:GetWide(), height or child:GetTall() )

	return self:AddPanel( child )

end

function PANEL:AddPanel( child, height )

	child:SetPos( 0, self.Y )

	self.Y = self.Y + ( height or child:GetTall() )
	self:SetTall( self.Y )

	return child

end

function PANEL:AddSpace( height )

	self.Y = self.Y + MainMenu.Scale( height )
	self:SetTall( self.Y )

end

function PANEL:AddText( text, fontSize, fontWeight, bCentered )

	fontSize = fontSize or self:GetFontSize()

	local font = MainMenu.Font( fontSize, fontWeight or 400 )
	local lines = MainMenu.WrapText( language.GetPhrase( text ), font, self:GetWide() )
	local lineH = MainMenu.LineHeight( fontSize )
	local color = self:GetTextColor()

	local label = self:Add( "Panel", #lines * lineH )
	label:SetMouseInputEnabled( false )
	label.Paint = function( s, w )
		for i, line in ipairs( lines ) do
			local x = bCentered and math.floor( ( w - MainMenu.TextSize( line, font ) ) / 2 ) or 0
			MainMenu.DrawText( line, font, x, ( i - 1 ) * lineH, color )
		end
	end

	return label

end

function PANEL:AddButton( label, style, onClick, bBig )

	local button = self:Add( "MainMenuFlatButton", MainMenu.LineHeight( bBig and 32 or 16 ) + MainMenu.Scale( bBig and 20 or 10 ) )
	button:Setup( label, style, bBig and 32 or 16 )
	button.OnClick = onClick

	self:AddSpace( 5 )

	return button

end

function PANEL:AddToggle( class, text, bChecked, onChange )

	local row = vgui.Create( "MainMenuToggleLabel", self )
	row:Setup( class, text, self:GetFontSize(), self:GetTextColor() )
	row:SetChecked( bChecked )
	row.OnChange = function( s, bValue ) onChange( bValue ) end

	return self:AddPanel( row, self:GetToggleHeight() and MainMenu.Scale( self:GetToggleHeight() ) )

end

function PANEL:AddRadioGroup( options, value, onChange )

	local radios = {}

	for _, option in ipairs( options ) do
		radios[ option[ 2 ] ] = self:AddToggle( "MainMenuRadioButton", option[ 1 ], option[ 2 ] == value, function()
			for key, radio in pairs( radios ) do radio:SetChecked( key == option[ 2 ] ) end
			onChange( option[ 2 ] )
		end )
	end

end

function PANEL:AddTextEntry( placeholder, value, onChange )

	local entry = self:Add( "MainMenuTextEntry", MainMenu.LineHeight( 13 ) + MainMenu.Scale( 6 ) + 2 )
	entry:SetPaddingX( 5 )
	entry:SetFontSize( 13 )
	entry:SetPlaceholder( placeholder )
	entry:SetValue( value or "" )
	entry.OnValueChange = function( s, newValue ) onChange( newValue ) end

	return entry

end

vgui.Register( "MainMenuStack", PANEL, "Panel" )
