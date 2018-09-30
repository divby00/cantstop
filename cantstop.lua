-- title: Can't stop
-- author: divby00
-- desc: Adaptation of the board game with the same name
-- script: lua
-- input: gamepad
-- saveid: cantstop

--[[ Stage ]]--
settings = {
  music = false,
  sfx = false,
  players = 4,
  player_colors = { 8, 12, 11, 10}
}

Stage = {}

function Stage:new(o)
  o = o or {}
  setmetatable(o, {__index=self})
  return o
end

function Stage:init() end
function Stage:update(dt) end
function Stage:quit() end

--[[ IntroStage ]]--
Intro = Stage:new{
  text_visible = false,
  text_flash = false,
  text_counter = 0,
  glitch_counter = 0,
  glitch_direction = 0,
  glitch_x = 0,
  glitch_y = 0,
  initial_time = 0
}

function Intro:init()
  self.initial_time = time()
end

function Intro:update(dt)
  if self.text_flash then
    self.text_counter = self.text_counter + 1
    if btn(5) then
      sm.switch("game", Game)
    end
  end
  self.glitch_counter = self.glitch_counter + 1

  if self.glitch_counter == 40 then
    self.glitch_direction = math.random(4)
    if self.glitch_direction == 1 then
      self.glitch_x = 1
      self.glitch_y = 0
    elseif self.glitch_direction == 2 then
      self.glitch_x = 0
      self.glitch_y = 1
    end
  end

  if self.glitch_counter == 55 then
    self.glitch_counter = 0
    self.glitch_x = 0
    self.glitch_y = 0
  end

  if not self.text_flash and time() > self.initial_time + 1500 then
    self.text_flash = true
  end
  if self.text_counter == 25 and self.text_flash then
    self.text_visible = not self.text_visible
    self.text_counter = 0
  end
  self:draw()
end

function Intro:draw()
  cls(0)
  if self.text_visible then
    print("Press x to continue", 68, 80, 6)
  end
  self:draw_logo()
  self:draw_pixel_band()
end

function Intro:draw_logo()
  for i=0,12 do
    spr(64 + i, 68 + (8 * i), 40)
    spr((64 + 16) + i, 68 + (8 * i), 48)
    if self:check_display_glitch() then
      spr(64 + i, 68 + (8 * i) + self.glitch_x, 40 + self.glitch_y, 0)
      spr((64 + 16) + i, (68 + (8 * i)) + self.glitch_x, 48 + self.glitch_y, 0)
     end
  end
end

function Intro:draw_pixel_band()
  if self:check_display_glitch() then
    for band=0, math.random(5) do
      local y = math.random(136)
      for x=0, 240 do
        if math.random(5) == 1 then
          pix(x, y, math.random(3) + 4)
        end
      end
    end
  end
end

function Intro:check_display_glitch()
  return self.glitch_counter >= 50 and self.glitch_counter <= 65 
    and self.glitch_direction > 0 and self.glitch_direction < 3
end

--[[ MenuStage ]]--
Game = Stage:new {
  active_player = 1,
  status = 1, -- Rolling dices
  board_x = 60,
  board_y = 4,
  dices = {},
  shake_x = 0, 
  shake_y = 0,
  shake_counter = 0,
  shake_direction = 0,
  dice_x = {0, 1},
  dice_y = {1, 0},
  dice_init_x = {99, 96},
  dices_stopped = false,
  dices_stopped_time = 0,
  sin_count = 0,
  players = { -- type: 0 human, 1 computer
    {name = "Player 1", points = 0, type = 0},
    {name = "Player 2", points = 1, type = 1},
    {name = "Player 3", points = 2, type = 1},
    {name = "Player 4", points = 3, type = 1}
  },
  draw_function = nil
}

function Game:init()
  self.draw_function = self.draw_info_box
end

function Game:update(dt)
  if self.status == 1 then -- Rolling dices message
    self.dices[1] = math.random(6)
    self.dices[2] = math.random(6)
    if self.players[self.active_player].type == 0 then
      if btnp(5, 120, 0) then
        self.status = 2
        self.draw_function = self.draw_dices_throw
      end
    else
      -- TODO: Add the AI for computer players
    end
  elseif self.status == 2 then -- Hand shaking
    self.dices_stopped = false
    self.shake_counter = self.shake_counter + 1
    if self.shake_counter % 5 == 0 then
      self.shake_direction = .5
      if self.shake_counter % 10 == 0 then
        self.shake_direction = -.5
      end
      if self.shake_counter % 50 == 0 then
        self.status = 3
      end
    end
    self.shake_y = self.shake_y + self.shake_direction
  elseif self.status == 3 then -- Dices moving over the table
    for dice=1, 2 do
      local sin = math.sin(self.dice_x[dice])
      if self.sin_count < 34 then
        self.dice_x[dice] = self.dice_x[dice] + .6
        self.dice_y[dice] = 72 + sin
        if sin < 0.1 then
          self.sin_count = self.sin_count + 1
        end
      else
        for dice=1, 2 do
          self.dice_y[dice] = 72
          self.dices_stopped = true
          if self.sin_count == 34 then
            self.dices_stopped_time = time()
            self.sin_count = 35
          end      
          if self.dices_stopped_time + 1500 < time() then
            self.status = 4
            self.draw_function = nil
          end
        end
      end
    end
  elseif self.status == 4 then -- Move --
  end
  self:draw()
end

function Game:draw()
  cls(1)
  map(0, 0, 15, 16, self.board_x, self.board_y, 0)
  if self.draw_function then 
    self:draw_function() 
  end
  self:draw_player_scores()
end

function Game:draw_info_box()
  rect(48, 48, 144, 40, 0)
  rectb(48, 48, 144, 40, 7)
  print(self.players[self.active_player].name, 96, 56, settings.player_colors[self.active_player])
  local message = "Rolling dices..."
  if self.players[self.active_player].type == 0 then 
    message = "Press x to roll dices"
  end
  print(message, 64, 72, 7)
end

function Game:draw_dices_throw()
  rect(80, 48, 80, 40, 0)
  rectb(80, 48, 80, 40, 7)
  if self.status == 2 then -- Draw closed hand
    spr(63, 88 + self.shake_x, 64 + self.shake_y )
    spr(77, 96 + self.shake_x, 64 + self.shake_y)
  elseif self.status == 3 then
    if not self.dices_stopped then -- Draw opened hand
      spr(63, 88 + self.shake_x, 64 + self.shake_y )
      spr(78, 96 + self.shake_x, 64 + self.shake_y)
      spr(79, 104 + self.shake_x, 64 + self.shake_y)
      spr(93, 96 + self.shake_x, 56 + self.shake_y)
      for dice=1, 2 do
        pix(self.dice_x[dice] + self.dice_init_x[dice], self.dice_y[dice], 7)
      end
    else -- Draw dices (removing hand)
      spr(self.dices[1], 108, 64)
      spr(self.dices[2], 125, 64)
    end
  end
end

function Game:draw_player_scores()
  local pscore_coordinates = {
    {2, 2}, {194, 2}, {2, 128}, {194, 128}, -- Player name text coordinates
    {1, 10}, {215, 10}, {1, 116}, {215, 116} -- Player points sprites coordinates
  }
  for player = 1, settings.players do
    print("Player " .. player, pscore_coordinates[player][1], pscore_coordinates[player][2], settings.player_colors[player])
    for point = 0, 2 do
      spr(14, pscore_coordinates[player + 4][1] + (8 * point), pscore_coordinates[player + 4][2])
    end
    for point = 0, self.players[player].points - 1 do
      spr(15, pscore_coordinates[player + 4][1] + (8 * point), pscore_coordinates[player + 4][2])
    end
  end
end

--[[ StageManager ]]--
function StageManager()
  local stages = {}
  local actual_stage = {
    instance = Stage:new()
  }

  return {
    add = function(name, stage)
      stages[name] = {
        name=name,
        proto=stage,
        instance=nil
      }
    end,

    switch = function(name, keep_instance)
      keep_instance = keep_instance or false
      local new_stage = stages[name]
      
      if new_stage == nil then return end
      if actual_stage.name == name then return end

      actual_stage.instance:quit()
      if not keep_instance then actual_stage.instance = nil end

      if new_stage.instance == nul then
        new_stage.instance = new_stage.proto:new()
        new_stage.instance:init()
      end
      actual_stage = new_stage
    end,

    update = function(dt)
      actual_stage.instance:update(dt)
    end
  }
end

--[[ Entity ]]--
Entity = {
  x=0, y=0,
  active=true,
  stage=nil
}

function Entity:new(o)
  o = o or {}
  return setmetatable(o, {__index=self})
end

function Entity:draw() end

function Entity:update() end

sm = StageManager()
sm.add("intro", Intro)
sm.add("game", Game)
sm.switch("intro")
last_time = time()

--[[ TIC ]]--
function TIC()
  local actual_time = time()
  local dt = actual_time - last_time

  if dt < 500 then
    sm.update(dt)
  end
  last_time = actual_time
end
