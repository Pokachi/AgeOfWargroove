local Utils = {}

function Utils.getTableIndex(tab, value)
    for i, val in ipairs(tab) do
        if val == value then
            return i
        end
    end
    return -1
end

function Utils.getTableKey(tab, value)
    for key, val in pairs(tab) do
        if val == value then
            return key
        end
    end
    return nil
end

function Utils.tableContains(tab, value)
    for i, val in ipairs(tab) do
        if val == value then
            return true
        end
    end
    return false
end


function Utils.TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

return Utils