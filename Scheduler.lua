Scheduler = {}

function Scheduler:create()

	local scheduler = {}
	
	self.timer = nil

	function scheduler:start(isDevice,sceneData,schData)
		local startime = parseTime(schData.startTime)
		local endtime = parseTime(schData.endTime)
		local weekDays = weekDays or {}
		self.timer = C4:SetTimer(60 * 1000, function(timer, skips)
			 local wday = os.date("%w")
			 for _,v in ipairs(weekDays) do
			 	if v == wday then
			 		self:execute(isDevice,sceneData,schData)
			 	end
			 end

			 if self.isDevice or #weekDays == 0 then
			 	self:execute(isDevice,sceneData,schData)
			 end
			 
		end,true)
	end

	function scheduler:execute(isDevice,sceneData,schData)
		local startime = parseTime(schData.startTime)
		local endtime = parseTime(schData.endTime)

		local now = os.date("*t")
		local year = now.year
		local month = now.month
		local day = now.day

		local sysMin = os.time() - os.time() % 60
		local startMin = os.time{year = year,month = month, day = day, hour = startime.hour , min = startime.min}
		local endMin = os.time{year = year,month = month, day = day, hour = endtime.hour , min = endtime.min}
		if sysMin == startMin then
		  if isDevice then
			 C4:SendToDevice(sceneData.deviceID,"ON",{})
			 C4:SetTimer(sceneData.interval, function(timer, skips)
				C4:SendToDevice(sceneData.deviceID,"OFF",{})
				timer:Cancel()
			 end)
		  else
			 Scene.start(sceneData)
		  end
		end

		if not isDevice then
			if sysMin == endMin then
			 	Scene.stop(sceneData)
			end
		end
	end

	function scheduler:stop()
		if self.timer then
		  self.timer:Cancel()
	   end
	end

	return scheduler

end

function parseTime(t)
	local pattern = "(%d%d?):(%d%d)"
	local hour,min = t:match(pattern)
	return {hour=tonumber(hour),min=tonumber(min)}
end