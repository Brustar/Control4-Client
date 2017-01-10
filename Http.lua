local JSON = require('json')
Http = {}

function Http:create(data)

    local http = {}
    http.data = data
    local host = "115.28.151.85"
    local port = 8082
    
    function http:upload()
	   local postData = string.format("opttype=1&hostid=%s&jsondata=%s",Properties["masterID"],self.data)
	   local url = string.format("http://%s:%d/cloud/host_config_upload.aspx",host,port)
	   local ticketId = C4:urlPost(url, postData)
	   return ticketId
    end
    
    function http:IsSucceeded(responseData)
	   local json = JSON:decode(responseData)
	   return json.errortype == "0"
    end

    function http:ReceivedAsync(ticketId, strData, responseCode, tHeaders)
	   print('http:ReceivedAsync, ticketId = ' .. tostring(ticketId) .. ' responseCode = ' .. tostring(responseCode))
	   if (responseCode == 200) then
		  if self:IsSucceeded(strData) then
			 C4:UpdateProperty("Http Status","upload success")
		  else
			 C4:UpdateProperty("Http Status","upload fail")
		  end
	   else
		  C4:UpdateProperty("Http Status","upload error")
	   end
	   
    end
    
    return http
end