
local colorText = Color( 51, 51, 51 )
local colorSeparatorDark = Color( 128, 128, 128 )
local colorSeparatorLight = Color( 192, 192, 192 )
local colorFadedRow = Color( 194, 194, 194 )
local fadedIconAlpha = 187

local function DrawIcon( mat, x, alpha )

	if ( !mat ) then return end

	MainMenu.DrawImage( mat, MainMenu.Scale( x ), MainMenu.Scale( 2 ), MainMenu.Scale( 16 ), MainMenu.Scale( 16 ), alpha )

end

local function SortGames( a, b )

	if ( a.installed != b.installed ) then return a.installed end
	if ( a.owned != b.owned ) then return a.owned end

	return a.title < b.title

end

MainMenu.AddPopup( "games", function( popup, menu )

	popup:SetRight( 153 )
	popup:SetContentWidth( 260 )
	popup:SetMaxContentHeight( MainMenu.Scale( 300 ) )

	local notOwned = MainMenu.Material( "html/img/notowned.png" )
	local notInstalled = MainMenu.Material( "html/img/notinstalled.png" )
	local font = MainMenu.Font( 11, 700 )
	local itemH, gap = MainMenu.Scale( 20 ), MainMenu.Scale( 2 )
	local contentH = 0

	local function AddRow( height, marginTop, marginBottom )
		local row = popup:Add( "Panel" )
		row:Dock( TOP )
		row:DockMargin( 0, marginTop, MainMenu.Scale( 2 ), marginBottom )
		row:SetTall( height )

		contentH = contentH + marginTop + height + marginBottom

		return row
	end

	for _, legend in ipairs( { { notOwned, "game_not_owned" }, { notInstalled, "game_not_installed" } } ) do
		local text = language.GetPhrase( legend[ 2 ] )

		local row = AddRow( itemH, 0, gap )
		row.Paint = function( s, w, h )
			draw.RoundedBox( MainMenu.Scale( 2 ), 0, 0, w, h, color_white )
			DrawIcon( legend[ 1 ], 2 )
			MainMenu.DrawText( text, font, MainMenu.Scale( 25 ), MainMenu.Scale( 3 ), colorText )
		end
	end

	local separator = AddRow( MainMenu.Scale( 2 ), MainMenu.Scale( 6 ) - gap, MainMenu.Scale( 6 ) )
	separator.Paint = function( s, w, h )
		surface.SetDrawColor( colorSeparatorDark )
		surface.DrawRect( 0, 0, w, 1 )
		surface.SetDrawColor( colorSeparatorLight )
		surface.DrawRect( 0, 1, w, h - 1 )
	end

	local games = engine.GetGames()
	for _, game in ipairs( games ) do
		game.installed, game.owned, game.mounted = tobool( game.installed ), tobool( game.owned ), tobool( game.mounted )
	end

	table.sort( games, SortGames )

	for i, game in ipairs( games ) do
		local icon = MainMenu.Material( "games/16/" .. game.folder .. ".png" )
		local bFaded = !game.owned or !game.installed
		local status = !game.owned and notOwned or ( !game.installed and notInstalled or nil )

		local row = AddRow( itemH, 0, i == #games and 0 or gap )
		row.Paint = function( s, w, h )
			local alpha = bFaded and fadedIconAlpha or 255

			draw.RoundedBox( MainMenu.Scale( 2 ), 0, 0, w, h, bFaded and colorFadedRow or color_white )
			DrawIcon( status, 2, alpha )
			DrawIcon( icon, 22, alpha )
			MainMenu.DrawText( game.title, font, MainMenu.Scale( 41 ), MainMenu.Scale( 3 ), colorText )
		end

		if ( game.installed ) then
			local checkbox = vgui.Create( "MainMenuCheckBox", row )
			checkbox:SetPos( MainMenu.Scale( 4 ), MainMenu.Scale( 3 ) )
			checkbox:SetChecked( game.mounted )
			checkbox.OnChange = function( s, bChecked ) engine.SetMounted( tostring( game.depot ), bChecked ) end
		end
	end

	return contentH

end )
