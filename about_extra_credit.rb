class DiceSet
  attr_reader :values

  def initialize
    @values = []
  end

  def roll(tim)
    @values = []
    tim.times { @values << 1+rand(6) }
    @values
  end

  def score(dice)
    if dice.empty?
      return 0
    else
      # A hash with key -> the face value of dice roll and value -> number of times the value occurs in the dice array
      dice_dict = Hash.new(0)
      dice.each { |roll_value| dice_dict[roll_value] += 1 }

      # Scoring logic
      score = 0
      dice_dict.keys.each do | roll_value |
        if dice_dict[roll_value] >= 3
          score += roll_value == 1 ? 1000 : roll_value*100
          dice_dict[roll_value] -= 3
        end
        if roll_value == 1 || roll_value == 5
          multiply = (roll_value == 1) ? 100 : 50
          score += dice_dict[roll_value]*multiply
          dice_dict.delete(roll_value)
        end
      end
      dice_dict.select! { |key, value| value > 0 }
      return score, dice_dict
    end
  end
end

class Player
  attr_accessor :name, :allowed_to_accumulate
  attr_reader :score

  @@dice_set = nil

  class DiceSetNotDefined < Exception
  end

  def Player.set_dice_set(dice_set)
    @@dice_set = dice_set
  end

  def initialize(name)
    raise ArgumentError.new('Name of a person cannot be empty') if name.nil? or name.strip.empty?
    @name = name.strip
    @score = 0
    @allowed_to_accumulate = false
  end

  def play_turn
    acc_score = 0
    num_dice = 5
    
    raise DiceSetNotDefined if @@dice_set.nil?

    loop do
      puts "\n\n\n #{self} is rolling #{num_dice} dices... Press Enter to continue."
      gets.chomp
      rolled_array = @@dice_set.roll num_dice
      puts "#{self} rolled #{rolled_array}."
      roll_score, non_scoring = @@dice_set.score(rolled_array)
      puts "The score in current roll is #{roll_score} with non-scoring dices #{non_scoring}"

      if !allowed_to_accumulate
        puts "The player is not yet allowed to accumulate scores!"
        return roll_score
      end
      
      if roll_score == 0
        puts "You lose your chance as you scored zero in this roll. Your total score is #{self.score}."
        acc_score = 0
        return roll_score
      end

      acc_score += roll_score
      num_dice = non_scoring.values.inject { |sum, values| sum + values}
      num_dice = 5 if(num_dice == 0 || num_dice.nil?)
      is_s = (num_dice > 1) ? "s" : ""
      puts "Enter 'yes' if you want to roll #{num_dice} dice#{is_s} again. Your accumulated score uptil now is #{acc_score}. And your total score is #{@score}."
      response = gets.chomp

      if not response.downcase.include?("yes")
        @score += acc_score
        puts "You forfieted your turn."
        break
      end

    end
    puts "Your total score is #{@score}."
    return @score
  end

  def to_s
    "#{self.name} with score #{self.score}"
  end

  def inspect
    self.to_s
  end
end

class Game
  attr_reader :players

  def initialize
    @players = []
    @next_turn = 0
    @completed = false
    Player.set_dice_set(DiceSet.new)
  end

  def start(no_of_players)
    raise ArgumentError.new('Number of Players must be greater than 1') if no_of_players < 2
    puts "New game with #{no_of_players} players is now started !"
    no_of_players.times do | num |
      puts "Enter the name of player #{num+1} -"
      temp_player = nil
      while temp_player.nil?
          begin
            temp_player = Player.new(gets.chomp)
          rescue
            puts "The Player name cannot be empty! Enter the player's name again -"
          end
      end
      @players << temp_player
    end
    @stop_game_at = no_of_players+1
  end

  def play_turn
    # returns true if the game is completed


    # Check if the last round was the final round
    if @next_turn == @stop_game_at
      puts "The game is over."
      return true
    end

    next_player = self.next_turn
    player_score = next_player.play_turn

    if player_score >= 300
      if !next_player.allowed_to_accumulate
        next_player.allowed_to_accumulate = true
        puts "#{next_player} is now allowed to accumulate scores from the next turn!"
      elsif player_score >= 3000 && !@completed
        @stop_game_at = @next_turn
        puts "----------\nPlayer #{next_player} reached #{player_score}.\nThis is the Final Round!\n----------"
        @completed = true
      end
    end

    self.increment_turn
    false
  end

  def results
    @players.sort_by! { |player| player.score }
    @players.reverse!
    puts "\nThe players and their scores are -"
    puts @players
    puts "\nThe winner is -- #{@players[0]}"
  end

  def increment_turn
    @next_turn += 1
    @next_turn = 0 if @next_turn >= @players.size
  end

  def next_turn
    @players[@next_turn]
  end
end


new_game = Game.new

puts "Starting a new game..."
puts "Enter the number of players - "

loop do
  begin
    num_players = gets.chomp.to_i
    new_game.start(no_of_players=num_players)
    break
  rescue ArgumentError
    puts "Number of players must be a number and must be at least 2. Enter the number of players - "
  end
end

puts "players #{new_game.players}"
loop do
  puts "\nturn - #{new_game.next_turn}"
  break if new_game.play_turn
end
new_game.results
