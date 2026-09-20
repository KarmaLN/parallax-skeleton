-- =========================
-- SECTION COLORS
-- =========================
local sectionMeta = {
    actions = { name = "Actions", color = Color(120,170,255), order = 1 },
    emotes  = { name = "Emotes",  color = Color(255,170,120), order = 2 },
    medical = { name = "Medical", color = Color(255,100,100), order = 4 },
    player = { name = "Player", color = Color(50,50,50), order = 5 },
}

-- =========================
-- MENU DATA
-- =========================
ax.radialMenus = {}

ax.radialMenus.main = {
    actions = {
        { name = "Sleep", func = function()
            RunConsoleCommand("say", "/charfallover")
        end},
    },
    emotes = {
        submenu = "emotes"
    },
    medical = {
        submenu = "medical"
    },
    player = {
        submenu = "player"
    }
}
ax.radialMenus.emotes = {
    items = {
        { name = "Wave", func = function()
            RunConsoleCommand("act", "wave")
            RunConsoleCommand("say", "/me waves")
        end },
        { name = "Salute", func = function()
            RunConsoleCommand("act", "salute")
            RunConsoleCommand("say", "/me salutes")
        end },
        { name = "Cheer", func = function()
            RunConsoleCommand("act", "cheer")
            RunConsoleCommand("say", "/me cheers")
        end },
        { name = "Agree", func = function()
            RunConsoleCommand("act", "agree")
            RunConsoleCommand("say", "/me agrees")
        end },
        { name = "Disagree", func = function()
            RunConsoleCommand("act", "disagree")
            RunConsoleCommand("say", "/me disagrees")
        end },
    },
}

ax.radialMenus.medical = {
    items = {
        { 
            name = "Revive", 
            func = function()
                RunItemAction("medical_defib", "revive")
            end,
            canRun = function()
                local ply = LocalPlayer()
                local char = ply:GetCharacter()
                if not char then return false end

                local inv = char:GetInventory()
                local tr = ply:GetEyeTraceNoCursor()
                local target = ax.util:GetPlayerFromAttachedRagdoll(tr.Entity)

                return target and inv:HasItem("medical_defib")
            end 
        },
        {
            name = "Heal",
            func = function()
                RunItemAction("medical_fak", "heal")
            end,
            canRun = function()
                local ply = LocalPlayer()
                local char = ply:GetCharacter()
                if not char then return false end

                local inv = char:GetInventory()
                return inv:HasItem("medical_fak") and ply:Health() < ply:GetMaxHealth()
            end
        },
        {
            name = "Heal Target",
            func = function()
                RunItemAction("medical_fak", "heal_target")
            end,
            canRun = function()
                local ply = LocalPlayer()
                local char = ply:GetCharacter()
                if not char then return false end

                local inv = char:GetInventory()
                local tr = ply:GetEyeTraceNoCursor()
                return ax.util:IsValidPlayer(tr.Entity) and inv:HasItem("medical_fak")
            end
        }
    }
}

ax.radialMenus.player = {
    items = {
        { 
            name = "Tie", 
            func = function()
                RunItemAction("zip_tie", "tie")
            end,
            canRun = function()
                local ply = LocalPlayer()
                local char = ply:GetCharacter()
                if not char then return false end

                local inv = char:GetInventory()
                local tr = ply:GetEyeTraceNoCursor()

                return (ax.util:IsValidPlayer(tr.Entity) and !tr.Entity:IsRestrained()) and inv:HasItem("zip_tie")
            end 
        },
        { 
        	name = "Cut Restrains", 
            func = function()
                RunItemAction("zip_tie", "cut_restraints")
            end,
            canRun = function()
                local ply = LocalPlayer()
                local char = ply:GetCharacter()
                if not char then return false end

                local inv = char:GetInventory()
                local tr = ply:GetEyeTraceNoCursor()

                return (ax.util:IsValidPlayer(tr.Entity) and tr.Entity:IsRestrained()) and inv:HasItem("zip_tie")
            end 
        },
        {
            name = "Search",
            func = function()
                RunItemAction("zip_tie", "search")
                LocalPlayer():ConCommand( "say /charsearch" )
            end,
            canRun = function()
                local ply = LocalPlayer()
                local char = ply:GetCharacter()
                if not char then return false end

                local inv = char:GetInventory()
                local tr = ply:GetEyeTraceNoCursor()
                return (ax.util:IsValidPlayer(tr.Entity) and tr.Entity:IsRestrained()) and inv:HasItem("zip_tie")
            end
        },
    }
}

-- =========================
-- ITEM HELPERS (MUST BE FIRST)
-- =========================
function GetItemFromInventory(class)
    local ply = LocalPlayer()
    local char = ply:GetCharacter()
    if not char then return end

    local inv = char:GetInventory()
    if not inv then return end

    for _, item in pairs(inv:GetItems() or {}) do
        if item.class == class then
            return item
        end
    end
end

function RunItemAction(class, action)
    local item = GetItemFromInventory(class)
    if (not item) then 
        print("[Radial] Item not found:", class)
        return 
    end
	ax.net:Start("ax.RunItemAction", {
    	itemID = item:GetID(),
        action = action
    })
end

-- =========================
-- BUILDER
-- =========================
local function BuildRadial(menuName, parentSection)
    if (IsValid(ax.gui.radialMenu)) then
        ax.gui.radialMenu:Remove()
    end

    local panel = vgui.Create("ax.radial.menu")
    panel:InitializeRadialMenu({ guiKey = "radialMenu" })

    local sections, sectionMap = {}, {}
    local menu = ax.radialMenus[menuName]

    local function add(sectionId, item)
        local meta = sectionMeta[sectionId] or sectionMeta.actions
        local section = ax.radialmenu:CreateSectionBucket(sectionMap, sections, sectionId, meta)

        section.items[#section.items + 1] = {
            id = item.id,
            data = {
                name = item.data.name,
                callback = item.callback -- ✅ FIXED: store callback in data
            }
        }
    end

    -- MAIN MENU
    if (menu.actions or menu.emotes or menu.medical) then
        for sectionId, data in pairs(menu) do
            if (data.submenu) then
                add(sectionId, {
                    id = sectionId,
                    data = { name = sectionMeta[sectionId].name },
                    callback = function()
                        BuildRadial(data.submenu, sectionId)
                    end
                })
            else
                for _, v in ipairs(data) do
                    if (not v.canRun or v.canRun()) then
                        add(sectionId, {
                            id = v.name,
                            data = { name = v.name },
                            callback = v.func
                        })
                    end
                end
            end
        end
    end

    -- SUBMENU
    if (menu.items) then
        for _, v in ipairs(menu.items) do
            if (not v.canRun or v.canRun()) then
                add(parentSection or "actions", {
                    id = v.name,
                    data = { name = v.name },
                    callback = v.func
                })
            end
        end
    end

    panel:SetResolvedWheelData(ax.radialmenu:FinalizeWheelData(sections))
end

function ax.OpenRadialMenu()
    BuildRadial("main")
end

-- =========================
-- INPUT
-- =========================
function SCHEMA:PlayerButtonDown(_, key)
    if (key == KEY_N) then
        ax.OpenRadialMenu()
    end
end

-- =========================
-- PANEL HOOKS (FIXED)
-- =========================
local PANEL = vgui.GetControlTable("ax.radial.menu")

function PANEL:OnMousePressed(mouseCode)
    if (mouseCode == MOUSE_LEFT) then
        local item = self.hoveredItem or self.previewItem
		self:CommitItem(item, false)

    elseif (mouseCode == MOUSE_RIGHT) then
        self:Remove()
    end
end

function PANEL:CommitItem(item)
    if !item then return end
    local callback = item.callback or (item.data and item.data.callback)

    if not callback then
        print("[Radial] No callback!")
        return false
    end

    callback()
    self:Remove()
    return true
end