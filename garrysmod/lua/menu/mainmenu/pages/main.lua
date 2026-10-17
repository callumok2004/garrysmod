
MainMenu.AddPage( "main", function( pnl, menu )

	local x = MainMenu.Scale( 50 + 20 + 16 )
	local y = MainMenu.Scale( 50 + 23 + 2 )
	local rowH = MainMenu.Scale( 27 )

	local function AddSpace()
		y = y + rowH
	end

	local function AddOption( phrase, onClick )
		local link = vgui.Create( "MainMenuLink", pnl )
		link:Setup( phrase )
		link:SetPos( x, y )
		link.OnClick = onClick

		AddSpace()
	end

	local logo = MainMenu.Material( "gamemodes/" .. engine.ActiveGamemode() .. "/logo.png" )
	if ( logo ) then
		local logoW, logoH = MainMenu.MaterialSize( logo )

		local image = vgui.Create( "Panel", pnl )
		image:SetPos( x, y )
		image:SetSize( logoW, logoH )
		image.Paint = function( s, w, h ) MainMenu.DrawImage( logo, 0, 0, w, h ) end

		y = y + logoH + MainMenu.Scale( 6 )
	else
		AddSpace()
	end

	AddSpace()

	if ( IsInGame() ) then
		AddOption( "resume_game", function() gui.HideGameUI() end )
		AddSpace()
	end

	AddOption( "new_game", function() menu:OpenPage( "newgame" ) end )
	AddOption( "find_mp_game", function() menu:OpenPage( "servers" ) end )
	AddSpace()
	AddOption( "addons", function() menu:OpenPage( "addons" ) end )
	AddOption( "dupes", function() menu:OpenPage( "dupes" ) end )
	AddOption( "saves", function() menu:OpenPage( "saves" ) end )
	AddOption( "demos", function() menu:OpenPage( "demos" ) end )
	AddSpace()
	AddOption( "options", function() RunGameUICommand( "OpenOptionsDialog" ) end )
	AddSpace()

	if ( IsInGame() ) then
		AddOption( "disconnect", function() RunGameUICommand( "Disconnect" ) end )
	end

	AddOption( "quit", function() RunGameUICommand( "QuitNoConfirm" ) end )

	local news = vgui.Create( "MainMenuNews", pnl )
	news:SetPos( pnl:GetWide() - MainMenu.Scale( 50 + 512 ), MainMenu.Scale( 75 ) )
	news:SetItems( menu.NewsList, menu.HideNews )
	news.OnHiddenChanged = function( s, bHidden )
		menu.HideNews = bHidden
		SaveHideNews( bHidden )
	end

	hook.Add( "MainMenuNewsChanged", news, function( s, items, bHidden )
		news:SetItems( items, bHidden )
	end )

end )
