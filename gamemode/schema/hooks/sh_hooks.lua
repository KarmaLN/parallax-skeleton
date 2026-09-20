function SCHEMA:OnSchemaLoaded()
    local models = {
    }
    
    for k,v in pairs(models) do
        ax.animations:SetModelClass(Model(v), "player")
    end
end