
local PANEL = {}

local colorBorder = Color( 51, 51, 51 )

AccessorFunc( PANEL, "m_iRight", "Right", FORCE_NUMBER )
AccessorFunc( PANEL, "m_iContentWidth", "ContentWidth", FORCE_NUMBER )
AccessorFunc( PANEL, "m_iMaxContentHeight", "MaxContentHeight", FORCE_NUMBER )
AccessorFunc( PANEL, "m_iPaddingBottom", "PaddingBottom", FORCE_NUMBER )
AccessorFunc( PANEL, "m_Background", "Background" )

function PANEL:Init()

	local border = MainMenu.Scale( 3 )

	self.Scroll = vgui.Create( "DScrollPanel", self )
	self.Scroll:Dock( FILL )
	self.Scroll:DockMargin( border, border, border, border )
	MainMenu.StyleScrollBar( self.Scroll:GetVBar() )

	self:SetRight( 13 )
	self:SetContentWidth( 230 )
	self:SetMaxContentHeight( math.huge )
	self:SetPaddingBottom( 0 )
	self:SetBackground( colorBorder )

end

function PANEL:Add( class )

	return self.Scroll:Add( class )

end

function PANEL:GetCanvas()

	return self.Scroll:GetCanvas()

end

function PANEL:SetContentHeight( contentH )

	local parent = self:GetParent()
	local border = MainMenu.Scale( 3 )
	local w = MainMenu.Scale( self:GetContentWidth() ) + border * 2
	local h = math.min( contentH, self:GetMaxContentHeight() ) + border * 2 + MainMenu.Scale( self:GetPaddingBottom() )

	self:SetSize( w, h )
	self:SetPos( parent:GetWide() - MainMenu.Scale( self:GetRight() ) - w, parent:GetTall() - MainMenu.Scale( 53 ) - h )

end

function PANEL:Paint( w, h )

	local border = MainMenu.Scale( 3 )

	draw.RoundedBox( border, 0, 0, w, h, colorBorder )

	surface.SetDrawColor( self:GetBackground() )
	surface.DrawRect( border, border, w - border * 2, h - border * 2 )

end

vgui.Register( "MainMenuPopup", PANEL, "EditablePanel" )
