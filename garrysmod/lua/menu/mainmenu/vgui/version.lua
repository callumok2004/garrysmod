
local PANEL = {}

local colorText = Color( 170, 170, 170 )

function PANEL:Init()

	self:SetText( "" )

	self.bBranch = BRANCH != "unknown"

	if ( self.bBranch ) then
		self.Label = "You are on the " .. BRANCH .. " branch. Click here to find out more. ( " .. VERSIONSTR .. " )"
	else
		self.Label = VERSIONSTR
	end

	local textW, textH = MainMenu.TextSize( self.Label, MainMenu.Font( 11, 700 ) )
	self:SetSize( textW + MainMenu.Scale( 10 ), textH + MainMenu.Scale( 10 ) )

end

function PANEL:DoClick()

	if ( self.bBranch ) then
		gui.OpenURL( "https://commits.facepunch.com/r/garrysmod.main" )
	else
		gui.OpenURL( "http://gmod.facepunch.com/changes/" )
	end

end

function PANEL:Paint( w, h )

	draw.RoundedBox( MainMenu.Scale( 3 ), 0, 0, w, h, color_black )
	MainMenu.DrawText( self.Label, MainMenu.Font( 11, 700 ), MainMenu.Scale( 5 ), MainMenu.Scale( 5 ), colorText )

end

vgui.Register( "MainMenuVersion", PANEL, "DButton" )
