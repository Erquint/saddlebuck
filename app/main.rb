# --window_width 800 --window_height 600

# DR GTK 1.14
# c0a19ce1fa25044fcf0289bcd6e6f1d64988075d


# I shouldn't be doing it like this but here we go again…
module Giatros
  module Initialize
    def initialize args_hash
      args_hash.each{|key, value|
        instance_variable_set("@#{key}", value)
      }
    end
  end
  
  module Serialize
    def serialize
      instance_variables.map{|key|
        [key.to_s[1..-1].to_sym, instance_variable_get(key)]
      }.to_h
    end
    
    def inspect
      serialize.to_s
    end
    
    def to_s
      serialize.to_s
    end
  end
  
  module Rectangle
    def w= arg
      @w = arg
      calc_diagonal
    end
    
    def h= arg
      @h = arg
      calc_diagonal
    end
    
    private
    
    def calc_diagonal
      # @diagonal = Math.sqrt(@w**2 + @h**2).ceil
      @diagonal = GTK::Geometry.distance({x: @x, y: @y}, {x: @x + @w, y: @y + @h}).ceil
    end
  end
  
  class SolidBorder
    include Initialize
    include Serialize
    include Rectangle
    
    attr_accessor :x, :y, :r, :g, :b, :a, :extras
    attr_reader :w, :h, :primitive_marker, :fill, :diagonal
    
    def initialize args_hash
      super
      @x ||= 0
      @y ||= 0
      @w ||= 50
      @h ||= 50
      @r ||= 255
      @g ||= 255
      @b ||= 255
      @a ||= 255
      @fill ||= false
      calc_diagonal
      calc_primitive_marker
      [:x, :y, :w, :h, :r, :g, :b, :a,
        :primitive_marker, :fill, :diagonal].each{|key| args_hash.delete key}
      @extras = args_hash
    end
    
    def fill= arg
      @fill = arg
      calc_primitive_marker
    end
    
    private
    
    def calc_primitive_marker
      @primitive_marker = @fill ? :solid : :border
    end
  end
  
  class Vector2
    include Serialize
    
    attr_reader :magnitude, :x, :y
    
    def initialize args_hash
      @x = args_hash[:x]
      @y = args_hash[:y]
      calc_magnitude
    end
    
    def normal
      out = self.dup
      out.xlite = out.x / @magnitude
      out.y /= @magnitude
      return out
    end
    
    def x= arg
      @x = arg
      calc_magnitude
    end
    
    def y= arg
      @y = arg
      calc_magnitude
    end
    
    private
    
    def xlite= arg
      @x = arg
    end
    
    def calc_magnitude
      @magnitude = Math.sqrt (@x**2 + @y**2)
    end
  end
end

include Giatros

def tick args
  if args.state.tick_count == 0
    $state = {
      solids: {},
      borders: {},
      sprites: {},
      RTs: {},
      mouse: {},
      labels: {},
      timing: {},
      subject: {}
    }
    args.state.mundane = $state
    
    $state[:solids][:groundPlane] = SolidBorder.new({
      fill: true,
      w: args.grid.w,
      h: args.grid.h / 3,
      r: 255,
      g: 0,
      b: 0,
    })
  
    $state[:solids][:mainCharacter] = SolidBorder.new({
      fill: true,
      x: args.grid.w / 2,
      y: args.grid.h / 3 * 2,
      w: args.grid.w / 32,
      h: args.grid.h / 16,
      r: 20,
      g: 20,
      b: 20,
      mass: 1.0,
      velocity: {x: 0.0, y: 0.0},
      acceleration: Vector2.new({x: 0.0, y: 0.0}),
      force: {x: 0.0, y: 0.0}
    })
  end
  if (!!args.inputs.left ||
    !!args.inputs.right ||
    !!args.inputs.down ||
    !!args.inputs.up)
  then
    if args.inputs.left
      $state[:solids][:mainCharacter].extras[:acceleration].x = -1.0 end
    if args.inputs.right
      $state[:solids][:mainCharacter].extras[:acceleration].x = 1.0 end
    if args.inputs.down
      $state[:solids][:mainCharacter].extras[:acceleration].y = -1.0 end
    if args.inputs.up
      $state[:solids][:mainCharacter].extras[:acceleration].y = 1.0 end
  else
    $state[:solids][:mainCharacter].extras[:acceleration].x = 0
    $state[:solids][:mainCharacter].extras[:acceleration].y = 0
  end
  
  temp = $state[:solids][:mainCharacter].extras[:acceleration]
  $state[:solids][:mainCharacter].extras[:acceleration] =
    $state[:solids][:mainCharacter].extras[:acceleration].normal
  
  $state[:solids][:mainCharacter].extras[:velocity][:x] +=
    $state[:solids][:mainCharacter].extras[:acceleration].x
  $state[:solids][:mainCharacter].extras[:velocity][:y] +=
    $state[:solids][:mainCharacter].extras[:acceleration].y
  
  $state[:solids][:mainCharacter].x +=
    $state[:solids][:mainCharacter].extras[:velocity][:x]
  $state[:solids][:mainCharacter].y +=
    $state[:solids][:mainCharacter].extras[:velocity][:y]
  
  args.outputs.primitives << [
    $state[:solids][:groundPlane],
    $state[:solids][:mainCharacter]
  ]
  
  args.outputs.labels << [
    {
      x: args.grid.w / 2 - 200,
      y: args.grid.w / 2,
      text: temp.inspect
    }, {
      x: args.grid.w / 2 - 200,
      y: args.grid.w / 2 - 20,
      text: $state[:solids][:mainCharacter].extras[:acceleration].inspect
    }, {
      x: args.grid.w / 2 - 200,
      y: args.grid.w / 2 + 20,
      text: (!!args.inputs.left || !!args.inputs.right || !!args.inputs.down || !!args.inputs.up).inspect
    }, {
      x: args.grid.w / 2 - 200,
      y: args.grid.w / 2 + 40,
      text: (!!args.inputs.keyboard.key_held.a || !!args.inputs.keyboard.key_held.d || !!args.inputs.keyboard.key_held.s || !!args.inputs.keyboard.key_held.w).inspect
    }
  ]
end
