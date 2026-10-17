
local PANEL = {}

local colors = {
	Top = Color( 85, 204, 85 ),
	Bottom = Color( 34, 189, 34 ),
	HoverTop = Color( 102, 221, 102 ),
	HoverBottom = Color( 51, 204, 51 ),
	Border = Color( 34, 170, 34 ),
	BorderBottom = Color( 17, 136, 17 )
}

local colorMenuBorder = Color( 170, 170, 170 )
local colorOptionHovered = Color( 170, 204, 255 )

function PANEL:Init()

	self:SetText( "" )

	self.Options = {}

end

function PANEL:AddOption( label, value )

	table.insert( self.Options, { label = language.GetPhrase( label ), value = value } )

end

function PANEL:SetValue( value )

	self.Value = value

end

function PANEL:GetSelectedLabel()

	for _, option in ipairs( self.Options ) do
		if ( option.value == self.Value ) then return option.label end
	end

	return self.Options[ 1 ] and self.Options[ 1 ].label or ""

end

function PANEL:OnSelect( value )
end

function PANEL:Paint( w, h )

	MainMenu.DrawGradientBox( 0, 0, w, h, MainMenu.Scale( 3 ), colors, self:IsHovered() )

	local font = MainMenu.Font( 12, 700 )
	local _, textH = MainMenu.TextSize( "W", font )

	MainMenu.DrawText( self:GetSelectedLabel(), font, MainMenu.Scale( 11 ), math.floor( ( h - textH ) / 2 ), color_white )

	local caretX, caretY = w - 1 - MainMenu.Scale( 20 ), MainMenu.Scale( 11 )

	draw.NoTexture()
	surface.SetDrawColor( 255, 255, 255 )
	surface.DrawPoly( {
		{ x = caretX, y = caretY },
		{ x = caretX + MainMenu.Scale( 10 ), y = caretY },
		{ x = caretX + MainMenu.Scale( 5 ), y = caretY + MainMenu.Scale( 5 ) }
	} )

end

function PANEL:DoClick()

	if ( IsValid( self.Menu ) ) then
		self.Menu:Remove()
		return
	end

	self:OpenMenu()

end

function PANEL:OpenMenu()

	local font = MainMenu.Font( 13 )
	local optionH = MainMenu.LineHeight( 13 ) + MainMenu.Scale( 8 )

	local menu = vgui.Create( "Panel", self:GetParent() )
	menu:NoClipping( true )
	menu:SetPos( self:GetX(), self:GetY() + MainMenu.Scale( 31 ) )
	menu:SetSize( self:GetWide(), #self.Options * optionH + 2 )
	menu:MoveToFront()
	menu.Paint = function( s, w, h )
		local radius = MainMenu.Scale( 4 )

		s:GetSkin().tex.Shadow( -4, -4, w + 10, h + 10 )
		draw.RoundedBox( radius, 0, 0, w, h, colorMenuBorder )
		draw.RoundedBox( radius, 1, 1, w - 2, h - 2, color_white )
	end

	self.Menu = menu

	for i, option in ipairs( self.Options ) do
		local item = vgui.Create( "DButton", menu )
		item:SetText( "" )
		item:SetPos( 1, 1 + ( i - 1 ) * optionH )
		item:SetSize( menu:GetWide() - 2, optionH )
		item.Paint = function( s, w, h )
			if ( s:IsHovered() ) then
				surface.SetDrawColor( colorOptionHovered )
				surface.DrawRect( 0, 0, w, h )
			end

			MainMenu.DrawText( option.label, font, MainMenu.Scale( 15 ), MainMenu.Scale( 4 ), color_black )
		end
		item.DoClick = function()
			self.Value = option.value
			menu:Remove()
			self:OnSelect( option.value )
		end
	end

end

function PANEL:OnRemove()

	if ( IsValid( self.Menu ) ) then self.Menu:Remove() end

end

vgui.Register( "MainMenuDropdown", PANEL, "DButton" )
