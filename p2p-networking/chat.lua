function CHAT()
  if not os.loadAPI('HTP') then error("can't load HTP") end
  this = {}
  this.HTP = HTP()

  function this.update(self,data)
    print(data)
  end

  function this.on_event(self,event,p1,p2,p3,p4)
    if event == "key" then
      msg = io.read()
      self.HTP:broadcast(msg)
    end
  end

  return this
end
