local smatch = string.match
local sfind = string.find

local function check_is_admin()
	return function(req, res, next)
		local to_check = false
		local requestPath = req.path
		local match, err = smatch(requestPath, "^/admin/")
        if match then
            to_check = true
        end

        if to_check then
			local is_admin = false
		    if req and req.session and req.session.get("user") then
		        is_admin = req.session.get("user").is_admin
		        if is_admin == true or is_admin == 1 then  
		           is_admin = true
		        end
		    end

		    if is_admin then
		    	next()
		    else
		    	if sfind(req.headers["Accept"], "application/json") then
	        		return res:json({
	        			success = false,
	        			msg = "该操作需要管理员权限."
	        		})
	        	else
	            	return res:render("error",{
	            		errMsg = "该操作需要管理员权限."
	            	})
	            end
		    end
		end

		next()
	end
end

return check_is_admin

