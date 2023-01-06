require 'gosu'
require './player.rb'
require './card.rb'
require './gm.rb'

class MainWindow < Gosu::Window
    def initialize
        super 800, 600
        self.caption =
         "Slay the Ghosts!!!"
            
        @stage = 0
        @gm = nil

        @times = 0.0

        @bg_wall = Gosu::Image.new("./images/bg_wall.png")
        @bg_enemy = Gosu::Image.new("./images/bg_night.png")

        @mouse_locations = []
    end

    def update
        @times += update_interval

        createStage if !@gm || @gm.state == "win"
        exit() if ["lose", "draw"].include?(@gm.state)

        @gm.update(@mouse_locations)

        @mouse_locations = []
    end

    def draw
        return if !@gm
        @bg_wall.draw(0, 0, 0, width.to_f / @bg_wall.width, height.to_f / @bg_wall.height, 0x60_FFFFFF)
        #@bg_enemy.draw(30, 30, 0, 450.0 / @bg_enemy.width, 140.0 / @bg_enemy.height)
        @gm.draw(@times, mouse_x, mouse_y)
    end

    def createPlayer
        plyArr = []
        plyArr.append(Player.new("Fighter"))
        plyArr
    end

    def createEnemy1
        enmArr = []
        enmArr.append(Player.new("A Ghost"))
        enmArr
    end
    
    def createEnemy2
        enmArr = []
        3.times do
            enmArr.append(Player.new("A Tiny Ghost"))
        end        
        enmArr
    end
        
    def createEnemy3
        enmArr = []
        enmArr.append(Player.new("The King of Ghost"))
        enmArr
    end

    def createStage
        case @stage
        when 0
            plyArr = createPlayer
            enmArr = createEnemy1
            @gm = GM.new(plyArr, enmArr)
            @stage = 1
            @music = Gosu::Song.new("./sounds/PerituneMaterial_8bitRPG_Battle.mp3")
            @music.volume = 0.5
            @music.play(true)    
        when 1
            plyArr = @gm.plyArr
            enmArr = createEnemy2
            @gm = GM.new(plyArr, enmArr)
            @stage = 2
            @music = Gosu::Song.new("./sounds/PerituneMaterial_8bitRPG_Battle.mp3")
            @music.volume = 0.5
            @music.play(true)

        when 2
            plyArr = @gm.plyArr
            enmArr = createEnemy3
            @gm = GM.new(plyArr, enmArr)
            @stage = 3
            @music = Gosu::Song.new("./sounds/PerituneMaterial_BattleField5.mp3")
            @music.volume = 0.5
            @music.play(true)
        else
            exit() # TODO: game clear?
        end
    end

    def button_down(id)
        case id
        when Gosu::MsLeft
            @mouse_locations << [mouse_x, mouse_y]
        end
    end
end

MainWindow.new.show
