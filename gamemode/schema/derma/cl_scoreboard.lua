local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    self.list = self:Add("DListView")
    self.list:Dock(FILL)
    
	self.list:SortByColumn(1)
    self.list:SetHeaderHeight(40)
    self.list:SetDataHeight(50)
    self.list:SetMultiSelect(false)
    
    -- === THEME COLORS ===
    local glass = ax.theme:GetGlass()

    -- Background
    self.list.Paint = function(_, w, h)
        surface.SetDrawColor(glass.panel)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(glass.panelBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    -- Columns
    local columns = {
        "Faction",
        "Name",
        "Class",
        "Rank",
        --"Unit"
    }

    for _, name in ipairs(columns) do
        local col = self.list:AddColumn("")

        col.Header.Paint = function(self, w, h)
            surface.SetDrawColor(glass.panel)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(glass.panelBorder)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            
            draw.DrawText( name, "ax.regular", 5, 0, Color(255,255,255, 255), TEXT_ALIGN_LEFT )
        end

        col.Header:SetTextColor(color_white)
    end

    -- Disable default sorting click
    for _, col in pairs(self.list.Columns) do
        col.DoClick = function() end
    end

    -- Row styling
    self.list.PaintOver = function(self, w, h)
    end

    -- Unique timer
    self.timerID = "ax.scoreboard.refresh." .. LocalPlayer():Nick()

    timer.Create(self.timerID, 1, 0, function()
        if IsValid(self) then
            self:RefreshPlayers()
        end
    end)

    self:RefreshPlayers()
end

function PANEL:OnRemove()
    if self.timerID then
        timer.Remove(self.timerID)
    end
end

-- Populate list
function PANEL:RefreshPlayers()
    self.list:Clear()

    local players = player.GetAll()

    table.sort(players, function(a, b)
        local ca, cb = a:GetCharacter(), b:GetCharacter()
        if not ca then return false end
        if not cb then return true end
        return ca:GetFaction() > cb:GetFaction()
    end)

    for _, ply in ipairs(players) do
        if not IsValid(ply) then continue end

        local char = ply:GetCharacter()
        if not char or char:GetFaction() == 0 then continue end

        local faction = ax.faction:Get(char:GetFaction())

        local factionName = faction and faction.name or "None"
        local factionColor = faction and faction.color or color_white

        local baseName = char:GetName()
        local name = ply:IsMuted() and (baseName .. " (Muted)") or baseName

        local line = self.list:AddLine(
            factionName,
            name,
            char:GetClassName(),
            char:GetRankName()
        )

        line.player = ply
        line.Paint = function(self, w, h)
            local glass = ax.theme:GetGlass()

            local isHovered = line:IsHovered()
            local isSelected = line:IsSelected()

            -- Base background
            surface.SetDrawColor(glass.button)
            surface.DrawRect(0, 0, w, h)

            -- Hover effect
            if isHovered then
                surface.SetDrawColor(glass.highlight)
                surface.DrawRect(0, 0, w, h)
            end

            -- Selected row
            if isSelected then
                surface.SetDrawColor(glass.highlight)
                surface.DrawRect(0, 0, w, h)
            end

            -- Bottom border (clean table look)
            surface.SetDrawColor(glass.panelBorder)
            surface.DrawLine(0, h - 1, w, h - 1)
        end

        for _, column in pairs(line.Columns) do
            column:SetFont("ax.regular")
        end
        
        line.Columns[1]:SetTextColor(factionColor)
        --line.Columns[5]:SetTextColor(char:GetUnitColor() or color_white)
    end

    -- Context menu
    self.list.OnRowSelected = function(_, _, line)
        local selected = line.player
        if not IsValid(selected) then return end

        local menu = vgui.Create("ax.dmenu")

        local pingText = selected:IsBot() and "Bot" or (selected:Ping() .. " ms")

        local group = ax.admin:GetUsergroup(selected:GetUsergroup() or "")
        local usergroupText = group and group.name or "user"

        local info = menu:Add("ax.text")
        info:SetText(selected:SteamName() .. " \nPing: " .. pingText .. "\nUsergroup: " .. usergroupText, true)
        info:SetFont("ax.small")
        info:Dock(TOP)
        info:DockMargin(30, 0, 0, 0)

        menu:AddOption("View Profile", function()
            selected:ShowProfile()
        end)

        menu:AddOption("Copy SteamID", function()
            SetClipboardText(selected:IsBot() and tostring(selected:EntIndex()) or selected:SteamID())
        end)

        menu:AddOption(selected:IsMuted() and "Unmute" or "Mute", function()
            selected:SetMuted(not selected:IsMuted())
        end)

        if LocalPlayer():IsAdmin() then
            menu:AddSpacer()

            menu:AddOption("Kick Player", function()
                LocalPlayer():ConCommand("ax plykick " .. selected:Nick())
            end)

            menu:AddOption("Goto Player", function()
                LocalPlayer():ConCommand("ax plygoto " .. selected:Nick())
            end)

            menu:AddOption("Bring Player", function()
                LocalPlayer():ConCommand("ax plybring " .. selected:Nick())
            end)
        end

        menu:Open()
    end
end

vgui.Register("ax.tab.scoreboard", PANEL, "EditablePanel")

hook.Remove("PopulateTabButtons", "ax.tab.scoreboard")

hook.Add("PopulateTabButtons", "ax.tab.scoreboard", function(buttons)
    buttons["scoreboard"] = {
        Populate = function(_, panel)
            panel:Add("ax.tab.scoreboard")
        end
    }
end)
