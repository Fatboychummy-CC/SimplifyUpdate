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
  if args.n == 0 then error("No arguments given!", 2) end
  local str = table.concat(args, ' ')
  local lines = {}
  local maxX = term.getSize() - 11
  local line = {}

  local function insertLine(data)
    -- pad short text to ensure proper length
    -- cut long text to ensure proper length

    lines[#lines + 1] = string.format(string.format("%%%ds", -maxX), table.concat(data, ' ')):sub(1, maxX)
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
    end
  end
  insertLine(line)

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

-- Check validity.
action(1, "Checking remote Simplifile URL validity.")
local isValid, err = http.checkURL(simplifileRemote)
if not isValid then
  action(3, string.format("Invalid URL: %s", err))
  printUsage("Invalid URL given by user or Simplifile.")
end

-- Grab all the data.
action(1, "Downloading new Simplifile.")
local h, err, hh = http.get(simplifileRemote)
if not h then
  action(3, "Failed to download remote.")
  print()
  if hh then hh.close() end
  error(err, 0)
end
simplifileData = h.readAll()
h.close()

simplifileData = textutils.unserialize(simplifileData)
if not simplifileData then
  action(3, "Failed to unserialize data.")
  printUsage("Failed to unserialize data, did you input the correct link?")
end

-- Verify the data.
action(1, "Verifying data.")
local function verifyFail(reason)
  action(3, "Verification failed.")
  print()
  error(reason, 0)
end
local function verify(thing, reason)
  return not thing and verifyFail(reason)
end

-- Simplifile remote should generate a table
verify(type(simplifileData) == "table", "Remote Simplifile does not create a table.")
-- Simplifile remote should point to itself
verify(simplifileData.remote == simplifileRemote, "Remote Simplifile does not point to itself.")
-- Simplifile should have "files" section
verify(type(simplifileData.files) == "table", "'.files' field is missing from remote.")
-- Each file should contain a remote and downloaded location.
for i = 1, #simplifileData.files do
  verify(type(simplifileData.files[i]) == "table", string.format(".files[%d] is not a table.", i))
  verify(type(simplifileData.files[i].remote) == "string", string.format(".files[%d] is missing field '.remote'.", i))
  verify(type(simplifileData.files[i].location) == "string", string.format(".files[%d] is missing field '.location'.", i))
end
-- removed section for removed files
if type(simplifileData.removed) ~= "table" and type(simplifileData.removed) ~= "nil" then
  action(2, "'.removed' field is not of expected type 'table', it is of type", type(simplifileData.removed) .. ".", "It has been removed.")
  simplifileData.removed = nil
end
if simplifileData.removed then
  for i = 1, #simplifileData.removed do
    verify(type(simplifileData.removed[i]) == "string", string.format(".removed[%d] is expected to be a string.", i))
  end
end
action(1, "Verification OK.")

-- clean current working directory, if needed.
if ARGS[2] and ARGS[2]:lower() == "clean" then
  local files = fs.list(SELF_DIR)
  action(2, string.format("Cleaning %d files/folders in current directory.", #files))

  for i = 1, #files do
    action(2, string.format("Removing %s.", files[i]))
    fs.delete(fs.combine(SELF_DIR, files[i]))
  end
end
