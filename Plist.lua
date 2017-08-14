Plist = {}

function Plist.nextTag(s, i)
    return string.find(s, "<(%/?)([%w:]+)(%/?)>", i)
end

function Plist.array(s, i)
    local arr, nextTag, array, dictionary = {}, Plist.nextTag, Plist.array, Plist.dictionary
    local ni, j, c, label, empty

    while true do
        ni, j, c, label, empty = nextTag(s, i)
        assert(ni)

        if c == "" then
            if empty == "/" then
                if label == "dict" or label == "array" then
                    arr[#arr+1] = {}
                else
                    arr[#arr+1] = (label == "true") and true or false
                end
            elseif label == "array" then
                arr[#arr+1], i, j = array(s, j+1)
            elseif label == "dict" then
                arr[#arr+1], i, j = dictionary(s, j+1)
            else
                i = j + 1
                ni, j, c, label, empty = nextTag(s, i)

                local val = string.sub(s, i, ni-1)
                if label == "integer" or label == "real" then
                    arr[#arr+1] = tonumber(val)
                else
                    arr[#arr+1] = val
                end
            end
        elseif c == "/" then
            assert(label == "array")
            return arr, j+1, j
        end

        i = j + 1
    end
end

function Plist.dictionary(s, i)
    local dict, nextTag, array, dictionary = {}, Plist.nextTag, Plist.array, Plist.dictionary
    local ni, j, c, label, empty

    while true do
        ni, j, c, label, empty = nextTag(s, i)
        assert(ni)

        if c == "" then
            if label == "key" then
                i = j + 1
                ni, j, c, label, empty = nextTag(s, i)
                assert(c == "/" and label == "key")

                local key = string.sub(s, i, ni-1)

                i = j + 1
                ni, j, c, label, empty = nextTag(s, i)

                if empty == "/" then
                    if label == "dict" or label == "array" then
                        dict[key] = {}
                    else
                        dict[key] = (label == "true") and true or false
                    end
                else
                    if label == "dict" then
                        dict[key], i, j = dictionary(s, j+1)
                    elseif label == "array" then
                        dict[key], i, j = array(s, j+1)
                    else
                        i = j + 1
                        ni, j, c, label, empty = nextTag(s, i)

                        local val = string.sub(s, i, ni-1)
                        if label == "integer" or label == "real" then
                            dict[key] = tonumber(val)
                        else
                            dict[key] = val
                        end
                    end
                end
            end
        elseif c == "/" then
            assert(label == "dict")
            return dict, j+1, j
        end
    
        i = j + 1
    end
end

function Plist.plistParse(s)
    local i, ni, tag, version, empty = 0

    while label ~= "plist" do
        ni, i, label, version = string.find(s, "<([%w:]+)(.-)>", i+1)
        assert(ni)
    end
    
    ni, i, _, label, empty = Plist.nextTag(s, i)

    if empty == "/" then
        return {}
    elseif label == "dict" then
        return Plist.dictionary(s, i+1)
    elseif label == "array" then
        return Plist.array(s, i+1)
    end
end

function Plist.deepPrint(t, prefix)
    if prefix == nil then prefix = "" end
    
    if not next(t) then print(prefix.."{empty}") return end
    
    for k,v in pairs(t) do
        if type(v) == "table" then
            print(prefix.."["..tostring(k).."] -> table")
            Plist.deepPrint(v, prefix .. "   ")
        else
            print(prefix.."["..tostring(k).."]: "..tostring(v))
        end
    end
end

function Plist.parseToTable(fileName)
    local data = File.read(fileName)
    data = data:gsub("<(false)%s?/>","<integer>0</integer>"):gsub("<(true)%s?/>","<integer>1</integer>"):gsub("<(%w+)%s?/>","<%1></%1>")
    return Plist.plistParse(data)
end

function Plist.parseSchedule(fileName)
    local plist = Plist.parseToTable(fileName)
    if plist.schedules and #plist.schedules > 0 then
       return plist.schedules[1]
    else
        return nil
    end
end