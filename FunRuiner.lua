local function DebugMsg(msg) print(msg) end
FR_Enabled = true
local FR_DelayQueue = {}
local FR_UpdateFrame = CreateFrame("Frame")

FR_UpdateFrame:SetScript("OnUpdate", function(_, elapsed)
    if not FR_DelayQueue[1] then return end  -- no items
    local now = GetTime()
    local i = 1
    while FR_DelayQueue[i] do
        local item = FR_DelayQueue[i]
        if now >= item.time then
            SendChatMessage(item.msg, item.channel, nil, item.target)
            table.remove(FR_DelayQueue, i)
        else
            i = i + 1
        end
    end
end)

-- helper: get first non-empty answer
local function getAnswer(prefix, idx)
    for n = 1, 10 do
        local arr = _G[prefix .. "ANSWERS" .. n]
        if type(arr) == "table" then
            local a = arr[idx]
            if type(a) == "string" and a ~= "" then
                return a
            end
        end
    end
    return nil
end

local function normalize(s)
    if type(s) ~= "string" then return "" end
    s = string.lower(s)
    -- replace anything not a-z, 0-9, or space with space
    s = string.gsub(s, "[^%w%s]", " ")
    -- collapse multiple spaces
    s = string.gsub(s, "%s+", " ")
    -- trim edges
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

-- check message against a given bank
local function checkBank(bankName, prefix, msgLower, channel, sender)
	if not FR_Enabled then return false end
    local qArr = _G[bankName]
    if type(qArr) ~= "table" then return false end

    for i = 1, table.getn(qArr) do
        local q = qArr[i]
        if type(q) == "string" and string.find(normalize(q), normalize(msgLower), 1, true) then
            local ans = getAnswer(prefix, i)
			print("q" .. normalize(q) .. "ans" .. ans);
            if ans then
                if channel == "SAY" then
                    DelayedSendChatMessage(ans, "SAY")
                elseif channel == "WHISPER" then
                    print(ans);
                end
                return true
            end
        end
    end
    return false
end

function DelayedSendChatMessage(msg, channel, target)
    local delay = 1 + math.random() -- 0.5 to 1.5 sec
    table.insert(FR_DelayQueue, {
        msg = msg,
        channel = channel,
        target = target,
        time = GetTime() + delay,
    })
end

-- anti-spam
local lastAnswered = {}
local function recentlyAnswered(key)
    local now = GetTime and GetTime() or time()
    if lastAnswered[key] and (now - lastAnswered[key]) < 2.0 then return true end
    lastAnswered[key] = now
    return false
end

-- ===== slash command =====
SLASH_FUNRUINER1 = "/funruiner"
SlashCmdList["FUNRUINER"] = function()
    FR_Enabled = not FR_Enabled
    if FR_Enabled then
        print("FunRuiner is now ENABLED.")
    else
        print("FunRuiner is now DISABLED.")
    end
end

-- events
local playerName
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHAT_MSG_SAY")
f:RegisterEvent("CHAT_MSG_WHISPER")

f:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    if not FR_Announced then
      print("|cffff6666FunRuiner|r is engaged!")
      FR_Announced = true
    end
  end 
  
  if event == "CHAT_MSG_SAY" or event == "CHAT_MSG_WHISPER" then
    local msg, sender = arg1, arg2  -- use globals in 1.12
    if type(msg) ~= "string" or msg == "" then return end

    -- ignore our own /say (avoid echo); DO allow self-whispers for testing
    if event == "CHAT_MSG_SAY" and playerName and sender and string.find(sender, playerName, 1, true) then
      return
    end

    local msgLower = string.lower(msg)
    local channel = (event == "CHAT_MSG_SAY") and "SAY" or "WHISPER"

    -- Debug line to prove the branch fires:
    print("FunRuiner checking:", event, "msg:", msg)

    if checkBank("WOW_TRIVIA_QUESTIONS", "WOW_TRIVIA_", msgLower, channel, sender) then return end
    if checkBank("TURTLE_TRIVIA_QUESTIONS", "TURTLE_TRIVIA_", msgLower, channel, sender) then return end
	if checkBank("NORMAL_TRIVIA_QUESTIONS", "NORMAL_TRIVIA_", msgLower, channel, sender) then return end
	if checkBank("GEOGRAPHY_TRIVIA_QUESTIONS", "GEOGRAPHY_TRIVIA_", msgLower, channel, sender) then return end
  end
end)