require "File"
require "Plist"
require "Scene"

local JSON = require('json')

Http = {}

UPLOAD_TAG = 1
DOWNLOAD_TAG = 2

function Http:create()

    local http = {}

    local host = Properties["HTTP Address"]
    local port = tonumber(Properties["HTTP Port"])
    
    function http:upload(json)
    	self.tag = UPLOAD_TAG
	   local postData = string.format("optype=1&hostid=%s&jsondata=%s",Properties["masterID"],json)
	   local url = string.format("http://%s:%d/cloud/host_config_upload.aspx",host,port)
	   local ticketId = C4:urlPost(url, postData)
	   return ticketId
    end
    
    function http:IsSucceeded(responseData)
	   local json = JSON:decode(responseData)
	   Dbg:Debug("return json:" .. responseData)
	   return json.errortype == "0"
    end

    function http:prepareDownload(fileName,sceneID,deviceType)
    	self.tag = DOWNLOAD_TAG
	   self.fileName = fileName
	   self.sceneID = sceneID
	   self.deviceType = deviceType
	   local url = string.format("http://%s:%d/Cloud/download_plist.aspx",host,port)
	   local md5 = File.md5(fileName)
	   local param = string.format("filename=%s&md5=%s",self.fileName,md5)
	   local ticketId = C4:urlPost(url, param)
	   return ticketId
    end

    function http:download(url)
	   C4:urlGet(url, {}, false,
		  function(ticketId, strData, responseCode, tHeaders, strError)
			 if (strError == nil) then
				Dbg:Debug("C4:urlGet() succeeded: " .. strData)
				C4:FileDelete(self.fileName)
				File.write(self.fileName,strData)
				self:startSchedule()
			 else
				Dbg:Alert("C4:urlGet() failed: " .. strError)
			 end
	   end)

    end

    function http:startSchedule()
    	local schData = Plist.parseSchedule(self.fileName)
  		if schData then
	  		local isDevice = self.deviceType == DEVICE_SCHEDULE
	  		local sceneData = Plist.parseToTable(self.fileName)
	  		local sch = Scheduler:create()
	  		sch:start(isDevice,sceneData,schData)
	  		table.insert(scheduleMap,self.sceneID,sch)
	  	end
    end

    function http:paserURL(responseData)
	   local json = JSON:decode(responseData)
	   return json["plist_url"] or ""
    end

    function http:ReceivedAsync(ticketId, strData, responseCode, tHeaders)
	   Dbg:Debug('http:ReceivedAsync, ticketId = ' .. tostring(ticketId) .. ' responseCode = ' .. tostring(responseCode))
	   if self.tag == UPLOAD_TAG then
		   if (responseCode == 200) then
			  if self:IsSucceeded(strData) then
				 C4:UpdateProperty("Http Status","upload success")
				 return true
			  else
				 C4:UpdateProperty("Http Status","upload fail")
			  end
		   else
			  C4:UpdateProperty("Http Status","upload error")
		   end
		end

		if self.tag == DOWNLOAD_TAG then
			if (responseCode == 200) then
			  	local url = self:paserURL(strData)			  	
			  	if url == "" then
			  		self:startSchedule()
			  	else
					return self:download(url)
				end
		    else
			  	Dbg:Alert("ReceivedAsync: can not find command object!!")
		    end
		end
	   return false
    end
    
    return http
end