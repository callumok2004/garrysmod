
local PANEL = {}

local styles = {
	normal = { border = Color( 255, 255, 255 ), name = Color( 102, 102, 102 ), text = Color( 51, 51, 51 ) },
	installed = { border = Color( 210, 252, 123 ), name = Color( 102, 102, 102 ), text = Color( 51, 51, 51 ) },
	disabled = { border = Color( 206, 220, 177 ), name = Color( 102, 102, 102 ), text = Color( 51, 51, 51 ) },
	invalid = { border = Color( 221, 34, 34 ), name = color_white, text = color_white },
	invalidDisabled = { border = Color( 153, 34, 34 ), name = color_white, text = color_white }
}

local colorBackground = Color( 102, 102, 102 )
local colorOutline = Color( 0, 0, 0, 139 )
local colorOutlineBlur = Color( 0, 0, 0, 50 )
local colorDisabledOverlay = Color( 0, 0, 0, 200 )
local colorDescription = Color( 70, 180, 250, 242 )
local colorVotesUp = Color( 68, 170, 68 )
local colorVotesDown = Color( 170, 68, 68 )
local colorControl = Color( 245, 255, 128 )
local colorControlDisabled = Color( 191, 191, 191 )
local colorControlShadow = Color( 0, 0, 0, 160 )

local function PaintLabel( text, font, x, y, background, color, bRight, roundedCorner )

	local padX, padY = MainMenu.Scale( 6 ), MainMenu.Scale( 3 )
	local textW, textH = MainMenu.TextSize( text, font )
	local w, h = textW + padX * 2, textH + padY * 2

	if ( bRight ) then x = x - w end

	draw.RoundedBoxEx( MainMenu.Scale( 4 ), x, y, w, h, background, roundedCorner == 1, roundedCorner == 2, roundedCorner == 3, roundedCorner == 4 )
	MainMenu.DrawText( text, font, x + padX, y + padY, color )

	return h

end

function PANEL:Init()

	self:SetCursor( "arrow" )
	self:NoClipping( true )

	self.Style = styles.normal
	self.Controls = { left = {}, right = {} }

	self.bHovered = false
	self.HoverChangeTime = 0
	self.ControlsFraction = 0
	self.LabelsFraction = 0
	self.DescriptionFraction = 0

end

function PANEL:Setup( entry, style, description )

	self.Entry = entry
	self.Style = styles[ style ] or styles.normal
	self.Description = description
	self.bDisabled = style == "disabled" or style == "invalidDisabled"

end

function PANEL:AddControl( side, label, icon, onClick, bDisabled )

	local control = vgui.Create( "DButton", self )
	control:SetText( "" )
	control:SetCursor( bDisabled and "arrow" or "hand" )
	control.Label = label and language.GetPhrase( label )
	control.Icon = icon and MainMenu.Material( icon )
	control.bDisabled = bDisabled
	control.Paint = function( s, w, h )
		local background = colorControl
		if ( s.bDisabled ) then
			background = colorControlDisabled
		elseif ( s:IsHovered() ) then
			background = color_white
		end

		draw.RoundedBox( MainMenu.Scale( 2 ), MainMenu.Scale( 1 ), MainMenu.Scale( 1 ), w, h, colorControlShadow )
		draw.RoundedBox( MainMenu.Scale( 2 ), 0, 0, w - MainMenu.Scale( 1 ), h - MainMenu.Scale( 1 ), background )

		if ( s.Icon ) then
			local iconW, iconH = MainMenu.MaterialSize( s.Icon )
			MainMenu.DrawImage( s.Icon, MainMenu.Scale( 4 ), MainMenu.Scale( 5 ), iconW, iconH )
		else
			MainMenu.DrawText( s.Label, MainMenu.Font( 11 ), MainMenu.Scale( 4 ), MainMenu.Scale( 3 ), color_black )
		end
	end
	control.DoClick = function( s )
		if ( s.bDisabled ) then return end

		onClick()
		self:RebuildControls()
	end

	local width
	if ( control.Icon ) then
		width = MainMenu.MaterialSize( control.Icon )
	else
		width = MainMenu.TextSize( control.Label, MainMenu.Font( 11 ) )
	end

	control:SetSize( width + MainMenu.Scale( 9 ), MainMenu.Scale( 20 ) )

	table.insert( self.Controls[ side ], control )

end

function PANEL:RebuildControls()

	for _, side in pairs( self.Controls ) do
		for _, control in ipairs( side ) do control:Remove() end
	end

	self.Controls = { left = {}, right = {} }

	if ( self.BuildControls ) then self:BuildControls() end

	self:InvalidateLayout( true )

end

function PANEL:SetSelectable( bSelected, onToggle )

	self.Select = vgui.Create( "MainMenuCheckBox", self )
	self.Select:SetSize( MainMenu.Scale( 19 ), MainMenu.Scale( 19 ) )
	self.Select:SetChecked( bSelected )
	self.Select.OnChange = function( s, bChecked ) onToggle( bChecked ) end

end

function PANEL:OnOpen()
end

function PANEL:OnClicked()
end

function PANEL:IsOverName()

	local x, y = self:LocalCursorPos()

	return y < MainMenu.Scale( 25 ) and x < self:GetWide() - MainMenu.Scale( self.Select and 27 or 5 )

end

function PANEL:OnMousePressed( code )

	if ( code != MOUSE_LEFT ) then return end

	if ( self:IsOverName() ) then
		self:OnOpen()
	else
		self:OnClicked()
	end

end

function PANEL:PerformLayout( w, h )

	local border = MainMenu.Scale( 3 )
	local y = h - border - MainMenu.Scale( 9 ) - MainMenu.Scale( 20 ) + math.Round( ( 1 - self.ControlsFraction ) * MainMenu.Scale( 32 ) )
	local gap = MainMenu.Scale( 4 )

	local x = border + MainMenu.Scale( 8 )
	for _, control in ipairs( self.Controls.left ) do
		control:SetPos( x, y )
		x = x + control:GetWide() + gap
	end

	x = w - border - MainMenu.Scale( 8 )
	for i = #self.Controls.right, 1, -1 do
		local control = self.Controls.right[ i ]
		x = x - control:GetWide()
		control:SetPos( x, y )
		x = x - gap
	end

	if ( IsValid( self.Select ) ) then
		self.Select:SetPos( w - border - self.Select:GetWide(), border )
	end

end

local function Animate( from, target, duration, delay, elapsed )

	local progress = math.Clamp( ( elapsed - delay ) / duration, 0, 1 )

	return Lerp( progress, from, target )

end

function PANEL:Think()

	local bHovered = self:IsHovered() or self:IsChildHovered()

	if ( bHovered != self.bHovered ) then
		self.bHovered = bHovered
		self.HoverChangeTime = SysTime()
		self.AnimationStart = { self.ControlsFraction, self.LabelsFraction, self.DescriptionFraction }

		if ( bHovered ) then self:RebuildControls() end
	end

	if ( !self.AnimationStart ) then return end

	local elapsed = SysTime() - self.HoverChangeTime
	local target = bHovered and 1 or 0
	local controlsFraction = self.ControlsFraction

	self.ControlsFraction = Animate( self.AnimationStart[ 1 ], target, 0.1, bHovered and 0.2 or 0, elapsed )
	self.LabelsFraction = Animate( self.AnimationStart[ 2 ], target, 0.1, bHovered and 0 or 0.2, elapsed )
	self.DescriptionFraction = Animate( self.AnimationStart[ 3 ], target, bHovered and 0.05 or 0.1, 0, elapsed )

	if ( self.ControlsFraction != controlsFraction ) then self:InvalidateLayout() end

end

function PANEL:Paint( w, h )

	local entry = self.Entry
	local info = entry.info
	local style = self.Style
	local border = MainMenu.Scale( 3 )
	local innerW, innerH = w - border * 2, h - border * 2

	self:SetCursor( self:IsHovered() and self:IsOverName() and "hand" or "arrow" )

	local outline = MainMenu.Scale( 1 )

	draw.RoundedBox( border + outline * 2, -outline * 2, -outline * 2, w + outline * 4, h + outline * 4, colorOutlineBlur )
	draw.RoundedBox( border + outline, -outline, -outline, w + outline * 2, h + outline * 2, colorOutline )
	draw.RoundedBox( border, 0, 0, w, h, style.border )

	surface.SetDrawColor( colorBackground )
	surface.DrawRect( border, border, innerW, innerH )

	MainMenu.StartClip( self, border, border, innerW, innerH )

	local preview = MainMenu.GetWorkshopPreview( entry.background or "html/img/downloading.png" )
	if ( preview ) then
		local size = math.max( innerW, innerH ) + 1
		MainMenu.DrawImage( preview, border + math.floor( ( innerW - size ) / 2 ), border + math.floor( ( innerH - size ) / 2 ), size, size )
	end

	if ( self.bDisabled ) then
		surface.SetDrawColor( colorDisabledOverlay )
		surface.DrawRect( border, border, innerW, innerH )
	end

	local labelFont = MainMenu.Font( 11, 700 )

	if ( self.LabelsFraction < 1 ) then
		local slide = math.Round( self.LabelsFraction * MainMenu.Scale( 200 ) )
		local bottomY = h - border - MainMenu.LineHeight( 11 ) - MainMenu.Scale( 6 )

		if ( !entry.bLocal ) then
			local owner = info.ownername or language.GetPhrase( "ugc.loading" )
			local votes = ( info.up or 0 ) - ( info.down or 0 )

			PaintLabel( owner, labelFont, w - border + slide, bottomY, style.border, style.text, true, 1 )

			if ( votes != 0 ) then
				PaintLabel( ( votes > 0 and "+" or "" ) .. votes, labelFont, border - slide, bottomY, style.border, votes > 0 and colorVotesUp or colorVotesDown, false, 2 )
			end
		end

		if ( info.size ) then
			PaintLabel( MainMenu.FormatSize( info.size ), labelFont, w - border + slide, border + MainMenu.Scale( 22 ), style.border, style.text, true, 3 )
		end
	end

	if ( self.DescriptionFraction > 0 ) then
		local alpha = self.DescriptionFraction

		surface.SetDrawColor( colorDescription.r, colorDescription.g, colorDescription.b, colorDescription.a * alpha )
		surface.DrawRect( border, border, innerW, innerH )

		local font = MainMenu.Font( 11 )
		local lineH = MainMenu.LineHeight( 11 )
		local textColor = Color( 255, 255, 255, 255 * alpha )
		local y = border + MainMenu.Scale( 32 )

		local description = self.Description or info.description or ""
		if ( description != self.WrappedText ) then
			self.WrappedText = description
			self.WrappedLines = MainMenu.WrapText( description, font, innerW - MainMenu.Scale( 16 ) )
		end

		for _, line in ipairs( self.WrappedLines ) do
			if ( y + lineH > h - border - MainMenu.Scale( 32 ) ) then break end

			MainMenu.DrawText( line, font, border + MainMenu.Scale( 8 ), y, textColor )
			y = y + lineH
		end
	end

	surface.SetDrawColor( style.border )
	surface.DrawRect( border, border, innerW, MainMenu.Scale( 22 ) )

	local title = ( entry.extra and entry.extra.title ) or info.title or language.GetPhrase( "ugc.loading" )
	local nameRight = IsValid( self.Select ) and MainMenu.Scale( 24 ) or MainMenu.Scale( 2 )

	MainMenu.StartClip( self, border, border, innerW - nameRight, MainMenu.Scale( 22 ) )
	MainMenu.DrawText( title, MainMenu.Font( 14, 700 ), border + MainMenu.Scale( 2 ), border + MainMenu.Scale( 2 ), style.name )
	MainMenu.EndClip()

	MainMenu.EndClip()

end

vgui.Register( "MainMenuWorkshopIcon", PANEL, "Panel" )
