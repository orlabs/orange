local t = {
    ["1"] = "one",
    ["2"] = "two",
    ["3"] = "three",
    name = "sumory"
}

local n = string.gsub("hello, ${1}-${1}/$2MMM/${3}/${4}, $name", "%${([1-9]+)}", t)
print(n)

local x = string.gsub("$name-$version.tar.gz", "%$(%w+)", t)
print(x)

local v = {"one","two","three", nil}

local o = string.gsub("hello, ${1}-${1}/$2MMM/${3}/${4}, $name", "%${([1-9]+)}", function(m)
    return v[tonumber(m)]

end)
print(o)