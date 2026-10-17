
local PANEL = {}

function PANEL:Init()

	self:SetKeyboardInputEnabled( true )
	self:SetMouseInputEnabled( true )

	self.menuLoaded = true
	self.Page = "main"
	self.ProblemCount = 0
	self.ProblemSeverity = 0
	self.NewsList = {}
	self.HideNews = false

	self:MakePopup()
	self:SetPopupStayAtBack( true )

	if ( gui.IsConsoleVisible() ) then
		gui.ShowConsole()
	end

	self:Rebuild()

end

function PANEL:Rebuild()

	MainMenu.UpdateScale()
	self:Clear()

	self.Language = GetConVarString( "gmod_language" )
	self.Gamemode = engine.ActiveGamemode()
	self.IsInGame = IsInGame()
	self:SetSize( ScrW(), ScrH() )

	self:CreateNavBar()

	local version = vgui.Create( "MainMenuVersion", self )
	version:SetPos( self:GetWide() - MainMenu.Scale( 3 ) - version:GetWide(), MainMenu.Scale( 3 ) )

	self:OpenPage( self.Page, true )

end

function PANEL:CreateNavBar()

	local navBar = vgui.Create( "MainMenuNavBar", self )
	navBar:SetPos( 0, self:GetTall() - MainMenu.Scale( 50 ) )
	navBar:SetSize( self:GetWide(), MainMenu.Scale( 50 ) )
	self.NavBar = navBar

	self.Back = navBar:AddButton( "left", "back", "html/img/back_to_main_menu.png", "back_to_main_menu" )
	self.Back:SetSounds( "ui_hover", "ui_return" )
	self.Back.OnClick = function() self:OpenPage( "main" ) end

	self.BackToGame = navBar:AddButton( "center", "big", "html/img/back_to_game.png", "back_to_game" )
	self.BackToGame.OnClick = function() gui.HideGameUI() end

	self.Favorite = navBar:AddButton( "center", "big", "html/img/favourite_server.png", "favorite_this_server" )
	self.Favorite:SetHideLabelWhenNarrow( true )
	self.Favorite.OnClick = function() serverlist.AddCurrentServerToFavorites( true ) end

	self.Unfavorite = navBar:AddButton( "center", "big", "html/img/favourite_server_del.png", "unfavorite_this_server" )
	self.Unfavorite:SetHideLabelWhenNarrow( true )
	self.Unfavorite.OnClick = function() serverlist.AddCurrentServerToFavorites( false ) end

	self.Problems = navBar:AddButton( "right", "small", "html/img/error.png", "problems" )
	self.Problems:SetHideLabelWhenNarrow( true )
	self.Problems:SetBadge( self.ProblemCount, self.ProblemSeverity )
	self.Problems.OnClick = function() OpenProblemsPanel() end

	local games = navBar:AddButton( "right", "small", "html/img/games.png", "games" )
	games:SetHideLabelWhenNarrow( true )
	games.OnClick = function() self:TogglePopup( "games" ) end

	local lang = navBar:AddButton( "right", "small", "resource/localization/" .. self.Language .. ".png" )
	lang:SetIconY( 14 )
	lang.OnClick = function() self:TogglePopup( "languages" ) end

	self.GamemodeButton = navBar:AddButton( "right", "big" )
	self.GamemodeButton.OnClick = function() self:TogglePopup( "gamemodes" ) end
	self:SetPendingGamemode( self.Gamemode )

	self:UpdateNavBar()

end

function PANEL:UpdateNavBar()

	local bCanFavorite = self.IsInGame and self.CanAddServerToFavorites == true

	self.Back:SetVisible( self.Page != "main" )
	self.BackToGame:SetVisible( self.IsInGame )
	self.Favorite:SetVisible( bCanFavorite and !self.IsCurrentServerFavorite )
	self.Unfavorite:SetVisible( bCanFavorite and self.IsCurrentServerFavorite == true )

	self.NavBar:InvalidateLayout()

end

function PANEL:SetPendingGamemode( name )

	local title = name
	for _, gm in ipairs( engine.GetGamemodes() ) do
		if ( gm.name == name ) then title = gm.title end
	end

	self.GamemodeButton:Setup( "big", "gamemodes/" .. name .. "/icon24.png", title )
	self.NavBar:InvalidateLayout()

end

function PANEL:OpenPage( name, bForce )

	if ( name == self.Page and !bForce and IsValid( self.PagePanel ) ) then return end

	if ( IsValid( self.PagePanel ) ) then self.PagePanel:Remove() end

	self.Page = name

	self.PagePanel = vgui.Create( "Panel", self )
	self.PagePanel:SetSize( self:GetWide(), self:GetTall() - MainMenu.Scale( 50 ) )
	self.PagePanel:MoveToBack()

	MainMenu.Pages[ name ]( self.PagePanel, self )

	self:UpdateNavBar()

end

function PANEL:TogglePopup( name )

	local bOpen = IsValid( self.Popup ) and self.Popup.Name == name

	self:ClosePopup()
	if ( bOpen ) then return end

	self.Popup = vgui.Create( "MainMenuPopup", self )
	self.Popup.Name = name
	self.Popup:SetContentHeight( MainMenu.Popups[ name ]( self.Popup, self ) )

end

function PANEL:ClosePopup()

	if ( IsValid( self.Popup ) ) then self.Popup:Remove() end

end

function PANEL:SetNewsList( list, bHide )

	self.NewsList = list
	self.HideNews = bHide

	hook.Run( "MainMenuNewsChanged", list, bHide )

end

function PANEL:SetProblemCount( count, severity )

	self.ProblemCount = count
	self.ProblemSeverity = severity

	self.Problems:SetBadge( count, severity )

end

local function AddBackgrounds( folder )

	local files = file.Find( folder .. "*.*", "GAME" )

	if ( folder == "backgrounds/" ) then folder = "../" .. folder end

	for _, filename in ipairs( files ) do
		AddBackgroundImage( folder .. filename )
	end

	return #files > 0

end

function PANEL:RefreshContent()

	ClearBackgroundImages()

	if ( !AddBackgrounds( "gamemodes/" .. engine.ActiveGamemode() .. "/backgrounds/" ) ) then
		AddBackgrounds( "backgrounds/" )
	end

	ChangeBackground( engine.ActiveGamemode() )

	self:Rebuild()

end

for event, method in pairs( { OnAddServer = "AddServer", OnFinishedServers = "FinishedServers", OnUpdateServer = "UpdateServer", OnPlayerList = "SetPlayerList", OnFoundServers = "SetFoundServers" } ) do
	PANEL[ event ] = function( self, ... ) MainMenu.Servers[ method ]( MainMenu.Servers, ... ) end
end

for event, name in pairs( { OnServerSettings = "MainMenuServerSettings", OnAddonPresets = "MainMenuAddonPresets", OnImportPresetFailed = "MainMenuImportPresetFailed" } ) do
	PANEL[ event ] = function( self, ... ) hook.Run( name, ... ) end
end

function PANEL:OnMapListChanged()

	MainMenu.Servers:ResetMapIndex()
	hook.Run( "MainMenuMapListChanged" )

end

function PANEL:Call( js )
end

function PANEL:Think()

	if ( GetConVarString( "gmod_language" ) != self.Language or engine.ActiveGamemode() != self.Gamemode or IsInGame() != self.IsInGame ) then
		self:Rebuild()
		return
	end

	if ( !self.IsInGame ) then return end

	local bCanAdd = CanAddServerToFavorites()
	local bFavorite = serverlist.IsCurrentServerFavorite()

	if ( self.CanAddServerToFavorites != bCanAdd or self.IsCurrentServerFavorite != bFavorite ) then
		self.CanAddServerToFavorites = bCanAdd
		self.IsCurrentServerFavorite = bFavorite
		self:UpdateNavBar()
	end

end

function PANEL:OnScreenSizeChanged()

	timer.Create( "MainMenu.Rebuild", 0.1, 1, function()
		if ( IsValid( self ) ) then self:Rebuild() end
	end )

end

function PANEL:Paint()

	DrawBackground()

end

vgui.Register( "MainMenuVGUI", PANEL, "EditablePanel" )
