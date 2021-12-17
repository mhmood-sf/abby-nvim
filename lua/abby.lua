--- abby, a better experience with vim abbreviations.

-- Options
local abby_dir    = vim.g.abby_dir or vim.fn.stdpath("config") .. "/abby/"
local abby_prefix = vim.g.abby_prefix or "0"

-- Dictionary of loaded abbreviations.
local abbrvs = {}

-- VimL eat function to handle trailing space.
vim.cmd [[
function! Eat(...)
    let pat = a:0 ? a:1 : '\s'
    let chr = nr2char(getchar(0))
    return (chr =~ pat) ? '' : chr
endfunction
]]

-- Parse .ab source files
local parse = require"abby/parser".parse

-- Registers loaded abbreviations for given filetype.
local function abbreviate(filetype, make_local)
    for _, abbrv in ipairs(abbrvs[filetype]) do
        local cmd = "inoreabbrev"
        local exp = abbrv.is_expr and "<expr>" or ""
        local buf = make_local and "<buffer>" or ""
        local sil = "<silent>"
        local lhs = abby_prefix .. abbrv.name
        local rhs = abbrv.expansion

        local tbl = {cmd, exp, buf, sil, lhs, rhs}
        local str = table.concat(tbl, " ")

        vim.fn.execute(str)
    end
end

-- Loads _default.ab if available.
local function load_default()
    local filepath = abby_dir .. "/_default.ab"
    if vim.fn.filereadable(filepath) == 1 then
        local file = io.open(filepath, "r")
        local src  = file:read("*all")
        file:close()
        abbrvs["_default"] = parse(src)
            -- it would've returned nil if parsing failed!
        if abbrvs["_default"] then abbreviate("_default", false) end
    end
end

-- Loads a given filetype's abbreviations.
local function load()
    local filetype = vim.opt.filetype:get()
    -- Check if abbrvs aren't already loaded.
    if abbrvs[filetype] == nil then
        local filepath = abby_dir .. "/" .. filetype .. ".ab"
        if vim.fn.filereadable(filepath) == 1 then
            local file = io.open(filepath, "r")
            local src  = file:read("*all")
            file:close()
            abbrvs[filetype] = parse(src)
            -- it would've returned nil if parsing failed!
            if abbrvs[filetype] then abbreviate(filetype, true) end
        end
    else
        abbreviate(filetype, true)
    end
end

-- Always load default immediately.
load_default()
-- Register FileType autocmd for others.
vim.cmd "autocmd FileType * lua require'abby'.load()"
-- Register autocmd to detect .ab filetype.
vim.cmd "autocmd BufRead,BufNewFile *.ab set filetype=abby"

return { load = load }

