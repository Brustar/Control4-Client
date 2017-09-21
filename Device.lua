require "Pack"

Device = {}

CMD_ON = 0x01
CMD_OFF = 0x00
CMD_STOP = 0x32
CMD_TOGGLE = 0x33

CMD_RAMP = 0x1A
CMD_COLOR = 0x1B
CMD_HEAT = 0x39
CMD_COOL = 0x40
CMD_DRY = 0x42
CMD_FAN = 0x41
CMD_TEMPRETURE = 0x6B
CMD_SET_TEMPRETURE = 0x6A
CMD_MODE = 0x6D
CMD_SPEED = 0x6C
CMD_HIGH = 0x35
CMD_MIDDLE = 0x36
CMD_LOW = 0x37

CMD_WIND = 0x41

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
CMD_BACK = 0x10
CMD_VOLUME_UP = 0x02
CMD_VOLUME_DOWN = 0x03

CMD_MUTE_TOGGLE = 0x04
CMD_SET_VOLUME_LEVEL = 0xAA
CMD_PM25 = 0x7F

CMD_SCHEDULE = 0x8A
CMD_SCHEDULE_RESET = 0x8C

CMD_SHUFFLE = 0x46
CMD_REPEAT = 0x45

SCENE_SCHEDULE = 0x60
DEVICE_SCHEDULE = 0x61

VAR_TEMPERATURE_C = 1131
VAR_HUMIDITY = 1138

VAR_LEVEL_OPEN = 1000
VAR_LEVEL = 1001
VAR_MODE = 1002
VAR_SPEED = 1004
CURRENT_VOLUME = 1011
CURRENT_TEMPRETURE = 1003
VAR_SETTEMP = 1008

FRESH_STATE = 1007

AMPLIFIER_ID = 329

CURRENT_MEDIA = 1031

VAR_PM25 = 1145  --C4:GetVariable(375,1145)

function Device:create(data)

    device={}
    device.data = data
    
    device.LIGHT=0x02
    device.BLIND = 0x21
    device.FRESHAIR = 0x30
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
    device.PM25 = 0x37	
    
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
			 C4:SendToDevice(pack.deviceID, "ON", {addr = pack.b})
		  elseif pack.state == CMD_OFF then
			 C4:SendToDevice(pack.deviceID, "OFF", {addr = pack.b})
		  elseif pack.state == CMD_HEAT then
			 C4:SendToDevice(pack.deviceID, "HEAT", {addr = pack.b})
		  elseif pack.state == CMD_COOL then
			 C4:SendToDevice(pack.deviceID, "COOL", {addr = pack.b})
		  elseif pack.state == CMD_DRY then
			 C4:SendToDevice(pack.deviceID, "DRY", {addr = pack.b})
		  elseif pack.state == CMD_FAN then
			 C4:SendToDevice(pack.deviceID, "FAN", {addr = pack.b})
		  elseif pack.state == CMD_HIGH then
			 C4:SendToDevice(pack.deviceID, "HIGH", {addr = pack.b})
		  elseif pack.state == CMD_MIDDLE then
			 C4:SendToDevice(pack.deviceID, "MIDDLE", {addr = pack.b})
		  elseif pack.state == CMD_LOW then
			 C4:SendToDevice(pack.deviceID, "LOW", {addr = pack.b})
		  elseif pack.state == CMD_SET_TEMPRETURE then
			 if pack.r<30 and pack.r>15 then
				C4:SendToDevice(pack.deviceID, "TEMPTURE", {degree = pack.r,addr = pack.b})
			 end
		  end
		elseif pack.deviceType == self.FRESHAIR then
		  if pack.state == CMD_ON then
			 C4:SendToDevice(pack.deviceID, "FRESH_ON", {})
		  elseif pack.state == CMD_OFF then
			 C4:SendToDevice(pack.deviceID, "FRESH_OFF", {})
		  elseif pack.state == CMD_COOL then
			 C4:SendToDevice(pack.deviceID, "FRESH_COOL", {})
		  elseif pack.state == CMD_WIND then
			 C4:SendToDevice(pack.deviceID, "FRESH_WIND", {})
		  elseif pack.state == CMD_HIGH then
			 C4:SendToDevice(pack.deviceID, "FRESH_HIGH", {})
		  elseif pack.state == CMD_MIDDLE then
			 C4:SendToDevice(pack.deviceID, "FRESH_MIDDLE", {})
		  elseif pack.state == CMD_LOW then
			 C4:SendToDevice(pack.deviceID, "FRESH_LOW", {})
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
			 C4:SendToDevice(pack.deviceID,"SET_VOLUME_LEVEL",{LEVEL = pack.r})
		  elseif pack.state == CMD_VOLUME_DOWN then
			 C4:SendToDevice(AMPLIFIER_ID,"EMIT_CODE",{ID = 107})
		  elseif pack.state == CMD_VOLUME_UP then
			 C4:SendToDevice(AMPLIFIER_ID,"EMIT_CODE",{ID = 106})
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
		  elseif pack.state == CMD_BACK then
			 C4:SendToDevice(pack.deviceID,"BACK",{})
		  elseif pack.state == CMD_SET_VOLUME_LEVEL then
			 C4:SendToDevice(pack.deviceID,"SET_VOLUME_LEVEL",{LEVEL = pack.r})
		  end
	   elseif pack.deviceType == self.NETV then
	   elseif pack.deviceType == self.FM then
	   
	   elseif pack.deviceType == self.BGMUSIC then
		  --此驱动必须和my music在同一房间
		  if pack.state == CMD_PLAY or pack.state == CMD_ON then
			 self:bgMusicON(pack.deviceID,C4:RoomGetId())
		  elseif pack.state == CMD_SKIP_REV then
			 C4:SendToDevice(C4:RoomGetId(),"SKIP_REV",{})
		  elseif pack.state == CMD_PAUSE then
			 C4:SendToDevice(C4:RoomGetId(),"PAUSE",{})
		  elseif pack.state == CMD_SKIP_FWD then
			 C4:SendToDevice(C4:RoomGetId(),"SKIP_FWD",{})
		  elseif pack.state == CMD_STOP or pack.state == CMD_OFF then
			 C4:SendToDevice(C4:RoomGetId(),"STOP",{})
		  elseif pack.state == CMD_SET_VOLUME_LEVEL then
			 C4:SendToDevice(C4:RoomGetId(),"SET_VOLUME_LEVEL",{LEVEL = pack.r/2})
		  elseif pack.state == CMD_SHUFFLE then
			 C4:SendToDevice(pack.deviceID,"ToggleShuffle",{ROOMID = C4:RoomGetId()})
		  elseif pack.state == CMD_REPEAT then
			 C4:SendToDevice(pack.deviceID,"ToggleRepeat",{ROOMID = C4:RoomGetId()})
		  end
	   elseif pack.deviceType == self.PROJECTOR then
	   elseif pack.deviceType == self.SCREEN then
	   elseif pack.deviceType == self.CAMERA then
		  
	   elseif pack.deviceType == self.LOCK then
	   elseif pack.deviceType == self.AMPLIFIER then
		  self:switchAmplifier(pack.deviceID,pack.state)
	   else
		  return nil
	   end
	   pack.cmd = 0x02
	   return pack:hex()
    end
    
    function device:switch(pack)
	   if pack.state == CMD_ON then
		  C4:SendToDevice(pack.deviceID,"ON",{})
	   elseif pack.state == CMD_OFF then
		  C4:SendToDevice(pack.deviceID,"OFF",{})
	   end
    end
    
    function device:envData(deviceID,deviceType,roomId)
    	C4:SendToDevice(deviceID,"QUERY",{addr = roomId})
	   local ret = {}
	   
	   local data = self:tempreture(deviceID,deviceType)
	   table.insert(ret,data)

	   data = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),tonumber(C4:GetVariable(deviceID, VAR_LEVEL)),0,0,0,deviceID,deviceType):hex()
	   table.insert(ret,data)

	   data = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_SET_TEMPRETURE,tonumber(C4:GetVariable(deviceID, VAR_SETTEMP)),0,0,deviceID,deviceType):hex()
	   table.insert(ret,data)

	   data = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_MODE,tonumber(C4:GetVariable(deviceID, VAR_MODE)),0,0,deviceID,deviceType):hex()
	   table.insert(ret,data)

	   data = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_SPEED,tonumber(C4:GetVariable(deviceID, VAR_SPEED)),0,0,deviceID,deviceType):hex()
	   table.insert(ret,data)

	   return ret
    end
    
    function device:tempreture(deviceID,deviceType)
	   pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_TEMPRETURE,tonumber(C4:GetVariable(deviceID, CURRENT_TEMPRETURE)),0,0,deviceID,deviceType)
	   return pack:hex()
    end

    function device:freshState(deviceID,deviceType)
    	C4:SendToDevice(deviceID,"FRESH_READ",{})
    	pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),tonumber(C4:GetVariable(deviceID, FRESH_STATE)),0,0,0,deviceID,deviceType)
	   	return pack:hex()
    end
    -- include light,blind
    function device:deviceState(deviceID,deviceType)
	   if deviceType == self.BGMUSIC or deviceType == self.PM25 or deviceType == self.AIRCONDITION or deviceType == self.FRESHAIR then
		  return nil
	   end
	   local variable = C4:GetVariable(deviceID, VAR_LEVEL_OPEN)
	   local state = 0
	   if variable == "true" then
	   	state = 1
	   end
	   local pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),state,0,0,0,deviceID,deviceType)
	   return pack:hex()
    end
    
    function device:deviceLevel(deviceID,deviceType)
	   local variable = C4:GetVariable(deviceID, VAR_LEVEL) or "0"
	   local pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_RAMP,tonumber(variable),0,0,deviceID,deviceType)
	   return pack:hex()
    end
    
    function device:volume(deviceID,deviceType)
	   local variable = tonumber(C4:GetVariable(C4:RoomGetId(), CURRENT_VOLUME))
	   if variable < 0 then variable = 0 end
	   local pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_SET_VOLUME_LEVEL,variable,0,0,deviceID,deviceType)
	   return pack:hex()
    end

    function device:PM25FB(deviceID,deviceType)
    	local variable = C4:GetVariable(deviceID, VAR_PM25)
    	local reg = "PM2.5:%s?(%d+)"
    	local pm = tonumber(variable:match(reg))
	   if pm < 0 then pm = 0 end
	   local pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),CMD_PM25,pm,0,0,deviceID,deviceType)
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
    
    function device:switchAmplifier(deviceID,state)
	   local irCodeID = 12
	   if state == CMD_ON then
		  C4:SendToDevice(deviceID,"EMIT_CODE",{ID = irCodeID})
	   elseif state == CMD_OFF then
		  irCodeID = 102
		  C4:SendToDevice(deviceID,"EMIT_CODE",{ID = irCodeID})
	   end
    end
    
    function device:bgMusicON(deviceID,roomId)
	   if self:hasSong(roomId)>0 then
		  C4:SendToDevice(roomId,"PLAY",{})
	   else
		  self:playSong(deviceID,roomId)
	   end
    end
    
    function device:playSong(deviceID,roomId)
	   local param = {["type"] = "PLAYLIST",idMedia = 1,idRoom = roomId,volume = 35,shuffle = 0,["repeat"] = 0}
	   C4:SendToDevice(deviceID-1,"DEVICE_SELECTED",param)
    end

    function device:hasSong(roomId)
	   local xml = C4:GetVariable(roomId,CURRENT_MEDIA)
	   local songs = C4:ParseXml(xml)
	   return #songs.ChildNodes
    end

    function device:isPlaying(deviceID,deviceType)
	   local playing = 0
	   if C4:GetVariable(deviceID-1,VAR_LEVEL) == "PLAY" then
		  playing = 1
	   end
	   local pack = Pack:create(CMD_UPLOAD,tonumber(Properties["masterID"]),playing,0,0,0,deviceID,deviceType)
	   return pack:hex()
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