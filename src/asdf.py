import csv
import json
import numpy as np
import matplotlib.pyplot as plt
import networkx as nx
import re
# print "lol"

def timeToHMS(time):
   ms = int((time*1000 - int(time)*1000))
   m, s = divmod(time, 60)
   h, m = divmod(m, 60)
   returnTime = "{:0>2d}:{:0>2d}:{:0>2d}.{:0>3d}".format(int(h), int(m), int(s), ms)
   return returnTime

with open('UBCx__Climate101x__3T2015_cleaned/tracklog_cleaned.csv') as csvfile:
	reader = csv.DictReader(csvfile)
	
	users = {}
	videos = {}
	videoGraphs = {}
	oldTimes = []
	newTimes = []
	# N = 2000

	i = 0
	seeks = 0
	seekBackwards = 0
	seekForwards = 0
	maxSeek = 0

	binSize = 5

	for row in reader:
		i += 1
		if "Video" in row['name']:
			videoName = row['name']

			if not videos.has_key(videoName):
				videos[videoName] = {}
				# zeroes = np.zeros(N)
				videos[videoName]['videoName'] = videoName
				videos[videoName]['seeksTo'] = []#zeroes;
				videos[videoName]['seeksFrom'] = []#zeroes;

				videoGraphs[videoName] = nx.MultiDiGraph(name=videoName)


		if "seek" in row['event_type']:
			seeks += 1

			newjson = json.loads(row['event'])

			newTime = newjson['new_time']
			oldTime = newjson['old_time']

			videoGraphs[videoName].add_node(int(oldTime / binSize) * binSize)
			videoGraphs[videoName].add_node(int(newTime / binSize) * binSize)
			videoGraphs[videoName].add_edge(int(oldTime / binSize) * binSize, int(newTime / binSize) * binSize)

			# videoGraphs[videoName].add_node(timeToHMS(int(oldTime / binSize) * binSize))
			# videoGraphs[videoName].add_node(timeToHMS(int(newTime / binSize) * binSize))
			# videoGraphs[videoName].add_edge(timeToHMS(int(oldTime / binSize) * binSize), timeToHMS(int(newTime / binSize) * binSize))

			# if(int(newTime) == 0):
				# print "From " + str(newjson['old_time']) + " to " + str(newjson['new_time'])

			videoName = row['name']
			# print str(len(videos[videoName]['seeksTo'])) + " " + str(newTime)
			while len(videos[videoName]['seeksTo'])  < int(newTime / binSize) + 1:
				videos[videoName]['seeksTo'].append(0)

			# print str(len(videos[videoName]['seeksTo'])) + " " + str(newTime)
			# print videos[videoName]['seeksTo'][int(newTime)]

			while len(videos[videoName]['seeksFrom']) - 1 < int(oldTime / binSize) + 1:
				videos[videoName]['seeksFrom'].append(0)


			videos[videoName]['seeksTo'][int(newTime / binSize)] += 1
			videos[videoName]['seeksFrom'][int(oldTime / binSize)] += 1

			if not users.has_key(row['user_id']):
				users[row['user_id']] = {'user_id': row['user_id'], 'seekCount': 1}

				if(oldTime > newTime):
					users[row['user_id']]['seeksBackwards'] = 1
				else:
					users[row['user_id']]['seeksForwards'] = 1

			else:
				users[row['user_id']]['seekCount'] += 1


			if(oldTime > newTime):
				seekBackwards += 1
			else:
				seekForwards += 1

			maxSeek = max(oldTime, max(newTime, maxSeek))

	for video in videos.values():
		# for i in range(0, len(video['seeksTo']) - 1):
		# 	video['seeksTo'][i] /= binSize
		# for i in range(0, len(video['seeksFrom']) - 1):
		# 	video['seeksFrom'][i] /= binSize

		while len(video['seeksFrom']) < len(video['seeksTo']):
			video['seeksFrom'].append(0)
		while len(video['seeksFrom']) > len(video['seeksTo']):
			video['seeksTo'].append(0)

	print "Number of rows: " + str(i)
	print "Number of seeks: " + str(seeks)
	print "Number of users who seeked: " + str(len(users))
	print "Number of seeks forward: " + str(seekForwards)
	print "Number of seeks backwards: " + str(seekBackwards)
	# print maxSeek

	for videoName in videoGraphs:
		print videoGraphs[videoName]
		filename = re.sub('[:./]', '', videoName)
		nx.write_graphml(videoGraphs[videoName], filename + ".graphml")
		# nx.draw_circular(videoGraphs[videoName])
		# break

	for video in videos.values():
		# print video
		seeksToData = video['seeksTo']
		seeksFromData = video['seeksFrom']

		binSize = 10
		binned = []
		seekSum = 0

		print video['videoName'] + str(seeksToData)
		print str(len(seeksFromData)) + " " + str(len(seeksToData))

		n_groups = len(max(seeksToData, seeksFromData))

		fig, ax = plt.subplots()

		index = np.arange(n_groups)
		bar_width = 0.4

		opacity = 0.4
		error_config = {'ecolor': '0.3'}

		rects1 = plt.bar(index, seeksToData, bar_width,
		                 alpha=opacity,
		                 color='b',
		                 # yerr=std_men,
		                 error_kw=error_config,
		                 label=video['videoName'])

		rects2 = plt.bar(index + bar_width, seeksFromData, bar_width,
		                 alpha=opacity,
		                 color='r',
		                 # yerr=std_men,
		                 error_kw=error_config,
		                 label=video['videoName'])


		plt.show()
		break
