local GLab = GLab

--- Inspector is a Singleton class (meaning there's only ever one instance of it) that handles all of the "inspection" and debug actions in the Dev Tools.

---@class DevTools.Inspector
local defaults = {
    ---@type UIC
    panel = nil,

	---@type GLab.GameObject.Base
	current_context = nil,

	is_open = false,
}

---@class DevTools.Inspector
local Inspector = GLab.NewClass("Inspector", defaults)

-- TODO currently-selected context
-- TODO different context types - settlement, faction, character (other classes?)
-- TODO populate UI based on current context
-- TODO different actions based on current context

--- TODO an "inspector" feature, you press it and it tells you information of the currently selected thing (selected character etc)
--- TODO show/hide details in inspection
--- TODO inspector only available in Campaign.

function Inspector:FirstFill(panel)
	self.panel = panel

	-- held info about the currently selected object
	local info_holder = core:get_or_create_component("info_holder", "ui/campaign ui/script_dummy", panel)
	info_holder:SetDockingPoint(2)
	info_holder:SetDockOffset(0, 5)
	info_holder:Resize(panel:Width(), panel:Height() * 0.6)

	-- buttons to do stuff with the currently selected object
	local actions_holder = core:get_or_create_component("actions_holder", "ui/campaign ui/script_dummy", panel)
	actions_holder:SetDockingPoint(8)
	actions_holder:SetDockOffset(0, -10)
	actions_holder:Resize(panel:Width(), panel:Height() * 0.3)
end

function Inspector:SetContext(context)
    -- TODO
	self.current_context = context

	self:Populate()
end

function Inspector:PopulateFaction()
	-- autofill info about the player's faction
		-- name
		-- clickable faction leader
		-- clickable capital
		-- treasury
		-- number of armies / soldiers / characters
		-- number of settlements
	-- available actions
		-- add +1000 gold
		-- skip turn

	local panel = self.panel
	local info_holder = find_uicomponent(panel, "info_holder")
	local actions_holder = find_uicomponent(panel, "actions_holder")

	local Faction = self.current_context
	---@cast Faction GLab.GameObject.Faction

	local faction_details_box = core:get_or_create_component("details_box", "ui/groovy/layouts/vlist", info_holder)
	faction_details_box:SetDockingPoint(4)
	faction_details_box:SetDockOffset(10, 10)

	local faction_name = core:get_or_create_component("faction_name", "ui/groovy/text/section_header", faction_details_box)
	-- faction_name:SetDockingPoint(1)
	-- faction_name:SetDockOffset(5, 5)
	faction_name:SetText("Player Faction: " .. Faction:Name())
	local tw, th = faction_name:TextDimensions()
	faction_name:Resize(tw, th)

	--- TODO player name
	-- TODO clickable faction leader
	-- TODO clickable capital 

	--- TODO UI wrappers for clickable characters, and an OnClick function for those.
	local go_FactionLeader = Faction:FactionLeader()
	local cco_FactionLeader = cco("CcoCampaignCharacter", go_FactionLeader:CommandQueueIndex())

	local faction_leader_row = GLab.UI:NewCharacterButton("faction_leader", faction_details_box, cco_FactionLeader)
	faction_leader_row:OnClick(function()
		-- change context of Inspector to the character!
		Inspector:SetContext(go_FactionLeader)
	end)

	faction_leader_row:ShowRankIcon(false)

	--- TODO sidebar tabs for settlement / characters lists

	--- TODO implement action row to start
		-- add money to treasury
	local btn_add_money = GLab.UI:NewButton("button_monies", actions_holder, "ui/skins/default/icon_money.png", "Add 1000 gold to treasury", "square", "medium")
	btn_add_money:OnClick(function()
		Faction:ModifyTreasury(1000)
	end)

		-- skip turn
	local btn_skip_turn = GLab.UI:NewButton("button_skip_turn", actions_holder, "ui/skins/default/icon_money.png", "Skip this faction's turn!", "square", "medium")
	btn_skip_turn:OnClick(function()
		cm:end_turn_for_faction(Faction:__get())
	end)
end

function Inspector:PopulateCharacter()
	local panel = self.panel
	local info_holder = find_uicomponent(panel, "info_holder")
	local actions_holder = find_uicomponent(panel, "actions_holder")

	local Faction = self.current_context
	---@cast Faction GLab.GameObject.Character

	local faction_details_box = core:get_or_create_component("details_box", "ui/groovy/layouts/vlist", info_holder)
	faction_details_box:SetDockingPoint(4)
	faction_details_box:SetDockOffset(10, 10)

	local faction_name = core:get_or_create_component("faction_name", "ui/groovy/text/section_header", faction_details_box)
	-- faction_name:SetDockingPoint(1)
	-- faction_name:SetDockOffset(5, 5)
	faction_name:SetText("Character: " .. Faction:Name())
	local tw, th = faction_name:TextDimensions()
	faction_name:Resize(tw, th)
end

function Inspector:PopulateSettlement()

end

function Inspector:Clear()
	local panel = self.panel
	local info_holder = find_uicomponent(panel, "info_holder")
	local actions_holder = find_uicomponent(panel, "actions_holder")

	info_holder:DestroyChildren()
	actions_holder:DestroyChildren()
end

function Inspector:Populate()
	if not self.panel then return end
	if not self.panel:Visible() then return end

	if is_nil(self.current_context) then
		self:SetContext(GLab.World:GetLocalFaction())
		return
	end

	local context = self.current_context
	c_print("New Context: " .. tostring(context))

	self:Clear()

	if context.className == "GameObject.Faction" then
		self:PopulateFaction()
	elseif context.className == "GameObject.Character" then
		self:PopulateCharacter()
	elseif context.className == "GameObject.Settlement" then
		self:PopulateSettlement()
	end
end

function Inspector:Close()
	self.current_context = nil
	
end

---@param uic UIC
function Inspector:OnClick(uic)
	-- TODO
end

return Inspector