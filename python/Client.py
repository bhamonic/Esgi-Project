import os
import sys
import socket

if len(sys.argv)<3:
	print("Usage :",sys.argv[0],"IP_server port_server")
	sys.exit(-1)


# Création de la Socket IPv4 TCP
mySocket=socket.socket(socket.AF_INET,socket.SOCK_STREAM)	# création d'une socket 'mySocket' TCP sur IPv4

try:
	mySocket.connect((sys.argv[1],int(sys.argv[2])))			# demande de connexion au serveur
except socket.error:
	print("La connexion a echouée.")
	sys.exit(-1)
print("Connexion établie avec le serveur.")

while True:
	msgClient = input("Client> ")

	# On vérifie si le client renseigne ls ou pwd
	if msgClient == "ls" or msgClient == "pwd":
		# On doit créer un processus fils pour eviter que la connexion ne fonctionne plus
		child=os.fork()

		# Si on est dans le processus fils
		if child==0:
			# Le client vérifie que la commande est ls
			if msgClient == "ls":
				# Le client execute ls en local
				os.execl("/bin/ls","ls")
			# Le client vérifie que la commande est pwd
			elif msgClient == "pwd":
				# Le client execute pwd en local
				os.execl("/bin/pwd","pwd")
		else:
			# Permet de retourner dans la boucle
			os.wait()
	# On vérifie si la commande envoyée est cd
	elif "cd" in msgClient:
		# Permet de se déplacer dans le bon répertoire
		# [3:] Récupère tous les caractères après le troisième caractère "cd "
		os.chdir(msgClient[3:])


	# On verifie si l'utilisateur envoie des informations
	# Si pas d'info envoyé alors on le déconnecte
	else:
		if len(msgClient)==1 or len(msgClient)==0:		
			mySocket.close()
			print("Deconnexion du serveur")	
			break				
		mySocket.send(msgClient.encode("utf-8"))		
		msgServeur=mySocket.recv(1024)	
		msgServeur=str(msgServeur,'utf-8').replace('\n', '')
		print("Serveur: " + msgServeur)


		if "WHO" in msgServeur:
			print("Login:")

		if "PASSWD" in msgServeur:
			print("Password:")

		if "BYE" in msgServeur:
			mySocket.close()


