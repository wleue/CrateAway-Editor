' Sokoban Level Editor
' Rev 1.0.0 William M Leue 28-Oct-2023

option default integer
option base 1

' Constants

' arena size limits
const MAX_LEVELS       = 99
const MIN_ARENA_WIDTH  = 5
const MAX_ARENA_WIDTH  = 25
const MIN_ARENA_HEIGHT = 5
const MAX_ARENA_HEIGHT = 18

' editing commands
const UP     = 128
const DOWN   = 129
const LEFT   = 130
const RIGHT  = 131
const ESC    = 27
const SPACE  = 32
const DELETE = 127
const PGUP   = 136
const PGDOWN = 137
const FLOOR_CMD      = asc("F")
const WALL_CMD       = asc("W")
const PLAYER_CMD     = asc("P")
const CRATE_CMD      = asc("C")
const GOAL_CMD       = asc("G")
const DELETE_CMD     = asc("D")

' SOK tile symbols
const FLOOR$          = " "
const WALL$           = "#"
const GOAL$           = "."
const CRATE$          = "$"
const CRATEONGOAL$    = "*"
const PLAYER$         = "@"
const PLAYERONGOAL$   = "+"
const DELETED$        = "\"  ' non-standard for deleted tiles
const NUM_VALUES      = 8

' Tile Size
const TSIZE     = 32

' Globals
dim arena$(MAX_LEVELS, MAX_ARENA_WIDTH, MAX_ARENA_HEIGHT)
dim avalues$(NUM_VALUES) = (" ", "#", ".", "$", "*", "@", "+", "\")
dim tlocs(NUM_VALUES, 2)
dim width(MAX_LEVELS)
dim height(MAX_LEVELS)
dim comment$(MAX_LEVELS)
dim ax = 0
dim ay = 0
dim aw = 0
dim ah = 0
dim level = 0
dim pcol = 0
dim prow = 0
dim nlevels = 0
dim pickedup = 0
dim pickupch$ = ""
dim fn$ = ""

' Main Program
'open "debug.txt" for output as #1
page write 2 : cls
load png "CrateAwaySprites.png"
box 96, 96, TSIZE, TSIZE,, rgb(gray), rgb(black)
ReadTlocs
page write 0
ShowHelp
cls
do
  z$ = INKEY$
loop until z$ = ""
print "Enter Filename for existing map (',sok' will be added) or just ENTER for a new map"
input "Your filename: ", fn$
if len(fn$) = 0 then
  print "Enter filename for a NEW levels file ('.sok' will be added): ";
  input "Your filename: ", fn$
  if len(fn$) = 0 then end
  if instr(1, fn$, ".sok") = 0 then
    cat fn$, ".sok"
  end if
  level = 1
  Init
else
  if instr(1, fn$, ".sok") = 0 then
    cat fn$, ".sok"
  end if
  LoadMap fn$
end if
cls
more = 0
do
  DrawMap level
  HandleEvents
  SaveMap
  AskNewLevel more
loop until more = 0
end

' Read the tile location offsets for page 2
sub ReadTlocs
  local i
  for i = 1 to NUM_VALUES
    read tlocs(i, 1) : read tlocs(i, 2)
  next i
end sub

' Initialize Map Level
sub Init
  local row, col, ok, a$, m$
  do
    ok = 1
    m$ = "(" + str$(MIN_ARENA_HEIGHT) + ".." + str$(MAX_ARENA_HEIGHT) + ")"
    print "Enter desired maximum arena height " + m$ + ": ";
    input "", a$
    height(level) = val(a$)
    if (height(level) < MIN_ARENA_HEIGHT) or (height(level) > MAX_ARENA_HEIGHT) then
      print "Your value is out of range - please try again."
      ok = 0
    end if
  loop until ok
  do
    ok = 1
    m$ = "(" + str$(MIN_ARENA_WIDTH) + ".." + str$(MAX_ARENA_WIDTH) + ")"
    print "Enter desired maximum arena width " + m$ + ": ";
    input "", a$
    width(level) = val(a$)
    if (width(level) < MIN_ARENA_WIDTH) or (width(level) > MAX_ARENA_WIDTH) then
      print "Your value is out of range - please try again."
      ok = 0
    end if
  loop until ok
  print "Enter level comment for level ";level;": ";
  input "", comment$(level)
  for row = 1 to height(level)
    for col = 1 to width(level)
      if row = 1 then
        arena$(level, col, row) = WALL$
      else if row = height(level) then
        arena$(level, col, row) = WALL$
      else
        arena$(level, col, row) = FLOOR$
      end if
      if (col = 1) or (col = width(level)) then
        arena$(level, col, row) = WALL$
      end if
    next col
  next row
  nlevels = level
end sub

' Draw the Arena Map
sub DrawMap level
  local row, col, x, y, tx, ty, m$, c
  aw = width(level)*TSIZE
  ah = height(level)*TSIZE
  ax = mm.hres\2 - aw\2
  ay = mm.vres\2 - ah\2
  for row = 1 to height(level)
    for col = 1 to width(level)
      DrawCell level, col, row, 0, arena$(level, col, row)
    next col
  next row
  m$ = "Level " + str$(level)
  text mm.hres\2, 1, m$, "CT", 7,, rgb(black), rgb(white)
end sub

' Draw the specified cell in the arena
sub DrawCell level, col, row, hilite, c$
  DrawTile col, row, GetIndex(c$), hilite
end sub

' Given an arena character, return its number index (1..NUM_VALUES)
function GetIndex(c$)
  local i
  GetIndex = 0
  for i = 1 to NUM_VALUES
    if avalues$(i) = c$ then
      GetIndex = i
      exit function
    end if
  next i
end function

' Draw a specified tile at the specified location
sub DrawTile col, row, which, hilite
  local tx, ty, ec
  x = ax + (col-1)*TSIZE
  y = ay + (row-1)*TSIZE
  if hilite = 1 then
    ec = rgb(green)
  else if hilite = 2 then
    ec = rgb(red)
  end if
  tx = tlocs(which, 1) : ty = tlocs(which, 2)
  blit tx, ty, x, y, TSIZE, TSIZE, 2
  if hilite then box x, y, TSIZE, TSIZE,, ec
end sub

' Event Handler
sub HandleEvents
  local z$, cmd, row, col, c$, fc$, hv, nch$
  row = 1 : col = 1
  z$ = INKEY$
  hv = 1
  do
    cmd = 0
    do
      z$ = INKEY$
    loop until z$ <> ""
    cmd = asc(UCASE$(z$))
    select case cmd
      case UP
        if row > 1 then
          inc row, -1
        else
          row = height(level)
        end if        
      case DOWN
        if row < height(level) then
          inc row
        else
          row = 1
        end if
      case LEFT
        if col > 1 then
          inc col, -1
        else
          col = width(level)
        end if
      case RIGHT
        if col < width(level) then
          inc col
        else
          col = 1
        end if
      case SPACE
        c$ = arena$(level, col, row)
        if pickedup then  ' drop item
          if (c$ <> FLOOR$) and (c$ <> GOAL$) then continue do
          if c$ = FLOOR$ then
            arena$(level, col, row) = pickupch$
            DrawCell level, col, row, 1, arena$(level, col, row)
          else if c$ = GOAL$ then
            if pickupch$ = PLAYER$ then
              arena$(level, col, row) = PLAYERONGOAL$
              DrawCell level, col, row, 1, arena$(level, col, row)
            else if pickupch$ = CRATE$ then
              arena$(level, col, row) = CRATEONGOAL$
              DrawCell level, col, row, 1, arena$(level, col, row)
            else
              continue do
            end if
          end if
          pickupch$ = ""
        else  ' pick up item
          c$ = arena$(level, col, row)
          if (c$ = FLOOR$) or (c$ = WALL$) or (c$ = DELETED$) then continue do
          select case c$
            case PLAYER$
              pickupch$ = PLAYER$
              c$ = FLOOR$
            case PLAYERONGOAL$
              pickupch$ = PLAYER$
              c$ = GOAL$
            case CRATE$
              pickupch$ = CRATE$
              c$ = FLOOR$
            case CRATEONGOAL$
              pickupch$ = CRATE$
              c$ = GOAL$
            case GOAL$
              pickupch$ = GOAL$
              c$ = FLOOR$
          end select
          DrawCell level, col, row, 2, pickupch$
          arena$(level, col, row) = c$
        end if
        pickedup = 1 - pickedup
      case DELETE, DELETE_CMD
        arena$(level, col, row) = DELETED$
        DrawCell level, col, row, 8, c$
      case FLOOR_CMD
        c$ = FLOOR$
        arena$(level, col, row) = c$
        DrawCell level, col, row, 1, c$
      case WALL_CMD
        c$ = WALL$
        arena$(level, col, row) = c$
        DrawCell level, col, row, 1, c$
      case PLAYER_CMD
        c$ = PLAYER$
        arena$(level, col, row) = c$
        DrawCell level, col, row, 1, c$
      case CRATE_CMD
        c$ = CRATE$
        arena$(level, col, row) = c$
        DrawCell level, col, row, 1, c$
      case GOAL_CMD
        c$ = GOAL$
        arena$(level, col, row) = c$
        DrawCell level, col, row, 1, c$
      case PGUP
        if level < nlevels then
          inc level
          cls
          DrawMap level
        end if
      case PGDOWN
        if level > 1 then
          inc level, -1
          cls
          DrawMap level
        end if
      case ESC
        exit do
      case else
        ' nothing
    end select
    if (col <> pcol) or (row <> prow) then
      if pcol > 0 then
        pc$ = arena$(level, pcol, prow)
        DrawCell level, pcol, prow, 0, pc$
      end if
      if pickedup then
        c$ = pickupch$
        DrawCell level, col, row, 2, c$
      else
        c$ = arena$(level, col, row)
        DrawCell level, col, row, 1, c$
      end if
    end if
    pcol = col : prow = row
  loop
end sub

' Return the value of a cell after pickup
function CellAfterPickup$(level, col, row)
  local c$
  c$ = arena$(level, col, row)
  if (c$ = PLAYERONGOAL$) or (c$ = CRATEONGOAL$) then
    CellAfterPickup$ = GOAL$
  else
    CellAfterPickup$ = FLOOR$
  end if
end function

' Get the current cell value
function GetCell$(col, row)
  GetCell$ = arena$(level, col, row)
end function

' Set the cell value to the specified value
sub SetCell col, row, value$
  arena$(level, col, row) = value$
end sub

' Read the arena map
sub LoadMap fn$
  local row, col, buf$, state, bl, sp, c$
  on error skip 1
  open fn$ for input as #2
  if mm.errno <> 0 then
    print "Error open file '";fn$;"': ";mm.errmsg$
    end
  end if
  state = 0
  level = 1
  height(level) = 0
  width(level) = 0
  do
    line input #2, buf$
    bl = len(buf$)
    if bl = 0 then continue do
    sp = instr(1, buf$, ";")
    if sp >= 1 then
      state = 0
      comment$(level) = MID$(buf$, sp+1)
      inc level
    else
      if bl > width(level) then width(level) = bl
      inc height(level)
      for i = 1 to bl
        c$ = MID$(buf$, i, 1)
        arena$(level, i, height(level)) = c$
      next i
    end if
  loop until eof(2)
  close #2
  inc level, -1
  nlevels = level
'PrintMap level
end sub

' Save the Map to a File in standard Sokoban form
sub SaveMap
  local i, row, col
  cls
  if fn$ = "" then
    print "Enter filename for saving Map ('.sok' will be added): ";
    input "", fn$
    if instr(1, fn$, ".sok") = 0 then
      cat fn$, ".sok"
    end if
  end if
  open fn$ for output as #2
  if mm.errno <> 0 then
    print "Error Opening file '";fn$;"': ";mm.errmsg$
    end
  end if
  for i = 1 to nlevels
    for row = 1 to height(i)
      for col = 1 to width(i)
        print #2, arena$(i, col, row);
        next col
      print #2, ""
    next row
    print #2, "; " + Strip$(comment$(i))
    print #2, ""
  next i
  close #2
  print "Levels Saved to file ";fn$
end sub

' Strip leading spaces from a string
function Strip$(s$)
  local i, h, sl, ss$, c$
  sl = len(s$)
  ss$ = ""
  h = 1
  for i = 1 to sl
    c$ = MID$(s$, i, 1)
    if (c$ <> " ") or (not h) then
      cat ss$, c$
      h = 0
    end if
  next i
  Strip$ = ss$
end function

' Ask user if they want to create another level
sub AskNewLevel more
  more = 0
  print "Do you want to create another level in this file? (Y,N): ";
  input "", a$
  if LEFT$(UCASE$(a$), 1) = "Y" then
    inc nlevels
    level = nlevels
    Init
    more = 1
  end if
end sub
  
' Beep for error
sub Beep
  play tone 800, 800, 300
end sub

' Help
sub ShowHelp
  local z$
  cls
  text mm.hres\2, 10, "Level Editor Help", "CT", 4,, rgb(green), -1
  print @(0, 30) ""
  print "The LevelEditor lets you create and modify Sokoban-type game levels."
  print "It reads and saves levels using standard '.sok' text format. Each file can have"
  print "up to 99 levels.
  print "On startup, you choose whether to create a new '.sok' file or work on an existing"
  print "file. If you are creating a new file, you specify the dimensions of the first level"
  print "in 'tile' units up to 25 tiles wide by 18 tiles high. The level opens up for editing"
  print "as a field of 'floor' tiles surrounded by 'wall' tiles on all sides."
  print "Use the keyboard arrow keys to navigate around the field. The current tile is hilited"
  print "with a green outline. You do not have to keep the starting rectangular area. You can"
  print "use the 'D' or DELETE key to delete the current tile; it will be replaced by a gray square in"
  print "the display. However, to be compatible with all Sokoban-type games, you need to keep"
  print "the remaining area completely surrounded by a wall. Although you can make the level"
  print "smaller by deleting tiles, you cannot make it larger than its starting size.
  print "To make a tile into a FLOOR, press the 'F' key. To make a tile into a wall, press the 'W'"
  print "key.
  print "To add a person to a tile, press the 'P' key. To add a crate, press the 'C' key, and to"
  print "add a goal, press the 'G' key.
  print "You can move players, crates, and goals. To move an object, navigate to it and press the"
  print "spacebar. The green outline will change to red. Use the arrow keys to move the object"
  print "to another square, and then press the spacebar again to drop the object in its new"
  print "location. Objects can only be dropped onto FLOOR tiles or GOAL tiles! GOAL objects cannot"
  print "be dropped onto anything except FLOOR tiles.
  print "When you have finished editing a level, press the Escape key to save the level to a '.sok'
  print "file. If this is a new file, you will be asked for a filename. After saving, you will be"
  print "asked if you want to add another level. If so, then you will be asked for the dimensions"
  print "of the new level, and you can then edit it.
  print "For each new level, you will be asked to enter a level comment. This comment will be"
  print "written to the '.sok' file after the semicolon that terminates the level."
  print "At any time during editing, you can use the keyboard PAGE UP and PAGE DOWN keys to switch"
  print "between levels."
  print ""
  print "Command summary:
  print "  Navigation:              keyboard arrow keys
  print "  Change levels:           PAGE UP and PAGE DOWN keys
  print "  Delete a tile:           D key or DELETE key
  print "  Add a person:            P key
  print "  Add a crate:             C key
  print "  Add a goal:              G key
  print "  Change to a FLOOR tile:  F key
  print "  Change to a WALL tile:   W key
  print "  Pick up or drop:         spacebar
  print "  Finished with level:     Escape key
  text mm.hres\2, mm.vres-1, "Press Any Key to Continue", "CB"
  z$ = INKEY$
  do
    z$ = INKEY$
  loop until z$ <> ""
end sub

' Tile locations on page 2
data 32, 0  ' Floor
data 64, 0  ' Wall
data 64, 32 ' Goal
data 0 , 32 ' Crate
data 32, 32 ' Crate on Goal
data 0,  0  ' Player
data 96, 0  ' Player on Goal
data 96, 96 ' Deleted tile

' ========================
' End of Source Code
' ========================
