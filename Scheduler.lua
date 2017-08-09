Scheduler = {}

function Scheduler:create(obj)

	local scheduler = {}
	
	self.timer = nil

	self.startime = parseTime(obj.schData.startTime)
	self.isDevice = obj.isDevice
	if self.isDevice then
		self.interval = obj.schData.interval
		self.deviceID = obj.schData.deviceID
	else
		self.endtime = parseTime(obj.schData.endTime)
		self.sceneData = obj.sceneData
    end

	function scheduler:start(weekDays)
		weekDays = weekDays or {}
		self.timer = C4:SetTimer(60 * 1000, function(timer, skips)
			 local wday = os.date("%w")
			 for _,v in ipairs(weekDays) do
			 	if v == wday then
			 		self:execute()
			 	end
			 end

			 if self.isDevice or #weekDays == 0 then
			 	self:execute()
			 end
			 
		end,true)
	end

	function scheduler:execute()
		local now = os.date("*t")
		local year = now.year
		local month = now.month
		local day = now.day

		local sysMin = os.time() - os.time() % 60
		local startMin = os.time{year = year,month = month, day = day, hour = self.startime.hour , min = self.startime.min}
		local endMin = os.time{year = year,month = month, day = day, hour = self.endtime.hour , min = self.endtime.min}
		if sysMin == startMin then
		  if self.isDevice then
			 C4:SendToDevice(self.deviceID,"ON",{})
			 C4:SetTimer(self.interval, function(timer, skips)
				C4:SendToDevice(self.deviceID,"OFF",{})
				timer:Cancel()
			 end)
		  else 
			 Scene.start(self.sceneData)
		  end
		end

		if not self.isDevice then
			if sysMin == endMin then
			 	Scene.stop(self.sceneData)
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