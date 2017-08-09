File = {}

function File.md5(path)
    local data =  File.read(path)
    if data == "" then
	   return ""
    end
    return C4:Hash("MD5", data)
end

function File.write(path,data)
    local fh = C4:FileOpen(path)
    if (fh == -1) then
        return
    end

    local numWritten = C4:FileWriteString(fh, data)
    print("Bytes written :" .. numWritten)
    C4:FileClose(fh)
end

function File.read(path)
    local fileData = ""
    
    local fh = C4:FileOpen(path)
    if C4:FileIsValid(fh) then
	   C4:FileSetPos(fh, 0)
	   local fileSize = C4:FileGetSize(fh)
	   fileData = C4:FileRead(fh, fileSize)
    end

    C4:FileClose(fh)
    return fileData
end