-- DNS based Internet Access Policy
-- Check Block List, Check Allow List, Default: Block
-- Selfservice vlan whitelist

-- configuration
allow_list_file = "allow.db"
block_list_file = "block.db"
white_list_file = "white.db"

-- Load files
function load_list_file(file)
    local list = {}
        for line in io.lines(file) do
            if string.len(line) > 0 and string.sub(line, 1, 1) ~= "#" then
                table.insert(list, line .. ".")
            end
        end
    return list
end

function string.ends(String,ending)
    return ending=='' or string.sub(String,-string.len(ending))==ending
end

block_list = load_list_file(block_list_file)
allow_list = load_list_file(allow_list_file)
white_list = load_list_file(white_list_file)

function check_iap_acl(acl_list, domain)
    for k,v in pairs(acl_list) do
    dotv = "." .. v
        if string.sub(domain, -string.len(v)) == v then
            return true
        elseif string.ends(domain,dotv) then
            return true
        end
    end
    return false
end

-- Resolver Function Override
-- If we run with preresolve, then we need to disable the caching, which we don't want to do.
-- function preresolve(requestorip, domain, qtype)
function postresolve(requestorip, domain, qtype)
    if qtype == pdns.A then
-- First, we check the queried domain against the whitelist
        if check_iap_acl(white_list, domain) then
            return -1, {}
-- Redirect queries to appropriate ethernet/web interface
-- SELF Blocked
        elseif matchnetmask(requestorip, "10.64.8.0/23") then
            return 0, { {qtype=pdns.A, content="127.0.0.1"} }
-- bypass allow list, If it's allowlisted, then requestor IP doesn't matter.
        elseif check_iap_acl(allow_list, domain) then
            return -1, {}
-- LAN Blocked
        elseif matchnetmask(requestorip, "10.64.2.0/23") then
            return 0, { {qtype=pdns.A, content="127.0.0.1"} }
-- CC Blocked
        elseif matchnetmask(requestorip, "10.64.12.0/23") then
            return 0, { {qtype=pdns.A, content="127.0.0.1"} }
-- Add other vlans go with allow list only
-- Whitelist end

-- Second, we check the queried domain against the blacklist
        elseif check_iap_acl(block_list, domain) then
-- setvariable() here for excluding these requests from packet cache
            setvariable()
-- The VM shouldn't filter itself (should have full access)
            if matchnetmask(requestorip, "127.0.0.1/32") then
                return -1, {}
-- MNGT Blocked
            elseif matchnetmask(requestorip, "10.64.10.0/23") then
                return 0, { {qtype=pdns.A, content="127.0.0.1"} }
-- Default action for "if requestor IP is not defined"
-- "return -1" here means "permit unlisted requestor IP access to queried domain"
-- "return 0" here means "forbid unlisted requestor IP access to queried domain"           
			else
                return -1, {}
            end
-- Blacklist end

-- No list match (default policy)
-- "return -1" here means "permit everything except the blacklist"
-- "return 0" here means "forbid everything except the whitelist"
        else

            return -1, {}
        end

    end
-- Continue if not an A record.
    return -1, {}
end
