
MainMenu = MainMenu or {}
MainMenu.Panels = MainMenu.Panels or {}
MainMenu.Pages = {}
MainMenu.Popups = {}

function MainMenu.AddPage( name, build )

	MainMenu.Pages[ name ] = build

end

function MainMenu.AddPopup( name, build )

	MainMenu.Popups[ name ] = build

end

include( "drawing.lua" )
include( "servers.lua" )
include( "workshop.lua" )

include( "vgui/link.lua" )
include( "vgui/navbutton.lua" )
include( "vgui/navbar.lua" )
include( "vgui/checkbox.lua" )
include( "vgui/togglelabel.lua" )
include( "vgui/stack.lua" )
include( "vgui/textentry.lua" )
include( "vgui/button.lua" )
include( "vgui/bluebutton.lua" )
include( "vgui/virtuallist.lua" )
include( "vgui/popup.lua" )
include( "vgui/version.lua" )
include( "vgui/menu.lua" )

include( "vgui/main/news.lua" )

include( "vgui/newgame/dropdown.lua" )
include( "vgui/newgame/mapicon.lua" )

include( "vgui/servers/shadowlabel.lua" )
include( "vgui/servers/header.lua" )
include( "vgui/servers/flagfilter.lua" )
include( "vgui/servers/gamemodelist.lua" )
include( "vgui/servers/serverlist.lua" )
include( "vgui/servers/findserver.lua" )
include( "vgui/servers/serverinfo.lua" )

include( "vgui/workshop/icon.lua" )
include( "vgui/workshop/pagination.lua" )

include( "vgui/addons/flatbutton.lua" )
include( "vgui/addons/dialog.lua" )

include( "popups/games.lua" )
include( "popups/gamemodes.lua" )
include( "popups/languages.lua" )

include( "pages/main.lua" )
include( "pages/newgame.lua" )
include( "pages/servers.lua" )
include( "pages/workshop.lua" )
include( "pages/addons.lua" )

function MainMenu.IsEnabled()

	return cookie.GetNumber( "mainmenu_vgui", 1 ) == 1

end

function MainMenu.Create()

	MainMenu.UpdateScale()

	local class = MainMenu.IsEnabled() and "MainMenuVGUI" or "MainMenuPanel"

	for name, pnl in pairs( MainMenu.Panels ) do
		if ( IsValid( pnl ) ) then pnl:SetVisible( name == class ) end
	end

	if ( class == "MainMenuPanel" and IsValid( MainMenu.Panels.MainMenuVGUI ) ) then
		MainMenu.Panels.MainMenuVGUI:OpenPage( "main" )
	end

	if ( IsValid( MainMenu.Panels[ class ] ) ) then
		pnlMainMenu = MainMenu.Panels[ class ]
		pnlMainMenu:MakePopup()
		pnlMainMenu:SetPopupStayAtBack( true )
	else
		pnlMainMenu = vgui.Create( class )
		MainMenu.Panels[ class ] = pnlMainMenu

		if ( class == "MainMenuPanel" ) then
			pnlMainMenu:Call( "UpdateVersion( '" .. VERSIONSTR:JavascriptSafe() .. "', '" .. NETVERSIONSTR:JavascriptSafe() .. "', '" .. BRANCH:JavascriptSafe() .. "' )" )
		end
	end

	pnlMainMenu:SetProblemCount( GetProblemCount() )

end

concommand.Add( "menu_vgui", function( ply, cmd, args )

	local bEnable = !MainMenu.IsEnabled()
	if ( args[ 1 ] ) then bEnable = tobool( args[ 1 ] ) end

	cookie.Set( "mainmenu_vgui", bEnable and "1" or "0" )

	MainMenu.Create()

	LanguageChanged( GetConVarString( "gmod_language" ) )
	hook.Run( "GameContentChanged" )
	LoadNewsList()

end )
