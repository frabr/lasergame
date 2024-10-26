require 'app/primitives/sprite'

class Player < Sprite
  attr_accessor :speed, :player_jump_power, :player_jump_power_duration, :player_speed_slowdown_rate, :dy,
                :jumped_at

  SPEED = 24
  STATIC_SPRITE = 'sprites/lasercat_low_static.png'
  MOVE_SPRITE = 'sprites/lasercat_low.png'

  def initialize(y)
    self.x = 120
    self.y = y
    self.w = 60
    self.h = 50
    self.path = STATIC_SPRITE
    self.tile_x = 0
    self.tile_y = 0
    self.tile_h = 20
    self.tile_w = 24
    # self.r = 0
    # self.g = 0
    # self.b = 0
    self.speed = 6
    self.player_jump_power = 9
    self.player_jump_power_duration = 3
    self.player_speed_slowdown_rate = 0.9
    self.dy = 0
  end

  def run(distance)
    self.path = MOVE_SPRITE
    self.tile_x = 24 * ((distance / 25).floor % 8)
  end

  def stand
    self.path = STATIC_SPRITE
    self.tile_x = 0
  end

  def jump(tick_count)
    self.jumped_at ||= tick_count # set to current frame
    return unless self.jumped_at.elapsed_time < player_jump_power_duration # && !s.player.falling

    self.dy = player_jump_power
    # s.player.dx *= s.player_speed_slowdown_rate # scales dx down
  end

  def calc(grid, floor, gravity)
    self.y += dy
    self.dy += gravity
    self.x = x.clamp(0, grid.w - w)
    self.y = self.y.clamp(floor, grid.h - h)
    return unless self.y <= floor

    self.dy = 0
    self.jumped_at = nil
  end
end
