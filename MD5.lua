function MD5.md5byFile(filepath)
    local md5 = ""
    local fh = C4:FileOpen(filepath)
    if C4:FileIsValid(fh) then
	   C4:FileSetPos(fh, 0)
	   local fileData = C4:FileRead(fh, fileSize)
	   md5 = C4:Hash("MD5", fileData)
    end

    C4:FileClose(fh)
    return md5
end