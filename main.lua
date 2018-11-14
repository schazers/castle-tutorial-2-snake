-- Castle Example: Snake
-- http://www.playcastle.io

-- Constants
local GAME_WIDTH = 512
local GAME_HEIGHT = GAME_WIDTH
local GRID_SIZE = 24
local SQUARE_SIZE = (GAME_WIDTH / GRID_SIZE)
local TICK_SECONDS = 0.05
local INITIAL_SNAKE_LENGTH = 5
local GAME_OVER_WAIT_SECONDS = 0.75

-- Globals
local gameStarted = false
local timeSinceGameOver = -1
local timeSinceLastTick = 0
local justAteApple = false

local soundEatApple
local soundTurnSnake
local soundCrashSnake

-- a table with keys being the index of each snake block,
-- ordered from the head to the tail, where each value stores
-- a table with the {col, row} for that block of the snake
local snake = {}

-- Store current location of the apple
local apple = { col = -1, row = -1 }

-- one of "up", "down", "left", "right"
local snakeDirection = "up"
local latestKeyPressed = "up"

function love.load()
  math.randomseed(os.time())
  soundEatApple = love.audio.newSource("eat_apple.mp3", "static")
  soundTurnSnake = love.audio.newSource("turn_snake.mp3", "static")
  soundCrashSnake = love.audio.newSource("crash_snake.mp3", "static")
  soundEatApple:setVolume(0.3)
  soundTurnSnake:setVolume(0.2)
  soundCrashSnake:setVolume(0.3)
  resetGame()
end

local function resetGame()
  initSnake()
  placeRandomApple()
end

-- create the snake, facing upward towards center 
-- of grid, and with a starting length
local function initSnake()
  for k,v in pairs(snake) do snake[k] = nil end
  for i = 1, INITIAL_SNAKE_LENGTH do
    snake[i] = { col = GRID_SIZE/2 , row = GRID_SIZE/2 + i } 
  end
  latestKeyPressed = "up"
  snakeDirection = "up"
end

-- put an apple on the screen on a block that
-- the snake doesn't currently cover
-- note this method will take a long time to run 
-- if the snake gets so long that there are few empty
-- spaces. but that's so unlikely that we settle 
-- for this simple algorithm for now.
local function placeRandomApple()
  local appleIsClearOfSnake = true
  repeat
    apple.col = math.random(1, GRID_SIZE)
    apple.row = math.random(1, GRID_SIZE)
    appleIsClearOfSnake = true
    for i = 1, #snake do
      if (apple.col == snake[i].col) and (apple.row == snake[i].row) then
        appleIsClearOfSnake = false
      end
    end
  until appleIsClearOfSnake
end

function love.update(dt)
  if not gameStarted then
    return
  end

  if timeSinceGameOver > 0 then
    timeSinceGameOver = timeSinceGameOver - dt 
    if timeSinceGameOver <= 0 then
      resetGame()
      gameStarted = false
    end
    return
  end

  local shouldMoveSnakeOnce = (timeSinceLastTick > TICK_SECONDS)
  if shouldMoveSnakeOnce then
    -- extend tail during tick after apple was eaten
    if justAteApple then
      snake[#snake + 1] = { snake[#snake].col, snake[#snake].row }
      justAteApple = false
    end

    -- move all tail pieces one spot towards head
    for i = #snake - 1, 1, -1 do
      if i < #snake then
        snake[i + 1].col = snake[i].col
        snake[i + 1].row = snake[i].row
      end
    end

    -- move the head one space
    if latestKeyPressed == "up" and snakeDirection ~= "down" then
      snake[1].row = snake[1].row - 1
      snakeDirection = "up"
    elseif latestKeyPressed == "down" and snakeDirection ~= "up" then
      snake[1].row = snake[1].row + 1
      snakeDirection = "down"
    elseif latestKeyPressed == "left" and snakeDirection ~= "right" then
      snake[1].col = snake[1].col - 1
      snakeDirection = "left"
    elseif latestKeyPressed == "right" and snakeDirection ~= "left" then
      snake[1].col = snake[1].col + 1
      snakeDirection = "right"
    end

    -- wrap around the board
    if snake[1].row == 0 then
      snake[1].row = GRID_SIZE
    end
    if snake[1].col == 0 then
      snake[1].col = GRID_SIZE
    end
    if snake[1].col > GRID_SIZE then
      snake[1].col = 1
    end
    if snake[1].row > GRID_SIZE then
      snake[1].row = 1
    end

    -- check if ran into self
    for i = 2, #snake do
      if (snake[1].col == snake[i].col) and (snake[1].row == snake[i].row) then
        timeSinceGameOver = GAME_OVER_WAIT_SECONDS
        soundCrashSnake:play()
        return
      end
    end

    -- check if eating apple
    if snake[1].col == apple.col and snake[1].row == apple.row then
      placeRandomApple()
      justAteApple = true
      soundEatApple:stop()
      soundEatApple:play()
    end

    timeSinceLastTick = 0
  end
  
  timeSinceLastTick = timeSinceLastTick + dt
end

function love.keypressed(key, scancode, isrepeat)
  if timeSinceGameOver > 0 then
    return
  end

  if not gameStarted then
    gameStarted = true
    return
  end

  local aKeyWasPressed = false
  if (key == "up" or key == "w") and snakeDirection ~= "down" then
    latestKeyPressed = "up"
    aKeyWasPressed = true
  elseif (key == "down" or key == "s") and snakeDirection ~= "up" then
    latestKeyPressed = "down"
    aKeyWasPressed = true
  elseif (key == "left" or key == "a") and snakeDirection ~= "right" then
    latestKeyPressed = "left"
    aKeyWasPressed = true
  elseif (key == "right" or key == "d") and snakeDirection ~= "left" then
    latestKeyPressed = "right"
    aKeyWasPressed = true
  end

  if aKeyWasPressed then
    soundTurnSnake:setPitch(0.8 + 0.4 * math.random())
    soundTurnSnake:stop()
    soundTurnSnake:play()
  end
end

function love.draw()

  -- center game within castle window
  love.graphics.push()
  gTranslateScreenToCenterDx = 0.5 * (love.graphics.getWidth() - GAME_WIDTH)
  gTranslateScreenToCenterDy = 0.5 * (love.graphics.getHeight() - GAME_HEIGHT)
  love.graphics.translate(gTranslateScreenToCenterDx, gTranslateScreenToCenterDy)

  -- ground
  love.graphics.setColor(0.075, 0.075, 0.1, 1.0)
  love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

  -- frame
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
  love.graphics.rectangle("line", 0, 0, GAME_WIDTH, GAME_HEIGHT)

  -- apple
  love.graphics.setColor(1.0, 0.4, 0.4, 1.0)
  love.graphics.rectangle("fill", (apple.col - 1) * SQUARE_SIZE,
                                  (apple.row - 1) * SQUARE_SIZE,
                                  SQUARE_SIZE,
                                  SQUARE_SIZE)

  -- snake
  for i = 1, #snake do
    if i % 2 == 0 then 
      love.graphics.setColor(0.8, 0.9, 0.3, 1.0)
    else
      love.graphics.setColor(0.3, 0.8, 0.3, 1.0)
    end
    love.graphics.rectangle("fill", (snake[i].col - 1) * SQUARE_SIZE,
                                    (snake[i].row - 1) * SQUARE_SIZE,
                                    SQUARE_SIZE,
                                    SQUARE_SIZE)
  end

  -- center game within castle window
  love.graphics.pop()
end
