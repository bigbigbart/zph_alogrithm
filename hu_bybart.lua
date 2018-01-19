function table.copy( src )
    local dst = {}
    for k,v in pairs(src) do
        dst[k] = v
    end
    return dst
end

function table.index(tbl, obj)
    if tbl == nil or obj == nil then
        return
    end
    for i,v in pairs(tbl) do
        if v == obj then
            return i
        end
    end
end

function table.dump( object, cache )
    if type(object) == 'table' then
        cache = cache or {}
        if cache[object] then
            return ""
        end
        cache[object] = true
        local s = '{ '
        for k,v in pairs(object) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. table.dump(v, cache) .. ','
        end
        return s .. '} '
    elseif type(object) == 'function' then
        return "@@@function"
    elseif type(object) == 'string' then
        return string.format("%q", object)
    else
        return tostring(object)
    end
end

local SPECIAL_CARD_TBL = {2, 7, 10}
local SPECIAL_INC_DEC = {
	[1] = {5, 8},
	[2] = {-5, 3},
	[3] = {-8, -3}
}

local function get_dict_info(dict)
	local least_count = 1000
	local least_card = 0
	local card_count = 0
	for card, num in pairs(dict) do
		if num < least_count then
			least_count = num
			least_card = card
		end
		card_count = card_count + num
	end
	return least_card, least_count, card_count
end

local function get_straight(dict, value)
	-- 找普通顺子
	 -- 10 没有单独处理
	local straight = {}
    
    if dict[value] == 3 then
        table.insert(straight, {value, value, value})
    end
    
	if dict[value - 2] and dict[value - 1] and dict[value] then -- 123
		table.insert(straight, {value - 2, value - 1, value})
	elseif value ~= 10 and dict[value - 1] and dict[value] and dict[value + 1] then -- 234
		table.insert(straight, {value - 1, value, value + 1})
	elseif value%10 < 9 and dict[value] and dict[value + 1] and dict[value + 2] then  --345
		table.insert(straight, {value, value + 1, value + 2})
	end
	-- 找2710
	local idx = table.index(SPECIAL_CARD_TBL, (value > 10 and value - 10 or value))
	if  dix then
		if dict[value + SPECIAL_INC_DEC[idx][1]] and dict[value + SPECIAL_INC_DEC[idx][2]] then
			local tbl_2710 = {value, value + SPECIAL_INC_DEC[idx][1], value + SPECIAL_INC_DEC[idx][2]}
			table.sort(tbl_2710)
			table.insert(straight, tbl_2710)
		end
	end

	-- 找绞顺 -- 1个 和 2个  -- 1 + 2  
	if dict[value > 10] and dict[value - 10] == 2 or dict[value + 10] == 2 then
		if value > 10 then
			table.insert(straight, {value - 10, value - 10, value})
		else
			table.insert(straight, {value, value + 10, value + 10})
		end
	end
	return straight
end

local do_chech_hu = nil
do_check_hu = function (hu_result_tbl, hu_ret, hand_dict, hand_pairs) 
	local dict = table.copy(hand_dict)
	local least_card, least_count, card_count= get_dict_info(dict)
	if card_count == 0 then 
		table.insert(hu_result_tbl.shunzi, hu_ret)
	end

	if hand_pairs and #hand_pairs > 0 then
		local pairs_tbl = table.copy(hand_pairs)
		for i, pairs_card in ipairs(pairs_tbl) do
			local _dict = table.copy(dict)
			--_dict[pairs_card] = _dict[pairs_card] - 2
			hu_result_tbl.duizi = {pairs_card, pairs_card}
			hu_ret = {}
			do_check_hu(hu_result_tbl, hu_ret, _dict, false)
		end
	else
		local straight = get_straight(dict, least_card) 
		for idx, sz_tbl in pairs(straight) do
			table.insert(hu_ret, sz_tbl)
			for _, value in ipairs(sz_tbl) do
				dict[value] = dict[value] - 1 > 0 and dict[value] - 1 or nil  
			end
			do_check_hu(hu_result_tbl, hu_ret, dict)
		end
	end
	
end

local function check (hand_tbl)
	local hu_result_tbl = {duizi = {}, shunzi = {}}
	local hu_ret = {}
	if #hand_tbl % 3 == 0 or #hand_tbl % 3 == 2 then
		local hand_dict = {}
		local hand_pairs = {}
		for _, value in ipairs(hand_tbl) do
			hand_dict[value] = (hand_dict[value] or 0) + 1
		end
		if #hand_tbl % 3 == 2 then
			for card, count in pairs(hand_dict) do
				if count >= 2 then
                    hand_dict[card] = hand_dict[card] - 2
					table.insert(hand_pairs, card)
				end
			end
		end
		do_check_hu(hu_result_tbl, hu_ret, hand_dict, hand_pairs)
		print("cur hu_result_tbl is : %s", table.dump(hu_result_tbl))
	else
		return hu_result_tbl
	end
end

-- local tbl = {1, 2, 3, 20, 20, 15, 15, 16, 16, 17, 17}
local tbl = {3, 3, 3, 4, 5,} -- 
--local hand = {3, 3, 3, 4, 4, 5, 5, 6, 6} -- 最后摸一张
check(tbl)
