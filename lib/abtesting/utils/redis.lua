local modulename = "abtestingRedis"
local _M = {}

_M._VERSION = '0.0.1'

local redis = require('resty.redis')

_M.new = function(self, conf)
    self.host       = conf.host
    self.port       = conf.port
    self.uds        = conf.uds
    self.timeout    = conf.timeout
    self.dbid       = conf.dbid
    self.poolsize   = conf.poolsize
    self.idletime   = conf.idletime
    self.pass = conf.pass

    local red = redis:new()
    return setmetatable({redis = red}, { __index = _M } )
end

_M.connectdb = function(self)

    local uds   = self.uds
    local host  = self.host
    local port  = self.port
    local dbid  = self.dbid
    local red   = self.redis
    local pass = self.pass

    if not uds and not (host and port) then
        return nil, 'no uds or tcp avaliable provided'
    end
    if not dbid then dbid = 0 end

    local timeout   = self.timeout 
    if not timeout then 
        timeout = 1000   -- 10s
    end
    red:set_timeout(timeout)

    local ok, err 
    if uds then
        ok, err = red:connect('unix:'..uds)
        if ok then return red:select(dbid) end
    end

    if host and port then
        ok, err = red:connect(host, port)
        --if ok then return red:select(dbid) end
        if ok then
            if pass then
                --口令认证
                local count, _ = red:get_reused_times()
                if count == 0 then
                    local o, _ = red:auth(pass)
                    if not o then
                        return
                    end --认证失败退出
                    end
                    return red:select(dbid)
                else
                    return red:select(dbid)  --无口令直接连接
                end
            end
    end

    return ok, err
end

_M.keepalivedb = function(self)
    local   pool_max_idle_time  = self.idletime --毫秒
    local   pool_size           = self.poolsize --连接池大小

    if not pool_size then pool_size = 1000 end
    if not pool_max_idle_time then pool_max_idle_time = 90000 end
    
    return self.redis:set_keepalive(pool_max_idle_time, pool_size)  
end

return _M