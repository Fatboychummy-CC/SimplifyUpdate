local ARGS = table.pack(...)
local SIMPLIFILE_NAME = "Simplifile"
local SELF_DIR = shell.dir()

local simplifileRemote, simplifileData

local function printUsage(reason)
  print()
  print("Usage: SimplifyUpdate [simplifile] [clean]")
  error(reason, 0)
end

local function action(level, ...)
  local args = table.pack(...)
  local str = table.concat(args, ' ')
  local lines = {}
  local maxX = term.getSize() - 11
  local line = {}
  local new = true

  local function insertLine(data)
    -- pad short text to ensure proper length
    -- cut long text to ensure proper length

    lines[#lines + 1] = string.format(string.format("%%%ds", -maxX), table.concat(data, ' ')):sub(1, maxX)
    new = false
  end

  -- cut input into words, then combine them into multiple lines for printing
  for word in str:gmatch("%S+") do
    line[#line + 1] = word -- insert the word

    -- if the line is now too long
    if #table.concat(line, ' ') > maxX then
      -- remove the current word, adding it makes the line too long.
      line[#line] = nil

      -- add the line to the list
      insertLine(line)

      -- start the next line, ensuring the line isn't too long
      if #word > maxX then
        word = "[removed]"
      end
      line = {word}
      new = true
    end
  end
  if new then
    insertLine(line)
  end

  local function createBlit(str, second)
    return string.format(second and "           %s" or "[UPDATER]: %s", str),
           string.format(
             "01111111000%s",
             string.rep(
               level == 1 and '8'
               or level == 2 and '4'
               or level == 3 and 'e'
               or '0',
               #str
             )
           ),
           string.format(string.rep(' ', 11 + #str))
  end

  for i = 1, #lines do
    term.blit(createBlit(lines[i], i ~= 1))
    print()
  end
end

-- Check arguments
if not ARGS[1] and not fs.exists(fs.combine(SELF_DIR, "Simplifile")) then
  printUsage("No arguments given, but local Simplifile was not found.")
end

-- Determine the remote location
if not ARGS[1] then
  action(1, "Determining remote location from local Simplifile.")
  local handle, err = io.open(fs.combine(SELF_DIR, "Simplifile"))
  if not handle then
    action(3, "Failed to open Simplifile for reading:")
    printError(err)
    return
  end
  local data = handle:read("*a")
  handle:close()

  data = textutils.unserialize(data)

  simplifileRemote = data.remote_location
else
  simplifileRemote = ARGS[1]
end

action(1, "Checking remote location URL validity.")
-- Check validity.
local isValid, err = http.checkURL(simplifileRemote)
if not isValid then
  action(3, string.format("Invalid URL: %s", err))
  printUsage("Invalid URL given by user or Simplifile.")
end

-- clean current working directory, if needed.
if ARGS[2] and ARGS[2]:lower() == "clean" then
  local files = fs.list(SELF_DIR)
  action(string.format("Cleaning %d files/folders in current directory.", #files))

  for i = 1, #files do
    action(string.format("Removing %s", files[i]))
    fs.delete(files[i])
  end
end
