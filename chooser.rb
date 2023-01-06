require 'gosu'

require './gm.rb'

def isin(x, y, bb, inclusive)
    bx, by, w, h = bb
    if !inclusive
        bx -= 1
        by -= 1
        w -= 2
        h -= 2
    end
    bx <= x && x <= bx + w && by <= y && y <= by + h
end

class Chooser
    attr_accessor :chosen, :gm
    def initialize(gm)
        @chosen = nil
        @gm = gm
        @font = Gosu::Font.new(30, {bold: true})
    end

    def message
        "?"
    end

    def possible()
    end

    def choose(mouse_locations)
    end
    
    def draw(times, mouse_x, mouse_y)
        @font.draw_text(message, 5, 5, 0, 1, 1, 0xFF_FFFFFF)
    end

    def setChosen(chosen)
        @chosen = chosen
    end

    def getChosen
        @chosen
    end

    def release
        setChosen(nil)
    end
end

class SkillChooser < Chooser
    def initialize(gm)
        super(gm)
        gm.offenceArr.each {|ply|
            ply.hand.each{|crd|
                crd.release
                crd.playable = ply.life > 0 && ply.mana >= crd.cost
            }
        }
    end

    def possible()
        @gm.offenceArr.each_with_index{|ply, i|
            ply.hand.each_with_index{|crd, j|
                return true if crd.playable
            }
        }
        return false
    end

    def choose(mouse_locations)
        ignore_bb = @gm.turn == "enemy"
        mouse_locations.append([-1, -1]) if ignore_bb
        for mx, my in mouse_locations
            @gm.offenceArr.each_with_index{|ply, i|
                ply.hand.each_with_index{|crd, j|
                    hit = crd.playable && (ignore_bb || isin(mx, my, crd.bb, false))
                    if hit
                        ply.select
                        crd.select
                        setChosen([i, j])
                        break
                    end
                }
                break if getChosen
            }
            break if getChosen
        end
    end

    def message
        "#{@gm.turn} turn: Which skill?"
    end

    def chosenPlayer
        chosen = getChosen
        @gm.offenceArr[chosen[0]]
    end

    def chosenCard
        chosen = getChosen
        @gm.offenceArr[chosen[0]].hand[chosen[1]]
    end
end

class MeChooser < Chooser
    def initialize(gm, ply)
        super(gm)
        @me = ply
    end

    def choose(mouse_locations)
        setChosen(@me)
    end

    def message
        "Targeting myself!"
    end

    def targetArr
        [getChosen]
    end
end

class EnemyChooser < Chooser
    def initialize(gm)
        super(gm)
        gm.offenceArr.each{|ply| ply.targetable = false}
        gm.defenceArr.each{|ply| ply.targetable = ply.life > 0}
    end

    def choose(mouse_locations)
        ignore_bb = @gm.turn == "enemy"
        mouse_locations.append([-1, -1]) if ignore_bb
        for mx, my in mouse_locations
            @gm.defenceArr.each_with_index{|ply, i|
                hit = ply.targetable && (ignore_bb || isin(mx, my, ply.bb, false))
                if hit
                    ply.select
                    setChosen(ply)
                    break
                end
            }
            break if getChosen
        end
    end

    def message
        "#{@gm.turn} turn: Which enemy?"
    end

    def targetArr
        [getChosen]
    end
end

def createTargetChooser(gm, ply, targetType)
    case targetType
    when "me"
        return MeChooser.new(gm, ply)
    when "enemy"
        return EnemyChooser.new(gm)
    end
end
