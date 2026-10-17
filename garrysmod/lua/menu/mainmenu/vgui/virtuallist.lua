
local PANEL = {}

AccessorFunc( PANEL, "m_iRowHeight", "RowHeight", FORCE_NUMBER )

function PANEL:Init()

	self:SetRowHeight( MainMenu.Scale( 22 ) )

	self.VBar = vgui.Create( "DVScrollBar", self )
	self.VBar:Dock( RIGHT )
	MainMenu.StyleScrollBar( self.VBar )

	self.LastClickTime = 0
	self.Items = {}

end

function PANEL:SetItems( items )

	self.Items = items

end

function PANEL:GetCount()

	return #self.Items

end

function PANEL:PaintRow( index, x, y, w, h, bHovered )
end

function PANEL:OnRowClicked( index, code, x, y )
end

function PANEL:OnRowDoubleClicked( index )
end

function PANEL:GetRowWidth()

	return self:GetWide() - ( self.VBar:IsVisible() and self.VBar:GetWide() or 0 )

end

function PANEL:GetRowY( index )

	return ( index - 1 ) * self:GetRowHeight() - self.VBar:GetScroll()

end

function PANEL:GetRowAt( y )

	local index = math.floor( ( y + self.VBar:GetScroll() ) / self:GetRowHeight() ) + 1
	if ( index < 1 or index > self:GetCount() ) then return end

	return index

end

function PANEL:GetScroll()

	return self.VBar:GetScroll()

end

function PANEL:SetScroll( scroll )

	self:InvalidateLayout( true )
	self.VBar:SetScroll( scroll )

end

function PANEL:PerformLayout( w, h )

	self.VBar:SetUp( h, self:GetCount() * self:GetRowHeight() )

end

function PANEL:Think()

	local count = self:GetCount()

	if ( count != self.LastCount ) then
		self.LastCount = count
		self:InvalidateLayout()
	end

end

function PANEL:OnMouseWheeled( delta )

	return self.VBar:OnMouseWheeled( delta )

end

function PANEL:Paint( w, h )

	local rowW = self:GetRowWidth()
	local rowH = self:GetRowHeight()

	local hoveredRow
	if ( self:IsHovered() ) then
		local x, y = self:LocalCursorPos()
		if ( x < rowW ) then hoveredRow = self:GetRowAt( y ) end
	end

	local first = math.max( 1, math.floor( self.VBar:GetScroll() / rowH ) + 1 )

	for index = first, self:GetCount() do
		local y = self:GetRowY( index )
		if ( y > h ) then break end

		self:PaintRow( index, 0, y, rowW, rowH, index == hoveredRow )
	end

end

function PANEL:OnMousePressed( code )

	local x, y = self:LocalCursorPos()
	local index = self:GetRowAt( y )
	if ( !index ) then return end

	if ( code == MOUSE_LEFT and self.LastClickIndex == index and SysTime() - self.LastClickTime < 0.4 ) then
		self.LastClickTime = 0
		self:OnRowDoubleClicked( index )
		return
	end

	self.LastClickTime = SysTime()
	self.LastClickIndex = index

	self:OnRowClicked( index, code, x, y - self:GetRowY( index ) )

end

vgui.Register( "MainMenuVirtualList", PANEL, "Panel" )
