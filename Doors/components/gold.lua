local gold = {}

local function find_target(model)
	if model:IsA("BasePart") then
		return model
	end

	if model:IsA("Model") and model.PrimaryPart then
		return model.PrimaryPart
	end

	local hitbox = model:FindFirstChild("Hitbox")

	if hitbox and hitbox:IsA("BasePart") then
		return hitbox
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

function gold.init(ctx)
	local tracker = ctx.make_room_tracker({
		enabled_key = "gold_esp",
		color_key = "gold_color",
		fill_transparency = 0.72,
		watch_prompt = true,

		attributes = {
			"GoldValue",
			"ParentRoom",
		},

		match = function(model)
			return model.Name == "GoldPile"
				or model.Name == "StardustPickup"
		end,

		find_target = find_target,

		ready = function(model)
			return model.Name ~= "GoldPile"
				or model:GetAttribute("GoldValue") ~= nil
		end,

		get_text = function(model)
			if model.Name == "StardustPickup" then
				return "Stardust Pile"
			end

			local value = model:GetAttribute("GoldValue")

			if value ~= nil then
				return "Gold [" .. tostring(value) .. "]"
			end

			return "Gold Pile"
		end,
	})

	for name, method in pairs(tracker) do
		gold[name] = method
	end
end

return gold
