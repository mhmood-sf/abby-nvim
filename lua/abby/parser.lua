--- abby parser

--- Utils

-- Checks if source has been fully consumed.
local function consumed(state)
    return state.pos > #state.src
end

-- Returns current item in state's source, or
-- `default` if source has been consumed.
local function cur_item(state, default)
    if consumed(state) then
        return default
    else
        return state.src[state.pos]
    end
end

-- Increments state position.
local function advance(state)
    state.pos = state.pos + 1
end

-- Echoes error msg with highlighting.
local function error(msg)
    vim.cmd("echohl Error")
    vim.cmd("echom '" .. msg .. "'")
    vim.cmd("echohl None")
end

--- Scanner

-- Scans BLOCK token and adds it to state.
local function scan_block(state)
    local token = { type = "BLOCK", lexeme = "" }
    -- Track depth of nested braces.
    local depth = 1

    -- Consume until depth is 0.
    while depth ~= 0 do
        -- EOF before depth 0 means missing brace.
        if consumed(state) then
            state.err = true
            return error "abby: Unexpected end of file; missing '}'"
        end

        local char = cur_item(state)
        -- Ignore newlines.
        if char ~= "\n" then
            -- Update depth if char is a brace.
            if char == "{" then
                depth = depth + 1
            elseif char == "}" then
                depth = depth - 1
            end

            -- Only add char to lexeme if depth is not 0,
            -- i.e, we are still inside the block.
            local lexeme = token.lexeme
            token.lexeme = (depth ~= 0) and (lexeme .. char) or lexeme
        end

        advance(state)
    end

    table.insert(state.tokens, token)
end

-- Scans KW_* or IDENT token and adds it to state.
local function scan_ident(state)
    local token = { type = "", lexeme = "" }

    -- Scan until we see a whitespace character.
    while string.match(cur_item(state, ""), "%s") == nil do
        if not consumed(state) then
            token.lexeme = token.lexeme .. cur_item(state)
            advance(state)
        end
    end

    -- Check if it's a keyword or identifier.
    if token.lexeme == "abbr" then
        token.type = "KW_ABBR"
    elseif token.lexeme == "expr" then
        token.type = "KW_EXPR"
    else
        -- Ensure identifiers are only keyword characters.
        local re = vim.regex("^\\k*$")
        if re:match_str(token.lexeme) == nil then
            state.err = true
            return error "abby: identifiers may only contain keyword characters"
        end

        token.type = "IDENT"
    end

    table.insert(state.tokens, token)
end

-- Takes source string and returns a list of tokens,
-- or nil if an error occurred.
local function tokenize(raw_src)
    local chars = vim.split(raw_src, "")
    local state = { tokens = {}, src = chars, pos = 1, err = false }

    while not (consumed(state) or state.err) do
        local char = cur_item(state)
        -- '{' starts a block.
        if char == "{" then
            advance(state)
            scan_block(state)
        -- '#' starts a comment.
        elseif char == "#" then
            -- Newline character
            local NL = vim.fn.nr2char(10)
            while not (cur_item(state) == NL or consumed(state)) do
                advance(state)
            end
        -- Ignore whitespace.
        elseif string.match(char, "%s") then
            advance(state)
        else
            scan_ident(state)
        end
    end

    return state.err and nil or state.tokens
end

--- Parser

-- Returns current token if it matches expected type,
-- otherwise nil.
local function expect(types, state)
    local ty = cur_item(state).type
    if vim.tbl_contains(types, ty) then
        local token = cur_item(state)
        advance(state)
        return token
    else
        state.err = true
        return error("abby: Expected " .. table.concat(types, " or "))
    end
end

-- Takes list of tokens and returns list of abbrv objects,
-- or nil if there was an error.
local function parse_tokens(tokens)
    local state = { abbrvs = {}, src = tokens, pos = 1, err = false }

    while not (consumed(state) or state.err) do
        local kw    = expect({ "KW_ABBR", "KW_EXPR" }, state)
        local ident = expect({ "IDENT" }, state)
        local block = expect({ "BLOCK" }, state)

        -- Add abbrv if there were no errors.
        if not state.err then
            local abbrv = {
                name      = ident.lexeme,
                is_expr   = (kw.type == "KW_EXPR") and true or false,
                expansion = block.lexeme
            }

            table.insert(state.abbrvs, abbrv)
        end
    end

    return state.err and nil or state.abbrvs
end

-- Takes source string and returns list of abbrv objects,
-- or nil if there was an error.
local function parse(raw_src)
    local tokens = tokenize(raw_src)
    local abbrvs = parse_tokens(tokens)
    return abbrvs
end

return { parse = parse }

