
local PANEL = {}

local colorOverlay = Color( 0, 0, 0, 200 )

for _, name in ipairs( { "Add", "AddSpace", "AddText", "AddButton", "AddToggle", "AddRadioGroup", "AddTextEntry" } ) do
	PANEL[ name ] = function( self, ... ) return self.Stack[ name ]( self.Stack, ... ) end
end

function PANEL:Init()

	self:SetMouseInputEnabled( true )
	self:SetKeyboardInputEnabled( true )

	self.Box = vgui.Create( "Panel", self )
	self.Box.Paint = function( s, w, h ) draw.RoundedBox( MainMenu.Scale( 5 ), 0, 0, w, h, color_white ) end

	self.Stack = vgui.Create( "MainMenuStack", self.Box )
	self.Stack:SetPos( MainMenu.Scale( 20 ), MainMenu.Scale( 20 ) )
	self:SetContentWidth( 350 )

end

function PANEL:SetContentWidth( width )

	self.Stack:SetWide( MainMenu.Scale( width ) )

end

function PANEL:AddCancel()

	return self:AddButton( "addons.cancel", "normal", function() self:Remove() end )

end

function PANEL:Finish()

	local padding = MainMenu.Scale( 20 )
	local boxW = self.Stack:GetWide() + padding * 2
	local boxH = self.Stack:GetTall() - MainMenu.Scale( 5 ) + padding * 2

	self:SetSize( self:GetParent():GetSize() )
	self.Box:SetSize( boxW, boxH )
	self.Box:SetPos( math.floor( ( self:GetWide() - boxW ) / 2 ), math.floor( ( self:GetTall() - boxH ) / 2 ) )

	self:MoveToFront()

end

function PANEL:Paint( w, h )

	surface.SetDrawColor( colorOverlay )
	surface.DrawRect( 0, 0, w, h )

end

vgui.Register( "MainMenuDialog", PANEL, "EditablePanel" )
