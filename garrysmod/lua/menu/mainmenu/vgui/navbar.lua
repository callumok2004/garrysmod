
local PANEL = {}

function PANEL:Init()

	self:NoClipping( true )

	self.Groups = { left = {}, center = {}, right = {} }

end

function PANEL:AddButton( group, style, icon, label )

	local button = vgui.Create( "MainMenuNavButton", self )
	button:Setup( style, icon, label )

	table.insert( self.Groups[ group ], button )

	return button

end

local function MeasureButtons( buttons, bNarrow )

	local width = 0

	for _, button in ipairs( buttons ) do
		if ( button:IsVisible() ) then
			button:SetShowLabel( !( bNarrow and button:GetHideLabelWhenNarrow() ) )
			width = width + button:GetIdealWidth() + MainMenu.Scale( 3 )
		end
	end

	return width

end

local function LayoutButtons( buttons, x )

	for _, button in ipairs( buttons ) do
		if ( button:IsVisible() ) then
			local w = button:GetIdealWidth()
			button:SetPos( x, MainMenu.Scale( 5 ) )
			button:SetSize( w, MainMenu.Scale( 40 ) )

			x = x + w + MainMenu.Scale( 3 )
		end
	end

end

function PANEL:PerformLayout( w, h )

	local bNarrow = MainMenu.ViewportWidth() <= 940
	local margin = bNarrow and MainMenu.Scale( 15 ) or math.floor( w * 0.1 )

	MeasureButtons( self.Groups.left, bNarrow )

	local rightX = w - MeasureButtons( self.Groups.right, bNarrow )
	local centerX = rightX - margin - MeasureButtons( self.Groups.center, bNarrow )

	LayoutButtons( self.Groups.left, MainMenu.Scale( 5 ) )
	LayoutButtons( self.Groups.right, rightX )
	LayoutButtons( self.Groups.center, centerX )

end

function PANEL:Paint( w, h )

	surface.SetDrawColor( 0, 0, 0, 200 )
	surface.DrawRect( 0, 0, w, h )

end

vgui.Register( "MainMenuNavBar", PANEL, "Panel" )
