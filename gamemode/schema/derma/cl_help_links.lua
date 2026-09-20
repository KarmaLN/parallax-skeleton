local links = {
	{title = "Content Pack", link = "https://steamcommunity.com/sharedfiles/filedetails/?id=2128292251"},
    {title = "Content Pack (NPC)", link = "https://steamcommunity.com/sharedfiles/filedetails/?id=2795202830"},
    {title = "Discord", link = "https://discord.gg/v6YdtBfDMu"},
    {title = "Donation", link = "https://www.paypal.com/paypalme/luminnetwork"},
}

local function PopulateLink(this, panel)
    local client = ax.client
    local character = IsValid(client) and client:GetCharacter() or nil
    
    local mainPanel = panel:Add("ax.frame")
    mainPanel:Dock(FILL)
    mainPanel:SetTitle("Links")
    mainPanel:ShowCloseButton(false)
    mainPanel:SetDraggable(false)
    mainPanel:SetSizable(false)
    
	for k, v in pairs(links) do
   
		local link = mainPanel:Add("ax.button")
        link:Dock(TOP)
        link:DockMargin(0,0,0,15)
        link:SetText(v.title)
        link:SizeToContents()
        link.DoClick = function()
        	gui.OpenURL(v.link)
		end
	end
end

hook.Remove("PopulateHelpCategories", "ax.tab.help.links")

hook.Add("PopulateHelpCategories", "ax.tab.help.links", function(categories)
    categories["links"] = {
        sort = 50,
        name = "Links",
        Populate = PopulateLink
    }
end)