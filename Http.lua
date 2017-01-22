local JSON = require('json')
Http = {}

function Http:create(data)

    local http = {}
    http.data = data
    local host = Properties["HTTP Address"]
    local port = tonumber(Properties["HTTP Port"])
    
    function http:upload()
	   local postData = string.format("optype=1&hostid=%s&jsondata=%s",Properties["masterID"],self.data)
	   local url = string.format("http://%s:%d/cloud/host_config_upload.aspx",host,port)
	   local ticketId = C4:urlPost(url, postData)
	   return ticketId
    end
    
    function http:IsSucceeded(responseData)
	   local json = JSON:decode(responseData)
	   print("return:" .. responseData)
	   return json.errortype == "0"
    end

    function http:ReceivedAsync(ticketId, strData, responseCode, tHeaders)
	   print('http:ReceivedAsync, ticketId = ' .. tostring(ticketId) .. ' responseCode = ' .. tostring(responseCode))
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
	   return false
    end
    
    return http
end