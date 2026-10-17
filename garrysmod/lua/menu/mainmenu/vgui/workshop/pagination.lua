
local PANEL = {}

local maxPages = 32

local function CreateArrow( parent, image, delta )

	local button = vgui.Create( "MainMenuBlueButton", parent )
	button:SetSize( MainMenu.Scale( 48 ), MainMenu.Scale( 36 ) )
	button:SetRadius( 3 )
	button:SetIcon( image )
	button.DoClick = function() parent:OnGo( delta ) end

	return button

end

function PANEL:Init()

	self.Back = CreateArrow( self, "html/img/arrow_left.png", -1 )
	self.Next = CreateArrow( self, "html/img/arrow_right.png", 1 )
	self.Dot = MainMenu.Material( "html/img/pagination_page.png" )

	self.Page = 1
	self.PageCount = 1

	self:SetSize( MainMenu.Scale( 500 ), MainMenu.Scale( 44 ) )

end

function PANEL:SetPage( page, pageCount )

	self.Page = page
	self.PageCount = pageCount

end

function PANEL:OnGo( delta )
end

function PANEL:OnGoToPage( page )
end

function PANEL:GetDotRange()

	local first = math.floor( ( self.Page - 1 ) / maxPages ) * maxPages + 1

	return first, math.min( self.PageCount, first + maxPages - 1 )

end

function PANEL:GetDotRect( index, first, last )

	local dotW = MainMenu.Scale( 12 )
	local x = math.floor( ( self:GetWide() - ( last - first + 1 ) * dotW ) / 2 ) + ( index - first ) * dotW

	return x, MainMenu.Scale( 10 ), dotW, MainMenu.Scale( 12 )

end

function PANEL:OnMousePressed( code )

	if ( code != MOUSE_LEFT ) then return end

	local mouseX, mouseY = self:LocalCursorPos()
	local first, last = self:GetDotRange()

	for page = first, last do
		local x, y, w, h = self:GetDotRect( page, first, last )
		if ( mouseX >= x and mouseX < x + w and mouseY >= y and mouseY < y + h ) then
			self:OnGoToPage( page )
			return
		end
	end

end

function PANEL:PerformLayout( w, h )

	self.Back:SetPos( MainMenu.Scale( 4 ), MainMenu.Scale( 4 ) )
	self.Next:SetPos( w - MainMenu.Scale( 52 ), MainMenu.Scale( 4 ) )

end

function PANEL:Paint( w, h )

	draw.RoundedBox( MainMenu.Scale( 4 ), 0, 0, w, h, color_white )

	local first, last = self:GetDotRange()

	if ( self.Dot ) then
		for page = first, last do
			local x, y, dotW, dotH = self:GetDotRect( page, first, last )
			MainMenu.DrawImage( self.Dot, x, y, dotW, dotH, page == self.Page and 255 or 128 )
		end
	end

	local font = MainMenu.Font( 14 )
	local text = tostring( self.Page )

	MainMenu.DrawText( text, font, math.floor( ( w - MainMenu.TextSize( text, font ) ) / 2 ), MainMenu.Scale( 24 ), color_black )

end

vgui.Register( "MainMenuPagination", PANEL, "Panel" )
