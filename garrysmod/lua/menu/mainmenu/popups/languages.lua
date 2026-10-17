
local colorBackground = Color( 238, 238, 238 )
local colorFlagBorder = Color( 136, 136, 136 )

MainMenu.AddPopup( "languages", function( popup, menu )

	popup:SetRight( 103 )
	popup:SetPaddingBottom( 4 )
	popup:SetBackground( colorBackground )

	local languages = {}
	for _, filename in ipairs( file.Find( "resource/localization/*.png", "MOD" ) ) do
		table.insert( languages, string.StripExtension( filename ) )
	end

	local cellW, cellH = MainMenu.Scale( 26 ), MainMenu.Scale( 24 )
	local marginTop, marginRight = MainMenu.Scale( 5 ), MainMenu.Scale( 3 )
	local rowH = MainMenu.Scale( 32 )
	local contentW = MainMenu.Scale( popup:GetContentWidth() )
	local perRow = math.max( 1, math.floor( contentW / ( cellW + marginRight ) ) )
	local canvas = popup:GetCanvas()

	for i, lang in ipairs( languages ) do
		local row = math.floor( ( i - 1 ) / perRow )
		local column = ( i - 1 ) % perRow
		local inRow = math.min( perRow, #languages - row * perRow )
		local rowX = math.floor( ( contentW - inRow * ( cellW + marginRight ) ) / 2 )
		local flag = MainMenu.Material( "resource/localization/" .. lang .. ".png" )

		local item = vgui.Create( "DButton", canvas )
		item:SetText( "" )
		item:SetPos( rowX + column * ( cellW + marginRight ), row * rowH + marginTop )
		item:SetSize( cellW, cellH )
		item.Paint = function( s, w, h )
			if ( s:IsHovered() ) then draw.RoundedBox( MainMenu.Scale( 4 ), 0, 0, w, h, color_white ) end

			if ( flag ) then
				local flagW, flagH = MainMenu.MaterialSize( flag )
				MainMenu.DrawBorderedImage( flag, MainMenu.Scale( 5 ), MainMenu.Scale( 5 ), flagW, flagH, MainMenu.Scale( 1 ), colorFlagBorder )
			end
		end
		item.DoClick = function()
			RunConsoleCommand( "gmod_language", lang )
			menu:ClosePopup()
		end
	end

	local contentH = math.ceil( #languages / perRow ) * rowH
	canvas:SetTall( contentH )

	return contentH

end )
