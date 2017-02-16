SERVER_PORT = 8009

local server = {
      clients = {},
      clientsCnt = 0,
      --socket = nil,
      notifyOthers = function(self, client, message)
             for cli,info in pairs(self.clients) do
                    if (cli ~= client and info.name ~= nil) then
                          cli:Write(message .. "\r\n")
                    end
             end
      end,
      broadcast = function(self, client, message)
             local info = self.clients[client]
             print("broadcast for client " .. tostring(client) .. " info: " ..tostring(info))
             if (info ~= nil and info.name ~= nil) then
                    self:notifyOthers(client, info.name .. " wrote: " .. message .. "\r\n")
                    client:Write("You wrote: " .. message .. "\r\n")
             end
      end,
      haveName = function(self, name)
             for _,info in pairs(self.clients) do
                    if (info.name ~= nil and string.lower(info.name) == string.lower(name)) then
                          return true
                    end
             end
             return false
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
                          print("Disconnecting " .. cli:GetRemoteAddress().ip .. ":" .. cli:GetRemoteAddress().port .. ": name: " .. tostring(info.name))
                          cli:Write("Server is shutting down!\r\n"):Close(true)
                    end
             end
      end,
      start = function(self, maxClients, bindAddr, port, done)
             local calledDone = false
             self.socket = C4:CreateTCPServer()
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
                                 print("Server " .. tostring(srv) .. " resolved listening address")
                                 for i = 1, #endpoints do
                                        print("Available endpoints: [" .. i .. "] ip=" .. endpoints[i].ip .. ":" .. endpoints[i].port)
                                 end
                          end
                    )
                    :OnListen(
                           function(srv, endpoint)
                                 -- Handling this callback is optional.  It merely lets you know that the server is now actually listening.
                                 local addr = srv:GetLocalAddress()
                                 print("Server " .. tostring(srv) .. " chose endpoint " .. endpoint.ip .. ":" .. endpoint.port .. ", listening on " .. addr.ip .. ":" .. addr.port)
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
                                 print("Server " .. tostring(srv) .. " Error " .. code .. " (" .. msg .. ")")
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
                                 print("Connection on server " .. tostring(srv) .. " accepted, client: " .. tostring(client))
                                 if (self.clientsCnt >= maxClients) then
                                        client:Write("Sorry, I only allow " .. maxClients .. " concurrent connections!\r\n"):Close(true)
                                        return
                                  end
                                 local info = {}
                                 self.clients[client] = info
                                 self.clientsCnt = self.clientsCnt + 1
                                 client:OnRead(
                                              function(cli, data)
                                                      -- cli is the C4LuaTcpClient instance (same as client in the OnAccept handler) that the data was read on
                                                      if (string.sub(data, -2) == "\r\n") then
                                                             -- Need to check if the delimiter exists.  It may not if the client sent data without one and then disconnected!
                                                             data = string.sub(data, 1, -3) -- Cut off \r\n
                                                      end
                                                      data = self:stripControlCharacters(data)
                                                      if (info.name == nil) then
                                                             if (#data > 0) then
                                                                    if (self:haveName(data)) then
                                                                          cli:Write("Choose a different name, please:\r\n")
                                                                    else
                                                                          info.name = data
                                                                          self:notifyOthers(cli, info.name .. " joined!\r\n")
                                                                          cli:Write("Thank you, " .. info.name .. "! Type 'quit' to disconnect.\r\n")
                                                                    end
                                                             else
                                                                    cli:Write("Please enter your name:\r\n")
                                                             end
                                                             cli:ReadUntil("\r\n")
                                                      elseif (data == "quit") then
                                                             cli:Write("Goodbye, " .. info.name .. "!\r\n"):Close(true)
                                                      else
                                                             if (#data > 0) then
                                                                    self:broadcast(cli, data)
                                                             end
                                                             cli:ReadUntil("\r\n")
                                                      end
                                               end
                                        )
                                        :OnWrite(
                                               function(cli)
                                                      -- cli is the C4LuaTcpClient instance (same as client in the OnAccept handler).  This callback is called when
                                                      -- all data was sent.
                                                      print("Server " .. tostring(srv) .. " Client " .. tostring(client) .. " Data was sent.")
                                               end
                                        )
                                        :OnDisconnect(
                                               function(cli, errCode, errMsg)
                                                      -- cli is the C4LuaTcpClient instance (same as client in the OnAccept handler) that the data was read on
                                                      -- errCode is the system error code (as a number).  On a graceful disconnect, this value is 0.
                                                      -- errMsg is the error message as a string.
                                                      if (errCode == 0) then
                                                             print("Server " .. tostring(srv) .. " Client " .. tostring(client) .. " Disconnected gracefully.")
                                                      else
                                                             print("Server " .. tostring(srv) .. " Client " .. tostring(client) .. " Disconnected with error " .. errCode .. " (" .. errMsg .. ")")
                                                      end
                                                      if (info.name ~= nil) then
                                                             self:notifyOthers(cli, info.name .. " disconnected!\r\n")
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
                                                      print("Server " .. tostring(srv) .. " Client " .. tostring(client) .. " Error " .. code .. " (" .. msg .. ") on " .. op)
                                               end
                                        )
                                        :Write("Welcome! Please enter your name:\r\n")
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
			  local minutes = 10
			  print("Server listening on " .. info.ip .. ":" .. info.port .. ". Will stop in " .. minutes .. " minutes!")
			  C4:SetTimer(minutes * 60 * 1000, function()
				    print("Stopping server and disconnecting clients now.")
				    server:stop()
			  end)
		else
			  print("Could not start server: " .. info)
		end
    end)
end