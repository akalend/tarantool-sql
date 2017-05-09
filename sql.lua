local string = require "std.string"

function parse_insert(sql) 
	local s1,s2 = string.match(sql, '[iI][nN][sS][Ee][Rr][tT] [iI][nN][tT][oO] *([%d%a]+) *[Vv][Aa][lL][Uu][Ee][Ss] ?%((.+)%)')
	return {s1,s2} 
end

function parse_values( values )
	local res = string.split(values, ",")
	if type(res) ~= 'table' then 
		error('parse sql: values error')
	end

	local v
	local out = {}
	for _,v in ipairs(res) do
		if string.byte(v,1) ~= 39 then
			table.insert(out, tonumber(v))
		else
			v = string.sub(v, 2, string.len(v) - 2 )
			table.insert(out,v)
		end 
	end
	return out

end


function parse_name(sql)

		local out = {}
		out ['table'] = sql.match(sql, "[fF][Rr][Oo][Mm] ([A-Za-z0-9]+)")
		local where,action,value = sql.match(sql, "[wW][Hh][Ee][Rr][Ee] ([A-Za-z0-9]+) *([%=<>][%=<>]?) *(.+)")

    if  where then
			out['where'] = where
			out['value'] = value
			out['it'] = action
		end

	return out	
end


function parse_limit(where_sql)
	if where_sql == nil then return {nil, nil} end
	local s1,s2 = string.match(where_sql, '(.+) +[lL][Ii][mM][Ii][Tt] +(%d+)')

	return {s1,s2}
end


function parse_sql( sql )

	local out = parse_name(sql)

	if string.match(sql, "[sS][Ee][lL][Ee][cC][tT]") then

		out["action"] = 'select'

		if string.match(sql, "[cC][oO][Uu][Nn][tT]%(%*%)") then
			out['action'] = 'count'
		end


	elseif string.match(sql, "[dD][Ee][lL][Ee][tT][Ee]") then
		
		out['action'] = 'delete'

	elseif string.match(sql, "[iI][nN][sS][Ee][Rr][tT]") then

		local res = parse_insert(sql)
		
		if res[1] == nil then
			error('parse sql: absent table name')
		end	
		out = { ["table"] = res[1], ["action"] = 'insert' }

		if res[2] then
			out['data'] = parse_values(res[2])
		else
			error('parse sql: absent values')
		end

	else	
		error('parse sql, must be start with: SELECT, DELETE, UPDATE or INSERT ' )
	end	

	if out['table'] == nil then 
		error('parse sql, must be set the tablename') 
	end
	
	return out
end


function get_type(dataspace, index)
	local index = dataspace.index[index]
	if index == nil then error('invalid index name') end
	return index.parts[1].type
end


function get_iterator( action )

	local it = nil
	if action == '=' then
		it = 'EQ'
	elseif 	action == '<' then
		it = 'LT'
	elseif action == '>=' then
		it = 'GE'
	elseif action == '>' then
		it = 'GT'
	elseif 	action == '<=' then
		it = 'LE'
	end	

	return it
end


function sql( sql )

	if sql == nil then  
		error('query is nil') 
	end

	local res = parse_sql(sql)
	if res['action'] == nil then error('parse sql error: action is null') end 
	if res['table'] == nil then error('parse sql error: table is null') end 

	local spacename = res['table']
	local dataspace = box.space[spacename]
	if dataspace == nil then error('404: spacename not found') end

	local action = res['action']
	it = get_iterator(res['it'])
	local value = res['value']
	
	if res['action'] == 'select' then
		
		if value == nil then
			return dataspace:len()
		elseif it ~= nil then

			if get_type(dataspace, res['where']) == 'unsigned' then value = tonumber(value)  end

			local parse_res = parse_limit(value)
			local limit_value = tonumber(parse_res[2])
			if parse_res[2] ~= nil and limit_value > 0 then
				return dataspace.index[res['where']]:select({parse_res[1]}, {iterator=it, limit=limit_value})
			end

			return dataspace.index[res['where']]:select({value}, {iterator=it})
		end

	elseif res['action'] == 'count' then

		if it == nil then
			return dataspace:count()
		else
			if res['value'] == nil then error('parse sql error: value is null') end

			if get_type(dataspace, res['where']) == 'unsigned' then value = tonumber(value)  end
			
			return dataspace.index[res['where']]:count({value}, {iterator=it})

		end

	elseif res['action'] == 'insert' then
		if type(dataspace) == 'table' then
			dataspace:insert(res['data'])
		else
			error('exec sql: error datatype')
		end	
	elseif res['action'] == 'delete' then

		if res['value'] == nil then error('parse sql error: value is null') end
		local value = res['value']
		if get_type(dataspace, res['where']) == 'unsigned' then value = tonumber(value)  end

		return dataspace:delete{value}
	elseif res['action'] == '*' then
		error('ERR *******')
	end

end
