---------------------------
-- a sample socket server tcp
local socket = require("socket")
local luasql = require("luasql.mysql")

local host = '*'
local port = 8008


function sampleclass(clzz)
	local lz = {};
	for k, v in pairs(clzz) do
		lz[i] = v;
	end
	return lz;
end

--
CMD = {
	cs_LOGIN = 1001,
	SC_LOGIN = 1002,

	CS_REGISTER = 1003,
	SC_REGISTER = 1004,

	CS_SAY_PUBLIC = 1005,
	SC_SAY_PUBLIC = 1006,

	CS_SAY_PRIVATE = 1007,
	SC_SAY_PRIVATE = 1008,
}
--====================================
db = {};
function db:connect(dbname,dbuser,dbpwd, dbip, dbport)
	self.evn = assert(luasql.mysql());
	self.con, err = self.evn:connect(dbname,dbuser,dbpwd, dbip, dbport);
	if (self.con) then
		return true;
	end
	return false;
end

function db:exc_select(sql)
	local cur, er = self.con:execute(sql);
	local dt = {};
	local rs = cur:fetch({}, "a");
	while (rs) do
		table.insert(dt, rs);
		rs = cur:featch({}, "a");
	end

	return dt;
end

function db:exc_update(sql)
end

function db:exc_insert(sql)
end

function db:exc_delete(sql)
end

function db:close()
	if (self.con) then
		self.con:close();
		self.con = nil;
	end
end



--====================================
buffer = {};

function buffer:push(line)
end
function buffer:enough()
end
function buffer:pop()
end


--====================================
master = {client_t={}, userid_key={}};
function master:open(c)
	client_t[c] = {dt=nil, bf=sampleclass(buffer), client=nil};
end
function master:close(c)
	client_t[c] = nil;
end
function master:receive(c, dt)
	local role = client_t[c];
	if (role) then
		local bf = role.bf;
		bf:push(dt);
		if (bf:enough()) then
			local line = bf:pop();
			local msg = self:decode(line); -- {cmd=, uid=, data={}}
		end
	end
end

function master:domessage(role, msg)
	local cmd = msg.cmd;
	if (cmd == CMD.cs_LOGIN) then
		-- {cmd=, uid=, username=, userpwd=}

	elseif (cmd == CMD.CS_REGISTER) then
		-- {cmd=, uid=0, username=, userpwd=}

	elseif (cmd == CMD.CS_SAY_PUBLIC) then
		-- {cmd=, uid=, data=string}

	elseif (cmd == CMD.CS_SAY_PRIVATE) then
		-- {cmd=, uid=, data=string, tuid=}

	end
end

function master:encode(dt)
	-- TODO
end

function master:decode(dt)
	-- TODO
end

function master:send(c, dt)
	local line = self:encode(dt);
	c:send(line);
end

--====================================
local function remove_from_table(t, c)
	for j, k in ipairs(t) do
		if (k == c) then
			table.remove(t, j);
			return;
		end
	end
end
--====================================

function server_run(host, port)
	local recvt = {};
	local errt = {};
	local server = assert(socket.bind(host, port));
	-- local i, p = s:getsockname();
	print("binding to host: "..host..".. and port:"..port.."...");
	while (1) then
		local client = nil;
		local rt = socket.select(recvt, nil, 0.5);
		for key, ds in pairs(rt) do
			if (ds == server) then
				client = server:accept();
			else
				local line, err = ds:receive();
				if (not err) then
					master:receive(ds, line);
				else
					table.insert(errt, ds);
				end
			end
		end
		-- add new client
		if (client) then
			table.insert(recvt, client);
			master:open(client);
		end
		-- remove err client
		for i, ds in ipairs(errt) do
			ds:close();
			remove_from_table(recvt, ds);
			master:close(ds);
		end
		socket.sleep(0.01);
	end
end


