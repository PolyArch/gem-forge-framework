
import os
import sys
import json

def get_key(entry):
    d = entry['directory']
    f = entry['file']
    return f if f.startswith('/') else os.path.join(d, f)

all_commands = dict()
# Read in new commands and update.
for fn in sys.argv[1:]:
    if not os.path.isfile(fn):
        continue
    with open(fn) as f:
        commands = json.load(f)
        for e in commands:
            all_commands[get_key(e)] = e

# Sort and output. Assume argv[1] is the out file.
command_list = list(all_commands.values())
command_list.sort(key=lambda e: get_key(e))
with open(sys.argv[1], 'w') as f:
    json.dump(command_list, f, indent=2)