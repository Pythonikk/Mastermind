# frozen_string_literal: true

# defines rules of the game
class Instructions
  def initialize; end

  def self.display
    puts "\n\n--------Mastermind--------\n\n"
    puts 'The codebreaker gets 12 attempts to break the code.'
    puts 'The code is 4 digits containing numbers 1-6 (i.e 1416).'
    puts 'After each attempt, feedback is given about the guess.'
    puts "Feedback is given as symbols:\n\n"
    puts '-- ☂  indicates the existence of a correct number but in the wrong position.'
    puts "-- ☀  indicates a correct number that's in the correct position.\n\n"
    puts 'Feedback is not ordered. A guess of 4125 with feedback '\
      "☀ ☂  does not mean 4 is given ☀  and 1 is given ☂ \n\n"
    puts 'Scoring: 1 point is given to the codemaker for each '\
      'guess the codebreaker makes. An additional point is awarded '\
      'if the codebreaker is unable to guess the code in 12 turns.'
  end
end

# defines player
class Player
  attr_reader :games, :start_position
  def initialize
    @games = number_of_games
    @start_position = maker_or_breaker
  end

  def number_of_games
    prompt_num_of_games
    loop do
      num = input.to_i
      break num if num.even?

      puts 'Must choose an even number for fair play.'
    end
  end

  def maker_or_breaker
    prompt_position
    loop do
      position = input
      break position if valid?(position)

      puts "\n\nPlease enter 'codebreaker' or 'codemaker'."
    end
  end

  def valid?(position)
    %w[codebreaker codemaker].include?(position)
  end

  def input
    gets.chomp
  end

  def prompt_position
    puts "\n\nDo you want to start as the codebreaker or codemaker?"
  end

  def prompt_num_of_games
    puts "\n\nA winner is determined after a set (even)number of rounds."
    puts 'How many rounds would you like to play?'
  end
end

# defines the game board
class Board
  attr_accessor :board
  def initialize
    @board = {}
  end

  def update(turn, guess, feedback)
    board[turn] = guess, feedback
  end

  def display
    board.each do |key, value|
      puts "\n\nTurn #{format(key)}  =>  #{format(value[0])}  |  #{format(value[1])}"
    end
  end

  def format(element)
    if element.class == Integer && element < 10
      '0' + element.to_s
    else
      element.to_s.gsub(/[",\[\]]/, '"': '', ',': '', '[': '', ']': '')
    end
  end
end

# defines the secret code
class Codemaker
  attr_reader :maker, :secret_code
  def initialize(maker)
    @maker = maker
    @secret_code = random_code if maker == 'computer'
    @secret_code = set_code if maker == 'player'
  end

  def random_code
    code = []
    4.times { code << rand(1..6) }
    code
  end

  def set_code
    puts "\n\nEnter the code for the computer to guess:"
    loop do
      code = format(input)
      break code if valid?(code)

      puts "\n\nA valid code is 4 digits and contains only numbers 1-6."
    end
  end

  def input
    gets.chomp
  end

  def valid?(code)
    code.length == 4 && code.all?(1..6)
  end

  def format(code)
    code.split('').map(&:to_i)
  end
end

# defines the players attempt to break the code
class PlayerBreaker
  attr_reader :guess

  def initialize
    @guess = attempt
  end

  def attempt
    puts "\n\nGuess the code:"
    loop do
      guess = format(input)
      break guess if valid?(guess)

      puts 'Enter a 4 digit code containing numbers 1-6.'
    end
  end

  def input
    gets.chomp
  end

  def format(input)
    input.split('').map(&:to_i)
  end

  def valid?(attempt)
    attempt.length == 4 && attempt.all?(1..6)
  end
end

# defines the computer's attempt to break the code
class ComputerBreaker
  @included_nums = []
  @permutations = nil
  @guesses = []

  class << self
    attr_accessor :included_nums, :permutations, :guesses
  end

  attr_reader :turn_number, :feedback, :guess

  def initialize(feedback, turn_number)
    @feedback = feedback
    @turn_number = turn_number
    @guess = []
    take_turn
  end

  def self.reset_class_vars
    self.included_nums = []
    self.permutations = nil
    self.guesses = []
  end

  def take_turn
    # first find the correct four digits.
    if ComputerBreaker.included_nums.length < 4
      include_nums if feedback
      find_nums
    end
    return unless ComputerBreaker.included_nums.length == 4

    find_permutations
    eliminate_previous_guesses
    @guess = random_permutation
    ComputerBreaker.guesses << guess
  end

  def find_nums
    if turn_number < 6
      4.times { guess << turn_number }
    else
      (4 - ComputerBreaker.included_nums.length).times { ComputerBreaker.included_nums << 6 }
    end
  end

  def include_nums
    # - 1 because it's feedback from the previous turn.
    feedback.length.times { ComputerBreaker.included_nums << turn_number - 1 }
  end

  def find_permutations
    ComputerBreaker.permutations = ComputerBreaker.included_nums.permutation(4).to_a
  end

  def eliminate_previous_guesses
    ComputerBreaker.guesses.each do |guess|
      ComputerBreaker.permutations.delete(guess)
    end
  end

  def random_permutation
    ComputerBreaker.permutations.sample
  end
end

# defines feedback on an attempt
class Feedback
  attr_accessor :feedback
  attr_reader :attempt, :secret_code
  def initialize(attempt, secret_code)
    @attempt = attempt
    @secret_code = secret_code
    @feedback = []
    analyze_attempt
  end

  def analyze_attempt
    secret_code.each_with_index do |num, index|
      if secret_code[index] == attempt[index]
        add_feedback('☀ ')
      elsif attempt.include?(num)
        next unless secret_code[0..index].include?(num)

        add_feedback('☂ ')
      end
    end
  end

  def add_feedback(symbol)
    feedback << symbol
    feedback.shuffle!
  end
end

# defines the course of the game
class Game
  @round_number = 0
  @player_position = nil
  @player_score = 0
  @computer_score = 0

  class << self
    attr_accessor :round_number, :player_score, :computer_score, :player_position
  end

  attr_reader :board, :maker, :feedback, :player, :breaker
  attr_accessor :turn_number

  def initialize(player)
    @player = player
    Game.player_position = determine_position
    @board = Board.new
    Game.round_number += 1
    display_new_game(Game.player_position)
    if Game.player_position == 'codebreaker'
      play_round('computer', 'player', 'computer')
    elsif Game.player_position == 'codemaker'
      play_round('player', 'computer', 'player')
    end
  end

  def determine_position
    if Game.round_number.zero?
      player.start_position
    else
      return 'codebreaker' if Game.player_position == 'codemaker'
      return 'codemaker' if Game.player_position == 'codebreaker'
    end
  end

  def display_new_game(position)
    puts "\n\n---------- Round #{Game.round_number} ----------"
    puts "Player: #{Game.player_score}    Computer: #{Game.computer_score}"
    return unless Game.round_number > 1

    puts "\n\nYour turn to be the codebreaker." if position == 'codebreaker'
    puts "\n\nYour turn to be the codemaker." if position == 'codemaker'
  end

  def play_round(whos_maker, whos_breaker, point_reciever)
    @turn_number = 0
    @maker = Codemaker.new(whos_maker)
    loop do
      @turn_number += 1
      initialize_breaker(whos_breaker)
      @feedback = Feedback.new(breaker.guess, maker.secret_code)
      board.update(turn_number, breaker.guess, feedback.feedback)
      board.display if whos_breaker == 'player'
      next unless round_over?

      award_points(point_reciever, turn_number)
      display_round_result(whos_breaker)
      break
    end
  end

  def initialize_breaker(whos_breaker)
    if whos_breaker == 'player'
      @breaker = PlayerBreaker.new
    elsif whos_breaker == 'computer'
      ComputerBreaker.reset_class_vars
      @breaker = ComputerBreaker.new(feedback&.feedback, turn_number)
    end
  end

  def code_cracked?
    maker.secret_code == breaker.guess
  end

  def round_over?
    code_cracked? || turn_number == 12
  end

  def award_points(reciever, turn_num)
    if reciever == 'player'
      Game.player_score += turn_num
      Game.player_score += 1 if turn_num == 12 && code_cracked? == false
    else
      Game.computer_score += turn_num
      Game.computer_score += 1 if turn_num == 12 && code_cracked? == false
    end
  end

  def display_round_result(whos_breaker)
    if whos_breaker == 'player'
      if turn_number == 12 && !code_cracked?
        puts "\n\nThe code is: #{maker.secret_code}"
      else
        puts "\n\nNailed it!"
      end
    elsif whos_breaker == 'computer'
      if turn_number == 12 && !code_cracked?
        puts "\n\n**The computer wasn't able to guess your code.**"
      else
        puts "\n\n**The computer guessed your code on turn number #{turn_number}**"
      end
    end
  end
end

Instructions.display
player = Player.new
loop do
  game = Game.new(player)
  break if Game.round_number == player.games
end
puts "The final score is   Player:  #{Game.player_score}    "\
      "Computer:  #{Game.computer_score}"
puts 'Congratulations! You win!' if Game.player_score > Game.computer_score
