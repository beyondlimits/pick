local creative = minetest.settings:get_bool('creative_mode')
local range = creative and 10 or 4

local players = {} -- last state of players' MMB

minetest.register_on_leaveplayer(function()
	players[player:get_player_name()] = nil
end)

minetest.register_globalstep(function()
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		if player:get_player_control().MMB then
			if not players[name] then
				players[name] = true
			
				local itemdef = player:get_wielded_item():get_definition()
				local itemrange = itemdef.range or range
				local pos = player:get_pos()
				
				-- me:get_eye_offset() ignored (some vector math needed)
				--   - just expose freaking player:get_pointed_thing()
				
				pos.y = pos.y + player:get_properties().eye_height
				
				local ray = minetest.raycast(
					pos,
					vector.add(pos, vector.multiply(player:get_look_dir(), range)),
					true,
					itemdef.liquids_portable
				)
				
				local thing = ray()
				
				if thing and thing.ref == player then
					thing = ray()
				end
				
				if thing and thing.type == 'node' then
					pos = thing.under
					thing = minetest.get_node(pos).name
					
					local nodedef = minetest.registered_nodes[thing]
					
					if nodedef and nodedef.on_pick then
						thing = nodedef.on_pick(player, pos)
					end
					
					local wielded = player:get_wielded_item()
					
					if wielded:get_name() ~= thing then
						local inv = player:get_inventory()
						local list = inv:get_list('main')
						local slot
						
						for i, v in ipairs(list) do
							if v:get_name() == thing then
								slot = i
								break
							end
						end
						
						if slot then
							wielded, list[slot] = list[slot], wielded
							inv:set_list('main', list)
							player:set_wielded_item(wielded)
						elseif creative or minetest.check_player_privs(name, {creative=true}) then
							player:set_wielded_item(thing)
						end
					end
				end
			end
		else
			players[name] = nil
		end
	end
end)
