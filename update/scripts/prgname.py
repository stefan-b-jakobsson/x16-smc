# Init array
version = {}
version["version_major"] = -1
version["version_minor"] = -1
version["version_patch"] = -1

# Parse version number from firmware source code
try:
    f = open("../version.h")
except:
    print("Could not open version.h")
    exit()

line = f.readline()
while line:
    parts = line.split()
    if len(parts) == 3:
        if parts[0].lower() == "#define":
            try:
                version[parts[1].lower()] = int(parts[2])
            except:
                print("Error parsing: " + line)
    line = f.readline()

f.close()

# Return SMCUPDATE file name with version
print("SMCUPDATE-" + str(version["version_major"]) + "." + str(version["version_minor"]) + "." + str(version["version_patch"]) + ".PRG")
