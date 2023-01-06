require 'gosu'
require './player.rb'
require './card.rb'
require './gm.rb'

class MainWindow < Gosu::Window
    def initialize
        super 800, 720
        self.caption =
         "Slay the Ghosts!!!"
            
        @stage = 0
        @gm = nil

        @times = 0.0

        @bg_wall = Gosu::Image.new("./images/bg_wall.png")
        #@bg_enemy = Gosu::Image.new("./images/bg_night.png")

        @music = Gosu::Song.new("./sounds/PerituneMaterial_8bitRPG_Battle.mp3")
        #@music = Gosu::Song.new("./sounds/PerituneMaterial_BattleField5.mp3")
        @music.volume = 0.5
        @music.play(true)

        @mouse_locations = []
    end

    def update
        @times += update_interval

        if !@gm
            if @stage == 0
                @gm = createStage1
                @stage = 1
            end
        end

        @gm.update(@mouse_locations)

        @mouse_locations = []
    end

    def draw
        @bg_wall.draw(0, 0, 0, width.to_f / @bg_wall.width, height.to_f / @bg_wall.height, 0x60_FFFFFF)
        #@bg_enemy.draw(30, 30, 0, 450.0 / @bg_enemy.width, 140.0 / @bg_enemy.height)
        @gm.draw(@times, mouse_x, mouse_y)
    end

    def createStage1()
        plyArr = []
        1.times do
            plyArr.append(Player.new("Fighter"))
        end

        enmArr = []
        3.times do
            enmArr.append(Player.new("A Tiny Ghost"))
        end        
        GM.new(plyArr, enmArr)
    end

    def button_down(id)
        case id
        when Gosu::MsLeft
            @mouse_locations << [mouse_x, mouse_y]
        end
    end
end

MainWindow.new.show
