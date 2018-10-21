-- title: Can't stop
-- author: divby00
-- desc: Adaptation of the board game with the same name
-- script: lua
-- input: gamepad
-- saveid: cantstop

settings = {
  music = false,
  sfx = false,
  players = 4,
  player_colors = { 8, 12, 11, 10}
}

--------------------------------- Stage ---------------------------------
Stage = {}

function Stage:new(o)
  o = o or {}
  setmetatable(o, {__index=self})
  return o
end

function Stage:init() end
function Stage:update(dt) end
function Stage:quit() end

---------------------------------- Intro Stage ---------------------------------
Intro = Stage:new{
  text = {visible = false, flash = false, counter = 0, initial_time = 0},
  glitch = { x = 0, y = 0, counter = 0, direction = 0}
}

function Intro:init()
  self.text.initial_time = time()
end

function Intro:update(dt)
  if self.text.flash then
    self.text.counter = self.text.counter + 1
    if btn(5) then
      sm.switch("game", Game)
    end
  end
  self.glitch.counter = self.glitch.counter + 1

  if self.glitch.counter == 40 then
    self.glitch.direction = math.random(4)
    if self.glitch.direction == 1 then
      self.glitch.x = 1
      self.glitch.y = 0
    elseif self.glitch.direction == 2 then
      self.glitch.x = 0
      self.glitch.y = 1
    end
  end

  if self.glitch.counter == 55 then
    self.glitch.counter = 0
    self.glitch.x = 0
    self.glitch.y = 0
  end

  if not self.text.flash and time() > self.text.initial_time + 1500 then
    self.text.flash = true
  end
  if self.text.counter == 25 and self.text.flash then
    self.text.visible = not self.text.visible
    self.text.counter = 0
  end
  self:draw()
end

function Intro:draw()
  cls(0)
  if self.text.visible then
    print("Press x to continue", 68, 80, 6)
  end
  self:_draw_logo()
  self:_draw_pixel_band()
end

function Intro:_draw_logo()
  for i=0,12 do
    spr(64 + i, 68 + (8 * i), 40)
    spr((64 + 16) + i, 68 + (8 * i), 48)
    if self:_check_display_glitch() then
      spr(64 + i, 68 + (8 * i) + self.glitch.x, 40 + self.glitch.y, 0)
      spr((64 + 16) + i, (68 + (8 * i)) + self.glitch.x, 48 + self.glitch.y, 0)
     end
  end
end

function Intro:_draw_pixel_band()
  if self:_check_display_glitch() then
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

function Intro:_check_display_glitch()
  return self.glitch.counter >= 50 and self.glitch.counter <= 65 
    and self.glitch.direction > 0 and self.glitch.direction < 3
end

--------------------------------- Game Stage ---------------------------------
Game = Stage:new {
  status = 1, -- Rolling dices
  dices = { x = {0, 1}, y = {1, 0}, init_x = {99, 96}, stopped = false, stopped_time = 0, sin_count = 0 },
  shake = { x = 0, y = 0, counter = 0, direction = 0 },
  players = { -- type: 0 human, 1 computer
    active_player = 1,
    { name = "Player 1", points = 0, type = 0, id = 1, runners = {{0, 0}, {0, 0}, {0, 0}}, active_runner = 1 },
    { name = "Player 2", points = 0, type = 1, id = 2, runners = {{0, 0}, {0, 0}, {0, 0}}, active_runner = 1 },
    { name = "Player 3", points = 0, type = 1, id = 4, runners = {{0, 0}, {0, 0}, {0, 0}}, active_runner = 1 },
    { name = "Player 4", points = 0, type = 1, id = 8, runners = {{0, 0}, {0, 0}, {0, 0}}, active_runner = 1 }
  },
  update_function = nil,
  draw_function = nil,
  cursor = { x = 0, y = 0, frame = 0, column = 0, row = 0 },
  board = { x = 60, y = 4,
    cols = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    col_max_size = {2, 4, 6, 8, 10, 12, 10, 8, 6, 4, 2},
    col_coordinates = {
      {76, 68}, {84, 76}, {92, 84}, {100, 92}, {108, 100}, {116, 108}, 
      {124, 100}, {132, 92}, {140, 84}, {148, 76}, {156, 68}
    }
  }
}

function Game:init()
  self.update_function = self.update_rolling_dices
  self.draw_function = self.draw_info_box
end

function Game:update_rolling_dices(dt)
  self.dices[1] = math.random(6)
  self.dices[2] = math.random(6)
  if self.players[self.players.active_player].type == 0 then
    if btnp(5, 120, 0) then
      self.status = 2
      self.update_function = self.update_hand_shaking
      self.draw_function = self.draw_dices_throw
    end
  else
    -- TODO: Add the AI for computer players
  end
end

function Game:update_hand_shaking(dt)
  self.dices.stopped = false
  self.shake.counter = self.shake.counter + 1
  if self.shake.counter % 5 == 0 then
    self.shake.direction = .5
    if self.shake.counter % 10 == 0 then
      self.shake.direction = -.5
    end
    if self.shake.counter % 50 == 0 then
      self.status = 3
      self.update_function = self.update_dices_over_table
    end
  end
  self.shake.y = self.shake.y + self.shake.direction
end

function Game:update_dices_over_table(dt)
  for dice=1, 2 do
    local sin = math.sin(self.dices.x[dice])
    if self.dices.sin_count < 34 then
      self.dices.x[dice] = self.dices.x[dice] + .6
      self.dices.y[dice] = 72 + sin
      if sin < 0.1 then
        self.dices.sin_count = self.dices.sin_count + 1
      end
    else
      for dice=1, 2 do
        self.dices.y[dice] = 72
        self.dices.stopped = true
        if self.dices.sin_count == 34 then
          self.dices.stopped_time = time()
          self.dices.sin_count = 35
        end      
        if self.dices.stopped_time + 1500 < time() then
          self.status = 4
          self.update_function = self.update_cursor
          self.draw_function = self.draw_cursor
          self.cursor.column = self.dices[1] + self.dices[2]
          self.cursor.x = self.board.col_coordinates[self.cursor.column - 1][1] - 1

          -- Find the next empty space for the selected column to get the cursor y coordinate
          local empty_position = 0
          while (self.board.cols[self.cursor.column - 1] & self.players[self.players.active_player].id ~= 0) do
            empty_position = empty_position + 1
          end
          self.cursor.y = self.board.col_coordinates[self.cursor.column - 1][2] - (8 * empty_position)
          self.cursor.row = empty_position + 1
        end
      end
    end
  end
end

function Game:update_cursor(dt)
  self.cursor.frame = self.cursor.frame + (.01 * dt)
  if self.cursor.frame >=4 then self.cursor.frame = 0 end
  if btn(5) then
    self.players[self.players.active_player].runners[1] = { self.cursor.x, self.cursor.y }
  end
end

function Game:draw_cursor()
  -- print(self.cursor.x.." "..self.cursor.y.." "..self.cursor.column.." "..self.cursor.row, 60, 0)
  spr(96 + math.floor(self.cursor.frame), self.cursor.x, self.cursor.y, 0);
end

function Game:draw_tokens()
  for player=1, 4 do
    for runner=1, 3 do
      if self.players[player].runners[runner][1] ~= 0 then
        spr(26 + self.players.active_player, self.players[player].runners[runner][1], self.players[player].runners[runner][2], 0)
      end
    end
  end
end

function Game:update(dt)
  if self.update_function then
    self:update_function(dt)
  end
  self:draw()
end

function Game:draw()
  cls(1)
  map(0, 0, 15, 16, self.board.x, self.board.y, 0)
  self:draw_tokens()
  if self.draw_function then 
    self:draw_function() 
  end
  self:draw_player_scores()
end

function Game:draw_info_box()
  rect(48, 48, 144, 40, 0)
  rectb(48, 48, 144, 40, 7)
  print(self.players[self.players.active_player].name, 96, 56, settings.player_colors[self.players.active_player])
  local message = "Rolling dices..."
  if self.players[self.players.active_player].type == 0 then 
    message = "Press x to roll dices"
  end
  print(message, 64, 72, 7)
end

function Game:draw_dices_throw()
  rect(80, 48, 80, 40, 0)
  rectb(80, 48, 80, 40, 7)
  if self.status == 2 then -- Draw closed hand
    spr(63, 88 + self.shake.x, 64 + self.shake.y )
    spr(77, 96 + self.shake.x, 64 + self.shake.y)
  elseif self.status == 3 then
    if not self.dices.stopped then -- Draw opened hand
      spr(63, 88 + self.shake.x, 64 + self.shake.y )
      spr(78, 96 + self.shake.x, 64 + self.shake.y)
      spr(79, 104 + self.shake.x, 64 + self.shake.y)
      spr(93, 96 + self.shake.x, 56 + self.shake.y)
      for dice=1, 2 do
        pix(self.dices.x[dice] + self.dices.init_x[dice], self.dices.y[dice], 7)
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

--------------------------------- Stage manager ---------------------------------
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

--------------------------------- TIC ---------------------------------
function TIC()
  local actual_time = time()
  local dt = actual_time - last_time
  if dt < 500 then
    sm.update(dt)
  end
  last_time = actual_time
end

--------------------------------- Start --------------------------------- 
sm = StageManager()
sm.add("intro", Intro)
sm.add("game", Game)
sm.switch("game")
last_time = time()
