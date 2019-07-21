import os
import sys
import socket

# Fonction permettant l'authentification du clients
def login(user,passwd):
	print("Debug login")
	print("login:",user)
	print("Password",passwd)
	for line in open("password").readlines():
		login_info = line.split()
		if user == login_info[0] and passwd == login_info[1]:
			return True
			break
	return False


def serveur_fils():
	mySocket.close()
	while True:
		data=Connexion.recv(1024)
		if len(data)==1 or len(data)==0:
			print("Deconnexion de",client)
			Connexion.close()
			sys.exit(0)

		# Le serveur décode le message pour le passer en utf-8
		# + On supprime le retour chariot qui est ajouté par les byte-object
		msgClient = data.decode("utf-8").replace('\n', '')
		# Affichage du messages du client
		print("Client: " + msgClient)

		# On verifie sur le message reçu est BONJ
		if msgClient == "BONJ":
			# Le serveur envoie WHO pour demander le login
			Connexion.send(b'WHO')
			# Le serveur attends un Login
			user = Connexion.recv(4096)
			# Affichage du login du client pour debug
			print("Login:",user)
			counter = 0
			# Boucle des 3 essais de connexion
			while counter<3:
				# Envoie au client PASSWD pour que celui-ci nous envioe son Password
				Connexion.send(b'PASSWD')
				# Stockage du password dans une variable
				passwd = Connexion.recv(4096)
				# Vérification du couple user + password
				login_check = login(user.decode(),passwd.decode())

				# Si le couple est valide, on quitte la boucle
				if login_check == True:
					break
				# Si le couple n'est pas valide,
				#on incrémente la variable counter et on relance la boucle
				counter += 1
			if login_check == True:
				# Si le client est authentifié on lui envoie WELC
				Connexion.send(b'WELC')
			else:
				# Si le client echoue sur ces trois tentative, on lui réponds BYE
				Connexion.send(b'BYE')

		else:
			Connexion.send(b'Valeur attendue BONJ')

############################################################################
if len(sys.argv)!=2:
	print("Usage : ",sys.argv[0],"n°_port")
	sys.exit()

mySocket=socket.socket(socket.AF_INET,socket.SOCK_STREAM)

try:
	mySocket.bind(('',int(sys.argv[1])))
except socket.error:
	print("La liaison du socket à l'adresse choisie a échoué.")
	sys.exit(0)

# Permet d'avoir 10 clients connectés simultanément
mySocket.listen(10)
while True:
	print("Attente d'un client")
	# On autorise le fais qu'un client se connecte
	Connexion,client=mySocket.accept()
	print("Connection de",client)
	# On créé un processus fils pour chaque nouvelle connexion
	child=os.fork()
	if child==0:
		serveur_fils()
	else:
		Connexion.close()