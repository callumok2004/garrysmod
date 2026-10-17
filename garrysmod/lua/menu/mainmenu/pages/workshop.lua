
local colorMessage = Color( 153, 153, 153 )

local function GetSubscriptions()

	local subscriptions = {}

	for _, item in ipairs( engine.GetAddons() ) do subscriptions[ tostring( item.wsid ) ] = item end
	for _, item in ipairs( engine.GetUserContent() ) do subscriptions[ tostring( item.wsid ) ] = item end

	return subscriptions

end

function MainMenu.AddRatingControls( browser, icon, entry )

	icon:AddControl( "left", nil, "html/img/thumb-up.png", function() browser:Rate( entry, true ) end, entry.info.voted_up )
	icon:AddControl( "left", nil, "html/img/thumb-down.png", function() browser:Rate( entry, false ) end, entry.info.voted_down )

	if ( entry.info.favorite ) then
		icon:AddControl( "left", nil, "html/img/favourite_addon_remove.png", function() browser:Favorite( entry, false ) end )
	else
		icon:AddControl( "left", nil, "html/img/favourite_addon.png", function() browser:Favorite( entry, true ) end )
	end

end

function MainMenu.BuildWorkshopPage( pnl, menu, config )

	local browser = MainMenu.GetWorkshopBrowser( config.Name, config.DefaultCategory, config.DefaultTag )
	browser:Attach( config.Library() )

	local page = { Panel = pnl, Menu = menu, Browser = browser, Config = config }

	local bNarrow = MainMenu.ViewportWidth() <= 1280
	local optionsW = MainMenu.Scale( MainMenu.ViewportWidth() <= 1024 and 200 or 320 )
	local linkSize = bNarrow and 16 or 23

	local options

	function page:IsSubscribed( entry )

		return self.Subscriptions[ tostring( entry.id ) ] != nil

	end

	function page:BuildOptions()

		if ( IsValid( options ) ) then options:Remove() end

		options = pnl:Add( "Panel" )
		options:SetWide( optionsW )
		options:Dock( LEFT )

		local x = MainMenu.Scale( bNarrow and 21 or 86 )
		local y = MainMenu.Scale( 75 )
		local rowH = MainMenu.LineHeight( linkSize ) + MainMenu.Scale( 1 )

		local function AddLink( phrase, onClick, bActive, indent, bSubmenu )
			local link = options:Add( "MainMenuLink" )
			link:Setup( phrase, bSubmenu and 17 or linkSize, bSubmenu )
			link:SetPos( x + MainMenu.Scale( indent or 0 ), y )
			link:SetActive( bActive )
			link.OnClick = onClick
		end

		local title = options:Add( "MainMenuShadowLabel" )
		title:SetPos( x, y )
		title:SetWide( MainMenu.Scale( 300 ) )
		title:SetFontSize( linkSize * 1.5 )
		title:SetText( config.Name )
		y = y + MainMenu.LineHeight( linkSize * 1.5 ) + MainMenu.Scale( 5 )

		for _, group in ipairs( config.Groups ) do
			for _, category in ipairs( group.Categories ) do
				local bActive = browser.Category == category

				AddLink( config.Name .. "." .. category, function() browser:Switch( category, 0, group.DefaultTag ) end, bActive )
				y = y + rowH

				local bShowTags = bActive and group.Tags and !( group.NoTags and group.NoTags[ category ] )
				if ( bShowTags ) then
					local tagH = group.Submenu and MainMenu.LineHeight( 17 ) - MainMenu.Scale( 4 ) or rowH

					y = y + MainMenu.Scale( group.Submenu and 0 or 4 )

					for _, tag in ipairs( group.Tags ) do
						AddLink( config.TagPrefix .. "." .. tag, function() browser:Switch( category, 0, tag ) end, browser.Tag == tag, group.Submenu and 20 or 36, group.Submenu )
						y = y + tagH
					end

					if ( group.Search ) then
						local search = options:Add( "MainMenuTextEntry" )
						search:SetPos( x + MainMenu.Scale( 20 ), y + MainMenu.Scale( 12 ) )
						search:SetSize( MainMenu.Scale( 150 ), MainMenu.Scale( 21 ) )
						search:SetPlaceholder( "addons.search" )
						search:SetValue( browser.Search )
						search.OnValueChange = function( s, value )
							browser.Search = value
							timer.Create( "MainMenu.WorkshopSearch", 0.5, 1, function() browser:Switch( browser.Category, 0, browser.Tag ) end )
						end

						y = y + MainMenu.Scale( 12 + 21 + 8 )
					end

					y = y + MainMenu.Scale( group.Submenu and 0 or 15 )
				end
			end

			y = y + rowH
		end

		AddLink( config.BottomLink[ 1 ], config.BottomLink[ 2 ], false )

	end

	function page:BuildContent()

		if ( IsValid( self.Content ) ) then self.Content:Remove() end

		local content = pnl:Add( "Panel" )
		content:Dock( FILL )
		content:DockMargin( 0, MainMenu.Scale( 16 ), MainMenu.Scale( 16 ), MainMenu.Scale( 16 ) )
		self.Content = content

		local titlePhrase = config.GetTitlePhrase and config.GetTitlePhrase( browser ) or ( config.Name .. "." .. browser.Category )

		local header = content:Add( "MainMenuHeader" )
		header:Dock( TOP )
		header:DockMargin( MainMenu.Scale( 16 ), MainMenu.Scale( 16 ), MainMenu.Scale( 16 ), 0 )
		header:Setup( titlePhrase, titlePhrase .. ".subtitle" )

		local container = content:Add( "Panel" )
		container:Dock( FILL )
		container:DockMargin( 0, MainMenu.Scale( 64 - 16 ) - header:GetTall(), 0, 0 )
		pnl:InvalidateLayout( true )
		content:InvalidateLayout( true )
		container.Paint = function( s, cw, ch )
			draw.RoundedBox( MainMenu.Scale( 3 ), 0, 0, cw, ch, color_white )

			local message = s.Message
			if ( !message ) then return end

			local font = MainMenu.Font( 48, 800 )
			local margin = MainMenu.Scale( ScrH() / MainMenu.ScaleFactor <= 800 and 16 or 64 )

			for i, line in ipairs( MainMenu.WrapText( language.GetPhrase( message ), font, cw - margin * 2 ) ) do
				local lineW = MainMenu.TextSize( line, font )
				MainMenu.DrawText( line, font, math.floor( ( cw - lineW ) / 2 ), MainMenu.Scale( 8 ) + margin + ( i - 1 ) * MainMenu.LineHeight( 48 ), colorMessage )
			end
		end
		self.Container = container

		local innerW = container:GetWide() - MainMenu.Scale( 16 )
		local innerH = container:GetTall() - MainMenu.Scale( 16 )
		local columns = math.Clamp( math.floor( math.max( MainMenu.Scale( 180 ), innerW ) / MainMenu.Scale( 180 ) ), 1, 6 )
		local rows = math.Clamp( math.floor( math.max( MainMenu.Scale( 180 ), innerH - MainMenu.Scale( 48 ) ) / MainMenu.Scale( 180 ) ), 1, 4 )

		self.Columns, self.Rows = columns, rows
		self.CellW = math.floor( innerW / columns )
		self.CellH = math.floor( ( innerH - MainMenu.Scale( 48 ) ) / rows )

		if ( browser.PerPage != columns * rows ) then
			browser.PerPage = columns * rows
			browser.Offset = math.floor( browser.Offset / browser.PerPage ) * browser.PerPage
		end

		self.Pagination = vgui.Create( "MainMenuPagination", container )
		self.Pagination:SetPos( math.floor( ( container:GetWide() - self.Pagination:GetWide() ) / 2 ), MainMenu.Scale( 8 ) + rows * self.CellH )
		self.Pagination.OnGo = function( s, delta ) browser:Go( delta * browser.PerPage ) end
		self.Pagination.OnGoToPage = function( s, number ) browser:Go( ( number - 1 ) * browser.PerPage - browser.Offset ) end

		if ( config.OnBuildContent ) then config.OnBuildContent( self, content ) end

		self:BuildIcons()

	end

	function page:BuildIcons()

		local container = self.Container

		for _, icon in ipairs( self.Icons or {} ) do icon:Remove() end
		self.Icons = {}

		self.Subscriptions = GetSubscriptions()
		self.bDisabled = select( 2, GetAddonStatus() )
		self.ShownFiles = browser.Files
		self.bShownLoading = browser.Loading

		local bEmpty = browser.TotalResults == 0 or browser.NumResults == 0

		if ( browser.Loading ) then
			container.Message = config.Name .. ".loading"
		elseif ( bEmpty and self.bDisabled and browser.Category == config.DisabledCategory ) then
			container.Message = config.DisabledMessage
		elseif ( bEmpty ) then
			container.Message = config.Name .. ".none"
		else
			container.Message = nil
		end

		self.Pagination:SetVisible( !browser.Loading and browser.TotalResults > 0 )
		self.Pagination:SetPage( browser:GetPage(), browser:GetPageCount() )

		if ( config.OnBuildIcons ) then config.OnBuildIcons( self ) end

		if ( browser.Loading ) then return end

		local margin = MainMenu.Scale( 10 )

		for i, entry in ipairs( browser.Files ) do
			local column = ( i - 1 ) % self.Columns
			local row = math.floor( ( i - 1 ) / self.Columns )

			local icon = vgui.Create( "MainMenuWorkshopIcon", container )
			icon:SetPos( MainMenu.Scale( 8 ) + column * self.CellW + margin, MainMenu.Scale( 8 ) + row * self.CellH + margin )
			icon:SetSize( self.CellW - margin * 2, self.CellH - margin * 2 )
			icon.OnOpen = function()
				if ( entry.id ) then steamworks.ViewFile( entry.id ) end
			end

			config.SetupIcon( self, icon, entry )

			table.insert( self.Icons, icon )
		end

	end

	pnl.Think = function()
		if ( browser.Files == page.ShownFiles and browser.Loading == page.bShownLoading ) then return end

		local optionsKey = browser.Category .. "|" .. browser.Tag
		if ( optionsKey != page.OptionsKey ) then
			page.OptionsKey = optionsKey
			page:BuildOptions()
		end

		page:BuildIcons()
	end

	pnl.OnRemove = function()
		browser:Detach()
	end

	hook.Add( "WorkshopSubscriptionsChanged", pnl, function() browser:Refresh() end )

	page.OptionsKey = browser.Category .. "|" .. browser.Tag
	page:BuildOptions()
	page:BuildContent()

	browser:Refresh()

	return page

end

local function AddCommonControls( page, icon, entry )

	local browser = page.Browser

	if ( entry.bLocal ) then
		icon:AddControl( "left", page.Config.Name .. ".publish", nil, function() browser:PublishLocal( entry ) end )
		icon:AddControl( "left", page.Config.Name .. ".delete", nil, function() browser:DeleteLocal( entry ) end )
		return
	end

	MainMenu.AddRatingControls( browser, icon, entry )

	if ( page:IsSubscribed( entry ) ) then
		icon:AddControl( "right", "ugc.unsubscribe", nil, function() steamworks.Unsubscribe( entry.id ) end )
	elseif ( !page.bDisabled ) then
		icon:AddControl( "right", "ugc.subscribe", nil, function() steamworks.Subscribe( entry.id ) end )
	end

end

local function SetupCommonIcon( page, icon, entry, addControls )

	icon:Setup( entry, !entry.bLocal and page:IsSubscribed( entry ) and "installed" or "normal" )
	icon.BuildControls = function()
		AddCommonControls( page, icon, entry )
		if ( addControls ) then addControls() end
	end

end

local function CreateConfig( name, library, tags, setupIcon )

	return {
		Name = name,
		TagPrefix = name,
		Library = library,
		DefaultCategory = "local",
		DisabledCategory = "subscribed_ugc",
		DisabledMessage = "ugc.disabled",
		Groups = {
			{ Categories = { "local", "subscribed_ugc" }, Tags = tags, NoTags = { [ "local" ] = true } },
			{ Categories = { "trending", "popular", "latest" }, Tags = tags },
			{ Categories = { "followed", "favorite", "friends", "mine" }, Tags = tags }
		},
		BottomLink = { name .. ".openfolder", function() OpenFolder( name ) end },
		SetupIcon = setupIcon
	}

end

local function DownloadAndRun( entry, run, download )

	if ( entry.bLocal ) then
		run( entry.info.file )
	else
		download( entry.id )
	end

end

MainMenu.AddPage( "saves", function( pnl, menu )

	MainMenu.BuildWorkshopPage( pnl, menu, CreateConfig( "saves", function() return ws_save end, { "scenes", "machines", "buildings", "courses", "others" }, function( page, icon, entry )
		SetupCommonIcon( page, icon, entry, function()
			icon:AddControl( "right", "saves.load", nil, function()
				DownloadAndRun( entry, function( filename ) ws_save:Load( filename ) end, function( id ) ws_save:DownloadAndLoad( id ) end )
			end )
		end )
	end ) )

end )

MainMenu.AddPage( "dupes", function( pnl, menu )

	MainMenu.BuildWorkshopPage( pnl, menu, CreateConfig( "dupes", function() return ws_dupe end, { "posed", "scenes", "machines", "vehicles", "buildings", "others" }, SetupCommonIcon ) )

end )

MainMenu.AddPage( "demos", function( pnl, menu )

	MainMenu.BuildWorkshopPage( pnl, menu, CreateConfig( "demos", function() return demo end, nil, function( page, icon, entry )
		SetupCommonIcon( page, icon, entry, function()
			icon:AddControl( "right", "demos.video", nil, function()
				DownloadAndRun( entry, function( filename ) demo:ToVideo( filename ) end, function( id ) demo:DownloadAndToVideo( id ) end )
			end )

			icon:AddControl( "right", "demos.play", nil, function()
				DownloadAndRun( entry, function( filename ) demo:Play( filename ) end, function( id ) demo:DownloadAndPlay( id ) end )
			end )
		end )
	end ) )

end )
