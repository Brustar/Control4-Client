Scene = {}

function Scene.start(data)
	print("start::::")
    for i,v in ipairs(data.devices) do

	   local deviceid = tonumber(v.enumber,16)
	   --switch
	   if v.isPoweron == 1 or v.poweron == 1 or v.swithon == 1 or v.unlock == 1 or v.pushing == 1 or v.showed == 1 or v.waiting == 1 then
		  C4:SendToDevice(deviceid,"ON",{})
	   end
	   
	   if v.isPoweron == 0 or v.poweron == 0 or v.swithon == 0 or v.pushing == 0 or v.showed == 0 or v.waiting == 0 then
		  C4:SendToDevice(deviceid,"OFF",{})
	   end
	   
	   --light
	   if v.brightness then
		  C4:SendToDevice(deviceid,"RAMP_TO_LEVEL", {LEVEL = v.brightness, TIME = 1000})
	   end
	   
	   if v.color and #v.color>0 then
		  C4:SendToDevice(deviceid,"SET_BUTTON_COLOR", {ON_COLOR = string.format("%2x%2x%2x",v.color[1],v.color[2],v.color[3])})
	   end
	   
	   --blind
	   if v.openvalue then
		  
	   end
	   
	   --TV
	   if v.volume then
		  C4:SendToDevice(deviceid,"SET_VOLUME_LEVEL",{LEVEL = v.volume})
	   end
	   
	   if v.channelID then
		  
	   end
	   
	   --DVD
	   if v.dvolume then
		  C4:SendToDevice(deviceid,"SET_VOLUME_LEVEL",{LEVEL = v.dvolume})
	   end
	   
	   --bgmusic
	   if v.bgvolume then
		  C4:SendToDevice(deviceid,"SET_VOLUME_LEVEL",{LEVEL = v.bgvolume})
	   end
    end
end

function Scene.stop()
	for i,v in ipairs(data.devices) do
		local deviceid = tonumber(v.enumber,16)
		C4:SendToDevice(deviceid,"OFF",{})
	end
end