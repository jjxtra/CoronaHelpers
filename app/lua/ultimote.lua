--[[
Corona® Ultimote v 1.42
--fixed group nesting problem
--fixed tap problem
--added google earth feature
--fixed hidden box/hittestable problem
Author: M.Y. Developers
Copyright (C) 2011 M.Y. Developers All Rights Reserved
Support: mydevelopergames@gmail.com
Website: http://www.mygamedevelopers.com/Corona-Ultimote.html
License: Many hours of genuine hard work have gone into this project and we kindly ask you not to redistribute or illegally sell this package. If you
have not purchased the companion Android/iOS app then you must use this work for evaluation purposes only and you may not use the given macros for debugging your own
commercial or free projects. You are not allowed to reverse engineer any protocols specified by this work or produce an app of your own that interfaces with this program.
We are constantly developing this software to provide you with a better development experience and any suggestions are welcome. Thanks for you support.

-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.
--]]
module (..., package.seeall)
local function createClient()
--[[
Corona® AutoLAN v 1.2
Author: M.Y. Developers
Copyright (C) 2011 M.Y. Developers All Rights Reserved
Support: mydevelopergames@gmail.com
Website: http://www.mygamedevelopers.com/Corona--Profiler.html
License: Many hours of genuine hard work have gone into this project and we kindly ask you not to redistribute or illegally sell this package. 
We are constantly developing this software to provide you with a better development experience and any suggestions are welcome. Thanks for you support.

-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.
--]]

local socket = require "socket"
local json = require "json"
local multiplayer = {}
local applicationName = "Default"

local client = {} --master object

----------------
--common client/server --takes care of the send queue/priority system
local circularBufferSize = 100
local bufferIndexLow = 1
local bufferIndexLowSend = 1 --last index looked at by send routine
local bufferIndexHigh = 1
local bufferIndexHighSend = 1 --last index looked at by send routine
local sendQueueLow = {} --will be a circular buffer
local sendQueueHigh = {} --will be an associative array
local sendQueueHighCallbacks = {}
local fileQueue = {}
local pendingFiles = {}
local fileQueueNumber = 0
local packetSize = 2000 ---in bytes
local myClientID
local connected = false
local onUpdate
local handshake


----------------
--UDP packet types
--type 1 = initial handshake, create a client object on server

------------client code
local broadcastListener
local listenTime = 1000
local scanTime = 30000
local timers = {}
local availibleServers = {} --key = ip, value = port
local serverIP,serverPort
local myIP,myPort
local handshakeTable = {"CoronaMultiplayer", applicationName}
local broadcastTime = 1000 --in ms, frequency to send broadcast for network discovery
local connectionTimeout = 2000
local connectionAttemptTime = 100
local networkRate = 30 --main loop
local UDPClient, HandshakeClient, tempClient
local HighPriorityRecieved = {0}
local numHighPriorityRecieved = 0
local HighPriorityCounters = {}
local HighPriorityCount = 50 --num cycles to wait before resending
--------hearbeat time
local heartbeatTime = 40
local timeoutPeriod = 500
local timeoutsLeft = timeoutPeriod
local heartbeatTimer = heartbeatTime --called every x frames nothing was sent to maintain connection
local numMessagesRecieved = 0 --keeps track of how many acks to send for flow control

--------flow control

local maxCredits = 9999 --num packets to send before waiting for a reply
local sendCredits = 1000 --each time we send one, we deduct a credit, each ACK we add credit
local rechargeRate = 500 --in ms
local rechargeAmount = 10 --if no response by rechargeRate then slowly fill up credits

------internet------------------------------------------------------------------------------------
local peerIP,  peerPort = socket.dns.toip("rijl-al-awwa.dreamhost.com"), 54613
local matchmakerTCPclient, pendingConnection

local function send(input, priority, listener) --adds to send buffer and assigns priority
	if(priority == 1) then
			if(UDPClient) then
				print ("sending interface")
				heartbeatTimer = heartbeatTime 
				local packetTemplate = {}
				packetTemplate[1] = input --payload
				packetTemplate[2] ={1,numMessagesRecieved} --flow control/acks
				packetTemplate[3] = HighPriorityRecieved --high priority acks	
				numHighPriorityRecieved = 0 			
				HighPriorityRecieved = {0}					
				numMessagesRecieved = 0
				UDPClient:send( json.encode(packetTemplate) ) --send data entry
				sendCredits = sendCredits-1
			end


			
	else
		--high priority
		sendQueueHighCallbacks[bufferIndexHigh] = listener			
	--		numMessagesRecieved = 0
	--		heartbeatTimer = heartbeatTime 
			if(UDPClient) then
				local packetTemplate = {}
				packetTemplate[1] = input --payload
				packetTemplate[2] ={2,numMessagesRecieved,bufferIndexHigh} -- control/acks
				packetTemplate[3] = HighPriorityRecieved --high priority acks	
				numHighPriorityRecieved = 0 	
				numMessagesRecieved = 0		
				HighPriorityRecieved = {0}	
				HighPriorityCounters[bufferIndexHigh] = HighPriorityCount --controls when to resend
				sendQueueHigh[bufferIndexHigh] = packetTemplate
				UDPClient:send( json.encode(packetTemplate) ) --send data entry
				sendCredits = sendCredits-1
				bufferIndexHigh = bufferIndexHigh+1	
					if(bufferIndexHigh == circularBufferSize) then
						bufferIndexHigh = 1 --wrap
					end	

			end		
		
			
	end
end

local function sendFile(filename, path, destFile)
	path = (system.pathForFile(filename, path))
	filename = destFile or filename
	local file = io.open(path, "rb")
	if(file) then
		
		fileQueueNumber = fileQueueNumber+1
		local fileTable = {}
		fileTable = {}
		fileTable.file = file
		local fileSize = file:seek("end")
		fileTable.filename = filename
		fileTable.size = fileSize
		fileTable.numPackets = math.ceil(fileSize/packetSize)
		fileTable.currentPacket = 1 --must send number of packets in case out of order
		fileQueue[fileQueueNumber] = fileTable
		file:seek("set",0) -- reset to beginning of file
	end
end

local function addCredits(credit)
	sendCredits = sendCredits+credit
	if(sendCredits > maxCredits) then
		sendCredits = maxCredits
	end
end

------------

local function failedConnection()
	timer.cancel(timers.connectionAttempt)
	timers.connectionAttempt = nil
	------print("connection attempt failed")
	Runtime:dispatchEvent({name = "autolanConnectionFailed", serverIP = serverIP})
end

local function receive()
	if(UDPClient) then
		
		local message, error = UDPClient:receive()

		local noError = false
		while(message) do
		--print("message", message)
		noError = true

			numMessagesRecieved = numMessagesRecieved+1
			----print(#message,numMessagesRecieved)
			message = json.decode(message)
		if(message[1] == "e" or message[1] == "c") then
			return
		end
		if(message[2][1]==2) then
				--high priority,record ack to send
				numHighPriorityRecieved = numHighPriorityRecieved+1
				HighPriorityRecieved[numHighPriorityRecieved] = message[2][3] --log to send ack in a future packet (pooling)
			else
				--low priority, dont send ack
				--------print(json.encode(message[3]))
			end
			
			if(message[3][1] ~= 0) then --contains a high priorit ack
				local acks = message[3]
				--contain high priority acks
				for i=1,#acks do
					local ack = acks[i]
					sendQueueHigh[ack] = nil
					HighPriorityCounters[ack] = nil
					if(sendQueueHighCallbacks[ack]) then
						sendQueueHighCallbacks[ack]({phase = "complete"})
					end
				end
			end
			--------print("credits", sendCredits,message[2][2])					
			addCredits(message[2][2])	

			-------------------on top of transport layer, figure out message type
			local userMessage = message[1]
	
			if(userMessage[1]==2) then --file transfer
				------print(userMessage[1],userMessage[2],userMessage[3],userMessage[4], #userMessage[5])		
				--write file
				local filename = userMessage[2]
			
				if(pendingFiles[filename]==nil) then
					pendingFile = {}
					pendingFile.file = io.open(system.pathForFile(userMessage[2],system.DocumentsDirectory),"wb")
					pendingFile.recieved = {}
					pendingFile.buffer = {}
					pendingFile.index = 1 --file position
					pendingFiles[filename] = pendingFile
				end
				local pendingFile = pendingFiles[filename]		
				local packetindex = userMessage[3]
				pendingFile.recieved[packetindex] = 1 --1 = recieved but not written, 2 = written, nil = not rec.
				pendingFile.buffer[packetindex] = userMessage[5]
				local currentBuffer = pendingFile.buffer[pendingFile.index]
				while(currentBuffer ~= nil) do --if we reiceve packets out of order wait ultil we have a writable chunk
					------print("writing",pendingFile.index)
					pendingFile.file:write(currentBuffer)
					currentBuffer = nil
					pendingFile.index = pendingFile.index+1
					currentBuffer = pendingFile.buffer[pendingFile.index]
				end
				if(pendingFile.index == userMessage[4]+1) then
					--file transfer finished, trigger event
					------print("FILE DONE")
					Runtime:dispatchEvent({name = "autolanFileReceived", filename = filename})
					pendingFile.file:close()
					pendingFiles[filename]	 = nil
				end
			elseif userMessage[1]==1 then
				--print("client recieved")
				Runtime:dispatchEvent({name = "autolanReceived",  message = userMessage[2]})	
			end
			
			message, error = UDPClient:receive()
			
		end
		if error and not noError then
				if error == "timeout" then
					timeoutsLeft = timeoutsLeft-1 --clients responsibility to send alive packets
					if(timeoutsLeft == 0) then
						--this connection has timed out so kill it
						UDPClient:close()
						UDPClient = nil
						Runtime:dispatchEvent({name = "autolanDisconnected",  serverIP = serverIP, message = "timeout"})				
					end
				elseif error == "closed" then
					Runtime:dispatchEvent({name = "autolanDisconnected",  serverIP = serverIP, message = "closed"})					
					UDPClient:close()
					UDPClient = nil
					------print("closed")
				end
		else
			timeoutsLeft = timeoutPeriod --reset timeouts
		end
		
		
	end
end
local function mainLoop()		
	if(sendCredits >0) then
			local fileTable = fileQueue[1] --only send 1 file at a time, send the first in fifo
			--get the datagram data
			if(fileTable) then
				local data = fileTable.file:read(packetSize)
				local sendPacket = {2,fileTable.filename, fileTable.currentPacket, fileTable.numPackets, data} --first entry (high level) is type of packet 1 = user, 2 = file, 3=command
				fileTable.currentPacket = fileTable.currentPacket+1
				if(data) then
					send(sendPacket,2)

				else
					--end of file
					table.remove(fileQueue,1)
					fileQueueNumber = fileQueueNumber-1
				end
			end
		for i,packet  in pairs(sendQueueHigh) do
			local count = HighPriorityCounters[i]
			if(UDPClient) then
				if(count) then
					if(count == 0) then
						HighPriorityCounters[i] = HighPriorityCount
						--resend packet
						packet[2][2]  = numMessagesRecieved -- control/acks
						packet[3] = HighPriorityRecieved --high priority acks						
						UDPClient:send( json.encode(packetTemplate) ) --send data entry
						sendCredits = sendCredits-1
					else
						HighPriorityCounters[i] = count - 1
					end
				end
			else
				--client dead, ACK
				sendQueueHigh[i] = nil
				HighPriorityCounters[i] = nil	
				if(sendQueueHighCallbacks[i]) then
					sendQueueHighCallbacks[i]({phase = "cancelled"})
				end					
			end
		end
	end
	---sending complete, recieve
	--heartbeat to send periodically a packet to ensure connection is alive
	if(heartbeatTimer==0) then
		if(UDPClient) then
			local packetTemplate = {}
			packetTemplate[1] = {0} --payload
			packetTemplate[2] ={0,numMessagesRecieved} --flow control/acks
			packetTemplate[3] = HighPriorityRecieved --high priority acks	
			numHighPriorityRecieved = 0 			
			HighPriorityRecieved = {0}			
			numMessagesRecieved = 0
			UDPClient:send( json.encode(packetTemplate) ) --send data entry
		end			
			heartbeatTimer = heartbeatTime		
	end
	heartbeatTimer = heartbeatTimer-1	
end
local sendPhase = true 

local function connectToServer()
	if(timers.failedToConnect == nil) then
		----print("create timers")
		timers.failedToConnect = timer.performWithDelay(connectionTimeout,failedConnection)--stop handshaking and fail
		timers.connectionAttempt = timer.performWithDelay(connectionAttemptTime,connectToServer,-1)--try to handshake
	end
	if(HandshakeClient == nil) then
		----print("creating handshake client")
		HandshakeClient = socket.udp()
		HandshakeClient:setsockname("*", 0) --bind on any availible port and localserver ip address.
		HandshakeClient:settimeout(0)
		tempClient = socket.udp() --need a temp client b/c loop is still running
		tempClient:setsockname("*", 0) --bind on any availible port and localserver ip address.
		tempClient:settimeout(0)		
		myIP, myPort = tempClient:getsockname()	
		handshakeTable[3] = myPort
		handshake = json.encode(handshakeTable)
	end
	--send a handshake packet telling the server to create a connection for us/ alternate b/w send and recieve
		HandshakeClient:sendto(handshake,serverIP,serverPort)
		--recieve a confirmation packet telling us all is good for transmission
		local message = HandshakeClient:receive()
		----print("handshake", message)
		while(message) do
			--------print("recieved broadcast,", message)	
			message = json.decode(message)
			if(message) then
				if(message[1] and message[1]=="CoronaMultiplayer" and message[2] == applicationName) then --this is the protocol id				
								
					HandshakeClient:close()		
					HandshakeClient	= nil
					

					tempClient:setpeername(serverIP, message[4])
					UDPClient,tempClient = 	tempClient,nil
					if(timers.connectionAttempt) then
					timer.cancel(timers.connectionAttempt)
					timers.connectionAttempt = nil
					end
					if(timers.failedToConnect) then
					timer.cancel(timers.failedToConnect)
					timers.failedToConnect = nil
					end
					myClientID = message[5]
					------print("Connected!",serverIP, message[4]) --this is where we fire off connected event
					if(availibleServers[serverIP]) then
						Runtime:dispatchEvent({name = "autolanConnected",  myClientID = myClientID, serverIP = serverIP, customBroadcast = availibleServers[serverIP].customBroadcast})					
					else
						Runtime:dispatchEvent({name = "autolanConnected",  myClientID = myClientID, serverIP = serverIP, customBroadcast = {}})					
					end
					timeoutsLeft = timeoutPeriod
					--timer.performWithDelay(500,sendtest,-1)
					break
				end
			end
			message = HandshakeClient:receive()
		end		
end



local function stopListening() --we cant just listen forever or else we will have a huge buffer
	if(timers.scanTimer) then
		timer.cancel(timers.scanTimer)
		timers.scanTimer = nil
		if(broadcastListener) then
		broadcastListener:close()
		broadcastListener = nil
		end
		--here is where we would call the done scanning event listener
		----print("done scanning.")
		Runtime:dispatchEvent({name = "autolanDoneScanning",  servers = availibleServers})
	else
		------print("already not scanning...")
	end	
end

local function UDPBroadcastListen()
	if(broadcastListener) then
		local broadcastMessage, serverIP, serverPort 
		broadcastMessage,serverIP,serverPort = broadcastListener:receivefrom()
		local packets = 1
		while(broadcastMessage and type(broadcastMessage)=="string") do	
			packets = packets+1
			broadcastMessage = json.decode(broadcastMessage)
			if(broadcastMessage) then
				if(broadcastMessage[1] and broadcastMessage[1]=="CoronaMultiplayer" and broadcastMessage[2]==applicationName) then --this is the protocol id				
					if(availibleServers[serverIP] == nil) then
						availibleServers[serverIP] = {name = broadcastMessage[3], broadcastPort = serverPort, port = serverPort, customBroadcast = broadcastMessage[5]}
						Runtime:dispatchEvent({name = "autolanServerFound",  serverIP = serverIP, port = serverPort, customBroadcast = broadcastMessage[5], serverName = broadcastMessage[3]})				
						------print("found server adding...") --this is where we fire off server found event					
					end				
				end
			end
			if(broadcastListener) then
				broadcastMessage = nil
				broadcastMessage,serverIP,serverPort = broadcastListener:receivefrom()
			end
		end
	end
end

local function scanServers(scanTime)
	if(scanTimer) then
		------print("already scanning...")
	else
		if(broadcastListener==nil) then
			broadcastListener = socket.udp()
			broadcastListener:setsockname("*", 8080)
			broadcastListener:settimeout(0)
		end
		availibleServers = {}
		timers.scanTimer = timer.performWithDelay(listenTime,UDPBroadcastListen,-1)
			if(scanTime) then
				timers.scanStopTimer = timer.performWithDelay(scanTime,stopListening) --only scan for a certian amount of time and then stop and report what servers were found
			end
		end
end

local currentServer
local function connectToServerInternet()
	if(timers.scanTimerInternet) then
		timer.cancel(timers.scanTimerInternet)
		timers.scanTimerInternet = nil
		timers.connectTimerInternet = timer.performWithDelay(listenTime,connectToServerInternet,-1)
	end	
	if(pendingConnection == nil) then
		local udpclient = socket.udp()
		udpclient:setsockname("*", 0) --bind on any availible port and localserver ip address.
		udpclient:settimeout(0)	
		pendingConnection = udpclient
	end
--assumes a valid pending connection is established
	--print("establish connection")
	if(pendingConnection) then
		--print("internet Handshake at", serverIP)
		pendingConnection:sendto(json.encode{"CoronaAutoInternet",applicationName,"cc",serverIP},peerIP, peerPort+1) --send to server saying I am ready to connect, tell server to create socket, send the server(tcp) ip and port
		local msg,ip,port = pendingConnection:receivefrom()
		while(msg) do
		--print("udp", msg)
			local decoded = json.decode(msg)
			if(decoded and decoded[1]=="c") then
				pendingConnection:sendto(json.encode{"e"},decoded[2], decoded[3])		
			elseif(decoded and decoded[1]=="e") then
				--connection established event
				Runtime:dispatchEvent({name = "autolanConnected",  myClientID = decoded[1], serverIP = ip, customBroadcast = availibleServers[serverIP].customBroadcast})
				pendingConnection:setpeername(ip,port)
				UDPClient = pendingConnection
				pendingConnection = nil
				timer.cancel(timers.connectTimerInternet)
				timers.connectTimerInternet = nil
				return
			end
			msg,ip,port = pendingConnection:receivefrom()
		end
	end

	--print("sending", currentServer[1], currentServer[2])

		
end
-------------------------------------------INTERNET----------------------------------------------------
local function MatchmakerServerListen() --listens for a reponse from the matchmaker AND for response fromserverUDP

	local msg = matchmakerTCPclient:receive("*l")
	if(msg) then
		--print(msg)
		--resolve message type for the tcp it is only a list of servers.
		local decoded = json.decode(msg)
		if(decoded) then
			if(decoded[1] == "l") then
				--send connect request to matchmaker to send request to server for new sock
				for i=1,#decoded[2] do
					--add each to list
					currentServer = decoded[2][i]
					--print(currentServer[1].." added")
					local serverIP = currentServer[1]..currentServer[2] --this is the key we refer the internet server by
					availibleServers[serverIP] = {name = currentServer[2], port = currentServer[2], customBroadcast = currentServer[2], internet = true}
					Runtime:dispatchEvent({name = "autolanServerFound",  serverIP = serverIP, port = currentServer[2], customBroadcast = currentServer[4], serverName = currentServer[3], internet = true})				
				end			
			end
		end
	end
end
------------------------------------------INTERNET----------------------------------------------------

function client:scanServersInternet(scanTime)
	scanServers()
	--open a TCP connection to the matchmaking server
	matchmakerTCPclient = socket.tcp()
	matchmakerTCPclient:settimeout(1) --this is the only blocking operation	
	local err = matchmakerTCPclient:connect(peerIP, peerPort) --bind on any availible port and localserver ip address.
	--print(err)
	if(err==nil) then
		--print("server timeout")
		return
	end
	matchmakerTCPclient:send(json.encode({"CoronaAutoInternet",applicationName,"c"}).."\n") --send client token
	matchmakerTCPclient:settimeout(0)
	timers.scanTimerInternet = timer.performWithDelay(listenTime,MatchmakerServerListen,-1)
end

-------------------------------------------INTERNET----------------------------------------------------


function client:setOptions(params)
	broadcastTime = params.broadcastTime or broadcastTime
	customBroadcast = params.customBroadcast or customBroadcast
	networkRate = params.networkRate or networkRate --feqnuency to run network loop
	connectTime = params.connectTime or connectTime --frequency to look for new clients
	timeoutTime = params.timeoutTime or timeoutTime --number of cycles to wait before client is DC
	maxCredits = params.maxCredits or maxCredits --number of packets to send w/o ACK
	rechargeRate = params.rechargeRate or rechargeRate --time to recharge credits
	rechargeAmount = params.rechargeAmount or rechargeAmount --time to recharge credits
	circularBufferSize = params.circularBufferSize or circularBufferSize --max number of elements in circular buffer, 2^n
	packetSize = params.packetSize or packetSize
	onUpdate = params.onUpdate or onUpdate
end
function client:stop()
	for i,t in pairs(timers) do
		timer.cancel(t)
		t = nil
	end
end
function client:send(message)
	send({1,message}, 1)
end
function client:sendPriority(message, params)
	params = params or {}
	send({1,message}, 2, params.callback)
end
function client:sendFile(filename, path, destFile)
	sendFile(filename, path, destFile)
end
function client:start()
timers.recharge = timer.performWithDelay(rechargeRate, function() addCredits(rechargeAmount) end)
timers.mainLoop = timer.performWithDelay(networkRate,mainLoop,-1)
--Runtime:addEventListener("enterFrame", mainLoop)
timers.receive = timer.performWithDelay(1,receive,-1)
end
function client:scanServers()
	scanServers()
end
client.RTT = nil
local RTTTime
local sendPing
local function pingListener(e)
	if(e.phase == "began") then
		RTTTime = system.getTimer()
	elseif(e.phase == "complete") then
		client.RTT = system.getTimer() - RTTTime
		--print("pingACK",client.RTT)
		sendPing()
	else

	end
end
sendPing = function ()
	send({3,0}, 2, pingListener )	
end
function client:autoRTT()
	--send a high priority message to the server and figure out how long it takes
	sendPing()
	
end
function client:connect(ip)
	--
	stopListening()
	if(availibleServers[ip]) then
	serverIP,serverPort = ip,availibleServers[ip].port or 62123
		if(availibleServers[ip].internet) then
			connectToServerInternet()
		else
			connectToServer()
		end
	else
	serverIP,serverPort = ip,62123
	connectToServer()
	end

	--stopListening()
end	
local function autoConnectListener(e)
	
	--print(e.serverIP)
	client:connect(e.serverIP)
	Runtime:removeEventListener("autolanServerFound",autoConnectListener)
end

function client:autoConnect()
	Runtime:addEventListener("autolanServerFound",autoConnectListener)
	scanServers()
end
function client:disconnect()
	--this connection has timed out so kill it
	if(UDPClient) then
		UDPClient:close()
		UDPClient = nil
		Runtime:dispatchEvent({name = "autolanDisconnected",  serverIP = serverIP,  message = "user disconnect"})	
	end
end
function client:stopScanning()
	stopListening()
end
function client:setMatchmakerURL(url,port)
	peerIP,  peerPort = socket.dns.toip(url),port
end
return client
end
--------------START ULTIMOTE IMPLEMENTATION------

local _H = display.contentHeight 
local _W = display.contentWidth
local clientH,clientW = _H,_W
local socket = require "socket"
local json = require("json")
local connectToDevice = false
local registeredEvents =  {}
local macroFilesRecord = {}
local eventsToRecord = {}
local macroFilesPlay = {}
local options = {}
local objects = {}
local frames = {}
local focusTable = {}
local state = {}
state.system = {}
local deviceInfo = nil
local currentTouchID,tcpClientMessage,payload,sendMessage,sendImages,tcpServer,myIP,myPort,broadcast,orientationMatch,allMacros,connectedToDevice,playingMacro
local imagesSent = {}
local macrosOnDevice = {}
local xScale, yScale = 1,1 --scale of the screen based on the device
--replace display.getcurrentstage to enable setfocus to work over network
displayNet = {}


local function debugPrint(...)
	if not options.noDebug then
		print(unpack(arg))
	end
end

------------------------------------Options save/load
local path = system.pathForFile(  "UltimoteOptions.txt", system.DocumentsDirectory )
local file = io.open( path, "r" )
if file then
		-- read all contents of file into a string 
		local contents = file:read( "*a" ) 
		options = json.decode(contents);
		io.close( file )	
else

	options.noDebug  = false 
	options.overrideSystem = true
	options.sendAllObjects = false	
	options.noUDPBroadcast = false
	options.fps = 30
end	

local function SaveState(event)
	if( event.type ~= "applicationStart" ) then
        local path = system.pathForFile( "UltimoteOptions.txt", system.DocumentsDirectory )
        
        -- create file b/c it doesn't exist yet 
        local file = io.open( path, "w" ) 
 
        if file then
                file:write( json.encode(options) ) 
                io.close( file )
        end	
	end
end
local function SaveStateNow()
        local path = system.pathForFile( "UltimoteOptions.txt", system.DocumentsDirectory )
        
        -- create file b/c it doesn't exist yet 
        local file = io.open( path, "w" ) 
 
        if file then
                file:write( json.encode(options) ) 
                io.close( file )
        end	
end

Runtime:addEventListener( "system", SaveState );

display.getCurrentStageNative = display.getCurrentStage
display.setFocusNative =  display.getCurrentStage().setFocus
---[[
display.getCurrentStage = function()
	local stage = display.getCurrentStageNative()
	---[[
	function stage:setFocus(object, id)
	---[[
	--	self:setFocusNative(object, id)
		if id then
			focusTable[id] = object
			return display.setFocusNative(self, object, id)
		else
			if(currentTouchID) then
				focusTable[currentTouchID] = object		
			end
			return display.setFocusNative(self, object)
		end


		--]]
	end--]]
	return stage
end--]]
--re
function registerEvents (events)
	state.system.registerEvents = events
	registeredEvents = events
end
local function overrideSystem() 
system.hasEventSource = function()
	return true
end

--place acceleration intervels and stuff to go to device
local oldOpenURL = system.openURL
system.openURL = function( url )
	if(connectedToDevice) then
	state.system.openURL = url
	else
	oldOpenURL(url)
	end
end

system.setAccelerometerInterval = function ( frequency )

	state.system.setAccelerometerInterval = frequency
end
system.setGyroscopeInterval = function ( frequency )

	state.system.setGyroscopeInterval = frequency
end

system.setIdleTimer = function ( enabled )
	state.system.setIdleTimer = enabled
end
system.setLocationAccuracy = function ( distance )
	state.system.setLocationAccuracy = distance
end
system.setLocationThreshold = function ( distance )
	state.system.setLocationThreshold = distance
end
system.vibrate = function (  )
	state.system.vibrate = true
end

system.getInfoNative = system.getInfo
system.getInfo = function(param)
	if(options.deviceInfo and options.deviceInfo.getInfo ~= nil and options.deviceInfo.getInfo[param] ~= nil) then
		return options.deviceInfo.getInfo[param]
	else
		return system.getInfoNative(param)
	end
end
system.getPreference = function(category,name)
	return deviceInfo.getPreference[category][name]
end
end
if(options.overrideSystem) then
	overrideSystem() 
end


--first time lets set the timeout high to allow device to connect so all the deviceInfo is right from the start

local function setScreenSize(payload)
	if(payload.screenHeight) then
		clientH = payload.screenHeight
		clientW = payload.screenWidth
	end
	_H = display.contentHeight 
	_W = display.contentWidth

	local serverPortrait = _H>_W
	local clientPortrait =  clientH>clientW
	if(serverPortrait == clientPortrait) then
		orientationMatch = true
			
	else
		orientationMatch = false
	
	end
		yScale = clientH/_H
		xScale = clientW/_W 
end
Runtime:addEventListener("orientation", setScreenSize)
local circles = {}
local function drawTouchCirle(e)
	if(e.phase == "began") then
		circles[e.id] = display.newCircle(e.x,e.y,20)
		circles[e.id]:setFillColor(math.random(155)+100, math.random(155)+100, math.random(155)+100)
		transition.from(circles[e.id], {time = 500, xScale = 0.001, yScale = 0.001, transition = easing.outExpo})
	elseif(e.phase == "moved") then
		if(circles[e.id]) then
		circles[e.id].x, circles[e.id].y = e.x,e.y
		end
	elseif(e.phase == "ended" or e.phase == "cancelled") then
		display.remove(circles[e.id])
	end	
end

local function expandGroup(object, objectTable)
	if(object.numChildren and object.numChildren>0) then
		for j = object.numChildren, 1,-1 do
			objectTable[#objectTable+1] = object
			expandGroup(object[j],objectTable)
		end				
	else
		objectTable[#objectTable+1] = object
	end
end
local function scaleEvents(payload)--so that we can account for screen resolution differences
	local events = payload.events
		if(events) then

			for i = 1, #events do

				local event = events[i]
				
				if(event.name:find("touch") or event.name:find("tap")) then
					event.x, event.y = event.x/xScale, event.y/yScale
				end
				
			end
	end
end
local tapDetector = {}
local function dispatchEvents(payload)
	local stage =  display.getCurrentStageNative()
	objects = {}
	expandGroup(stage,objects)


	local events = payload.events
	if(events) then

	--tap generator, temporary code
	--tap generator, temporary code
	
	for i = 1, #events do
		
		local event = events[i]
		if(event.name:find("touch") or event.name:find("tap")) then
	
				currentTouchID = event.id
			if(tapDetector[currentTouchID] == nil) then
				tapDetector [currentTouchID]= {event.x, event.y}
			end
			if(event.phase == "ended" and event.name:find("touch") ) then
				--see if the same location
				local tapDetect = tapDetector[currentTouchID]
				local diffX, diffY = math.abs(tapDetect[1] - event.x), math.abs(tapDetect[2]- event.y)
				if(diffX<10 and diffY < 10) then
					--add a tap event to the end of the queue
					events[#events+1] = {name = "tap" ,x = event.x, y = event.y}
				end
			end
		end	
	end
		
	for i = 1, #events do
		
		local event = events[i]
		if(event.name:find("touch") or event.name:find("tap")) then
		
--			if(orientationMatch==false) then
--			event.x, event.y = event.y, event.x
--			end

			--now draw marker circles if wanted
			drawTouchCirle(event)
			currentTouchID = event.id

			--if stagefocus then just send the event directly
			if(focusTable[currentTouchID]) then
				local object = focusTable[currentTouchID]
				if(object.dispatchEvent) then
				event.target = object
				object:dispatchEvent( event )
				else
				focusTable[currentTouchID] = nil
				end
			else
			--we must figure out what object was touched

			local handled = false
				for j = 1, #objects do
					
					local object  = objects[j]	
					if(object.parent) then
					local x,y = event.x, event.y
					local bounds = object.contentBounds 
					if( x > bounds.xMin and x < bounds.xMax and y > bounds.yMin and y < bounds.yMax) then
						event.target = object
						--recursilvley check to see if parents and parents.. are visible
						local isVisible = object.isVisible
						local myParent = object.parent
						while(myParent and isVisible) do
							isVisible = myParent.isVisible
							myParent = myParent.parent
						end
						if( ( isVisible or object.isHitTestable) and object:dispatchEvent( event )) then handled = true; break;	end
					end
				end
				end
					if(not handled) then
						Runtime:dispatchEvent( event )
					end
				end
			else
				Runtime:dispatchEvent( event )
			end
		end				
	end
end
local screenshotnum = 10
local function generateBoundingBoxes()
	state.boundingBoxes = {}
	local stage =  display.getCurrentStageNative()
	local sin,rad = math.sin, math.rad
	
	for j = #objects, 1,-1 do
		
		local object  = objects[j]
		if(object.parent) then
						local isVisible = object.isVisible and object.alpha ~= 0
						local myParent = object.parent
						
						while(myParent and isVisible) do
							isVisible = myParent.isVisible and  myParent.alpha ~= 0
							myParent = myParent.parent

						end		
		if((options.sendAllObjects or object.ultimoteObject) and isVisible) then
		
			state.boundingBoxes[j] = {}
			local x,y = object:localToContent(0,0)
			state.boundingBoxes[j].x = x*xScale
			state.boundingBoxes[j].y = y*yScale	
			local rotationScaleCorrection = 1/((sin(rad(((object.rotation)*4-90)))+1)*.4141/2+1)
			state.boundingBoxes[j].w = object.contentWidth*xScale*rotationScaleCorrection
			state.boundingBoxes[j].h = object.contentHeight*yScale*rotationScaleCorrection
			state.boundingBoxes[j].r = object.rotation	
			state.boundingBoxes[j].xr = object.xReference
			state.boundingBoxes[j].yr = object.yReference
			if(not options.sendAllObjects) then
			if(object.ultimoteImage==nil) then
			local name = string.sub(tostring(object),8)..math.random(1,10000)..".jpg" --ensure a unique name
			debugPrint("sending ", name)
			display.save( object, name, system.TemporaryDirectory )
			
			local path = system.pathForFile(name, system.TemporaryDirectory )
			local file = io.open( path, "rb" )	
				if(file) then
					state.boundingBoxes[j].remoteImage = name
					object.ultimoteImage = name
				end
			end
			state.boundingBoxes[j].remoteImage = object.ultimoteImage	
			end
		end
		end
	end
end

----------------------------------------------------------------------------------------------------------
----------------------------Client Specific Startup-------------------------------------------------------
----------------------------------------------------------------------------------------------------------
local client = createClient()

local function networkLoopTCPThread()
	generateBoundingBoxes()			
	client:sendPriority(state)
	state = {}
end

----------------------------------------------------------------------------------------------------------
----------------------------Client Specific Listeners-----------------------------------------------------
----------------------------------------------------------------------------------------------------------
local function autolanConnected(event)
	debugPrint("broadcast", event.customBroadcast) --this is the user defined broadcast recieved from the server, it tells us about the server state.
	debugPrint("serverIP," ,event.serverIP) --this is the user defined broadcast recieved from the server, it tells us about the server state.
	--now that we have a connecton, let us just constantly send stuff to the server as an example
	debugPrint("connection established")
	Runtime:addEventListener("enterFrame", networkLoopTCPThread)
	connectedToDevice = true
end
Runtime:addEventListener("autolanConnected", autolanConnected)

local function autolanServerFound(event)
	debugPrint("broadcast", event.customBroadcast) --this is the user defined broadcast recieved from the server, it tells us about the server state.
	debugPrint("server name," ,event.serverName) --this is the name of the server device (from system.getInfo()). if you need more details just put whatever you need in the customBrodcast
	debugPrint("server IP:", event.serverIP) --this is the server IP, you must store this in an external table to connect to it later
	debugPrint("autolanServerFound")
end
Runtime:addEventListener("autolanServerFound", autolanServerFound)

local function autolanDisconnected(event)
	debugPrint("disconnected b/c ", event.message) --this can be "closed", "timeout", or "user disonnect"
	debugPrint("serverIP ", event.serverIP) --this can be "closed", "timeout", or "user disonnect"
	debugPrint("autolanDisconnected") 
	connectedToDevice = false
	--now just look for more servers
	if(event.message~= "user disonnect") then
		client:autoConnect()		
	end
end
Runtime:addEventListener("autolanDisconnected", autolanDisconnected)

local function autolanReceived(event)

	local payload = event.message
	if(payload) then
		--sendRemoteImages(payload)	
		if(payload.screenWidth and payload.screenHeight) then
			setScreenSize(payload)
		end
		if(payload.getImage and imagesSent[payload.getImage] == nil) then -- there are images to send
			client:sendFile(payload.getImage,system.TemporaryDirectory)
			imagesSent[payload.getImage] = true
		end		
		if(payload.macros) then
			macrosOnDevice = payload.macros
		end
		if(payload.deviceInfo) then
			deviceInfo = payload.deviceInfo
		end
		scaleEvents(payload)

	for i,macro in pairs(macroFilesRecord) do
		local file = macro.file
		if(macro.frames) then
			debugPrint("recording "..macro.name.." frame #".. macro.frames)
			local data = {}
			if(macro.frames == 1) then --put id information like fps
				file:write(json.encode({["fps"] = options.fps}).."\n")
			end
		--	sendMessage = sendMessage.." frame "..macro.frames.."/" ..macro.initFrames
			if(payload.events and next(payload.events) ~= nil) then
				data.events = payload.events
				data.frameNum = macro.frames
				file:write(json.encode(data).."\n")
			end
			macro.frames = macro.frames+1	
			if(macro.frames == macro.initFrames) then
				stopRecordingMacro({name = i})
			end
		end
	--	sendMessage = sendMessage..". "
	end
		
	--timer.performWithDelay(0,runTCPThread,1)
			if(not playingMacro ) then								
			dispatchEvents(payload)
		end	


	payload = nil
end
end
Runtime:addEventListener("autolanReceived", autolanReceived)

local function autolanFileReceived(event)
	debugPrint("filename = ", event.filename) --this is the filename in the system.documents directory
	debugPrint("autolanFileReceived")
end
Runtime:addEventListener("autolanFileReceived", autolanFileReceived)

local function autolanConnectionFailed(event)
	debugPrint("serverIP = ", event.serverIP) --this indicates that the server went offline between discovery and connection. the serverIP is returned so you can remove it form your list
	debugPrint("autolanConnectionFailed")
	client:autoConnect()	
end
Runtime:addEventListener("autolanConnectionFailed", autolanConnectionFailed)



local timeout = 0 -- in frames
local runTCPServer
local maxTimeout = 5



local function playMacroFrame()

	--play events
	 playingMacro = false
	for i,macro in pairs(macroFilesPlay) do
		playingMacro = true
		if(macro.data == nil) then --first line, read regardless
			local line = macro.file:read("*l") 
			if(line) then macro.data = json.decode(line)	end
			if(macro.frame == 0) then  
				macro.fpsFraction = macro.data.fps/options.fps 
				local line = macro.file:read("*l") 	
				if(line) then macro.data = json.decode(line)	end					
			end --- first line has fps data
		end
			
			macro.frame = macro.frame+macro.fpsFraction	
			debugPrint("playing "..macro.name.." frame #".. macro.frame)
		if(macro.data and macro.data.frameNum<=macro.frame) then	
			dispatchEvents(macro.data) 
--			sendMessage = sendMessage.."play macro ".. i .." frame "..macro.frame.."/"..macro.totalFrames.." . "
			local line = macro.file:read("*l") 
			if(line) then 
				macro.data = json.decode(line)
			else
				stopPlayingMacro({name = i})				
			end
						
		end
		
	end	
end
Runtime:addEventListener("enterFrame", playMacroFrame)
function screenCapture(params)
	if(params==nil) then params = {}; end
	print("CAPTURE IMAGE -----------------")
	local name = params.name or "screenshot.jpg"
	display.save( display.getCurrentStage() , name, system.DocumentsDirectory )	
	client:sendFile(name, system.DocumentsDirectory, "screenshot.jpg")
end

local screenCaptureTimer
function autoScreenCapture(params)
	if(params==nil) then params = {}; end
	params.name = params.name or "default.jpg"
	params.period = params.period or 6000
	if(screenCaptureTimer) then timer.cancel(screenCaptureTimer); end
	 screenCapture(params)
	screenCaptureTimer = timer.performWithDelay(params.period, function() if(connectedToDevice) then screenCapture(params); end end, -1)
end
function stopAutoScreenCapture()
	timer.cancel(screenCaptureTimer)
end


--params = name, 
function playMacro(params)

	if(params == nil) then params = {} end
	local name = params.name or "default"
	local path = system.pathForFile( name..".txt", system.DocumentsDirectory )
	--get number of frames in this file
	local file = io.open( path, "r" )
	if(file == nil) then 
		path = system.pathForFile( name..".txt", system.ResourcesDirectory )
		--get number of frames in this file
		file = io.open( path, "r" )
		if(file == nil) then 
			debugPrint("Macro "..params.name.." not found, getting from device")
			getMacros({params.name});
			timer.performWithDelay(1000, function() playMacro({name = params.name}) end)
			return 
		end
	end
	local numLines = 0
	for line in file:lines() do numLines = numLines+1 end
	io.close( file )

	macroFilesPlay[name] = {}
	macroFilesPlay[name].name = name
	macroFilesPlay[name].file = io.open( path, "r" )	
	macroFilesPlay[name].frame = 0
	macroFilesPlay[name].totalFrames = numLines		
	macroFilesPlay[name].onComplete = params.onComplete
end

function stopPlayingMacro(params)
	local name = params.name or "default"
	io.close( macroFilesPlay[name].file )
	local onComplete = macroFilesPlay[name].onComplete	

	macroFilesPlay[name] = nil
	if(onComplete) then
		onComplete(name)
	end		
end
function recordMacro(params)
	if(params == nil) then params = {} end
	local name = params.name or "default"
	local frames = params.frames or 1000
	local path = system.pathForFile( name..".txt", system.DocumentsDirectory )
	macroFilesRecord[name] = {}
	macroFilesRecord[name].file = io.open( path, "w" )
	macroFilesRecord[name].frames = 1
	macroFilesRecord[name].initFrames = frames	
	macroFilesRecord[name].name = name
	macroFilesRecord[name].onComplete = params.onComplete
end

function stopRecordingMacro(params)
	local name = params.name or "default"
	io.close( macroFilesRecord[name].file )
	local onComplete = macroFilesRecord[name].onComplete	
	macroFilesRecord[name] = nil
	if(onComplete) then
		onComplete(name)
	end	
end



function getMacros(params)
	if(state.getMacros == nil) then
		state.getMacros = {}
	end
	for i,v in ipairs(params) do
		state.getMacros[#state.getMacros+1] = v
	end
end
function connect(ip)
	client:start()
	--client:autoConnect()
	if(ip) then
		client:connect(ip)
	else
		client:autoConnect()
	end
end
function disconnect()
	client:disconnect()
	client:stop()
end


function getAllMacros()
	state.getAllMacros = true
end

function setOption(input)
	for i,v in pairs(input) do
		options[i] = v
	end
	if(input.overrideSystem) then
		overrideSystem() 
	end
end

function sendObject(params)
	if(params and params.object) then
		params.object.ultimoteObject = true
		params.object.ultimoteImage = params.image
	end
end

function playGoogleEarthMacro(params)
	--first parse and write the macro text file from kml
	if(params == nil) then params = {} end
	local name = params.name or "default"
	local path = system.pathForFile( name..".kml", system.DocumentsDirectory )
	--get number of frames in this file
	local file = io.open( path, "r" )
	if(file == nil) then 
		path = system.pathForFile( name..".kml", system.ResourcesDirectory )
		--get number of frames in this file
		file = io.open( path, "r" )
		if(file == nil) then 
			debugPrint("Google macro "..params.name..".kml not found")
			return 
		end
	end

	path = system.pathForFile( "UltimoteGPSPath.txt", system.DocumentsDirectory )
	--path = system.pathForFile( "test.txt", system.DocumentsDirectory )
	local fileout = io.open( path, "w" )
	fileout:write(json.encode({["fps"] = options.fps}).."\n")	--first file should be fps data
	
	local line = file:read()
	local frame = {["events"] = {[1] = {}}, ["frameNum"] = 1}
	local framdelt = params.frameRatio or 30
	while(line) do
		if(line:find("coordinates")) then
			line = file:read() --this contains the coordinates
			--now being parsing
			--{"events":["altitude":-4.9521527290344,"direction":254.51319885254,"name":"location","accuracy":14.340000152588,"longitude":-95.394081967865,"latitude":29.697387010166,"speed":14,"time":-1869915168}],"frameNum":44}
			
			 local stringit = string.gmatch(line, "[%d-%.]+")
			 local previouslat,previouslong,previousalt = 0,0,0
			 local r = 6378100*3.14159/180 -- in meters
			for long,i in stringit do
				local lat, alt =   stringit(), stringit()
				local difflong,difflat,diffalt = long-previouslong,lat-previouslat,alt-previousalt
				local dir = math.atan2(difflong,difflat)*57
				if(dir<0) then dir = dir+360 end
				frame.events[1] ={		["longitude"] = long,
										["latitude"] = lat,
										["altitude"] = alt,
										["speed"] = params.speed or (((difflat*difflat)+(difflong*difflong))*r*r+(diffalt*diffalt)),
										["direction"] = params.direction or dir+90,
										["name"] = "location",
										["time"] = frame.frameNum,
										["accuracy"] = params.accuracy or 10
								}
				frame.frameNum = frame.frameNum+framdelt
				previouslat,previouslong,previousAlt =lat,long,alt
				fileout:write(json.encode(frame).."\n")
			end
		end
		line = file:read()
	end
	io.close( file )
	io.close(fileout)

	--now play the macro
	playMacro({name = "UltimoteGPSPath"})
				

	
end
