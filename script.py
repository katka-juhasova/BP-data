import os
import sys
import getopt
import json


if len(sys.argv) != 2:
	print('Error: Incorrect number of arguments.')
	exit(1)

BPVis_dir = sys.argv[1]
path = BPVis_dir + '/data/'
files = list()

for r, d, f in os.walk(path):
    for file in f:
        if '.json' in file:
            files.append(os.path.join(r, file))

for file in files:
	with open(file) as f:
		data = json.load(f)

	# try:
	# 	raw_data = open(data['path'], 'rb').read()
	# except:
	# 	print(data['path'])

	x = ''

	if 'https://raw.githubusercontent.com/katka-juhasova/BP-data/master/modules-part1' in data['url']:
		x = data['url']
		x = x.replace(
			'https://raw.githubusercontent.com/katka-juhasova/BP-data/master/modules-part1', 
			BPVis_dir + '/modules'
		)

	elif 'https://raw.githubusercontent.com/katka-juhasova/BP-data/master/modules-part2' in data['url']:
		x = data['url']
		x = x.replace(
			'https://raw.githubusercontent.com/katka-juhasova/BP-data/master/modules-part2', 
			BPVis_dir + '/modules'
		)

	data['path'] = x

	with open(file, 'w') as fout:
		fout.write(json.dumps(data, indent=4))	

