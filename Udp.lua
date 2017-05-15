--udpclient
Udp = {}

UDP_CONNECT_ID = 6003
UDP_PORT = 9000
UDP_CMD = 0x80

function Udp:create()

    local udp = {}
    
    self.timer = nil
    
    function udp.connect()
	   C4:CreateNetworkConnection (UDP_CONNECT_ID, "255.255.255.255")
	   C4:NetConnect(UDP_CONNECT_ID, UDP_PORT, 'UDP')
    end
    
    function udp.OnConnectionStatusChanged(idBinding, nPort, strStatus)
	   if (strStatus == "ONLINE") then
		  local a,b,c,d = string.match(C4:GetControllerNetworkAddress(),"(%d+).(%d+).(%d+).(%d+)")
		  local pack = Pack:create(UDP_CMD,tonumber(Properties["masterID"]),tonumber(a),tonumber(b),tonumber(c),tonumber(d),SERVER_PORT,UDP_CMD)
		  self.timer = C4:SetTimer(5 * 1000, function(timer, skips)
			 C4:SendToNetwork(UDP_CONNECT_ID, UDP_PORT, pack:hex())
		  end,true)
	   end
    end
    
    function udp.stop()
	   if self.timer then
		  self.timer:Cancel()
	   end
	   
	   C4:NetDisconnect(UDP_CONNECT_ID, UDP_PORT, 'UDP')
    end
    
    return udp
end