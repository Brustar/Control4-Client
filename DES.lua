DES = {}

DES.cipher = "des-cbc"

DES.key = "ecloud88"

DES.iv = "12345678"

function DES.Encrypt(data)
    local result = C4:Encrypt(DES.cipher,DES.key,DES.iv,data,{ padding = true })
    return C4:Encode(result,"BASE64")
end

function DES.Decrypt(data)
{
	data = C4:Decode(data,"BASE64")
	return C4:Decrypt(DES.cipher,DES.key,DES.iv, data , { padding = true })
}