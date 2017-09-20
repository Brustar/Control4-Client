require "Pack"
require "Xml"
require "Http"
require "Device"
require "Server"
require "Udp"
require "Scheduler"

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Driver Declarations
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--[[
	Command Handler Tables
--]]
EX_CMD = {}
PRX_CMD = {}
NOTIFY = {}
DEV_MSG = {}
LUA_ACTION = {}
gTicketIdMap = {}
scheduleMap = {}
--[[
Tables of functions
The following tables are function containers that are called within the following functions:	

	OnDriverInit()
		- first calls all functions contained within ON_DRIVER_EARLY_INIT table
		- then calls all functions contained within ON_DRIVER_INIT table
	OnDriverLateInit()
		- calls all functions contained within ON_DRIVER_LATEINIT table
	OnDriverUpdate()
		- calls all functions contained within ON_DRIVER_UPDATE table
	OnDriverDestroyed()
		- calls all functions contained within ON_DRIVER_DESTROYED table
	OnPropertyChanged()
		- calls all functions contained within ON_PROPERTY_CHANGED table
--]]
ON_DRIVER_INIT = {}
ON_DRIVER_EARLY_INIT = {}
ON_DRIVER_LATEINIT = {}
ON_DRIVER_UPDATE = {}
ON_DRIVER_DESTROYED = {}
ON_PROPERTY_CHANGED = {}

-- Constants
DEFAULT_PROXY_BINDINGID = 5001

MAIN_SOCKET_BINDINGID = 6001
SUB_SOCKET_BINDINGID = 6002

SERVER = nil
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Common Driver Code
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--[[
	OnPropertyChanged
		Function called by Director when a property changes value.
	Parameters
		sProperty
			Name of property that has changed.
	Remarks
		The value of the property that has changed can be found with: Properties[sName]. Note
		that OnPropertyChanged is not called when the Property has been changed by the driver
		calling the UpdateProperty command, only when the Property is changed by the user from
		the Properties Page. This function is called by Director when a property changes value.
--]]
function OnPropertyChanged(sProperty)
	Dbg:Trace("OnPropertyChanged(" .. sProperty .. ") changed to: " .. Properties[sProperty])

	local propertyValue = Properties[sProperty]
	
	-- Remove any spaces (trim the property)
	local trimmedProperty = string.gsub(sProperty, " ", "")

	-- if function exists then execute (non-stripped)
	if (ON_PROPERTY_CHANGED[sProperty] ~= nil and type(ON_PROPERTY_CHANGED[sProperty]) == "function") then
		ON_PROPERTY_CHANGED[sProperty](propertyValue)
		return
	-- elseif trimmed function exists then execute
	elseif (ON_PROPERTY_CHANGED[trimmedProperty] ~= nil and type(ON_PROPERTY_CHANGED[trimmedProperty]) == "function") then
		ON_PROPERTY_CHANGED[trimmedProperty](propertyValue)
		return
	end
end

function ON_PROPERTY_CHANGED.DebugMode(propertyValue)
	gDebugTimer:KillTimer()
	Dbg:OutputPrint(propertyValue:find("Print") ~= nil)
	Dbg:OutputC4Log(propertyValue:find("Log") ~= nil)
	if (propertyValue == "Off") then return end
	gDebugTimer:StartTimer()
end

function ON_PROPERTY_CHANGED.DebugLevel(propertyValue)
	Dbg:SetLogLevel(tonumber(string.sub(propertyValue, 1, 1)))
end

---------------------------------------------------------------------
-- ExecuteCommand Code
---------------------------------------------------------------------
--[[
	ExecuteCommand
		Function called by Director when a command is received for this DriverWorks driver.
		This includes commands created in Composer programming.
	Parameters
		sCommand
			Command to be sent
		tParams
			Lua table of parameters for the sent command
--]]
function ExecuteCommand(sCommand, tParams)

	-- Remove any spaces (trim the command)
	local trimmedCommand = string.gsub(sCommand, " ", "")

	-- if function exists then execute (non-stripped)
	if (EX_CMD[sCommand] ~= nil and type(EX_CMD[sCommand]) == "function") then
		EX_CMD[sCommand](tParams)
	-- elseif trimmed function exists then execute
	elseif (EX_CMD[trimmedCommand] ~= nil and type(EX_CMD[trimmedCommand]) == "function") then
		EX_CMD[trimmedCommand](tParams)
	-- handle the command
	elseif (EX_CMD[sCommand] ~= nil) then
		QueueCommand(EX_CMD[sCommand])
	else
		Dbg:Alert("ExecuteCommand: Unhandled command = " .. sCommand)
	end
end

--[[
	Define any functions of commands (EX_CMD.<command>) received from ExecuteCommand that need to be handled by the driver.
--]]

--[[
	EX_CMD.LUA_ACTION
		Function called for any actions executed by the user from the Actions Tab in Composer.
--]]
function EX_CMD.LUA_ACTION(tParams)
	if tParams ~= nil then
		for cmd,cmdv in pairs(tParams) do
			if cmd == "ACTION" then
				if (LUA_ACTION[cmdv] ~= nil) then
					LUA_ACTION[cmdv]()
				else
					Dbg:Alert("Undefined Action")
					Dbg:Alert("Key: " .. cmd .. " Value: " .. cmdv)
				end
			else
				Dbg:Alert("Undefined Command")
				Dbg:Alert("Key: " .. cmd .. " Value: " .. cmdv)
			end
		end
	end
end

function connectEcloudServer(id)
    C4:CreateNetworkConnection (id, Properties["TCP Address"])
    C4:NetConnect(id, tonumber(Properties["TCP Port"]), "TCP")
end

function LUA_ACTION.Connect()
     --Dbg:Debug("connectting " .. Properties["TCP Address"])
	SERVER = tcpServer()
	--[[ Create a network connection for the IP address in the property ]]--
	connectEcloudServer(MAIN_SOCKET_BINDINGID)
	Udp:create().connect()
end

function LUA_ACTION.Disconnect()
     --Dbg:Debug("Disconnect " .. Properties["TCP Address"])
	--[[ We are connecting to TCP port 2000 ]]--
	SERVER:stop()
	C4:NetDisconnect(MAIN_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), "TCP")
	C4:UpdateProperty("Tcp Status", "tcp disconnected")
	Udp:create().stop()
end

function LUA_ACTION.Upload()
     Dbg:Debug("upload info")
	--upload info
     local proj = C4:GetProjectItems("LIMIT_DEVICE_DATA","NO_ROOT_TAGS")
	local xml = Xml:create(proj)
     local data = xml:toJson()
     Dbg:Debug(data)

	local http = Http:create()
	local ticketId = http:upload(data)
	table.insert(gTicketIdMap, ticketId, http)

end

function ReceivedAsync(ticketId, strData, responseCode, tHeaders)
    local this = gTicketIdMap[ticketId]
    if this then
        local success = this:ReceivedAsync(ticketId, strData, responseCode, tHeaders)
        gTicketIdMap[ticketId] = nil
	   if success then
		  connectEcloudServer(MAIN_SOCKET_BINDINGID)
	   end
    else
        Dbg:Alert("ReceivedAsync: can not find command object!!")
    end
end

--[[ This callback function is ran when data is returned from the C4:SendToNetwork command ]]--
function ReceivedFromNetwork(idBinding, nPort, strData)
    if (idBinding == UDP_CONNECT_ID) then
	   return
    end

	hexdump(strData, function(s) Dbg:Debug("<------ " .. s) end)
	local pack = Pack.decode(strData)
	if not (pack.head == 0xEC and pack.tail == 0xEA) then
	   C4:UpdateProperty("Tcp Status", "tcp error")
	   return
	end
	
	local device = Device:create(pack)
	if pack.cmd == MASTER_AUTHOR then
	   local ip = string.format("%d.%d.%d.%d",pack.state,pack.r,pack.g,pack.b)
	   local port = pack.deviceID
	   C4:NetDisconnect(MAIN_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), "TCP")
	   
	   C4:UpdateProperty("TCP Address",ip)
	   C4:UpdateProperty("TCP Port",port)
	   C4:CreateNetworkConnection(SUB_SOCKET_BINDINGID, ip)
	   C4:NetConnect(SUB_SOCKET_BINDINGID, port, "TCP")
	end
	
	if pack.cmd == SUB_AUTHOR then
	   C4:UpdateProperty("Tcp Status", "tcp connected success")
	end

	if pack.cmd == DEVICE_CONTROL then
	   local data = device:handle()
	   if data then
		  hexdump(data, function(s) Dbg:Debug("------>" .. s) end)
		  C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), data)
	   end
     end
	
	if pack.cmd == CMD_SCENE then
	   C4:SetVariable("SCENE_ID", tostring(pack.deviceID))
	   C4:FireEvent("tcp event")
	end

	if pack.cmd == CMD_QUERY then
	   local data = device:deviceState(tostring(pack.deviceID),pack.deviceType)
	   if data then
		  hexdump(data, function(s) Dbg:Debug("------>" .. s) end)
		  C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), data)
	   end
	   if pack.deviceType == device.LIGHT then
		  data = device:deviceLevel(tostring(pack.deviceID),pack.deviceType)
		  C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), data)
	   end

	   if pack.deviceType == device.AIRCONDITION then
		  for _,v in ipairs(device:envData(pack.deviceID,deviceType,pack.b)) do
			 hexdump(v, function(s) Dbg:Debug("------>" .. s) end)
			 C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), v)
		  end
	   end

	   if pack.deviceType == device.FRESHAIR then
	   	data = device:tempreture(pack.deviceID,pack.deviceType)
	   	C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), data)
	   	data = device:freshState(pack.deviceID,pack.deviceType)
	   	C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), data)
	   end
	   
	   if pack.deviceType == device.TV or pack.deviceType == device.DVD or pack.deviceType == device.BGMUSIC then
		  data = device:volume(tostring(pack.deviceID),pack.deviceType)
		  C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), data)
	   end

	   if pack.deviceType == device.BGMUSIC then
		  data = device:isPlaying(pack.deviceID,pack.deviceType)
		  C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), data)
	   end

	   if pack.deviceType == device.PM25 then
	   		data = device:PM25FB(pack.deviceID,pack.deviceType)
		  	C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), data)
	   end
	end

    if pack.cmd == CMD_SCHEDULE then
	   local http = Http:create()
	   if pack.state == CMD_ON then
		  local fileName = ""
		  if pack.deviceType == SCENE_SCHEDULE then
			 fileName = "%s_%d.plist"
		  elseif pack.deviceType == DEVICE_SCHEDULE then
			 fileName = "schedule_%s_%d.plist"
		  end
		  local path = string.format(fileName,pack.masterID,pack.deviceID)
		  local ticketId = http:prepareDownload(path,pack.deviceID,pack.deviceType)
		  table.insert(gTicketIdMap, ticketId, http)
	   elseif pack.state == CMD_OFF then
		  local sch = scheduleMap[tostring(pack.deviceID)]
		  if sch then
			 scheduleMap[tostring(pack.deviceID)] = nil
			 sch:stop()
		  end
	   end
    end
end

function OnConnectionStatusChanged(idBinding, nPort, strStatus)
    if (strStatus == "ONLINE") then
	   if (idBinding == MAIN_SOCKET_BINDINGID) then
		  local pack = Pack:create(MASTER_AUTHOR,tonumber(Properties["masterID"]))
		  C4:SendToNetwork(MAIN_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), pack:hex())
	   end
    
	   if (idBinding == SUB_SOCKET_BINDINGID) then
		  local pack = Pack:create(SUB_AUTHOR,tonumber(Properties["masterID"]))
		  C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), pack:hex())
		  pack = Pack:create(CMD_RESET_SCHEDULE,tonumber(Properties["masterID"]))
		  C4:SendToNetwork(SUB_SOCKET_BINDINGID, tonumber(Properties["TCP Port"]), pack:hex())
	   end
	   
	   if (nPort == UDP_PORT) then
		  Udp:create().OnConnectionStatusChanged(idBinding, nPort, strStatus)
	   end
    else
	   --重连
	   if (idBinding == SUB_SOCKET_BINDINGID) then
		  C4:NetDisconnect(idBinding, tonumber(Properties["TCP Port"]), "TCP")
		  connectEcloudServer(idBinding)
	   end
    end
end

---------------------------------------------------------------------
-- ReceivedFromProxy Code
---------------------------------------------------------------------
--[[
	ReceivedFromProxy(idBinding, sCommand, tParams)
		Function called by Director when a proxy bound to the specified binding sends a
		BindMessage to the DriverWorks driver.

	Parameters
		idBinding
			Binding ID of the proxy that sent a BindMessage to the DriverWorks driver.
		sCommand
			Command that was sent
		tParams
			Lua table of received command parameters
--]]
function ReceivedFromProxy(idBinding, sCommand, tParams)
	if (sCommand ~= nil) then
		if(tParams == nil)		-- initial table variable if nil
			then tParams = {}
		end
		Dbg:Trace("ReceivedFromProxy(): " .. sCommand .. " on binding " .. idBinding .. "; Call Function " .. sCommand .. "()")
		Dbg:Info(tParams)

		if (PRX_CMD[sCommand]) ~= nil then
			PRX_CMD[sCommand](idBinding, tParams)
		else
			Dbg:Alert("ReceivedFromProxy: Unhandled command = " .. sCommand)
		end
	end
end

---------------------------------------------------------------------
-- Notification Code
---------------------------------------------------------------------
-- notify with parameters
function SendNotify(notifyText, Parms, bindingID)
	C4:SendToProxy(bindingID, notifyText, Parms, "NOTIFY")
end

-- A notify with no parameters
function SendSimpleNotify(notifyText, ...)
	bindingID = select(1, ...) or DEFAULT_PROXY_BINDINGID
	C4:SendToProxy(bindingID, notifyText, {}, "NOTIFY")
end

---------------------------------------------------------------------
-- Initialization/Destructor Code
---------------------------------------------------------------------
--[[
	OnDriverInit
		Invoked by director when a driver is loaded. This API is provided for the driver developer to contain all of the driver
		objects that will require initialization.
--]]
function OnDriverInit()
	C4:ErrorLog("INIT_CODE: OnDriverInit()")
	
	SERVER = tcpServer()
	--[[ Create a network connection for the IP address in the property ]]--
	connectEcloudServer(MAIN_SOCKET_BINDINGID)
	Udp:create().connect()
	
	-- Call all ON_DRIVER_EARLY_INIT functions.
	for k,v in pairs(ON_DRIVER_EARLY_INIT) do
		if (ON_DRIVER_EARLY_INIT[k] ~= nil and type(ON_DRIVER_EARLY_INIT[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_EARLY_INIT." .. k .. "()")
			ON_DRIVER_EARLY_INIT[k]()
		end
	end

	-- Call all ON_DRIVER_INIT functions
	for k,v in pairs(ON_DRIVER_INIT) do
		if (ON_DRIVER_INIT[k] ~= nil and type(ON_DRIVER_INIT[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_INIT." .. k .. "()")
			ON_DRIVER_INIT[k]()
		end
	end

	-- Fire OnPropertyChanged to set the initial Headers and other Property global sets, they'll change if Property is changed.
	for k,v in pairs(Properties) do
		OnPropertyChanged(k)
	end
end

--[[
	OnDriverUpdate
		Invoked by director when an update to a driver is requested. This request can occur either by adding a new version of a driver
		through the driver search list or right clicking on the driver and selecting "Update Driver" from within ComposerPro.
		Its purpose is to initialize all components of the driver that are reset during a driver update.
--]]
function OnDriverUpdate()
	C4:ErrorLog("INIT_CODE: OnDriverUpdate()")
	
	-- Call all ON_DRIVER_UPDATE functions
	for k,v in pairs(ON_DRIVER_UPDATE) do
		if (ON_DRIVER_UPDATE[k] ~= nil and type(ON_DRIVER_UPDATE[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_UPDATE." .. k .. "()")
			ON_DRIVER_UPDATE[k]()
		end
	end
end

--[[
	OnDriverLateInit
		Invoked by director after all drivers in the project have been loaded. This API is provided
		for the driver developer to contain all of the driver objects that will require initialization
		after all drivers in the project have been loaded.
--]]
function OnDriverLateInit()
	C4:ErrorLog("INIT_CODE: OnDriverLateInit()")
	
	-- Call all ON_DRIVER_LATEINIT functions
	for k,v in pairs(ON_DRIVER_LATEINIT) do
		if (ON_DRIVER_LATEINIT[k] ~= nil and type(ON_DRIVER_LATEINIT[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_LATEINIT." .. k .. "()")
			ON_DRIVER_LATEINIT[k]()
		end
	end
end


--[[
	OnDriverDestroyed
		Function called by Director when a driver is removed. Release things this driver has allocated such as timers.
--]]
function OnDriverDestroyed()
	C4:ErrorLog("INIT_CODE: OnDriverDestroyed()")
	-- Call all ON_DRIVER_DESTROYED functions
	for k,v in pairs(ON_DRIVER_DESTROYED) do
		if (ON_DRIVER_DESTROYED[k] ~= nil and type(ON_DRIVER_DESTROYED[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_DESTROYED." .. k .. "()")
			ON_DRIVER_DESTROYED[k]()
		end
	end
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Debug Logging Code
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Log = {}

-- Create a Table with Logging functions
function Log:Create()
	
	-- table for logging functions
	local lt = {}
	
	lt._logLevel = 0
	lt._outputPrint = false
	lt._outputC4Log = false
	lt._logName =  "Set Log Name to display"
	
	function lt:SetLogLevel(level)
		self._logLevel = level
	end
	
	function lt:OutputPrint(value)
		self._outputPrint = value
	end
	
	function lt:OutputC4Log(value)
		self._outputC4Log = value
	end
	
	function lt:SetLogName(name)
		self._logName = name
	end

	function lt:Enabled()
		return (self._outputPrint or self._outputC4Log)
	end
	
	function lt:PrintTable(tValue, sIndent)
		if (type(tValue) == "table") then
			if (self._outputPrint) then
				for k,v in pairs(tValue) do
					print(sIndent .. tostring(k) .. ":  " .. tostring(v))
					if (type(v) == "table") then
						self:PrintTable(v, sIndent .. "   ")
					end
				end
			end
	
			if (self._outputC4Log) then
				for k,v in pairs(tValue) do
					C4:ErrorLog(self._logName .. ": " .. sIndent .. tostring(k) .. ":  " .. tostring(v))
					if (type(v) == "table") then
						self:PrintTable(v, sIndent .. "   ")
					end
				end
			end

		else
			if (self._outputPrint) then
				print (sIndent .. tValue)
			end
			
			if (self._outputC4Log) then
				C4:ErrorLog(self._logName .. ": " .. sIndent .. tValue)
			end
		end
	end
		
	function lt:Print(logLevel, sLogText)
		if (self._logLevel >= logLevel) then
			if (type(sLogText) == "table") then
				self:PrintTable(sLogText, "   ")
				return
			end
			
			if (self._outputPrint) then
				print (sLogText)
			end

			if (self._outputC4Log) then
				C4:ErrorLog(self._logName .. ": " .. sLogText)
			end
		end
	end
	
	function lt:Alert(strDebugText)
		self:Print(0, strDebugText)
	end
	
	function lt:Error(strDebugText)
		self:Print(1, strDebugText)
	end
	
	function lt:Warn(strDebugText)
		self:Print(2, strDebugText)
	end
	
	function lt:Info(strDebugText)
		self:Print(3, strDebugText)
	end
	
	function lt:Trace(strDebugText)
		self:Print(4, strDebugText)
	end
	
	function lt:Debug(strDebugText)
		self:Print(5, strDebugText)
	end
	
	return lt
end

function ON_DRIVER_EARLY_INIT.LogLib()
	-- Create and initialize debug logging
	Dbg = Log:Create()
	Dbg:SetLogName("base_template PLEASE CHANGE")
end

function ON_DRIVER_INIT.LogLib()
	-- Create Debug Timer
	gDebugTimer = Timer:Create("Debug", 45, "MINUTES", OnDebugTimerExpired)
end

--[[
	OnDebugTimerExpired
		Debug timer callback function
--]]
function OnDebugTimerExpired()
	Dbg:Warn("Turning Debug Mode Off (timer expired)")
	gDebugTimer:KillTimer()
	C4:UpdateProperty("Debug Mode", "Off")
	OnPropertyChanged("Debug Mode")
end
      
---------------------------------------------------------------------
-- Timer Code
---------------------------------------------------------------------
Timer = {}

-- Create a Table with Timer functions
function Timer:Create(name, interval, units, Callback, repeating, Info)
	-- timers table
	local tt = {}
	
	tt._name = name
	tt._timerID = TimerLibGetNextTimerID()
	tt._interval = interval
	tt._units = units
	tt._repeating = repeating or false
	tt._Callback = Callback
	tt._info = Info or ""
	tt._id = 0

	function tt:StartTimer(...)
		self:KillTimer()
		
		-- optional parameters (interval, units, repeating)
		if ... then
			local interval = select(1, ...)
			local units = select(2, ...)
			local repeating = select(3, ...)
			
			self._interval = interval or self._interval
			self._units = units or self._units
			self._repeating = repeating or self._repeating
		end
		
		if (self._interval > 0) then
			Dbg:Trace("Starting Timer: " .. self._name)
			self._id = C4:AddTimer(self._interval, self._units, self._repeating)
		end
	end

	function tt:KillTimer()
		if (self._id) then
			self._id = C4:KillTimer(self._id)
		end
	end
	
	function tt:TimerStarted()
		return (self._id ~= 0)
	end
			
	function tt:TimerStopped()
		return not self:TimerStarted()
	end
	
	gTimerLibTimers[tt._timerID] = tt
	Dbg:Trace("Created timer " .. tt._name)
	
	return tt
end

function TimerLibGetNextTimerID()
	gTimerLibTimerCurID = gTimerLibTimerCurID + 1
	return gTimerLibTimerCurID
end

function ON_DRIVER_EARLY_INIT.TimerLib()
	gTimerLibTimers = {}
	gTimerLibTimerCurID = 0
end

function ON_DRIVER_DESTROYED.TimerLib()
	-- Kill open timers
	for k,v in pairs(gTimerLibTimers) do
		v:KillTimer()
	end
end

--[[
	OnTimerExpired
		Function called by Director when the specified Control4 timer expires.
	Parameters
		idTimer
			Timer ID of expired timer.
--]]
function OnTimerExpired(idTimer)
	for k,v in pairs(gTimerLibTimers) do
		if (idTimer == v._id) then
			if (v._Callback) then
				v._Callback(v._info)
			end
		end
	end
end

C4:AddVariable("SCENE_ID", "0", "NUMBER")