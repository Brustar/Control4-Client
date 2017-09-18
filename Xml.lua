local JSON = require('json')

Xml = {}

function Xml:create(config)
    local xml = {}
    xml.config = config
    xml.nests = {}
    
    function xml:getRooms()
	   local rooms={}
	   
	   for id,name in string.gmatch(self.config,"<id>(%d+)</id>\n?<name>([^<^>]-)</name>\n?<type>8</type>") do
		  local tVers = C4:GetVersionInfo()
		  local strVers = tVers["version"]
		  local major, minor, _, _ = string.match(strVers, "(%d+)\.(%d+)\.(%d+)\.(%d+)")
		  local pattern="(<id>(%d+)</id>\n?<name>[^<^>]-</name>\n?<type>8</type>.*<type>7</type>)"
		  if tonumber(major) == 2 and tonumber(minor) > 8 then
			 pattern = "(<id>(%d+)</id><name>[^<^>]-</name>\n?<type>8</type>[%s%S]-)</c4i></item></subitems></item></subitems></item>"
		  end
		  local room = {}
		  local i = 1
		  for str,roomid in string.gmatch(self.config,pattern) do
			 if str and roomid == id then
				room.devices=self:getDevices(str)
				if i == 1 then
				    room.scenes = self:getScenes()
				else
				    room.scenes = {}
				end
			 end
			 i = i + 1
		  end
		  room.id = string.trim(string.format("%4X",tonumber(id)))
		  room.name = name
		  table.insert(rooms , room)
	   end
	   --C4:UpdateProperty("Nest ID", table.concat(self.nests,","))	-- 多个Nest
	   return rooms
    end
    
    function xml:getScenes()
	   local scenes={}
	   
	   local str = C4:GetProjectItems("AGENTS","NO_ROOT_TAGS")
	   
	   local pattern = "<name>Advanced Lighting</name>\n?<type>9</type>\n?<itemdata><large_image>[^\n]+</large_image><small_image>[^\n]+</small_image></itemdata>\n?<state>([^\n]+)</state>"
	   local tVers = C4:GetVersionInfo()
	   local strVers = tVers["version"]
	   local major, minor, _, _ = string.match(strVers, "(%d+)\.(%d+)\.(%d+)\.(%d+)")
	   if tonumber(major) == 2 and tonumber(minor) > 8 then
		  pattern = "<name>Advanced Lighting</name>\n?<type>9</type>\n?<itemdata><small_image>[^\n]-</small_image><large_image>[^\n]-</large_image></itemdata>\n?<state>([^\n]-)</state>"
	   end
	   local state = string.match(str,pattern)
	   state = state:gsub("&lt;","<"):gsub("&gt;",">")
	   for name,id in string.gmatch(state,"<AdvScene>%s*<name>(.-)</name>[%d%D]-<scene_id>(%d+)</scene_id>") do
		  local scene = {}
		  scene.id = string.trim(string.format("%4X",tonumber(id)+1))
		  scene.name = name
		  table.insert(scenes , scene)
	   end

	   if tonumber(major) == 2 and tonumber(minor) < 9 then
		  pattern = "<name>Macros</name>\n?<type>9</type>\n?<itemdata><large_image>[^\n]+</large_image><small_image>[^\n]+</small_image></itemdata>\n?<state>([^\n]+)</state>"
		  state = string.match(str,pattern)
		  state = state:gsub("&lt;","<"):gsub("&gt;",">")
		  for id,name in string.gmatch(state,"<id>(%d+)</id><name>(.-)</name>") do
			 local scene = {}
			 scene.id = string.trim(string.format("%4X",i+tonumber(id)-1))
			 scene.name = name
			 table.insert(scenes , scene)
		  end
	   
	   end
	   
	   return scenes
    end
    
    function xml:getDevices(str)
	   local devices={}
	   for id,name,f in string.gmatch(str,"<id>(%d+)</id>\n?<name>([^<^>]-)</name>\n?<type>7</type>\n?<itemdata><config_data_file>(%w+)") do
		  if f == "thermostatV2" then
			 table.insert(self.nests,id)
		  end
		  local device = {}
		  device.id = string.trim(string.format("%4X",tonumber(id)))
		  device.name = name
		  device.type = f
		  if f == "light_v2" then
			 local subtype = string.match(str,"<c4i>([%.%w]+)</c4i>\n?<subitems>\n?<item>\n?<id>".. id .. "</id>")
			 device.subtype = subtype
		  end
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