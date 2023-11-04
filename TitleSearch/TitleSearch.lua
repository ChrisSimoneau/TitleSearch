local _G = _G
local name, addon = ...
local CR = LibStub("AceConfigRegistry-3.0")
local CD = LibStub("AceConfigDialog-3.0")
local GUI = LibStub("AceGUI-3.0")
local TS = LibStub("AceAddon-3.0"):NewAddon(name, "AceEvent-3.0")

TS.DefaultConfig = {
    WindowIsLocked = true
}

TS.AceConfig = {
    type = "group",
    args = {
        lockWindow = {
            name = "Lock Frame",
            desc = "Lock frame position and size",
            type = "toggle",
            width = "full",
            order = 1,
            set = function(_, val)
                TS.Settings.WindowIsLocked = val

                if TS.Settings.WindowIsLocked then
                    _G.TitleSearchFrame.frame:SetMovable(false)
                    _G.TitleSearchFrame.frame:SetResizable(false)
                else
                    _G.TitleSearchFrame.frame:SetMovable(true)
                    _G.TitleSearchFrame.frame:SetResizable(true)
                end
            end,
            get = function(_)
                return TS.Settings.WindowIsLocked
            end
        }
    }
}

-- print available commands to the chat window
DEFAULT_CHAT_FRAME:AddMessage("|cff22f264" .."Type \"/titles\" to open the Title Search window")
DEFAULT_CHAT_FRAME:AddMessage("|cff22f264" .."Type \"/titles random\" to equip a random title")
DEFAULT_CHAT_FRAME:AddMessage("|cff22f264" .."Type \"/remove\" to remove your current title")

--Available slash commands
_G.SLASH_TITLES1 = "/titles" -- opens titlesearch window to search for titles
_G.SlashCmdList["RANDOM"] = function(args) -- helper function to equip a random title, random selection is done in titles

  --  local t = {}
    --for i = 1, GetNumTitles() do
      --  if IsTitleKnown(i) then
           -- tinsert(t, i)
        --end
    --end
   -- SetCurrentTitle((t[random(#t)]))
end

_G.SlashCmdList["TITLES"] = function(search) -- searches and equip a random title
    if (string.lower(search) == "random") then
        local t = {}
        for i = 1, GetNumTitles() do
            if IsTitleKnown(i) then
                tinsert(t, i)
            end
        end

        local randomInt =  random(#t)
        local titleString, isPlayerTitle = GetTitleName(t[randomInt])
        SetCurrentTitle(t[randomInt])
        DEFAULT_CHAT_FRAME:AddMessage("|cffe7fa3c" .."Random title set to: " .. titleString)
    else
        local titlesFound = TS:FilterTitles(search)

        if (tcount(titlesFound) > 0) then
            TS:UpdateGUI(titlesFound)
            if not _G.TitleSearchFrame:IsVisible() then
                _G.TitleSearchFrame:Show()
            else
                _G.TitleSearchFrame:Hide()
            end
        else
            print('No titles found with \'' .. search .. '\'') -- if no titles are found with the search, print this to the user
        end
    end
end

--remove current title being used
SLASH_REMOVE1 = "/remove"
SlashCmdList["REMOVE"] = function(msg)
local titleId = GetCurrentTitle();
local titleName, _ = GetTitleName(titleId)
    SetCurrentTitle(0)
    DEFAULT_CHAT_FRAME:AddMessage("|cfff51124" .."Title removed: " .. titleName)
end 


function TS:FilterTitles(search)
    -- Pull all player titles into a table
    
    local titleTable = {} -- All known titles go here
    local titlesToReturn = {} -- Filtered list

    -- Check all known titles and add to titleTable
    for i = 1, GetNumTitles() do
        local titleIsKnown = IsTitleKnown(i)
        if (titleIsKnown == true) then -- player has title, insert into table
           local titleString, isPlayerTitle = GetTitleName(i)     
            titleTable[i] = titleString
        end
    end

    -- Filter the table and put into titlesToReturn
    for k, v in pairs(titleTable) do
        if (search == nil or search == "") then
            -- no search, return all values
            titlesToReturn[k] = v
        end

        -- we have a search term
        if (string.find(string.lower(v), string.lower(search))) then -- if title name contains search string, return it
            titlesToReturn[k] = v
        end
    end
    return titlesToReturn -- return a bool if there are titles in this table

end


function tcount(table) -- counts the number of titles in a table
    local n = #table
    if (n == 0) then
        for _ in pairs(table) do
            n = n + 1
        end
    end

    return n
end

function TS:UpdateGUI(titles)
    -- Remove child labels to frame container
    local frame = _G.TitleSearchFrame
    local container = _G.TitleSearchFrame_MainContainer

    -- clear current labels
    container:ReleaseChildren()
    -- loop through and add labels for each power + group member with power
    if (tcount(titles) > 0) then
        -- add labels for all titles
        for k, v in pairs(titles) do
            local titleLabel = GUI:Create("InteractiveLabel")
            titleLabel:SetFullWidth(true)
            titleLabel:SetFont(_G.GameFontNormalHuge2:GetFont())
            titleLabel:SetCallback("OnClick", function()
                SetCurrentTitle(k)
                print("|cffe7fa3c" ..'Title set to ' .. v)
            end)

            titleLabel:SetText(v)

            container:AddChild(titleLabel)

            -- add spacer after every title (makes it look a bit nicer)
            local spacer = GUI:Create("Label")
            spacer:SetFullWidth(true)
            spacer:SetHeight(5)
            spacer:SetText(" ")
            container:AddChild(spacer)
        end
    else
        -- add a 'no title' label?
    end

    container:DoLayout()
end

function TS:OnInitialize()
    if not _G.TitleSearchSettings then
        _G.TitleSearchSettings = TS.DefaultConfig
    end

    if _G.TitleSearchSettings ~= nil then
        if not _G.TitleSearchSettings.WindowIsLocked then
            _G.TitleSearchSettings.WindowIsLocked = TS.DefaultConfig.WindowIsLocked
        end
    end

    TS.Settings = _G.TitleSearchSettings

    CR:RegisterOptionsTable(name, TS.AceConfig, nil)
    TS.OptionsMenu = CD:AddToBlizOptions(name, name)
end

function TS:OnEnable()
    _G.TitleSearchFrame = GUI:Create("Frame")
    local frame = _G.TitleSearchFrame
    frame:SetWidth(400)
    frame:SetHeight(300)
    frame:SetPoint("LEFT", 50, 0, _G.UIParent)
    frame:SetTitle(name)
    frame:SetLayout("List")
    frame:SetCallback("OnShow", function()
        TS:OnShow(TS)
    end)
    frame:SetCallback("OnDragStart", function(widget)
        if _G.TitleSearchSettings.WindowIsLocked then
            return
        end

        widget.frame:ClearAllPoints()

        widget.frame:StartMoving()
    end)
    frame:SetCallback("OnDragStop", function(widget)
        widget.frame:StopMovingOrSizing()
    end)

    _G.TitleSearch_Editbox = GUI:Create("EditBox")
    local editbox = _G.TitleSearch_Editbox
    editbox:SetFullWidth(true)
    editbox:SetCallback("OnTextChanged", function(widget, event, text)
        TS:UpdateGUI({})
        -- prints how many titles there are found within the search term
        local titlesFound = TS:FilterTitles(text)
        if (tcount(titlesFound) > 0) then
            TS:UpdateGUI(titlesFound)
            frame:SetStatusText('Found ' .. tostring(tcount(titlesFound)) .. ' titles with \'' .. text .. '\'')
        else
            frame:SetStatusText('No titles found with \'' .. text .. '\'')
        end
    end)
    frame:AddChild(editbox)

    _G.TitleSearchFrame_MainContainer = GUI:Create("ScrollFrame")
    local container = _G.TitleSearchFrame_MainContainer
    container:SetLayout("List")
    container:SetFullWidth(true)

    frame:AddChild(container)

    _G.tinsert(_G.UISpecialFrames, "TitleSearchFrame")
end

function TS:OnShow()
    if not _G.TitleSearchFrame_MainContainer:IsShown() then
        _G.TitleSearchFrame_MainContainer:Show()
    end
end


    