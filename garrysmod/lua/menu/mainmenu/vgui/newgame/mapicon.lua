
local PANEL = {}

local colorSelected = Color( 151, 197, 255 )

local thumbnails = {}

local function GetThumbnail( map, category )

	if ( category == "INFRA" ) then return MainMenu.Material( "html/img/incompatible.png" ) end

	if ( thumbnails[ map ] == nil ) then
		thumbnails[ map ] = MainMenu.Material( "maps/thumb/" .. map .. ".png" ) or MainMenu.Material( "maps/" .. map .. ".png" ) or MainMenu.Material( "maps/thumb/noicon.png" ) or false
	end

	return thumbnails[ map ] or nil

end

local function IsFavourite( map )

	for _, name in ipairs( GetMapList().Favourites or {} ) do
		if ( name:lower() == map:lower() ) then return true end
	end

	return false

end

function PANEL:Init()

	self:SetText( "" )

end

function PANEL:Setup( map, category )

	self.Map = map
	self.Category = category
	self.Thumbnail = GetThumbnail( map:Trim(), category )
	self.Lines = MainMenu.WrapTextAnywhere( map, MainMenu.Font( 10 ), MainMenu.Scale( 128 ) )

end

function PANEL:GetLineCount()

	return #self.Lines

end

function PANEL:IsOverFavourite()

	local x, y = self:LocalCursorPos()
	local left, top, size = MainMenu.Scale( 118 ), MainMenu.Scale( 10 ), MainMenu.Scale( 16 )

	return x >= left and x < left + size and y >= top and y < top + size

end

function PANEL:DoClick()

	if ( self:IsOverFavourite() ) then
		ToggleFavourite( self.Map )
		return
	end

	self:OnSelect()

end

function PANEL:DoDoubleClick()

	if ( self:IsOverFavourite() ) then return end

	self:OnSelect()
	self:OnStart()

end

function PANEL:OnSelect()
end

function PANEL:OnStart()
end

function PANEL:IsSelected()

	return false

end

function PANEL:Paint( w, h )

	if ( self:IsSelected() ) then
		draw.RoundedBox( MainMenu.Scale( 3 ), MainMenu.Scale( 2 ), MainMenu.Scale( 2 ), w - MainMenu.Scale( 4 ), h - MainMenu.Scale( 4 ), colorSelected )
	end

	local thumbSize = MainMenu.Scale( 128 )
	local thumbPos = MainMenu.Scale( 8 )

	if ( self.Thumbnail ) then
		MainMenu.DrawImage( self.Thumbnail, thumbPos, thumbPos, thumbSize, thumbSize )
	end

	local font = MainMenu.Font( 10 )
	local y = thumbPos + thumbSize + MainMenu.Scale( 2 )

	for _, line in ipairs( self.Lines ) do
		local lineW = MainMenu.TextSize( line, font )

		MainMenu.DrawText( line, font, thumbPos + math.floor( ( thumbSize - lineW ) / 2 ), y, color_black )
		y = y + MainMenu.LineHeight( 10 )
	end

	local bFavourite = IsFavourite( self.Map )
	local bHovered = self:IsHovered()

	if ( bHovered or bFavourite ) then
		local image = "html/img/favourite.png"
		if ( bHovered and self:IsOverFavourite() ) then
			image = bFavourite and "html/img/favourite_remove.png" or "html/img/favourite_add.png"
		end

		local mat = MainMenu.Material( image )
		if ( mat ) then MainMenu.DrawImage( mat, MainMenu.Scale( 118 ), MainMenu.Scale( 10 ), MainMenu.Scale( 16 ), MainMenu.Scale( 16 ) ) end
	end

end

vgui.Register( "MainMenuMapIcon", PANEL, "DButton" )
