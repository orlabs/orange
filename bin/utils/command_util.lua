local _M = {}


function _M.read_file(path)
    local contents
    local file = io.open(path, "rb")
    if file then
        contents = file:read("*all")
        file:close()
    end
    return contents
end

function _M.write_to_file(path, value)
    local file, err = io.open(path, "w")
    if err then
        return false, err
    end

    file:write(value)
    file:close()
    return true
end

function _M.run_command(command)
    local n = os.tmpname() -- get a temporary file name to store output
    local f = os.tmpname() -- get a temporary file name to store script
    _M.write_to_file(f, command)
    local exit_code = os.execute("/bin/bash "..f.." > "..n.." 2>&1")
    local result = _M.read_file(n)
    os.remove(n)
    os.remove(f)
    local v = result:match('(.*)(\n+)$')
    return v
end

function _M.pwd()
    return _M.run_command("pwd")
end


return _M
