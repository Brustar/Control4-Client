local JSON = require('json')

Xml = {}

function Xml:create(config)
    local xml = {}
    xml.config = config
    xml.nests = {}
    
    function xml:getRooms()
	   local rooms={}
	   
	   for id,name,t in string.gmatch(self.config,"<id>(%d+)</id>\n<name>(.+)</name>\n<type>(%d+)</type>") do
		  local pattern="(<id>(%d+)</id>\n<name>%w+</name>\n<type>8</type>[%s%S]*<type>7</type>)"
		  local str,roomid = string.match(self.config,pattern)
		  local room = {}
		  if t == "8" then
			 if roomid == id then
				room.devices=self:getDevices(str)
				room.scenes = self:getScenes()
			 end
			 room.id = string.trim(string.format("%4X",tonumber(id)))
			 room.name = name
			 table.insert(rooms , room)
		  end
	   end
	   C4:UpdateProperty("Nest ID", table.concat(self.nests,","))	-- 多个Nest
	   return rooms
    end
    
    function xml:getScenes()
	   local scenes={}
	   
	   local str = C4:GetProjectItems("AGENTS","NO_ROOT_TAGS")
	   local pattern = "<name>Macros</name>\n<type>9</type>\n<itemdata><large_image>[^\n]+</large_image><small_image>[^\n]+</small_image></itemdata>\n<state>([^\n]+)</state>"
	   local state = string.match(str,pattern)
	   state = state:gsub("&lt;","<"):gsub("&gt;",">")
	   --[\31-\243]+ 包括中英文，数字，空格，下划线
	   for id,name in string.gmatch(state,"<id>(%d+)</id><name>(.+)</name>") do
		  local scene = {}
		  scene.id = string.trim(string.format("%4X",tonumber(id)))
		  scene.name = name
		  table.insert(scenes , scene)
	   end
	   return scenes
    end
    
    function xml:getDevices(str)
	   local devices={}
	   for id,name,f in string.gmatch(str,"<id>(%d+)</id>\n<name>(.+)</name>\n<type>7</type>\n<itemdata><config_data_file>([_%w]+)") do
		  if f == "thermostatV2" then
			 print("insert.....")
			 table.insert(self.nests,id)
		  end
		  local device = {}
		  device.id = string.trim(string.format("%4X",tonumber(id)))
		  device.name = name
		  device.type = f
		  table.insert(devices , device)
	   end
	   
	   return devices
    end
    
    function xml:toJson()
	   local obj = {}
	   obj.rooms = self:getRooms()
	   --obj.scenes = self:getScenes()
	   return JSON:encode(obj)
    end
    
    return xml
end

function string.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end