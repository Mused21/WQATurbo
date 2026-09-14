-- Load options using the same source order as the addon, including legacy baselines.
return function(root)
    root = root or "."
    for line in io.lines(root .. "/WQATurbo.toc") do
        local path = line:gsub("\\", "/"):match("^%s*(.-)%s*$")
        if path == "UI/Options.lua" or path == "Options.lua"
            or path:match("^UI/Options/[^/]+%.lua$") then
            dofile(root .. "/" .. path)
        end
    end
end
