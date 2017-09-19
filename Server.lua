require "Pack"
require "Device"

SERVER_PORT = 8009
MASTER_AUTH = 0x84

MASTER_BEAT = 0x31
MASTER_BEAT_ANSWER = 0x32

local server = {
      clients = {},
      clientsCnt = 0,
      --socket = nil,
      notifyOthers = function(self, client, message)
             for cli,info in pairs(self.clients) do
                    if (cli ~= client) then
                          cli:Write(message)
                    end
             end
      end,
      broadcast = function(self, client, message)
             local info = self.clients[client]
             Dbg:Debug("broadcast for client " .. tostring(client) .. " info: " ..tostring(info))
             if (info ~= nil) then
                    self:notifyOthers(client, message)
                    client:Write(message)
             end
      end,
      stripControlCharacters = function(self, data)
             local ret = ""
             for i in string.gmatch(data, "%C+") do
                    ret = ret .. i
             end
             return ret
      end,
      stop = function(self)
             if (self.socket ~= nil) then
                    self.socket:Close()
                    self.socket = nil
                    -- Make a copy of all clients and reset the map.
                    -- This ensures that calls to self:broadcast() and self:notifyOthers()
                    -- during the shutdown process get ignored.  All we want the clients to
                    -- see is the shutdown message.
                    local clients = self.clients
                    self.clients = {}
                    self.clientsCnt = 0
                    for cli,info in pairs(clients) do
                          Dbg:Debug("Disconnecting " .. cli:GetRemoteAddress().ip .. ":" .. cli:GetRemoteAddress().port)
                          cli:Write(""):Close(true)
                    end
             end
      end,
      start = function(self, maxClients, bindAddr, port, done)
             local calledDone = false
             self.socket = C4:CreateTCPServer()
				            :Option("reuseaddr",1)
                    :OnResolve(
                          function(srv, endpoints)
                                 -- You do not need to set this callback function if you only want default behavior.
                                 -- You can return an index into the endpoints array that is provided, if you would like to choose
                                 -- listening on a specific address.  By default, the first entry is used.  Note that you can mess
                                 -- with this table as you wish, but any changes will not be looked at.  Not even if you change the
                                 -- ip/port in one of the entries.  All that matters is the index into the original array that was
                                 -- provided.  If you return 0, the server will not bind to any address and will not listen for
                                 -- anything, and it will call the OnError handler with error code 22 (Invalid argument)
                                 -- return 1 -- This is default behavior
                                 -- return 0 -- Abort the listen request
                                 Dbg:Debug("Server " .. tostring(srv) .. " resolved listening address")
                                 for i = 1, #endpoints do
                                        Dbg:Debug("Available endpoints: [" .. i .. "] ip=" .. endpoints[i].ip .. ":" .. endpoints[i].port)
                                 end
                          end
                    )
                    :OnListen(
                           function(srv, endpoint)
                                 -- Handling this callback is optional.  It merely lets you know that the server is now actually listening.
                                 local addr = srv:GetLocalAddress()
						   C4:UpdateProperty("Server Status", "Server listen success")
                                 Dbg:Debug("Server " .. tostring(srv) .. " chose endpoint " .. endpoint.ip .. ":" .. endpoint.port .. ", listening on " .. addr.ip .. ":" .. addr.port)
                                 if (not calledDone) then
                                        calledDone = true
                                        done(true, addr)
                                 end
                          end
                    )
                    :OnError(
                          function(srv, code, msg, op)
                                 -- code is the system error code (as a number)
                                 -- msg is the error message as a string
                                 Dbg:Debug("Server " .. tostring(srv) .. " Error " .. code .. " (" .. msg .. ")")
						   C4:UpdateProperty("Server Status", "Server error")
                                 if (not calledDone) then
                                        calledDone = true
                                        done(false, msg)
                                 end
                          end
                    )
                    :OnAccept(
                          function(srv, client)
                                 -- srv is the instance C4:CreateTCPServer() returned
                                 -- client is a C4LuaTcpClient instance of the new connection that was just accepted
                                 C4:UpdateProperty("Server Status", "A client accept success")
						   Dbg:Debug("Connection on server " .. tostring(srv) .. " accepted, client: " .. tostring(client))
						   client:ReadUntil(string.char(0xEA))
                                 if (self.clientsCnt >= maxClients) then
                                        client:Write(""):Close(true)
                                        return
                                  end
                                 local info = {}
                                 client:OnRead(
								    function(cli, strData)
										  hexdump(strData, function(s) Dbg:Debug("server:<------ " .. s) end)
										  local pack = Pack.decode(strData)
										  local device = Device:create(pack)
										  if not (pack.head == 0xEC and pack.tail == 0xEA and pack.masterID == tonumber(Properties["masterID"])) then
											 cli:ReadUntil(string.char(0xEA))
											 return
										  end
										  local data = nil
										  if pack.cmd == DEVICE_LOCAL_CONTROL then
											 data = device:handle()
											 if data then
												hexdump(data, function(s) Dbg:Debug("server control:------>" .. s) end)
												self:broadcast(cli , data)
											 end
										  elseif pack.cmd == CMD_SCENE then
											 C4:SetVariable("SCENE_ID", tostring(pack.deviceID))
											 C4:FireEvent("tcp event")
											 data = pack:hex()
											 self:broadcast(cli , data)
										  elseif pack.cmd == CMD_QUERY then
											 data = device:deviceState(tostring(pack.deviceID),pack.deviceType)
											 if data then
												hexdump(data, function(s) Dbg:Debug("server:------>" .. s) end)
												self:broadcast(cli , data)
											 end
											 if pack.deviceType == device.LIGHT then
												data = device:deviceLevel(tostring(pack.deviceID),pack.deviceType)
												hexdump(data, function(s) Dbg:Debug("server:------>" .. s) end)
												self:broadcast(cli , data)
											 end
											 
											 if pack.deviceType == device.AIRCONDITION then
												for _,v in ipairs(device:envData(pack.deviceID,pack.b)) do
												    self:broadcast(cli , v)
												end
											 end

											if pack.deviceType == device.FRESHAIR then
											 data = device:tempreture(pack.deviceID)	
											 self:broadcast(cli , data)
                       data = device:freshState(pack.deviceID)
                       self:broadcast(cli , data)
											end

											if pack.deviceType == device.PM25 then
											 data = device:PM25(pack.deviceID,pack.deviceType)
											 self:broadcast(cli , data)
											end
											 
											 if pack.deviceType == device.TV or pack.deviceType == device.DVD or pack.deviceType == device.BGMUSIC then
												data = device:volume(tostring(pack.deviceID),pack.deviceType)
												self:broadcast(cli , data)
											 end
											 
											 if pack.deviceType == device.BGMUSIC then
												data = device:isPlaying(pack.deviceID,pack.deviceType)
												self:broadcast(cli , data)
											 end
										  elseif pack.cmd == MASTER_AUTH then
											 if pack.masterID == tonumber(Properties["masterID"]) then
												self.clients[client] = info
												self.clientsCnt = self.clientsCnt + 1
												data = Pack:create(pack.cmd,pack.masterID,0x41):hex()
											 else
												data = Pack:create(pack.cmd,pack.masterID,0x40):hex()
											 end
											 hexdump(data, function(s) Dbg:Debug("server:------>" .. s) end)
											 cli:Write(data)
										  elseif pack.cmd == MASTER_BEAT then
											 if pack.masterID == tonumber(Properties["masterID"]) then
												data = Pack:create(MASTER_BEAT_ANSWER,pack.masterID):hex()
											 
												hexdump(data, function(s) Dbg:Debug("server:------>" .. s) end)
												cli:Write(data)
											 end
										  elseif pack.cmd == CMD_SCHEDULE then
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
										  cli:ReadUntil(string.char(0xEA))
								    end
                                        )
                                        :OnWrite(
                                               function(cli)
                                                      -- cli is the C4LuaTcpClient instance (same as client in the OnAccept handler).  This callback is called when
                                                      -- all data was sent.
                                                      Dbg:Debug("Server " .. tostring(srv) .. " Client " .. tostring(client) .. " Data was sent.")
                                               end
                                        )
                                        :OnDisconnect(
                                               function(cli, errCode, errMsg)
                                                      -- cli is the C4LuaTcpClient instance (same as client in the OnAccept handler) that the data was read on
                                                      -- errCode is the system error code (as a number).  On a graceful disconnect, this value is 0.
                                                      -- errMsg is the error message as a string.
                                                      if (errCode == 0) then
                                                             Dbg:Debug("Server " .. tostring(srv) .. " Client " .. tostring(client) .. " Disconnected gracefully.")
                                                      else
                                                             Dbg:Debug("Server " .. tostring(srv) .. " Client " .. tostring(client) .. " Disconnected with error " .. errCode .. " (" .. errMsg .. ")")
                                                      end
                                                      self.clients[cli] = nil
                                                      self.clientsCnt = self.clientsCnt - 1
                                               end
                                        )
                                        :OnError(
                                               function(cli, code, msg, op)
                                                      -- cli is the C4LuaTcpClient instance (same as client in the OnAccept handler) that the data was read on
                                                      -- code is the system error code (as a number)
                                                      -- msg is the error message as a string
                                                      -- op indicates what type of operation failed: "read", "write"
                                                      Dbg:Debug("Server " .. tostring(srv) .. " Client " .. tostring(client) .. " Error " .. code .. " (" .. msg .. ") on " .. (op or ""))
                                               end
                                        )
                                        :Write("")
                                        :ReadUntil("\r\n")
                          end
                    )
                    :Listen(bindAddr, port)
             if (self.socket ~= nil) then
                    return self
             end
      end
}

-- Start the server with a limit of 5 concurrent connections, listen on all interfaces on a randomly available port.  The server will shut down after 10 minutes.
function tcpServer()
    server:start(10, "*", SERVER_PORT, function(success, info)
		if (success) then
			  Dbg:Debug("Server listening on " .. info.ip .. ":" .. info.port)
		else
			  Dbg:Debug("Could not start server: " .. info)
		end
    end)
    return server
end