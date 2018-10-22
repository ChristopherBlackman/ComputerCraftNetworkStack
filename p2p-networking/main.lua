function init ()
  -- loads HTP lib
  os.loadAPI("HTP")
  os.loadAPI("CHAT")

  -- opens all possible modems
  sides = redstone.getSides()
  for i, side in pairs(sides) do
    if peripheral.getType(side) == "modem" then
      rednet.open(side)
    end
  end
end

init()

-- main loop
local running = true
programs = {}
programs.HTP = HTP()
programs.CHAT = CHAT()

programs.HTP:register(programs.CHAT)


while running do
  local event, p1,p2,p3,p4 = os.pullEvent()

  for k, v in pairs(programs) do
    v:on_event(event,p1,p2,p3,p4)
  end
  if event == 'key' and p1 == 41 then
    running = false
  end

end
