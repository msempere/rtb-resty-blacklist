ngx.req.read_body()
post = ngx.req.get_body_data()

if post ~= nil then
    domain = string.match(post, [["domain"%s*:%s*"(.-)"]])

    if domain ~= nil or domain ~= "" then
        local red = redis:new()

        -- 30 ms timeout for Redis operation
        -- including a possible connection
        red:set_timeout(30)

        local ok, err = red:connect("127.0.0.1", 6379)

        -- error while connecting
        if ok ~=1 then 
            ngx.log(ngx.ERR, err)
            ngx.status = 204
            ngx.exit(204)

            -- connection OK
        else
            blacklisted = false
            -- domain blacklisted
            if red:exists(domain) == 1 then
                blacklisted = true
            end

            -- put it into the connection pool of size 100,
            -- with 10 seconds max idle time
            local ok, err = red:set_keepalive(10000, 100)
            if ok ~= 1 then
                ngx.log(ngx.ERR, err)
            end

            if blacklisted then
                ngx.status = 204
                ngx.exit(204)
            end
        end
    end
end
