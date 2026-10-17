
local PANEL = {}

local colorBackground = Color( 255, 255, 255 )
local colorBackgroundHovered = Color( 230, 230, 230 )
local colorText = Color( 51, 51, 51 )

local badgeColors = {
	[ 0 ] = { Color( 217, 217, 217 ), colorText },
	[ 1 ] = { Color( 255, 200, 0 ), colorText },
	[ 2 ] = { Color( 255, 64, 0 ), color_white }
}

PANEL.Styles = {
	back = { iconX = 5, iconY = 4, labelX = 47, labelY = 14, paddingRight = 15, minWidth = 5, noLabelWidth = 40 },
	big = { iconX = 4, iconY = 4, labelX = 45, labelY = 13, paddingRight = 10, minWidth = 5, noLabelWidth = 35 },
	small = { iconX = 12, iconY = 12, labelX = 35, labelY = 13, paddingRight = 10, minWidth = 40, noLabelWidth = 40 }
}

AccessorFunc( PANEL, "m_bShowLabel", "ShowLabel", FORCE_BOOL )
AccessorFunc( PANEL, "m_bHideLabelWhenNarrow", "HideLabelWhenNarrow", FORCE_BOOL )

function PANEL:Init()

	self:SetText( "" )
	self:NoClipping( true )
	self:SetShowLabel( true )

	self.Style = self.Styles.small
	self.Label = ""

end

function PANEL:Setup( style, icon, label )

	self.Style = self.Styles[ style ]
	self.Icon = icon and MainMenu.Material( icon )
	self.IconY = self.Style.iconY
	self.Label = label and language.GetPhrase( label ) or ""

end

function PANEL:SetIconY( y )

	self.IconY = y

end

function PANEL:GetIdealWidth()

	local style = self.Style

	if ( !self:GetShowLabel() or self.Label == "" ) then return MainMenu.Scale( style.noLabelWidth ) end

	local textWidth = MainMenu.TextSize( self.Label, MainMenu.Font( 11, 700 ) )

	return math.max( MainMenu.Scale( style.minWidth ), MainMenu.Scale( style.labelX ) + textWidth + MainMenu.Scale( style.paddingRight ) )

end

function PANEL:SetSounds( hover, click )

	self.HoverSound = hover
	self.ClickSound = click

end

function PANEL:OnCursorEntered()

	if ( self.HoverSound ) then MainMenu.PlaySound( self.HoverSound ) end

end

function PANEL:DoClick()

	if ( self.ClickSound ) then MainMenu.PlaySound( self.ClickSound ) end

	self:OnClick()

end

function PANEL:OnClick()
end

function PANEL:SetBadge( count, severity )

	self.BadgeCount = count
	self.BadgeSeverity = severity

end

function PANEL:Paint( w, h )

	local style = self.Style
	local radius = MainMenu.Scale( 4 )

	draw.RoundedBox( radius, 0, 0, w, h, self:IsHovered() and colorBackgroundHovered or colorBackground )

	MainMenu.StartClip( self, 0, 0, w, h )

	if ( self.Icon ) then
		local iconW, iconH = MainMenu.MaterialSize( self.Icon )
		MainMenu.DrawImage( self.Icon, MainMenu.Scale( style.iconX ), MainMenu.Scale( self.IconY ), iconW, iconH )
	end

	if ( self:GetShowLabel() and self.Label != "" ) then
		MainMenu.DrawText( self.Label, MainMenu.Font( 11, 700 ), MainMenu.Scale( style.labelX ), MainMenu.Scale( style.labelY ), colorText )
	end

	MainMenu.EndClip()

end

function PANEL:PaintOver( w, h )

	if ( !self.BadgeCount or self.BadgeCount <= 0 ) then return end

	local colors = badgeColors[ self.BadgeSeverity ] or badgeColors[ 0 ]
	local text = tostring( self.BadgeCount )
	local font = MainMenu.Font( 11, 700 )
	local textW, textH = MainMenu.TextSize( text, font )
	local padding = MainMenu.Scale( 5 )
	local x, y = -MainMenu.Scale( 7 ), -MainMenu.Scale( 10 )

	draw.RoundedBox( MainMenu.Scale( 4 ), x, y, textW + padding * 2, textH + padding * 2, colors[ 1 ] )
	MainMenu.DrawText( text, font, x + padding, y + padding, colors[ 2 ] )

end

vgui.Register( "MainMenuNavButton", PANEL, "DButton" )
