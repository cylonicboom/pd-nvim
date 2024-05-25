set print pretty on
define kill_player 
 if $argc != 1
  printf "kill_player: Usage: kill_player <player_id>\n"
  return
 end 
end

# vim: set ft=gdb tabstop=2 shiftwidth=2 expandtab:
