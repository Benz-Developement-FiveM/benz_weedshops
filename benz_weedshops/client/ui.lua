-- benz_weedshops custom NUI UI bridge
-- This replaces ox_lib context/input dialogs with this resource's own HTML/CSS/JS UI.

local uiContexts = {}
local promptState = nil
local originalRegisterContext = lib and lib.registerContext
local originalShowContext = lib and lib.showContext
local originalInputDialog = lib and lib.inputDialog

local function normalizeIcon(icon)
    if not icon or icon == '' then return 'fa-solid fa-circle' end
    if type(icon) ~= 'string' then return 'fa-solid fa-circle' end
    if icon:find('fa%-') then return icon end
    return 'fa-solid fa-' .. icon
end

local function serializeOptions(ctx)
    local options = {}
    for i, opt in ipairs(ctx.options or {}) do
        options[#options + 1] = {
            index = i,
            title = opt.title or ('Option ' .. i),
            description = opt.description or '',
            icon = normalizeIcon(opt.icon),
            disabled = opt.disabled == true,
            arrow = opt.arrow == true or opt.menu ~= nil or opt.event ~= nil or opt.serverEvent ~= nil,
            metadata = opt.metadata or nil
        }
    end
    return options
end

local function showContext(id)
    local ctx = uiContexts[id]
    if not ctx then
        if originalShowContext then return originalShowContext(id) end
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        id = id,
        title = ctx.title or 'Menu',
        subtitle = ctx.description or 'Select an option',
        parent = ctx.menu,
        options = serializeOptions(ctx)
    })
end

local function closeUI()
    -- Always release NUI focus and tell the browser to hide.
    -- This prevents the cursor/UI from staying on screen after ESC, cancel, resource restart, or callback errors.
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
end

local function inputDialog(title, fields)
    promptState = { done = false, result = nil }

    local uiFields = {}
    for i, field in ipairs(fields or {}) do
        uiFields[#uiFields + 1] = {
            index = i,
            type = field.type or 'input',
            label = field.label or ('Field ' .. i),
            description = field.description or '',
            placeholder = field.placeholder or '',
            default = field.default,
            required = field.required == true,
            min = field.min,
            max = field.max,
            options = field.options or nil
        }
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openPrompt',
        title = title or 'Input',
        fields = uiFields
    })

    while promptState and not promptState.done do Wait(0) end

    local result = promptState and promptState.result or nil
    promptState = nil
    SetNuiFocus(false, false)
    return result
end

RegisterNUICallback('wfClose', function(_, cb)
    if promptState then
        promptState.result = nil
        promptState.done = true
    end
    closeUI()
    cb({ ok = true })
end)

RegisterNUICallback('wfBack', function(data, cb)
    local parent = data and data.parent
    if parent and uiContexts[parent] then
        showContext(parent)
    else
        closeUI()
    end
    cb({ ok = true })
end)

RegisterNUICallback('wfSelect', function(data, cb)
    local ctx = data and uiContexts[data.id]
    local index = tonumber(data and data.index)
    local opt = ctx and ctx.options and ctx.options[index]
    cb({ ok = true })

    if not opt or opt.disabled then return end

    if opt.menu and uiContexts[opt.menu] then
        showContext(opt.menu)
        return
    end

    closeUI()

    if opt.onSelect then
        CreateThread(function()
            local ok, err = pcall(opt.onSelect, opt.args)
            if not ok then print('[benz_weedshops/ui] onSelect error: ' .. tostring(err)) end
        end)
    elseif opt.event then
        TriggerEvent(opt.event, opt.args)
    elseif opt.serverEvent then
        TriggerServerEvent(opt.serverEvent, opt.args)
    end
end)

RegisterNUICallback('wfPromptSubmit', function(data, cb)
    if promptState then
        local values = {}
        for _, item in ipairs(data.values or {}) do
            local v = item.value
            if item.type == 'number' then v = tonumber(v) end
            if item.type == 'checkbox' then v = (v == true or v == 'true' or v == 'on' or v == '1') end
            values[tonumber(item.index) or (#values + 1)] = v
        end
        promptState.result = values
        promptState.done = true
    end
    closeUI()
    cb({ ok = true })
end)

RegisterNUICallback('wfPromptCancel', function(_, cb)
    if promptState then
        promptState.result = nil
        promptState.done = true
    end
    closeUI()
    cb({ ok = true })
end)

CreateThread(function()
    Wait(250)
    if lib then
        lib.registerContext = function(ctx)
            if not ctx or not ctx.id then return end
            uiContexts[ctx.id] = ctx
        end

        lib.showContext = function(id)
            return showContext(id)
        end

        lib.inputDialog = function(title, fields)
            return inputDialog(title, fields)
        end
    end
end)

RegisterCommand('weeduireset', function()
    closeUI()
end, false)


AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if promptState then
        promptState.result = nil
        promptState.done = true
    end
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)
