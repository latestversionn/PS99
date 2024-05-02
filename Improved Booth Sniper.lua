-- Wait till game load
repeat
    task.wait(.05)
until game:IsLoaded()

repeat
    task.wait(.05)
until game.PlaceId ~= nil

repeat
    task.wait(.05)
until game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character.HumanoidRootPart

repeat
    task.wait(.05)
until game:GetService("Workspace").__THINGS and game:GetService("Workspace").__DEBRIS

repeat
    task.wait(.05)
until game:GetService("ReplicatedStorage").Library

repeat
	task.wait(.05)
until not game.Players.LocalPlayer.PlayerGui:FindFirstChild("__INTRO")

-- Variables
local webhookBuilder = loadstring(game:HttpGet("https://raw.githubusercontent.com/lilyscripts/webhook-builder/main/webhookBuilder.lua"))()
local save = require(game.ReplicatedStorage.Library.Client.Save)
local Players = game:GetService("Players")
local Lib = game:GetService("ReplicatedStorage"):WaitForChild("Library")
local CCom = require(Lib.Client.CurrencyCmds)
local CDir = require(Lib.Directory.Currency)

-- Teleport to plaza if not there
if game.PlaceId == 8737899170 or game.PlaceId == 16498369169 then
	game:GetService("TeleportService"):Teleport(15502339080, nil, game.Players.LocalPlayer)
end

-- Functions
local function Message(Text)
	require(game:GetService("ReplicatedStorage").Library.Client.NotificationCmds.Message).Bottom({Message = Text, Color = Color3.new(0.298039, 0.333333, 1)})
end

function CurrencyData()
    local allCDetails = {}
    for cID, cInfo in pairs(CDir) do
        local maxAmount = cInfo.MaxAmount
        if not maxAmount and cInfo.Tiers and #cInfo.Tiers > 0 then
            maxAmount = cInfo.Tiers[#cInfo.Tiers].value  -- Use the highest tier value as the max amount if MaxAmount isn't found
        end
        allCDetails[cID] = {
            ID = cID,
            CurrAmt = CCom.Get(cID) or 0,
            MaxAmt = maxAmount or "Undefined"
        }
    end
    return allCDetails
end


local function UseTerminal()
	for i, v in getgenv().Config.ItemsToBuy do
		local args = {
			[1] = v.Class,
			[2] = "{\"id\":\"" .. v.ItemID .. "\"}",
			[4] = false
		}

		local TerminalRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("TradingTerminal_Search"):InvokeServer(unpack(args))

		if TerminalRemote then
			local success, result = pcall(function()
				return game:GetService("TeleportService"):TeleportToPlaceInstance(TerminalRemote["place_id"], TerminalRemote["job_id"], game.Players.LocalPlayer)
			end)

			if not success then
				Message("Teleport failed. Reason: " .. result)
			end
		else
			print("Remote not found. Wrong path?")
		end
	end

	task.wait(1)
	UseTerminal() -- Recursive call
end

Message("")

local function Main()
	-- Loop through all the players
	for _, player in Players:GetPlayers() do
		local PlayerListings = getsenv(game.Players.LocalPlayer.PlayerScripts.Scripts.Game["Trading Plaza"]["Booths Frontend"]).getByOwnerId(player.UserId)
		if PlayerListings then
			for ListingID, ListingInfo in PlayerListings.Listings do
				local ItemData = ListingInfo.Item._data

				for _, ItemInConfig in getgenv().Config.ItemsToBuy do
					if ItemInConfig.ItemID == ItemData.id and ListingInfo.DiamondCost <= ItemInConfig.PriceToBuyAt then
						local CurrencyDetails = CurrencyData()
						local PlayerDiamonds = CurrencyDetails.Diamonds.CurrAmt
						local Amount = ItemData._am

						if Amount ~= nil then
							if ListingInfo.DiamondCost * Amount > PlayerDiamonds then
								Amount = math.floor(PlayerDiamonds / ListingInfo.DiamondCost)
							end

							if Amount then
								local args = {
									[1] = player.UserId,
									[2] = {}
								}

								if ItemData._am == 1 then
									args[2][tostring(ListingID)] = 1
								else
									args[2][tostring(ListingID)] = Amount
								end

								local BuyItem = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_RequestPurchase"):InvokeServer(unpack(args))

								if BuyItem then
									local TotalAmount

									for _, ItemData in save.Get()["Inventory"][ItemInConfig.Class] do
										if ItemData.id == ItemInConfig.ItemID then
											TotalAmount = ItemData._am
										end
									end

									local webhook = webhookBuilder(getgenv().Config.Webhook)
									webhook:setContent("<@" .. getgenv().Config.YourDiscordId .. ">")
									webhook:setUsername("PS99 Booth Sniper")

									local embed = webhook:createEmbed()
									embed:setTitle(game.Players.LocalPlayer.Name .. " Sniped something")
									embed:setDescription("🔆 **Item: ** `" .. ItemData.id .. "`\n 🤑 **Total Cost: ** `" .. ListingInfo.DiamondCost * Amount .. "`\n 😍 **Cost Each: ** `" .. ListingInfo.DiamondCost .. "`\n 🥶 **Amount: ** `" .. Amount .. "`\n 🤩 **Now Has: ** `" .. TotalAmount + Amount .. " " .. ItemInConfig.ItemID .. "'s" .. "` \n 💎 **Gems Left: ** `" .. PlayerDiamonds .. "`")
									embed:setColor(Color3.fromRGB(255, 0, 0)) -- Example color, replace with your desired color

									local image
									for _, value in ipairs(game:GetService("ReplicatedStorage").__DIRECTORY:GetDescendants()) do
										if string.find(value.Name, ItemData.id) then
											if value:IsDescendantOf(game:GetService("ReplicatedStorage").__DIRECTORY.Pets) then
												local requirething = require(value).Thumbnail
												image = requirething
											else
												local requirething = require(value).Icon
												image = requirething
											end
										end
									end

									embed:setThumbnail("https://biggamesapi.io/image/" .. image)
									embed:setFooter("Shitware Sniper | https://discord.gg/A6HYsxSKyS", "https://i.etsystatic.com/21877275/r/il/6a5640/4970900455/il_fullxfull.4970900455_btfh.jpg")

									webhook:send()
								end
							end
						elseif string.find(ItemInConfig.ItemID, "Huge") or string.find(ItemInConfig.ItemID, "Egg") then
							local args = {
								[1] = player.UserId,
								[2] = ListingID
							}

							local BuyItem = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_RequestPurchase"):InvokeServer(unpack(args))

							if BuyItem then
								local TotalAmount

								for _, ItemData in pairs(save.Get()["Inventory"][ItemInConfig.Class]) do
									if ItemData.id == ItemInConfig.ItemID then
										TotalAmount = ItemData._am
									end
								end

								local webhook = webhookBuilder(getgenv().Config.Webhook)
								webhook:setContent("<@" .. getgenv().Config.YourDiscordId .. ">")
								webhook:setUsername("PS99 Booth Sniper")

								local embed = webhook:createEmbed()
								embed:setTitle(game.Players.LocalPlayer.Name .. " Sniped something")
								embed:setDescription("🔆 **Item: ** `" .. ItemData.id .. "`\n 🤑 **Total Cost: ** `" .. ListingInfo.DiamondCost .. "`\n 😍 **Cost Each: ** `" .. ListingInfo.DiamondCost .. "` \n 💎 **Diamonds Left: ** `" .. PlayerDiamonds .. "`")
								embed:setColor(Color3.fromRGB(255, 0, 0)) -- Example color, replace with your desired color

								local image
								for _, value in ipairs(game:GetService("ReplicatedStorage").__DIRECTORY:GetDescendants()) do
									if string.find(value.Name, ItemData.id) then
										if value:IsDescendantOf(game:GetService("ReplicatedStorage").__DIRECTORY.Pets) then
											local requirething = require(value).Thumbnail
											image = requirething
										else
											local requirething = require(value).Icon
											image = requirething
										end
									end
								end

								embed:setThumbnail("https://biggamesapi.io/image/" .. image)
								embed:setFooter("Shitware Sniper | https://discord.gg/A6HYsxSKyS", "https://i.etsystatic.com/21877275/r/il/6a5640/4970900455/il_fullxfull.4970900455_btfh.jpg")

								webhook:send()
							end
						end
					end
				end
			end
		end
		task.wait(0.05)
	end
	UseTerminal()
end 

Main()
