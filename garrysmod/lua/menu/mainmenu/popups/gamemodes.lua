
local colorItem = Color( 238, 238, 238 )
local colorText = Color( 51, 51, 51 )

MainMenu.AddPopup( "gamemodes", function( popup, menu )

	popup:SetMaxContentHeight( math.floor( menu:GetTall() * 0.8 ) - MainMenu.Scale( 6 ) )

	local gamemodes = {}
	for _, gm in ipairs( engine.GetGamemodes() ) do
		if ( gm.menusystem ) then table.insert( gamemodes, gm ) end
	end

	table.SortByMember( gamemodes, "name", true )

	local itemH, gap = MainMenu.Scale( 40 ), MainMenu.Scale( 2 )

	for i, gm in ipairs( gamemodes ) do
		local bFirst, bLast = i == 1, i == #gamemodes
		local icon = MainMenu.Material( "gamemodes/" .. gm.name .. "/icon24.png" )

		local item = popup:Add( "DButton" )
		item:SetText( "" )
		item:Dock( TOP )
		item:DockMargin( 0, 0, 0, bLast and 0 or gap )
		item:SetTall( itemH )
		item.Paint = function( s, w, h )
			draw.RoundedBoxEx( MainMenu.Scale( 3 ), 0, 0, w, h, s:IsHovered() and color_white or colorItem, bFirst, bFirst, bLast, bLast )

			if ( icon ) then
				local iconW, iconH = MainMenu.MaterialSize( icon )
				MainMenu.DrawImage( icon, MainMenu.Scale( 5 ), MainMenu.Scale( 5 ), iconW, iconH )
			end

			MainMenu.DrawText( gm.title, MainMenu.Font( 11, 700 ), MainMenu.Scale( 45 ), MainMenu.Scale( 13 ), colorText )
		end
		item.DoClick = function()
			RunConsoleCommand( "gamemode", gm.name )
			menu:SetPendingGamemode( gm.name )
			menu:ClosePopup()
		end
	end

	return #gamemodes * ( itemH + gap ) - ( #gamemodes > 0 and gap or 0 )

end )
