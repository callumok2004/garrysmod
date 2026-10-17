
local PANEL = {}

local colorTitle = Color( 255, 255, 255 )
local colorTitleHovered = Color( 255, 255, 170 )
local colorCaption = Color( 0, 0, 0, 172 )
local colorBackground = Color( 51, 51, 51 )

local buttonColors = {
	normal = Color( 102, 102, 102 ),
	new = Color( 255, 85, 85 ),
	selected = Color( 238, 238, 238 ),
	selectedNew = Color( 255, 204, 204 )
}

local newsLifetime = 60 * 60 * 24 * 3.5

local function ParseDate( str )

	if ( !isstring( str ) ) then return end

	local year, month, day = str:match( "^(%d+)-(%d+)-(%d+)" )
	if ( !year ) then return end

	local hour, minute, second = str:match( "[T ](%d+):(%d+):?(%d*)" )

	return os.time( {
		year = tonumber( year ),
		month = tonumber( month ),
		day = tonumber( day ),
		hour = tonumber( hour ) or 0,
		min = tonumber( minute ) or 0,
		sec = tonumber( second ) or 0
	} )

end

function PANEL:Init()

	self:NoClipping( true )
	self:SetSize( MainMenu.Scale( 512 ), MainMenu.Scale( 256 + 3 + 16 ) )

	self.Items = {}
	self.Buttons = {}

end

function PANEL:SetItems( items, bHidden )

	self.Items = items
	self.bHidden = bHidden
	self:Refresh()

end

function PANEL:OnHiddenChanged( bHidden )
end

function PANEL:AddButton( x, paint, click )

	local size = MainMenu.Scale( 16 )

	local button = vgui.Create( "DButton", self )
	button:SetText( "" )
	button:NoClipping( true )
	button:SetPos( x, MainMenu.Scale( 256 + 3 ) )
	button:SetSize( size, size )
	button.Paint = function( s, w, h )
		s:GetSkin().tex.Shadow( -4, -4, w + 10, h + 10 )
		paint( w, h )
	end
	button.DoClick = click

	table.insert( self.Buttons, button )

	return x - size - MainMenu.Scale( 3 )

end

function PANEL:Refresh()

	for _, button in ipairs( self.Buttons ) do button:Remove() end
	self.Buttons = {}

	self:SetVisible( #self.Items > 0 )
	if ( #self.Items == 0 ) then return end

	local bAnyNew = false
	for _, item in ipairs( self.Items ) do
		local time = ParseDate( item.Date )
		item.bNew = time != nil and time > os.time() - newsLifetime
		item.SortTime = time or 0

		if ( item.bNew ) then bAnyNew = true end
	end

	if ( bAnyNew ) then self.bHidden = false end

	if ( !table.HasValue( self.Items, self.Current ) ) then
		self:SetCurrent( self.Items[ 1 ] )
	end

	local x = self:GetWide() - MainMenu.Scale( 16 )

	if ( !self.bHidden and !bAnyNew ) then
		local cross = MainMenu.Material( "icon16/cross.png" )

		x = self:AddButton( x, function( w, h )
			draw.RoundedBox( MainMenu.Scale( 3 ), 0, 0, w, h, buttonColors.normal )
			if ( cross ) then MainMenu.DrawImage( cross, 0, 0, w, h ) end
		end, function() self:SetHidden( true ) end )
	end

	local sorted = table.Add( {}, self.Items )
	table.SortByMember( sorted, "SortTime", true )

	for _, item in ipairs( sorted ) do
		x = self:AddButton( x, function( w, h )
			local color
			if ( item == self.Current ) then
				color = item.bNew and buttonColors.selectedNew or buttonColors.selected
			else
				color = item.bNew and buttonColors.new or buttonColors.normal
			end

			draw.RoundedBox( MainMenu.Scale( 3 ), 0, 0, w, h, color )
		end, function()
			self:SetCurrent( item )
			self:SetHidden( false )
		end )
	end

end

function PANEL:SetCurrent( item )

	self.Current = item
	self.Material = MainMenu.CachedWebMaterial( item.HeaderImage )

	local width = MainMenu.Scale( 512 - 10 )

	self.TitleLines = MainMenu.WrapText( item.Title or "", MainMenu.Font( 24, 700 ), width )
	self.SummaryLines = ( item.SummaryHtml or "" ) != "" and MainMenu.WrapText( item.SummaryHtml, MainMenu.Font( 13 ), width ) or {}

	local _, titleH = MainMenu.TextSize( "W", MainMenu.Font( 24, 700 ) )
	local _, summaryH = MainMenu.TextSize( "W", MainMenu.Font( 13 ) )

	self.TitleHeight = titleH
	self.SummaryHeight = summaryH
	self.CaptionHeight = MainMenu.Scale( 10 ) + #self.TitleLines * titleH + #self.SummaryLines * summaryH

end

function PANEL:SetHidden( bHidden )

	self.bHidden = bHidden
	self:OnHiddenChanged( bHidden )
	self:Refresh()

end

function PANEL:IsShowingItem()

	return self.Current != nil and !self.bHidden

end

function PANEL:IsOverTitle()

	if ( !self:IsShowingItem() ) then return false end

	local x, y = self:LocalCursorPos()
	local font = MainMenu.Font( 24, 700 )
	local right = MainMenu.Scale( 512 - 5 )
	local top = MainMenu.Scale( 256 + 5 ) - self.CaptionHeight

	for i, line in ipairs( self.TitleLines ) do
		local lineW = MainMenu.TextSize( line, font )
		local lineY = top + ( i - 1 ) * self.TitleHeight

		if ( x >= right - lineW and x <= right and y >= lineY and y < lineY + self.TitleHeight ) then return true end
	end

	return false

end

function PANEL:Think()

	self:SetCursor( self:IsOverTitle() and "hand" or "arrow" )

end

function PANEL:OnMousePressed( code )

	if ( code == MOUSE_LEFT and self:IsOverTitle() ) then
		gui.OpenURL( self.Current.Url )
	end

end

function PANEL:Paint( w, h )

	if ( !self:IsShowingItem() ) then return end

	local imageW, imageH = MainMenu.Scale( 512 ), MainMenu.Scale( 256 )
	local radius = MainMenu.Scale( 8 )

	self:GetSkin().tex.Shadow( -4, -4, imageW + 10, imageH + 10 )
	draw.RoundedBox( radius, 0, 0, imageW, imageH, colorBackground )

	local mat = self.Material
	if ( mat ) then
		local coverScale = math.max( imageW / mat:Width(), imageH / mat:Height() )

		surface.SetDrawColor( 255, 255, 255 )
		MainMenu.DrawRoundedImage( mat, 0, 0, imageW, imageH, radius, 0, 0, imageW / ( mat:Width() * coverScale ), imageH / ( mat:Height() * coverScale ) )
	end

	local top = imageH - self.CaptionHeight
	draw.RoundedBoxEx( radius, 0, top, imageW, self.CaptionHeight, colorCaption, false, false, true, true )

	local right = imageW - MainMenu.Scale( 5 )
	local y = top + MainMenu.Scale( 5 )
	local titleColor = self:IsOverTitle() and colorTitleHovered or colorTitle

	local titleFont, titleShadow = MainMenu.Font( 24, 700 ), MainMenu.Font( 24, 700, 1 )
	for _, line in ipairs( self.TitleLines ) do
		MainMenu.DrawShadowText( line, titleFont, titleShadow, right - MainMenu.TextSize( line, titleFont ), y, titleColor, MainMenu.Scale( 2 ) )
		y = y + self.TitleHeight
	end

	local summaryFont = MainMenu.Font( 13 )
	for _, line in ipairs( self.SummaryLines ) do
		MainMenu.DrawText( line, summaryFont, right - MainMenu.TextSize( line, summaryFont ), y, colorTitle )
		y = y + self.SummaryHeight
	end

end

vgui.Register( "MainMenuNews", PANEL, "Panel" )
