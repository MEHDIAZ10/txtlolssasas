--Belzebass
--9/22/19
--Ban system. Thank you to Kensizo for getting the google sheets API setup!
--Require this module as a function (E.g. local a = require(this) a() ), and provide the player object as an argument. Will return true if banned, false if not.

local val = 1000 -- max bans list
local update_time = 60 -- How long to wait between ban list updates.
local sheetid = "XXX" -- Sheet key for google sheet.
local key = "XXX" -- API key
local http = game:GetService("HttpService")
local url = "https://content-sheets.googleapis.com/v4/spreadsheets/"..sheetid.."/values/2%3A"..val.."?valueRenderOption=FORMATTED_VALUE&dateTimeRenderOption=SERIAL_NUMBER&majorDimension=ROWS&key="..key -- URL to get ban data from.

local ban_list = {} -- Cached list of banned users.

local function check_bans()
	--Go through and see if a user is banned.
	for _,v in pairs(game.Players:GetPlayers()) do
		if ban_list[tostring(v.UserId)] and ban_list[tostring(v.UserId)].banned then -- Change when done modifying bot w/Kensizo.
			pcall(function()
				v:Kick(ban_list[tostring(v.UserId)].reason) -- Add support for reason.
			end)
		end
	end
end

local function list_update()
	--Update list from Google.
	local result,data = pcall(function()
		local pl = http:GetAsync(url)
		if pl then
			return http:JSONDecode(pl)
		else
			error("No data retrieved from URL")
		end
	end)
	if result and data then
		--Successfully got/decoded data.
		ban_list = {}
		for _,v in pairs(data.values) do
			ban_list[tostring(v[1])] = {banned=(v[2] == "FALSE" and false) or (v[2] == "TRUE" and true),reason=v[3]} -- Instead of having to iterate through all the keys (Bad with large ban list), look it up by key w/userid. Will change to have support for 3rd argument (Reason for ban) as soon as done modifying w/Kensizo.
		end
		check_bans() -- Recheck to see if a user is banned or not.
	else
		--Error.
		if data then
			print("Error retrieving ban list, reason: "..tostring(data))
		else
			print("Error retrieving ban list, no reason for error") -- Catch silent failures.
		end
	end
end

list_update()
spawn(function()
	while true do
		wait(update_time)
		list_update()
	end
end)

local function check_ban(plr)
	if plr.UserId == nil then
		repeat
			wait()
		until plr.UserId ~= nil
	end
	local d = ban_list[tostring(plr.UserId)]
	if d and d.banned then
		return d.banned,d.reason -- Scale for future
	else
		return false,nil --Not on list of bans.
	end
end

return check_ban