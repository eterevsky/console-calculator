local skip_space = function(s, processed)
    local spaces = string.match(s, '^%s*', processed + 1)
    return processed + string.len(spaces)
end

-- For recursion
local calc_subclause, calc_mult_clause, calc_expression

-- Process a number or an expression in () brackets.
calc_subclause = function(s, processed)
    processed = skip_space(s, processed)
    if processed >= string.len(s) then
        -- game.print("Unexpected end of expression")
        return
    end

    local c = string.byte(s, processed + 1)
    
    if c == 40 then  -- '('
        processed = processed + 1
        local value
        value, processed = calc_expression(s, processed)
        if value == nil then
            return
        end
        c = string.byte(s, processed + 1)
        if c ~= 41 then  -- ')'
            -- game.print("Expected ')' at position " .. (processed + 1))
            return
        end
        return value, processed + 1
    elseif c == 45 then  -- '-'
        processed = processed + 1
        local value
        value, processed = calc_subclause(s, processed)
        if value == nil then
            return
        end
        return -value, processed
    else
        local number = string.match(s, '^[%d%.]+', processed + 1)
        if number == nil then
            -- game.print("Expected a number at " .. (processed + 1))
            return
        end

        processed = processed + string.len(number)
        return tonumber(number), processed
    end
end

-- Process a multiplicative clause
calc_mult_clause = function(s, processed)
    local value
    value, processed = calc_subclause(s, processed)
    if value == nil then
        return
    end

    processed = skip_space(s, processed)

    while processed < string.len(s) do
        local c = string.byte(s, processed + 1)
        
        if c ~= 42 and c ~= 47 then
            return value, processed
        end

        processed = processed + 1

        local clause_value
        clause_value, processed = calc_subclause(s, processed)

        if clause_value == nil then
            return
        end

        if c == 42 then
            value = value * clause_value
        else
            value = value / clause_value
        end

        processed = skip_space(s, processed)
    end

    return value, processed
end

-- Process a full expression
calc_expression = function(s, processed)
    local value
    value, processed = calc_mult_clause(s, processed)
    if value == nil then
        return
    end

    processed = skip_space(s, processed)

    while processed < string.len(s) do
        local c = string.byte(s, processed + 1)
        
        if c ~= 43 and c ~= 45 then
            return value, processed
        end

        processed = processed + 1

        local clause_value
        clause_value, processed = calc_mult_clause(s, processed)

        if clause_value == nil then
            return
        end

        if c == 43 then
            value = value + clause_value
        else
            value = value - clause_value
        end

        processed = skip_space(s, processed)
    end

    return value, processed
end

local handle_chat = function(event)
    local message = event.message
    if string.match(message, "^[%d%.]*$") then
        return
    end
    local res, processed_len = calc_expression(message, 0)
    if res ~= nil and processed_len == string.len(message) then
        game.print("= " .. res)
    end
end

local help = function()
    game.print("To use Console Calculator, press ` to open console, type an arithmetic expression and press Enter. Other chats are ignored.")
end

script.on_event(defines.events.on_console_chat, handle_chat)
script.on_init(help)
