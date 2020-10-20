require './lib/board.rb'
require './lib/ship.rb'
require './lib/cell.rb'

class UserInterface
  attr_reader :user_board, :computer_board, :user_ships, :computer_ships

  def determine_play
    puts "Welcome to BATTLESHIP\nEnter 'p' to play. Enter 'q' to quit."
    get_requested_input("P", "Q")
  end

  def get_requested_input(continue_key, break_key)
    loop do
      input = gets.chomp.upcase
      if input == continue_key
        return :continue
        break
      elsif input == break_key
        return :break
        break
      else
        puts "Please enter a valid option."
      end
    end
  end

  def query_custom
    puts "Enter 'd' to play with default settings,  or enter 'c' to create a custom board and ships."
    if get_requested_input("C","D") == :continue
      print "Choose board size? (y/n) "
      if get_requested_input("Y", "N") == :continue
        custom_board
      else
        @board_width = 4
        @board_height = 4
      end
      print "Create custom ships? (y/n) "
      if get_requested_input("Y", "N") == :continue
        custom_ships
      end
    end
  end

  def custom_board
    print "Enter custom board width: "
    @board_width = get_integer(2,10, "Width")
    print "Enter custom board width: "
    @board_height = get_integer(2, 26, "Height")
  end

  def custom_ships
    @ships = []
    input = ""
    until input == :continue do
      print "Enter custom ship name: "
      name = gets.chomp.to_s.capitalize
      print "Enter #{name} length: "
      length = get_integer(1,[@board_width, @board_height].max, "Length")
      if (length + @ships.sum {|ship| ship[1]}) > (@board_width * @board_height)
        puts "There is not enough space left on the board for a ship of this length. #{name} cannot be created."
      else
        @ships << [name, length]
        puts "Created custom ship #{name} with length #{length} units"
      end
      puts "Enter 'c' to create another ship, or press 'd' for done."
      input = get_requested_input("D","C")
    end
    @ships.sort_by! {|ship| -ship[-1]}
  end

  def get_integer(min, max, description)
    input = gets.chomp.to_i
    until input >= min && input <= max do
      if input <= min
        print "#{description} cannot be smaller than #{min}. Please enter another value: "
      elsif input >= max
        print "#{description} cannot be greater than #{max}. Please enter another value: "
      end
      input = gets.chomp.to_i
    end
    input
  end

  def setup
    @user_board = create_board
    @computer_board = create_board
    @user_ships = create_ships
    @computer_ships = create_ships
  end

  def create_ships
    if @ships == nil
      [Ship.new("Cruiser", 3), Ship.new("Sumbarine", 2)]
    else
      @ships.map do |ship|
        Ship.new(ship[0], ship[1])
      end
    end
  end

  def create_board
      Board.new(@board_width, @board_height)
  end

  def prompt_ship_placement
    "I have laid out my ships on the grid.\n" +
    "You now need to lay out your #{@user_ships.length} ships:"
    @user_ships.map do |ship|
      "The #{ship.name} is #{ship.length} units long"
    end
  end

  def determine_ship_placement
    ships_index = 0
    while ships_index < (@user_ships.length)
      ship = @user_ships[ships_index]
      display_user_board
      puts "Enter the squares for the #{ship.name} (#{ship.length} spaces):"
      until place_ship(ship, input = gets.chomp.upcase) do
        puts "Those are invalid coordinates. Please try again: "
      end
      ships_index += 1
    end
  end

  def place_ship(ship,input)
    processed_input = input.gsub(",", " ").split(" ")
    if @user_board.valid_placement?(ship,processed_input)
      @user_board.place(ship,processed_input)
      true
    end
  end

  def turn
    display_turn_boards
    puts "Enter the coordinate for your shot:"
    determine_shot
  end

  def display_turn_boards
    puts "\n=============COMPUTER BOARD============="
    display_computer_board
    puts "==============PLAYER BOARD=============="
    display_user_board
  end

  def display_user_board
    puts @user_board.render(true)
  end

  def display_computer_board
    puts @computer_board.render
  end

  def determine_shot
    until rtrn = input_shot(gets.chomp.upcase) do
      if rtrn == false
        puts "You already shot there.  Please pick a new coordinate:"
      else
        puts "Please enter a valid coordinate:"
      end
    end
  end

  def input_shot(input)
    cell = @computer_board.cells[input]
    if !cell
      nil
    elsif cell.fired_upon?
      false
    else
      cell.fire_upon
      ship = cell.ship
      puts "Your shot on #{input}"+display_shot_result(!cell.empty?,ship)
      true
    end
  end

  def display_shot_result(hit,ship)
    if hit && ship.sunk?
      " was a hit.\nYou sunk my #{ship.name}!"
    elsif hit
      " was a hit."
    else
      " was a miss."
    end
  end

  def winner
    if @computer_ships.all? {|ship| ship.sunk?}
      "You won."
    elsif @user_ships.all? {|ship| ship.sunk?}
      "I won."
    else
      nil
    end
  end
end
