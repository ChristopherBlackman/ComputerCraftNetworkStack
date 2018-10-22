
-- p2p networking stack that works ontop of rednet
function HTP()
  local this = {}
  this.HTP = "HTP"
  this.DEFAULT_TTL = 90
  this.filter = {}
  this.fifo   = Queue()
  this.observers = {}

  --setup observer classes
  function this.register(self,observer)
    self.observers[observer] = observer
  end

  function this.unregister(self,observer)
    self.observers[observer] = nil
  end

  -- data   : input, type(~nil)
  -- return : encoded string
  function this.encode(self,data)
    local temp_d = {}
    temp_d.ip = os.getComputerID()
    temp_d.layer = self.HTP
    temp_d.data = data
    temp_d.ttl = self.DEFAULT_TTL

    --used to identifiy message
    temp_d.msg_id = math.random()
    temp_d.msg_time = os.time()
    temp_d.msg_ip = os.getComputerID()
    return textutils.serialize(temp_d)
  end

  -- input d : htp protocal object
  -- return  : mapping for message id
  function this.__mapping(self,d)
    return d["msg_id"]..d["msg_time"]..d["msg_ip"]
  end

  -- stream for keeping track of duplicate messages
  -- data : htp protocal object
  -- return : nil
  function this.__push_pop_queue_clean(self,data)
    if self.fifo:size() > 100 then
      self.filter[self.fifo:deque()] = nil
    end
    self.fifo:push(self:__mapping(data))
    self.filter[self:__mapping(data)] = true
    return
  end

  -- data : input, type(HTP encoded object)
  -- return : nil
  function this.__rebroadcast(self,data)
      if data.msg_ip == os.getComputerID() then
        return
      elseif data.ttl <= 0 then
        return 
      elseif self.filter[self:__mapping(data)] ~= nil then
        self:__push_pop_queue_clean(data)
        return
      end
      self:__push_pop_queue_clean(data)
      data.ttl = data.ttl - 1
      rednet.broadcast(textutils.serialize(data))
      print("HTP -- Data Recieved")
      print(textutils.serialize(data.data))
      print("HTP -- EOS")

      for k, observer in pairs(self.observers) do 
        observer:update(data.data)
      end
  end

  -- data : input, type(~nil)
  -- return : nil
  function this.broadcast(self,data)
    rednet.broadcast(self:encode(data))
  end

  -- data : HTP encoded object
  -- return : nil on non-HTP object
  -- return : encoded data on HTP object
  function this.decode(self,data)
    local temp_d = textutils.unserialize(data)
    if type(temp_d) ~= 'table' then return nil
    elseif temp_d['ip'] == nil then return nil
    elseif temp_d['layer'] ~= self.HTP then return nil
    elseif temp_d['data'] == nil then return nil
    elseif temp_d['ttl'] == nil then return nil
    elseif temp_d['msg_id'] == nil then return nil
    elseif temp_d['msg_time'] == nil then return nil
    elseif temp_d['msg_ip'] == nil then return nil
    end

    return temp_d['data']
  end

  -- event : os event
  -- p1    : os event parameter 1
  -- p2    : os event parameter 2
  -- p3    : os event parameter 3
  -- p4    : os event parameter 4
  -- return : nil
  function this.on_event(self,event,p1,p2,p3,p4)
    if event == "rednet_message" then
        if self:decode(p2) ~= nil then
          self:__rebroadcast(textutils.unserialize(p2))
        end
    end
  end

  return this
end



-- kept in class for eaiser loading
-- credits to : https://www.lua.org/pil/11.4.html
-- modified   : Christopher B.

function Queue()
  List = {}
  List.first = 0
  List.last  = -1
  List.size  = 0

  function List.size(self)
    return self.last - self.first + 1
  end

  -- used to peak at values of list
  function List.get(self,i)
    local index = self.first + i
    print(index)
    if (index < self.first) then error("index error") end
    if (index > self.last) then error("index error") end
    return self[index]
  end

  -- adds to front of list
  function List.push (list, value)
    local first = list.first - 1
    list.first = first
    list[first] = value
    return list
  end
      
  -- adds to back of list
  function List.append (list, value)
    local last = list.last + 1
    list.last = last
    list[last] = value
    return list
  end

  -- removes the front of the list
  function List.pop (list)
    local first = list.first
    if first > list.last then error("list is empty") end
    local value = list[first]
    list[first] = nil        -- to allow garbage collection
    list.first = first + 1
    return value
  end
      
  -- removes the end of the list
  function List.deque (list)
    local last = list.last
      if list.first > last then error("list is empty") end
      local value = list[last]
      list[last] = nil         -- to allow garbage collection
      list.last = last - 1
      return value
  end

  return List
end
