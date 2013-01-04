#!/usr/bin/env ruby

X = "X"
O = "O"
E = " "
POSITIONS = %w[ a1 a2 a3 b1 b2 b3 c1 c2 c3 ]
EXIT_MSG = "\n\nyou just can't seem to take tic-tac-toe seriously!\n\n"

def ask(question, a, b)
  print "#{question} (#{a}/#{b})> "
  r = $stdin.gets.strip

  4.times do
    unless r == a or r == b
      print "\nPlease type '#{a}' or '#{b}': "
      r = $stdin.gets.strip
    end
  end

  abort EXIT_MSG unless r == a or r == b
  r
end

def board(a)
  "
      1   2   3

  a   #{a[0]} | #{a[1]} | #{a[2]}
     ---+---+---
  b   #{a[3]} | #{a[4]} | #{a[5]}
     ---+---+---
  c   #{a[6]} | #{a[7]} | #{a[8]}
  "
end

def write(pos, char)
  $state[POSITIONS.index(pos)] = char
end

def player_move
  print "\nyour move> "
  move = $stdin.gets.strip
  v = 0
  
  4.times do
    unless v == 1

      if !POSITIONS.include?(move)
        print "\ninvalid move, try again> "
        move = $stdin.gets.strip
      elsif $state[POSITIONS.index(move)] != E
        print "\nplease choose an empty space> "
        move = $stdin.gets.strip
      else
        v = 1
      end
    end
  end

  abort EXIT_MSG unless v == 1

  write(move, $player_char)
end

def computer_move

end

# MAIN

unless ARGV[0] == "debug"
  system("clear")
  puts "\n  Welcome\n\n"
  sleep 1
  puts "     To\n\n"
  sleep 1
  puts "  T | I | C\n ---+---+---\n  T | A | C\n ---+---+---\n  T | O | E\n\n"
  sleep 1
end

case ask("Choose a side", "x", "o")
when "x"
  $player_char = X
  $computer_char = O
when "o"
  $player_char = O
  $computer_char = X
end

$player_first = ask("Do you wish to go first", "yes", "no")

$state = [ E, E, E, E, E, E, E, E, E ]
puts board($state)

player_move
puts board($state)
