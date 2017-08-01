local sqlite3= require("sqlite3")
Sqlite = {}


function Sqlite:create()
    local sqlite = {}
    
    function sqlite:conn()
	   self.conn = sqlite3.open("./ecloud.sqlite")
    end
    
    function sqlite:createTable(sql)
	   return self.conn:execute(sql)
    end
    
    function sqlite:save(sql)
	   return self.conn:execute(sql)
    end
    
    function sqlite:query(sql,num)
	   local ret,item = {},{}
	   local rs = conn:prepare(sql)
	   assert(rs, conn:errmsg())
	   while (rs:step() == sqlite3.ROW) do
		  for i = 1, select('#', rs:get_uvalues()) do
			 local key = select(i, rs:get_unames())
			 local arg = select(i, rs:get_uvalues())
			 item[key] = arg
		  end
		  table.insert(ret,item)
	   end
	   return ret
    end

    function sqlite:close()
    	self.conn:close()
    end
    
    return sqlite
end