
local colorSettings = Color( 238, 238, 238 )
local colorChild = Color( 221, 221, 221 )
local colorChildSubscribed = Color( 178, 214, 178 )
local colorChildButton = Color( 177, 177, 177 )
local colorChildButtonSubscribed = Color( 76, 175, 80 )
local colorPresetList = Color( 238, 238, 238 )
local colorPresetHovered = Color( 221, 221, 221 )
local colorPresetSelected = Color( 204, 204, 204 )
local colorSeparator = Color( 204, 204, 204 )

local addonTypes = { "gamemode", "map", "weapon", "tool", "npc", "entity", "effects", "vehicle", "model" }

local newItemActions = {
	{ "addons.action_nothing", "" },
	{ "addons.action_disable", "disable" },
	{ "addons.action_enable", "enable" }
}

local function GetSubscribedAddons()

	local addons = {}

	for _, item in ipairs( engine.GetAddons() ) do
		local wsid = tostring( item.wsid )
		if ( wsid != "0" ) then addons[ wsid ] = item end
	end

	return addons

end

local function SetMounted( ids, bMount )

	for _, id in ipairs( ids ) do
		steamworks.SetShouldMountAddon( id, bMount )
	end

	steamworks.ApplyAddons()

end

local function Unsubscribe( ids )

	for _, id in ipairs( ids ) do
		steamworks.Unsubscribe( id )
	end

	steamworks.ApplyAddons()

end

local function ShowMessage( menu, message, onConfirm, files )

	local dialog = vgui.Create( "MainMenuDialog", menu )
	dialog:SetContentWidth( 460 )

	dialog:AddText( "addons.warning", 20, 400, true )
	dialog:AddSpace( 20 )
	dialog:AddText( message, 20, 400, true )
	dialog:AddSpace( 20 )

	if ( message == "addons.uninstallall.warning" or message == "addons.uninstall_selected.warning" ) then
		dialog:AddText( "addons.cannotundo", 20, 400, true )
		dialog:AddSpace( 20 )
	end

	for _, wsid in ipairs( files or {} ) do
		local title = tostring( wsid )
		local tick, plus = MainMenu.Material( "html/img/tick.png" ), MainMenu.Material( "html/img/plus.png" )

		steamworks.FileInfo( wsid, function( info )
			if ( info and info.title ) then title = info.title end
		end )

		local row = dialog:Add( "DButton", MainMenu.Scale( 28 ) )
		row:SetText( "" )
		row.Paint = function( s, w, h )
			local bSubscribed = steamworks.IsSubscribed( wsid )
			local buttonW = MainMenu.Scale( 55 )
			local icon = bSubscribed and tick or plus

			draw.RoundedBox( MainMenu.Scale( 4 ), 0, 0, w, h, bSubscribed and colorChildSubscribed or colorChild )
			draw.RoundedBoxEx( MainMenu.Scale( 4 ), w - buttonW, 0, buttonW, h, bSubscribed and colorChildButtonSubscribed or colorChildButton, false, true, false, true )

			MainMenu.StartClip( s, 0, 0, w - buttonW, h )
			MainMenu.DrawText( title, MainMenu.Font( 16 ), MainMenu.Scale( 10 ), math.floor( ( h - MainMenu.LineHeight( 16 ) ) / 2 ), color_black )
			MainMenu.EndClip()

			if ( icon ) then
				local iconW, iconH = MainMenu.MaterialSize( icon )
				MainMenu.DrawImage( icon, w - buttonW + math.floor( ( buttonW - iconW ) / 2 ), math.floor( ( h - iconH ) / 2 ), iconW, iconH )
			end
		end
		row.DoClick = function( s )
			if ( s:LocalCursorPos() < s:GetWide() - MainMenu.Scale( 55 ) ) then
				steamworks.ViewFile( wsid )
			elseif ( !steamworks.IsSubscribed( wsid ) ) then
				steamworks.Subscribe( wsid )
			end
		end

		dialog:AddSpace( 2 )
	end

	if ( files ) then dialog:AddSpace( 3 ) end

	dialog:AddButton( "addons.confirm", files and "create" or "warning", function()
		dialog:Remove()
		if ( onConfirm ) then onConfirm() end
	end, true )

	if ( onConfirm ) then
		dialog:AddCancel()
	end

	dialog:Finish()

	return dialog

end

local function AddNewAction( dialog, preset )

	dialog:AddText( "addons.preset_new_action", 16, 700 )
	dialog:AddRadioGroup( newItemActions, preset.newAction, function( action ) preset.newAction = action end )
	dialog:AddSpace( 19 )

end

local function AddSeparator( dialog )

	local separator = dialog:Add( "Panel", MainMenu.Scale( 18 ) )
	separator.Paint = function( s, w, h )
		surface.SetDrawColor( colorSeparator )
		surface.DrawRect( 0, math.floor( h / 2 ), w, 1 )
	end

end

local function ShowLoading( menu )

	local dialog = vgui.Create( "MainMenuDialog", menu )
	dialog:AddText( "dupes.loading", 32, 700 )
	dialog:AddSpace( 5 )
	dialog:Finish()

	local function Close()
		if ( IsValid( dialog ) ) then dialog:Remove() end
	end

	hook.Add( "MainMenuAddonPresets", dialog, Close )
	hook.Add( "MainMenuImportPresetFailed", dialog, function()
		Close()
		ShowMessage( menu, "addons.import_preset_notcollection" )
	end )

end

local function ShowCreatePreset( menu )

	local preset = { name = "", bSaveEnabled = true, bSaveDisabled = true, newAction = "disable" }

	local dialog = vgui.Create( "MainMenuDialog", menu )
	dialog:AddText( "addons.create_preset", 16, 700 )
	dialog:AddSpace( 32 )

	local create

	dialog:AddTextEntry( "addons.preset_name_placeholder", "", function( value )
		preset.name = value
		create:SetStyle( value == "" and "disabled" or "create" )
	end )
	dialog:AddSpace( 32 )

	dialog:AddToggle( "MainMenuCheckBox", "addons.preset_save_enabled", true, function( bChecked ) preset.bSaveEnabled = bChecked end )
	dialog:AddToggle( "MainMenuCheckBox", "addons.preset_save_disabled", true, function( bChecked ) preset.bSaveDisabled = bChecked end )
	dialog:AddSpace( 19 )

	AddNewAction( dialog, preset )

	create = dialog:AddButton( "addons.create_preset", "disabled", function()
		local data = { name = preset.name, newAction = preset.newAction, enabled = {}, disabled = {} }

		for wsid, item in pairs( GetSubscribedAddons() ) do
			if ( item.mounted and preset.bSaveEnabled ) then table.insert( data.enabled, wsid ) end
			if ( !item.mounted and preset.bSaveDisabled ) then table.insert( data.disabled, wsid ) end
		end

		CreateNewAddonPreset( util.TableToJSON( data ) )
		dialog:Remove()
	end, true )

	AddSeparator( dialog )
	dialog:AddCancel()

	dialog:Finish()

end

local function GetWorkshopID( source )

	local id = source:match( "steamcommunity%.com/sharedfiles/filedetails/%?.-id=(%d+)" )

	return id or source:match( "(%d+)" )

end

local function ShowImportPreset( menu )

	local preset = { source = "", name = "", newAction = "disable" }

	local dialog = vgui.Create( "MainMenuDialog", menu )
	dialog:AddText( "addons.import_preset", 16, 700 )
	dialog:AddSpace( 32 )

	local import

	local function UpdateButton()
		import:SetStyle( ( preset.source == "" or preset.name == "" ) and "disabled" or "create" )
	end

	dialog:AddTextEntry( "addons.preset_source", "", function( value ) preset.source = value UpdateButton() end )
	dialog:AddSpace( 48 )
	dialog:AddTextEntry( "addons.preset_name_placeholder", "", function( value ) preset.name = value UpdateButton() end )
	dialog:AddSpace( 32 )

	AddNewAction( dialog, preset )

	import = dialog:AddButton( "addons.import_preset", "disabled", function()
		dialog:Remove()

		local data = { name = preset.name, newAction = preset.newAction, enabled = {}, disabled = {} }
		local source = preset.source:Trim()

		if ( source:StartsWith( "http" ) or source:match( "^%d+$" ) ) then
			local id = GetWorkshopID( source )
			if ( !id ) then
				ShowMessage( menu, "addons.import_preset_notcollection" )
				return
			end

			ShowLoading( menu )
			ImportAddonPreset( id, util.TableToJSON( data ) )
			return
		end

		local imported = util.JSONToTable( source )
		if ( !imported ) then
			ShowMessage( menu, "addons.import_preset_notcollection" )
			return
		end

		data.enabled = imported.enabled or {}
		data.disabled = imported.disabled or {}

		CreateNewAddonPreset( util.TableToJSON( data ) )
	end )

	AddSeparator( dialog )
	dialog:AddCancel()

	dialog:Finish()

end

local function LoadPreset( preset, newAction, bResubscribe )

	local subscribed = GetSubscribedAddons()

	if ( bResubscribe ) then
		for _, list in ipairs( { preset.enabled or {}, preset.disabled or {} } ) do
			for _, wsid in ipairs( list ) do
				if ( !subscribed[ tostring( wsid ) ] ) then steamworks.Subscribe( wsid ) end
			end
		end
	end

	local done = {}

	for _, wsid in ipairs( preset.disabled or {} ) do
		steamworks.SetShouldMountAddon( wsid, false )
		done[ tostring( wsid ) ] = true
	end

	for _, wsid in ipairs( preset.enabled or {} ) do
		steamworks.SetShouldMountAddon( wsid, true )
		done[ tostring( wsid ) ] = true
	end

	if ( newAction != "" ) then
		for wsid in pairs( subscribed ) do
			if ( !done[ wsid ] ) then steamworks.SetShouldMountAddon( wsid, newAction == "enable" ) end
		end
	end

	steamworks.ApplyAddons()

end

local function ShowLoadPreset( menu )

	local presets = {}
	local search = ""
	local selected
	local options = { newAction = "", bResubscribe = false }

	local dialog = vgui.Create( "MainMenuDialog", menu )
	dialog:SetContentWidth( 500 )
	dialog:AddText( "addons.load_preset", 16, 700 )
	dialog:AddSpace( 32 )

	local content = dialog:Add( "Panel", MainMenu.Scale( 300 ) )
	dialog:AddSpace( 5 )
	dialog:AddCancel()
	dialog:Finish()

	local sideW = MainMenu.Scale( 150 )

	local filter = vgui.Create( "MainMenuTextEntry", content )
	filter:SetPos( 0, 0 )
	filter:SetSize( sideW - MainMenu.Scale( 8 ), MainMenu.LineHeight( 13 ) + MainMenu.Scale( 4 ) + 2 )
	filter:SetPlaceholder( "addons.filter_preset" )

	local list = vgui.Create( "DScrollPanel", content )
	list:SetPos( 0, filter:GetTall() + MainMenu.Scale( 8 ) )
	list:SetSize( sideW, content:GetTall() - list:GetY() )
	list.Paint = function( s, w, h )
		surface.SetDrawColor( colorPresetList )
		surface.DrawRect( 0, 0, w, h )
	end
	MainMenu.StyleScrollBar( list:GetVBar() )

	local details
	local RefreshList

	local function RefreshDetails()
		if ( IsValid( details ) ) then details:Remove() end

		local preset = presets[ selected ]
		if ( !preset ) then return end

		details = vgui.Create( "MainMenuStack", content )
		details:SetPos( sideW + MainMenu.Scale( 5 ), 0 )
		details:SetWide( content:GetWide() - details:GetX() )
		details:SetToggleHeight( nil )

		local font, boldFont = MainMenu.Font( 16 ), MainMenu.Font( 16, 700 )

		local function AddLine( label, value )
			label = language.GetPhrase( label )

			details:Add( "Panel", MainMenu.LineHeight( 16 ) ).Paint = function()
				MainMenu.DrawText( label, boldFont, 0, 0, color_black )
				MainMenu.DrawText( value, font, MainMenu.TextSize( label .. " ", boldFont ), 0, color_black )
			end
		end

		AddLine( "addons.preset_name", preset.name or selected )
		AddLine( "addons.preset_enabled", tostring( #( preset.enabled or {} ) ) )
		AddLine( "addons.preset_disabled", tostring( #( preset.disabled or {} ) ) )

		details:AddToggle( "MainMenuCheckBox", "addons.preset_resub_missing", options.bResubscribe, function( bChecked ) options.bResubscribe = bChecked end )
		details:AddSpace( 17 )
		details:AddText( "addons.preset_new_action", 16, 700 )
		details:AddRadioGroup( newItemActions, options.newAction, function( action ) options.newAction = action end )
		details:AddSpace( 17 )

		details:AddButton( "addons.load_preset", "create", function()
			LoadPreset( preset, options.newAction, options.bResubscribe )
			dialog:Remove()
		end )

		details:AddButton( "addons.copy_preset", "normal", function()
			SetClipboardText( util.TableToJSON( preset ) )
		end )

		details:AddSpace( 17 )

		details:AddButton( "addons.delete_preset", "warning", function()
			ShowMessage( menu, language.GetPhrase( "addons.delete_preset_warn" ) .. " " .. selected, function()
				DeleteAddonPreset( selected )
				selected = nil
				RefreshDetails()
			end )
		end )
	end

	RefreshList = function()
		list:Clear()

		local names = table.GetKeys( presets )
		table.sort( names )

		for _, name in ipairs( names ) do
			if ( !name:lower():find( search:lower(), 1, true ) ) then continue end

			local item = list:Add( "DButton" )
			item:SetText( "" )
			item:Dock( TOP )
			item:SetTall( MainMenu.LineHeight( 16 ) + MainMenu.Scale( 10 ) )
			item.Paint = function( s, w, h )
				if ( name == selected ) then
					surface.SetDrawColor( colorPresetSelected )
					surface.DrawRect( 0, 0, w, h )
				elseif ( s:IsHovered() ) then
					surface.SetDrawColor( colorPresetHovered )
					surface.DrawRect( 0, 0, w, h )
				end

				MainMenu.DrawText( presets[ name ].name or name, MainMenu.Font( 16 ), MainMenu.Scale( 5 ), MainMenu.Scale( 5 ), color_black )
			end
			item.DoClick = function()
				selected = name
				options.newAction = presets[ name ].newAction or ""
				RefreshDetails()
			end
		end
	end

	filter.OnValueChange = function( s, value )
		search = value
		RefreshList()
	end

	hook.Add( "MainMenuAddonPresets", dialog, function( s, list )
		presets = list
		if ( selected and !presets[ selected ] ) then selected = nil end

		RefreshList()
		RefreshDetails()
	end )

	ListAddonPresets()

end

local function BuildSettings( page, content )

	local browser = page.Browser
	local menu = page.Menu

	if ( IsValid( page.Settings ) ) then page.Settings:Remove() end
	if ( browser.Category != "subscribed" ) then return end

	local selected = table.GetKeys( browser.Selected )
	local bAnySelected = #selected > 0
	local subscribed = GetSubscribedAddons()

	local settings = vgui.Create( "Panel", content )
	settings:SetVisible( browser.bSettingsOpen == true )
	settings.Paint = function( s, w, h )
		surface.SetDrawColor( colorSettings )
		surface.DrawRect( 0, 0, w, h )
	end
	page.Settings = settings

	local padding = MainMenu.Scale( 10 )
	local columnGap = math.floor( content:GetWide() * 0.01 )
	local x = padding
	local height = 0

	local function AddColumn( build )
		local column = vgui.Create( "Panel", settings )
		column:SetPos( x + columnGap, padding )

		local y, w = 0, MainMenu.Scale( 140 )

		local function Add( pnl )
			pnl:SetPos( 0, y )
			y = y + pnl:GetTall()
			w = math.max( w, pnl:GetWide() )
		end

		local function AddLabel( text, value )
			text = language.GetPhrase( text ) .. ( value and " " .. value or "" )

			local label = vgui.Create( "Panel", column )
			local font = MainMenu.Font( 13, 700 )
			label:SetSize( MainMenu.TextSize( text, font ), MainMenu.LineHeight( 13 ) )
			label.Paint = function() MainMenu.DrawText( text, font, 0, 0, color_black ) end
			Add( label )
		end

		local function AddToggle( class, text, bChecked, onChange )
			local row = vgui.Create( "MainMenuToggleLabel", column )
			row:Setup( class, text, 13, color_black )
			row:SetChecked( bChecked )
			row.OnChange = function( s, bValue ) onChange( bValue ) end

			row.bAutoWidth = true
			Add( row )
		end

		local function AddLink( text, onClick )
			local link = vgui.Create( "MainMenuFlatButton", column )
			link:Setup( text, "normal", 13, 700 )
			link:SetSize( math.max( MainMenu.Scale( 140 ), link:GetContentSize() + MainMenu.Scale( 30 ) ), MainMenu.LineHeight( 13 ) + MainMenu.Scale( 8 ) )
			link.OnClick = onClick

			y = y + MainMenu.Scale( 2 )
			Add( link )
		end

		build( AddLabel, AddToggle, AddLink )

		for _, child in ipairs( column:GetChildren() ) do
			if ( !child.bAutoWidth ) then child:SetWide( w ) end
		end

		column:SetSize( w, y )
		x = x + w + columnGap * 2
		height = math.max( height, y )
	end

	local function Switch()
		browser:Switch( browser.Category, 0, browser.Tag )
	end

	AddColumn( function( AddLabel, AddToggle )
		AddLabel( "addons.filter_by" )
		AddToggle( "MainMenuCheckBox", "addons.enabled_only", browser.Filter == "enabledonly", function( bChecked )
			browser.Filter = bChecked and "enabledonly" or ""
			Switch()
		end )
		AddToggle( "MainMenuCheckBox", "addons.disabled_only", browser.Filter == "disabledonly", function( bChecked )
			browser.Filter = bChecked and "disabledonly" or ""
			Switch()
		end )
	end )

	AddColumn( function( AddLabel, AddToggle )
		AddLabel( "addons.sort_by" )

		for _, sort in ipairs( { { "addons.name", "title" }, { "addons.size", "size" }, { "addons.update_date", "updated" }, { "addons.sub_date", "subscribed" } } ) do
			AddToggle( "MainMenuRadioButton", sort[ 1 ], browser.Sort == sort[ 2 ], function()
				browser.Sort = sort[ 2 ]
				Switch()
			end )
		end
	end )

	AddColumn( function( AddLabel, AddToggle, AddLink )
		local function SelectIDs( ids )
			for _, id in ipairs( ids ) do
				if ( ( tonumber( id ) or 0 ) >= 1 ) then browser.Selected[ id ] = true end
			end

			page:BuildIcons()
		end

		local function SelectPage()
			local ids = {}
			for _, entry in ipairs( browser.Files ) do table.insert( ids, entry.id ) end

			SelectIDs( ids )
		end

		local function ClearSelection()
			browser.Selected = {}
			page:BuildIcons()
		end

		if ( !bAnySelected ) then
			AddLink( "addons.selectall", function() SelectIDs( browser.FilesOther ) end )
			AddLink( "addons.selectpage", SelectPage )
			AddLink( "addons.enableall", function()
				ShowMessage( menu, "addons.enableall.warning", function() SetMounted( table.GetKeys( subscribed ), true ) end )
			end )
			AddLink( "addons.disableall", function()
				ShowMessage( menu, "addons.disableall.warning", function() SetMounted( table.GetKeys( subscribed ), false ) end )
			end )
			AddLink( "addons.uninstallall", function()
				ShowMessage( menu, "addons.uninstallall.warning", function() Unsubscribe( table.GetKeys( subscribed ) ) end )
			end )
		else
			AddLink( "addons.unselectall", ClearSelection )
			AddLink( "addons.selectpage", SelectPage )
			AddLink( "addons.enable_selected", function()
				SetMounted( selected, true )
				ClearSelection()
			end )
			AddLink( "addons.disable_selected", function()
				SetMounted( selected, false )
				ClearSelection()
			end )
			AddLink( "addons.uninstall_selected", function()
				ShowMessage( menu, "addons.uninstall_selected.warning", function()
					Unsubscribe( selected )
					ClearSelection()
				end )
			end )
		end
	end )

	AddColumn( function( AddLabel, AddToggle, AddLink )
		AddLink( "addons.create_preset", function() ShowCreatePreset( menu ) end )
		AddLink( "addons.load_preset", function() ShowLoadPreset( menu ) end )
		AddLink( "addons.import_preset", function() ShowImportPreset( menu ) end )
	end )

	AddColumn( function( AddLabel )
		AddLabel( "addons.total_subscriptions", table.Count( subscribed ) )
		AddLabel( "addons.total_selected", #selected )
	end )

	local settingsH = height + padding * 2

	settings:SetSize( content:GetWide(), settingsH )
	settings:SetPos( 0, content:GetTall() - MainMenu.Scale( 52 ) - settingsH )
	settings:MoveToFront()

end

local function BuildSettingsButton( page, content )

	local browser = page.Browser
	local button = vgui.Create( "MainMenuBlueButton", content )
	button:SetSize( MainMenu.Scale( 44 ), MainMenu.Scale( 44 ) )
	button:SetPos( content:GetWide() - MainMenu.Scale( 48 ), content:GetTall() - MainMenu.Scale( 48 ) )
	button:SetIcon( "html/img/settings.png" )
	button.DoClick = function()
		browser.bSettingsOpen = !browser.bSettingsOpen
		if ( IsValid( page.Settings ) ) then page.Settings:SetVisible( browser.bSettingsOpen ) end
	end

	page.SettingsButton = button

end

local function Subscribe( page, entry )

	local children = entry.info.children or {}
	local missing = false

	for _, wsid in ipairs( children ) do
		if ( !steamworks.IsSubscribed( wsid ) ) then missing = true break end
	end

	if ( !missing ) then
		steamworks.Subscribe( entry.id )
		return
	end

	ShowMessage( page.Menu, "addons.addon_depends", function() steamworks.Subscribe( entry.id ) end, children )

end

local function AddControls( page, icon, entry, subscription )

	local browser = page.Browser

	MainMenu.AddRatingControls( browser, icon, entry )

	if ( subscription ) then
		if ( subscription.mounted ) then
			icon:AddControl( "right", "addon.disable", nil, function() SetMounted( { entry.id }, false ) end )
		else
			icon:AddControl( "right", "addon.enable", nil, function() SetMounted( { entry.id }, true ) end )
		end

		icon:AddControl( "right", "addon.unsubscribe", nil, function() steamworks.Unsubscribe( entry.id ) end )
	else
		icon:AddControl( "right", "addon.subscribe", nil, function() Subscribe( page, entry ) end )
	end

	if ( browser.Category == "downloaded_ugc" ) then
		icon:AddControl( "right", "addon.mark_unused", nil, function()
			steamworks.MarkDownloadedItemAsUnused( entry.id )
			browser:Refresh()
		end )
	end

end

local function SetupIcon( page, icon, entry )

	local browser = page.Browser
	local info = entry.info
	local subscription = page.Subscriptions[ tostring( entry.id ) ]

	local style = "normal"
	if ( subscription ) then
		if ( subscription.invalid_reason and subscription.invalid_reason != "" ) then
			style = subscription.mounted and "invalid" or "invalidDisabled"
		else
			style = subscription.mounted and "installed" or "disabled"
		end
	end

	local description = subscription and subscription.invalid_reason
	if ( !description or description == "" ) then description = info.description end

	icon:Setup( entry, style, description )

	if ( info.floating ) then return end

	if ( browser.Category == "subscribed" ) then
		local function SetSelected( bSelected )
			browser.Selected[ entry.id ] = bSelected or nil
			icon.Select:SetChecked( bSelected )
			BuildSettings( page, page.Content )
		end

		icon:SetSelectable( browser.Selected[ entry.id ] == true, SetSelected )
		icon.OnClicked = function() SetSelected( !browser.Selected[ entry.id ] ) end
	end

	icon.BuildControls = function() AddControls( page, icon, entry, subscription ) end

end

MainMenu.AddPage( "addons", function( pnl, menu )

	local browser = MainMenu.GetWorkshopBrowser( "addons", "subscribed" )
	browser.Selected = browser.Selected or {}

	MainMenu.BuildWorkshopPage( pnl, menu, {
		Name = "addons",
		TagPrefix = "addons",
		Library = function() return addon end,
		DefaultCategory = "subscribed",
		DisabledCategory = "subscribed",
		DisabledMessage = "addons.disabled",
		Groups = {
			{ Categories = { "subscribed" }, Tags = addonTypes, Submenu = true, Search = true },
			{ Categories = { "trending", "popular", "latest" }, Tags = addonTypes, DefaultTag = "Addon" },
			{ Categories = { "followed", "favorite", "friends", "mine", "downloaded_ugc" }, Tags = addonTypes, NoTags = { downloaded_ugc = true }, DefaultTag = "Addon" }
		},
		BottomLink = { "addons.openworkshop", function() steamworks.OpenWorkshop() end },
		GetTitlePhrase = function( workshop )
			if ( workshop.Tag == "" or workshop.Tag == "Addon" ) then return "addons." .. workshop.Category end
			return "addons." .. workshop.Tag
		end,
		SetupIcon = SetupIcon,
		OnBuildContent = BuildSettingsButton,
		OnBuildIcons = function( page )
			page.SettingsButton:SetVisible( browser.Category == "subscribed" )
			BuildSettings( page, page.Content )
		end
	} )

end )
