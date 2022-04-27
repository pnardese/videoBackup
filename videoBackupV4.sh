#!/bin/bash
# uso: ./videoBackupV4.sh -T card_name
# flags: -t (opzionale) copia normale,
#        -T aggiunge timestamp al nome della directory (MDP non aggiorna nome dei reels)
#
# SCRIPT: videoBackupV4.sh
# AUTHOR: Enzo Nardese
# DATE: 27/04/2022
# REV: 4
#
# PLATFORM: (OSX)
# PURPOSE: Give a clear, and if necessary, long, description of the purpose of the shell script. This will also help you stay focused on the task at hand.
#
# REQUIREMENTS: rsync 3.2.3
# rsync opzioni --cc=STR, nessuna opzione = MD5
# STR = xxh128
#       xxh3
#       xxh64 (aka xxhash)
#       md5
#       md4
#
##########################################################
# DEFINE FILES AND VARIABLES HERE
##########################################################

##########################################################
# CONFIGURAZIONE
##########################################################

# numero di copie: 1-3
num_copie=2

# nome dischi destinazione
Nome_disco_1="Disco_1"
Nome_disco_2="Disco_2"
Nome_disco_3="Disco_3"

# estensione file media per creare report, per formati multipli: MOV|MP3|...
MEDIA="MOV"

##########################################################
# FINE CONFIGURAZIONE
##########################################################

##########################################################
# MAIN
##########################################################

TODAY=`date +%Y-%m-%d`
NOW=`date +%H%M%S`

# nome completo percorso dischi
DISK1="/Volumes/$Nome_disco_1/video/$TODAY/A"
DISK2="/Volumes/$Nome_disco_2/video/$TODAY/A"
DISK3="/Volumes/$Nome_disco_3/video/$TODAY/A"

if [ ! -d "$DISK1" ]; then
    mkdir -p $DISK1
fi

if [ ! -d "$DISK2" ]; then
    mkdir -p $DISK2
fi

if [ $num_copie == 3 ]; then
    if [ ! -d "$DISK3" ]; then
    mkdir -p $DISK3
    fi
fi

DIRECTORYDEST1="$DISK1"
DIRECTORYDEST2="$DISK2"
DIRECTORYDEST3="$DISK3"

# aggiunge una directory con l'orario preciso, quando la macchina da presa non genera nomi di reel
# quando si usa il flag -T

NOMESORG=`echo "$1"| grep -o '[a-zA-Z0-9_.-]*$'`

SWITCH=1
while getopts ":tT" opt;
do
  case $opt in
    t)
      DIRECTORYDEST1="$DISK1"
      DIRECTORYDEST2="$DISK2"
      DIRECTORYDEST3="$DISK3"
      NOMESORG=`echo "$2"| grep -o '[a-zA-Z0-9_.-]*$'`
      SWITCH=2
      ;;
    T)
      DIRECTORYDEST1="$DISK1/$NOW"
      DIRECTORYDEST2="$DISK2/$NOW"
      DIRECTORYDEST3="$DISK3/$NOW"
      NOMESORG=`echo "$2"| grep -o '[a-zA-Z0-9_.-]*$'`
      SWITCH=2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "Usare -t o -T"
      exit 1
      ;;
  esac
done

# copia su primo disco DISK1
echo COPIA 1 su $Nome_disco_1
sleep 2
SECONDS=0

# crea directory se non esiste
if [ ! -d "$DIRECTORYDEST1" ]; then
  mkdir -p $DIRECTORYDEST1
fi

# crea directory in anticipo per scrivere file di checksum
if [ ! -d "$DIRECTORYDEST1/$NOMESORG" ]; then
    mkdir -p $DIRECTORYDEST1/$NOMESORG
fi

# copia con rsync, --append per continuare transfer interrotti (quando non si usa flag -T), richiede rsync 3.2.3
rsync -av --progress --append --cc=xxh64 --log-file=$DIRECTORYDEST1/$NOMESORG/logs.txt --log-file-format="%f %b %l %C" ${!SWITCH} $DIRECTORYDEST1

chmod 777 $DIRECTORYDEST1/$NOMESORG/

# scrivi report
cat $DIRECTORYDEST1/$NOMESORG/logs.txt | grep -E "$MEDIA" | awk '{print $1" "$2" /"$4" "$6" "$7}' >> "/Volumes/$Nome_disco_1"/video_xxh64

# scrivi check su disco, contiene file name con path completo, dimensione e checksum
cat $DIRECTORYDEST1/$NOMESORG/logs.txt | grep -E "$MEDIA" | awk '{print "/"$4" "$6" "$7}' >> $DIRECTORYDEST1/$NOMESORG/check.txt

duration=$SECONDS
echo "Prima copia $(($duration / 60)) minuti e $(($duration % 60)) secondi."

if [ $num_copie == 1 ]; then
    exit
fi

# copia su secondo disco DISK2
echo COPIA 2 su $Nome_disco_2
sleep 2
SECONDS=0

# crea directory se non esiste
if [ ! -d "$DIRECTORYDEST2" ]; then
  mkdir -p $DIRECTORYDEST2
fi

# crea directory in anticipo per scrivere file di checksum
if [ ! -d "$DIRECTORYDEST2/$NOMESORG" ]; then
    mkdir -p $DIRECTORYDEST2/$NOMESORG
fi

# copia con rsync, --append per continuare transfer interrotti (quando non si usa flag -T), richiede rsync 3.2.3
rsync -av --progress --append --cc=xxh64 --log-file=$DIRECTORYDEST2/$NOMESORG/logs.txt --log-file-format="%f %b %l %C" ${!SWITCH} $DIRECTORYDEST2

chmod 777 $DIRECTORYDEST2/$NOMESORG/

# scrivi report
cat $DIRECTORYDEST2/$NOMESORG/logs.txt | grep -E "$MEDIA" | awk '{print $1" "$2" /"$4" "$6" "$7}' >> "/Volumes/$Nome_disco_2"/video_xxh64

## scrivi check su disco, contiene file name con path completo, dimensione e checksum
cat $DIRECTORYDEST2/$NOMESORG/logs.txt | grep -E "$MEDIA" | awk '{print "/"$4" "$6" "$7}' >> $DIRECTORYDEST2/$NOMESORG/check.txt

duration=$SECONDS
echo "Seconda copia $(($duration / 60)) minuti e $(($duration % 60)) secondi."

if [ $num_copie == 2 ]; then
    diff $DIRECTORYDEST1/$NOMESORG/check.txt $DIRECTORYDEST2/$NOMESORG/check.txt && echo "Copia $Nome_disco_1 e $Nome_disco_2 OK!!" || echo "ERRORE!!"
    exit
fi

# copia su terzo disco DISK3
echo COPIA 3 su $Nome_disco_3
sleep 2
SECONDS=0

if [ ! -d "$DIRECTORYDEST3" ]; then
  mkdir -p $DIRECTORYDEST3
fi

if [ ! -d "$DIRECTORYDEST3/$NOMESORG" ]; then
    mkdir -p $DIRECTORYDEST3/$NOMESORG
fi

rsync -av --progress --append --cc=xxh64 --log-file=$DIRECTORYDEST3/$NOMESORG/logs.txt --log-file-format="%f %b %l %C" ${!SWITCH} $DIRECTORYDEST3

chmod 777 $DIRECTORYDEST3/$NOMESORG/

cat $DIRECTORYDEST3/$NOMESORG/logs.txt | grep -E "$MEDIA" | awk '{print $1" "$2" /"$4" "$6" "$7}' >> "/Volumes/$Nome_disco_3"/video_xxh64

cat $DIRECTORYDEST3/$NOMESORG/logs.txt | grep -E "$MEDIA" | awk '{print "/"$4" "$6" "$7}' >> $DIRECTORYDEST3/$NOMESORG/check.txt

duration=$SECONDS
echo "Terza copia $(($duration / 60)) minuti e $(($duration % 60)) secondi."

# controlla se copie sono identiche
diff $DIRECTORYDEST1/$NOMESORG/check.txt $DIRECTORYDEST2/$NOMESORG/check.txt && echo "Copia $Nome_disco_1 e $Nome_disco_2 OK!!" || echo "ERRORE!!"
diff $DIRECTORYDEST1/$NOMESORG/check.txt $DIRECTORYDEST3/$NOMESORG/check.txt && echo "Copia $Nome_disco_3 OK!!" || echo "ERRORE!!"


# End of script
