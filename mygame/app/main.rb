require 'app/player'
require 'app/dog_bot'

class LaserGame
  attr_gtk

  def s
    # L'état ou un nouvel état
    state.laser_game ||= state.new_entity(:laser_game)
    state.laser_game
  end

  def tick
    init_game
    render
    calc
    input
  end

  def init_game
    s.floor ||= 250
    s.gravity = -0.3 # what goes up must come down because of gravity
    s.player ||= Player.new(s.floor)
    s.speed = 6
    s.distance ||= 0
    s.gravity = -0.3 # what goes up must come down because of gravity
    s.tick_count = state.tick_count
    s.lasers ||= []
    s.targets ||= 3.times.map { |_t| spawn_targets }
    s.dogs ||= 3.times.map { |t| DogBot.new(t * (s.distance + 1000)) }
    s.score ||= 0
    s.boundaries ||= [
      {x: 0, y: s.floor, x2: grid.w, y2: s.floor, r: 0, g: 0, b: 0},
      {x: 0, y: grid.h - 250, x2: grid.w, y2: grid.h - 250, r: 0, g: 0, b: 0}
    ]
    s.background ||= {x: 0, y: s.floor, w: grid.w, h: grid.h - 500, r: 0, g: 198, b: 94}
  end

  def input
    if inputs.left
      s.distance -= s.speed
      s.player.run(s.distance)
    elsif inputs.right
      s.distance += s.speed
      s.player.run(s.distance)
    else
      s.player.stand
    end

    if inputs.mouse.click || inputs.keyboard.key_down.enter
      # d'où part le laser
      base_x = s.player.x + 28
      base_y = s.player.y + 24
      s.lasers << Laser.new(
        base_x,
        base_y,
        [base_x, base_y].angle_to(args.inputs.mouse)
      )
    end

    return unless inputs.keyboard.key_down.space

    s.player.jump(s.tick_count)
  end

  def calc
    s.targets.each { |t| t.x = t.base_x - s.distance }
    s.dogs.each do |d|
      d.base_x -= d.speed
      d.x = d.base_x - s.distance
      d.move

      # When you fall, another rise
      s.dogs << DogBot.new(s.distance + 1000 + rand(500)) if d.base_x < 0
    end

    s.dogs.filter! { |d| d.base_x > 0 }

    s.lasers.each do |laser|
      laser.move

      if laser.x > grid.w || laser.x < 0 || laser.y < s.boundaries[0].y || laser.y > s.boundaries[1].y
        laser.dead = true
        next
      end

      s.targets.each do |target|
        next unless geometry.intersect_rect?(target, laser)

        target.dead = true
        laser.dead = true
        s.score += 1
        s.targets << spawn_targets
      end

      s.dogs.each do |dog|
        next unless geometry.intersect_rect?(dog, laser)

        dog.dead = true
        laser.dead = true
        s.score += 1
        s.dogs << spawn_dogs
      end
    end
    s.player.calc(grid, s.floor, s.gravity)
    s.targets.reject! { |t| t.dead }
    s.lasers.reject! { |f| f.dead }
    s.dogs.reject! { |d| d.dead }
  end

  def render
    outputs.lines << s.boundaries
    outputs.sprites << [s.player, s.lasers, s.dogs]
    outputs.solids << [s.background, s.targets]
    outputs.labels << [
      {x: 40, y: grid.h - 40, text: "last dog: #{s.dogs.first&.x}", size_enum: 4},
      {x: 700, y: grid.h - 40, text: "distance: #{s.distance}", size_enum: 4}
    ]
  end

  def spawn_targets
    # size = 64
    base_x = s.distance + 1000 + rand(1000)
    Obstacle.new(
      base_x,
      s.floor
    )
  end

  def spawn_dogs
    # size = 64
    base_x = s.distance + 1000 + rand(1000)
    d = DogBot.new(base_x)
    d.x = d.base_x - s.distance
    d
  end
end

$game = LaserGame.new

def tick(args)
  $game.args = args
  $game.tick
end

$gtk.reset

class Solid
  attr_accessor(:x, :y, :w, :h, :r, :g, :b, :a, :anchor_x, :anchor_y, :blendmode_enum, :dead)

  def primitive_marker
    :solid
  end
end

class Sprite
  attr_accessor :x, :y, :w, :h, :path, :angle, :a, :r, :g, :b, :tile_x,
                :tile_y, :tile_w, :tile_h, :flip_horizontally,
                :flip_vertically, :angle_anchor_x, :angle_anchor_y, :id,
                :angle_x, :angle_y, :z,
                :source_x, :source_y, :source_w, :source_h, :blendmode_enum,
                :source_x2, :source_y2, :source_x3, :source_y3, :x2, :y2, :x3, :y3,
                :anchor_x, :anchor_y, :scale_quality_enum,
                :dead

  def primitive_marker
    :sprite
  end

  def serialize
    {}
  end

  def inspect
    serialize
  end
end

class Laser < Sprite
  attr_accessor :direction

  SPEED = 24

  def initialize(x, y, direction)
    super
    self.x = x
    self.y = y
    self.direction = direction
    self.w = 32
    self.h = 5
    self.path = :pixel
    self.angle = direction
    self.r = 0
    self.g = 0
    self.b = 0
  end

  def move
    self.x += (direction.vector_x * SPEED)
    self.y += (direction.vector_y * SPEED)
  end
end

class Obstacle < Solid
  attr_accessor :base_x

  def initialize(x, y)
    self.base_x = x
    self.x = x
    self.y = y
    self.w = 32
    self.h = 64
  end
end
