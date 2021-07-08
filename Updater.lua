local ARGS = table.pack(...)
local SIMPLIFILE_NAME = "Simplifile"
local SELF_DIR = shell.dir()
local simplifileRemote

local function printUsage(reason)
  print("Usage: SimplifyUpdate [simplifile] [clean]")
  print("   OR: wget run <LINK_TO_SELF> [simplifile] [clean]")
  print("  > SimplifyUpdate")
  print("    - Checks the Simplifile in the current directory and updates based off that.")
  print("  > SimplifyUpdate https://github.com/some_repo/main/Simplifile")
  print("    - Downloads the Simplifile provided and updates/installs based on that.")
  print("  > SimplifyUpdate _ clean")
  print("    - Cleans the current directory, then reinstalls.")
  error(reason, 0)
end

-- Check arguments
if not ARGS[1] and not fs.exists(fs.combine(SELF_DIR, "Simplifile")) then
  printUsage("No arguments given, but local Simplifile was not found.")
end

-- Determine the remote location
if not ARGS[1] then
  local handle, err = io.open(fs.combine(SELF_DIR, "Simplifile"))
  if not handle then
    print("Failed to open Simplifile for reading:")
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
local isValid, err = http.checkURL(simplifileRemote)
if not isValid then
  printUsage(string.format("Invalid URL: %s", err))
end

-- clean current working directory, if needed.
if ARGS[2] and ARGS[2]:lower() == "clean" then
  
end
