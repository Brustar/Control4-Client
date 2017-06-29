require "Pack"

Device = {}

CMD_ON = 0x01
CMD_OFF = 0x00
CMD_STOP = 0x32
CMD_TOGGLE = 0x33

CMD_RAMP = 0x1A
CMD_COLOR = 0x1B
CMD_HEAT = 0x39
CMD_COOL = 0x3A
CMD_DRY = 0x3B
CMD_FAN = 0x3C
CMD_TEMPRETURE = 0x6A

CMD_SCAN_REV = 0x16
CMD_PLAY = 0x12
CMD_SCAN_FWD = 0x15
CMD_SKIP_REV = 0x17
CMD_PAUSE = 0x14
CMD_SKIP_FWD = 0x18
CMD_STOP = 0x13
CMD_EJECT = 0x20
CMD_MENU = 0x22
CMD_UP = 0x06
CMD_DOWN = 0x08
CMD_LEFT = 0x05
CMD_RIGHT = 0x07
CMD_ENTER = 0x09

CMD_MUTE_TOGGLE = 0x04
CMD_SET_VOLUME_LEVEL = 0xAA

VAR_TEMPERATURE_C = 1131
VAR_HUMIDITY = 1138

VAR_LEVEL_OPEN = 1000
VAR_LEVEL = 1001
CURRENT_VOLUME = 1011

function Device:create(data)

    device={}
    device.data = data
    
    device.LIGHT=0x03
    device.BLIND = 0x21
    device.AIRCONDITION = 0x31
    
    device.TV = 0x12
    device.NETV = 0x11
    device.DVD = 0x13
    device.FM = 0x15
    device.BGMUSIC = 0x14
    
    device.PROJECTOR = 0x16
    device.SCREEN = 0x17
    device.CAMERA = 0x45
    device.LOCK = 0x40
    device.AMPLIFIER = 0x18
    
    function device:handle()
	   local pack = self.data
	   self:switch(pack)
	   if pack.deviceType <= self.LIGHT then	--灯
		  if pack.state == CMD_RAMP then
			 C4:SendToDevice(pack.deviceID,"RAMP_TO_LEVEL", {LEVEL = pack.r, TIME = 1000})
		  elseif pack.state == CMD_COLOR then
			 C4:SendToDevice(pack.deviceID,"SET_BUTTON_COLOR", {ON_COLOR = string.format("%2x%2x%2x",pack.r,pack.b,pack.g)})
		  end
	   elseif pack.deviceType == self.AIRCONDITION then	--空调
		  if pack.state == CMD_ON then
			 C4:SendToDevice(pack.deviceID, "ON", {})
		  elseif pack.state == CMD_OFF then
			 C4:SendToDevice(pack.deviceID, "OFF", {})
		  elseif pack.state == CMD_HEAT then
			 C4:SendToDevice(pack.deviceID, "HEAT", {})
		  elseif pack.state == CMD_COOL then
			 C4:SendToDevice(pack.deviceID, "COOL", {})
		  elseif pack.state == CMD_DRY then
			 C4:SendToDevice(pack.deviceID, "DRY", {})
		  elseif pack.state == CMD_FAN then
			 C4:SendToDevice(pack.deviceID, "FAN", {})
		  elseif pack.state == CMD_TEMPRETURE then
			 if pack.r<30 and pack.r>15 then
				C4:SendToDevice(pack.deviceID, "TEMPTURE", {degree = pack.r})
			 end
		  end
	   elseif pack.deviceType == self.BLIND or pack.deviceType == self.BLIND + 1 then
		  if pack.state == CMD_STOP then
			 C4:SendToDevice(pack.deviceID,"STOP",{})
		  elseif pack.state == CMD_ON then
			 C4:SendToDevice(pack.deviceID,"UP",{})
		  elseif pack.state == CMD_OFF then
			 C4:SendToDevice(pack.deviceID,"DOWN",{})
		  elseif pack.state == CMD_TOGGLE then
			 C4:SendToDevice(pack.deviceID,"TOGGLE",{})
		  end
	   elseif pack.deviceType == self.DVD then
		  if pack.state == CMD_SCAN_REV then
			 C4:SendToDevice(pack.deviceID,"SCAN_REV",{})
		  elseif pack.state == CMD_PLAY then
			 C4:SendToDevice(pack.deviceID,"PLAY",{})
		  elseif pack.state == CMD_SCAN_FWD then
			 C4:SendToDevice(pack.deviceID,"SCAN_FWD",{})
		  elseif pack.state == CMD_SKIP_REV then
			 C4:SendToDevice(pack.deviceID,"SKIP_REV",{})
		  elseif pack.state == CMD_PAUSE then
			 C4:SendToDevice(pack.deviceID,"PAUSE",{})
		  elseif pack.state == CMD_SKIP_FWD then
			 C4:SendToDevice(pack.deviceID,"SKIP_FWD",{})
		  elseif pack.state == CMD_STOP then
			 C4:SendToDevice(pack.deviceID,"STOP",{})
		  elseif pack.state == CMD_EJECT then
			 C4:SendToDevice(pack.deviceID,"EJECT",{})
		  elseif pack.state == CMD_MENU then
			 C4:SendToDevice(pack.deviceID,"MENU",{})
		  elseif pack.state == CMD_UP then
			 C4:SendToDevice(pack.deviceID,"UP",{})
		  elseif pack.state == CMD_DOWN then
			 C4:SendToDevice(pack.deviceID,"DOWN",{})
		  elseif pack.state == CMD_LEFT then
			 C4:SendToDevice(pack.deviceID,"LEFT",{})
		  elseif pack.state == CMD_RIGHT then
			 C4:SendToDevice(pack.deviceID,"RIGHT",{})
		  elseif pack.state == CMD_ENTER then
			 C4:SendToDevice(pack.deviceID,"ENTER",{})
		  elseif pack.state == CMD_SET_VOLUME_LEVEL then
			 C4:SendToDevice(C4:RoomGetId(),"SET_VOLUME_LEVEL",{LEVEL = pack.r})
		  end
	   elseif pack.deviceType == self.TV then
		  --MUTE_TOGGLE
		  if pack.state == CMD_UP then
			 C4:SendToDevice(pack.deviceID,"UP",{})
		  elseif pack.state == CMD_DOWN then
			 C4:SendToDevice(pack.deviceID,"DOWN",{})
		  elseif pack.state == CMD_LEFT then
			 C4:SendToDevice(pack.deviceID,"LEFT",{})
		  elseif pack.state == CMD_RIGHT then
			 C4:SendToDevice(pack.deviceID,"RIGHT",{})
		  elseif pack.state == CMD_ENTER then
			 C4:SendToDevice(pack.deviceID,"ENTER",{})
		  elseif pack.state == CMD_MUTE_TOGGLE then
			 C4:SendToDevice(pack.deviceID,"MUTE_TOGGLE",{})
		  elseif pack.state == CMD_SET_VOLUME_LEVEL then
			 C4:SendToDevice(pack.deviceID,"SET_VOLUME_LEVEL",{LEVEL = pack.r})
		  end
	   elseif pack.deviceType == self.NETV then
	   elseif pack.deviceType == self.FM then
	   
	   elseif pack.deviceType == self.BGMUSIC then
		  --此驱动必须和my music在同一房间
		  if pack.state == CMD_PLAY then
			 C4:SendToDevice(C4:RoomGetId(),"PLAY",{})
		  elseif pack.state == CMD_SKIP_REV then
			 C4:SendToDevice(C4:RoomGetId(),"SKIP_REV",{})
		  elseif pack.state == CMD_PAUSE then
			 C4:SendToDevice(C4:RoomGetId(),"PAUSE",{})
		  elseif pack.state == CMD_SKIP_FWD then
			 C4:SendToDevice(C4:RoomGetId(),"SKIP_FWD",{})
		  elseif pack.state == CMD_STOP then
			 C4:SendToDevice(C4:RoomGetId(),"STOP",{})
		  elseif pack.state == CMD_MENU then
			 C4:SendToDevice(C4:RoomGetId(),"MUTE_ON",{})
		  elseif pack.state == CMD_SET_VOLUME_LEVEL then
			 C4:SendToDevice(C4:RoomGetId(),"SET_VOLUME_LEVEL",{LEVEL = pack.r})
		  end
	   elseif pack.deviceType == self.PROJECTOR then
	   elseif pack.deviceType == self.SCREEN then
	   elseif pack.deviceType == self.CAMERA then
		  
	   elseif pack.deviceType == self.LOCK then
	   elseif pack.deviceType == self.AMPLIFIER then
	   else
		  return nil
	   end
	   return pack:hex()
    end
    
    function device:switch(pack)
	   print("state:" .. pack.state)
	   print("type...".. pack.deviceType)
	   print("device..." .. pack.deviceID)
	   if pack.state == CMD_ON then
		  C4:SendToDevice(pack.deviceID,"ON",{})
	   elseif pack.state == CMD_OFF then
		  C4:SendToDevice(pack.deviceID,"OFF",{})
	   end
    end
    
    function device:envData()
	   local ret = {},idDevice,pack
	   
	   if Properties["Nest ID"] then
		  local ids = string.split(Properties["Nest ID"])
		  for _,id in ipairs(ids) do
			 idDevice = tonumber(id)
			 --湿度
			 pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_HUMIDITY,tonumber(C4:GetVariable(idDevice, VAR_HUMIDITY)),0,0,idDevice)
			 data = pack:hex()
			 table.insert(ret,data)
			 --温度
			 pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_TEMPRETURE,tonumber(C4:GetVariable(idDevice, VAR_TEMPERATURE_C)),0,0,idDevice)
			 local data = pack:hex()
			 table.insert(ret,data)
		  end
	   else
		  idDevice = tonumber(Properties["Aircondition ID"])
		  pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_TEMPRETURE,tonumber(C4:GetVariable(idDevice, self:airDeviceVariableID(idDevice,"CURRENT_TEMPRETURE"))),0,0,idDevice)
		  local data = pack:hex()
		  table.insert(ret,data)
	   end
	   
	   return ret
    end
    
    function device:deviceState(deviceID)
	   local variable = C4:GetVariable(deviceID, VAR_LEVEL_OPEN) or "0"
	   local pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),tonumber(variable),0,0,0,deviceID)
	   return pack:hex()
    end
    
    function device:deviceLevel(deviceID)
	   local variable = C4:GetVariable(deviceID, VAR_LEVEL) or "0"
	   local pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_RAMP,tonumber(variable),0,0,deviceID)
	   return pack:hex()
    end
    
    function device:volume(deviceID)
	   local variable = C4:GetVariable(C4:RoomGetId(), CURRENT_VOLUME)
	   local pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_SET_VOLUME_LEVEL,tonumber(variable),0,0,deviceID)
	   return pack:hex()
    end
    
    function device:airDeviceVariableID(deviceID,key)
	   key = key or "CONTROL_CMD"
	   for id,i in pairs(C4:GetDeviceVariables(deviceID)) do
		  for k,v in pairs(i) do
			 if k == "name" and v == key then
			    return id 
			 end
		  end
	   end
	   return 0
    end
    
    return device

end

function string.split(str, delimiter)
    local pos,arr = 0, {}
    if (not delimiter) then 
	   table.insert(arr,str)
	   return arr 
    end
    -- for each divider found
    for st,sp in function() return string.find(str, delimiter, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end