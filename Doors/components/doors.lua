local doors = {}

local function find_target(model)
	local part = model:FindFirstChild("Door")

	if part and part:IsA("BasePart") then
		return part
	end

	if model.PrimaryPart then
		return model.PrimaryPart
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function hide_barriers(model)
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart")
			and (
				child.Name == "Hidden"
				or child.Name == "ColBox"
			)
			and child.Transparency ~= 1
		then
			child.Transparency = 1
		end
	end
end

function doors.init(ctx)
	local tracker = ctx.make_room_tracker({
		enabled_key = "door_esp",
		color_key = "door_color",
		fill_transparency = 0.78,
		shallow_scan = true,

		match = function(model)
			return model.Name == "Door"
				and model:IsA("Model")
		end,

		accept = function(model, room)
			return model.Parent == room
				and tonumber(room.Name) ~= nil
		end,

		find_target = find_target,
		prepare = hide_barriers,

		get_text = function(model, room_num, context)
			local number = (room_num or 0) + 1
			local floor = context.get_floor()

			if floor == "Mines" then
				number += 100
			elseif floor == "Backdoor" then
				number -= 50
			end

			local locked = model:FindFirstChild("Lock") ~= nil
				or model:FindFirstChild("KeyObtain") ~= nil

			return "Door "
				.. tostring(number)
				.. (locked and " [locked]" or "")
		end,
	})

	for name, method in pairs(tracker) do
		doors[name] = method
	end
end

return doors
