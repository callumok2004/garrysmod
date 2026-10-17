
MainMenu.ScaleFactor = MainMenu.ScaleFactor or 1

function MainMenu.Scale( size )

	return math.Round( size * MainMenu.ScaleFactor )

end

function MainMenu.UpdateScale()

	local scale = ScrH() / 1080

	if ( math.abs( scale - 1 ) < 0.05 ) then scale = 1 end

	MainMenu.ScaleFactor = scale

end

function MainMenu.ViewportWidth()

	return ScrW() / MainMenu.ScaleFactor

end

local fontCellRatio = 1.149
local createdFonts = {}

function MainMenu.Font( size, weight, blur )

	weight = weight or 400
	blur = blur or 0

	local name = string.format( "MainMenu_%g_%d_%d_%g", size, weight, blur, MainMenu.ScaleFactor )
	if ( createdFonts[ name ] ) then return name end

	surface.CreateFont( name, {
		font = "Arial",
		size = math.Round( size * fontCellRatio * MainMenu.ScaleFactor ),
		weight = weight,
		blursize = blur > 0 and math.max( 1, MainMenu.Scale( blur ) ) or 0,
		extended = true
	} )

	createdFonts[ name ] = true

	return name

end

function MainMenu.LineHeight( size )

	return MainMenu.Scale( math.Round( size * 0.905 ) + math.Round( size * 0.212 ) )

end

function MainMenu.Ascent( size )

	return MainMenu.Scale( math.Round( size * 0.905 ) )

end

function MainMenu.PlaySound( name )

	surface.PlaySound( "garrysmod/" .. name .. ".wav" )

end

function MainMenu.BlendColor( from, to, fraction )

	return Color( Lerp( fraction, from.r, to.r ), Lerp( fraction, from.g, to.g ), Lerp( fraction, from.b, to.b ) )

end

local materials = {}

function MainMenu.Material( path )

	if ( materials[ path ] == nil ) then
		local mat = Material( path, "smooth" )
		materials[ path ] = !mat:IsError() and mat or false
	end

	return materials[ path ] or nil

end

function MainMenu.MaterialSize( mat )

	local w = mat:GetInt( "$realwidth" ) or mat:Width()
	local h = mat:GetInt( "$realheight" ) or mat:Height()

	return MainMenu.Scale( w ), MainMenu.Scale( h )

end

function MainMenu.CachedWebMaterial( url )

	if ( !isstring( url ) or url == "" ) then return end

	local hash = 5381
	for i = 1, #url do
		hash = ( hash * 33 + url:byte( i ) ) % 4294967296
	end

	local ext = url:lower():find( "%.jpe?g" ) and ".jpg" or ".png"
	local path = string.format( "mainmenu/cache/%08x%s", hash, ext )
	if ( !file.Exists( path, "DATA" ) ) then return end

	return MainMenu.Material( "../data/" .. path )

end

function MainMenu.DrawImage( mat, x, y, w, h, alpha )

	surface.SetDrawColor( 255, 255, 255, alpha or 255 )
	surface.SetMaterial( mat )
	surface.DrawTexturedRect( x, y, w, h )

end

function MainMenu.DrawBorderedImage( mat, x, y, w, h, border, color )

	surface.SetDrawColor( color )
	surface.DrawRect( x, y, w + border * 2, h + border * 2 )

	MainMenu.DrawImage( mat, x + border, y + border, w, h )

end

function MainMenu.DrawRoundedImage( mat, x, y, w, h, radius, u0, v0, u1, v1 )

	local du = ( u1 - u0 ) / w
	local dv = ( v1 - v0 ) / h

	surface.SetMaterial( mat )
	surface.DrawTexturedRectUV( x, y + radius, w, h - radius * 2, u0, v0 + radius * dv, u1, v1 - radius * dv )

	for i = 0, radius - 1 do
		local dy = radius - i - 0.5
		local inset = math.Round( radius - math.sqrt( radius * radius - dy * dy ) )
		local u, uEnd = u0 + inset * du, u1 - inset * du

		surface.DrawTexturedRectUV( x + inset, y + i, w - inset * 2, 1, u, v0 + i * dv, uEnd, v0 + ( i + 1 ) * dv )
		surface.DrawTexturedRectUV( x + inset, y + h - 1 - i, w - inset * 2, 1, u, v1 - ( i + 1 ) * dv, uEnd, v1 - i * dv )
	end

end

function MainMenu.TextSize( text, font )

	surface.SetFont( font )

	return surface.GetTextSize( text )

end

function MainMenu.DrawText( text, font, x, y, color )

	surface.SetFont( font )
	surface.SetTextColor( color.r, color.g, color.b, color.a )
	surface.SetTextPos( math.Round( x ), math.Round( y ) )
	surface.DrawText( text )

end

function MainMenu.DrawShadowText( text, font, shadowFont, x, y, color, offset )

	MainMenu.DrawText( text, shadowFont, x + offset, y + offset, color_black )
	MainMenu.DrawText( text, font, x, y, color )

end

function MainMenu.WrapText( text, font, width )

	surface.SetFont( font )

	local lines = {}
	local line = ""

	for word in text:gmatch( "%S+" ) do
		local test = line == "" and word or ( line .. " " .. word )

		if ( line != "" and surface.GetTextSize( test ) > width ) then
			table.insert( lines, line )
			line = word
		else
			line = test
		end
	end

	if ( line != "" or #lines == 0 ) then table.insert( lines, line ) end

	return lines

end

function MainMenu.WrapTextAnywhere( text, font, width )

	surface.SetFont( font )

	local lines = {}
	local line = ""

	for char in text:gmatch( utf8.charpattern ) do
		if ( line != "" and surface.GetTextSize( line .. char ) > width ) then
			table.insert( lines, line )
			line = char
		else
			line = line .. char
		end
	end

	table.insert( lines, line )

	return lines

end

local function CornerInset( row, h, radius )

	local dy
	if ( row < radius ) then
		dy = radius - row - 0.5
	elseif ( row >= h - radius ) then
		dy = row - ( h - radius ) + 0.5
	else
		return 0
	end

	return math.Round( radius - math.sqrt( math.max( 0, radius * radius - dy * dy ) ) )

end

local function DrawRow( x, y, w, h, radius, row, r, g, b )

	local inset = CornerInset( row, h, math.min( radius, math.floor( math.min( w, h ) / 2 ) ) )

	surface.SetDrawColor( r, g, b, 255 )
	surface.DrawRect( x + inset, y + row, w - inset * 2, 1 )

end

function MainMenu.DrawGradient( x, y, w, h, radius, top, bottom )

	for row = 0, h - 1 do
		local fraction = ( row + 0.5 ) / h
		DrawRow( x, y, w, h, radius, row, Lerp( fraction, top.r, bottom.r ), Lerp( fraction, top.g, bottom.g ), Lerp( fraction, top.b, bottom.b ) )
	end

end

function MainMenu.DrawGradientBox( x, y, w, h, radius, colors, bHovered )

	for row = 0, h - 1 do
		local border = row == h - 1 and colors.BorderBottom or colors.Border
		DrawRow( x, y, w, h, radius, row, border.r, border.g, border.b )
	end

	local top = bHovered and colors.HoverTop or colors.Top
	local bottom = bHovered and colors.HoverBottom or colors.Bottom
	local blend = 0.2

	for row = 0, h - 3 do
		local fraction = ( row + 1.5 ) / h
		local r, g, b = Lerp( fraction, top.r, bottom.r ), Lerp( fraction, top.g, bottom.g ), Lerp( fraction, top.b, bottom.b )
		if ( row == 0 ) then r, g, b = Lerp( blend, r, 255 ), Lerp( blend, g, 255 ), Lerp( blend, b, 255 ) end

		DrawRow( x + 1, y + 1, w - 2, h - 2, math.max( 0, radius - 1 ), row, r, g, b )
	end

end

local scrollTrack = Color( 250, 250, 250 )
local scrollGrip = Color( 180, 180, 180 )

function MainMenu.StyleScrollBar( bar )

	bar:SetWide( MainMenu.Scale( 8 ) )
	bar:SetHideButtons( true )
	bar.Paint = function( s, w, h ) draw.RoundedBox( MainMenu.Scale( 1 ), 0, 0, w, h, scrollTrack ) end
	bar.btnGrip.Paint = function( s, w, h ) draw.RoundedBox( MainMenu.Scale( 2 ), 0, 0, w, h, scrollGrip ) end

end

function MainMenu.StartClip( pnl, x, y, w, h )

	local screenX, screenY = pnl:LocalToScreen( x, y )
	render.SetScissorRect( screenX, screenY, screenX + w, screenY + h, true )

end

function MainMenu.EndClip()

	render.SetScissorRect( 0, 0, 0, 0, false )

end
