Pack = {}

MASTER_AUTHOR = 0x22
SUB_AUTHOR = 0x23
DEVICE_CONTROL = 0x03
CMD_UPLOAD = 0x01
CMD_SCENE = 0x89

CMD_HUMIDITY = 0x8A
CMD_OPEN = 0x9A

function Pack:create(cmd,masterID,state,r,g,b,deviceID,deviceType)
    --print("cmd:"..cmd)
    --print("masterID:"..masterID)
    local pack = {}
    local pattern = "bb>Hbbbb>Hbb"
    
    pack.head = 0xEC

    pack.cmd = cmd or 0x00
    pack.masterID = masterID or 0x00
    pack.state = state or 0x00
    pack.r = r or 0x00
    pack.g = g or 0x00
    pack.b = b or 0x00
    pack.deviceID = deviceID or 0x00
    pack.deviceType = deviceType or 0x00
    
    pack.tail = 0xEA
    
    function pack:split()
	   return self.head,self.cmd,self.masterID,self.state,self.r,self.g,self.b,self.deviceID,self.deviceType,self.tail
    end

    function pack:hex()
	   return string.pack(pattern,self:split())
    end
    
    function Pack.decode(data)
	   local _,_,cmd,masterID,state,r,b,g,deviceID,deviceType,_ = string.unpack(data,pattern)
	   return Pack:create(cmd,masterID,state,r,b,g,deviceID,deviceType)
    end
    
    return pack
end