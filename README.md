# LemonGo-Importer
A simple bash script that imports Level 30 PokemonGo account from LemonGo's Mapping service into a Monocle (or other) Database.

## Installation

### 1. Download script
Load script via `git clone https://github.com/TyrolMap/LemonGo-Importer` or download it manualy

### 2. Fix permissions
Run `chmod +x LemonGo-Importer/getAccs.sh`

### 3. Run script manually for testing 
The following script will load x accounts every 10h with a maximum age of 3h: <br>
`/PathToScript/getAccs.sh -c "=NumberOfAccs=" -k "=YourAPIKey=" -s "python3.6 /PathToMonocle/Scripts/import_accounts.py --level 30 #FILE#" >> /PathToScript/cron.log 2>&1`<br>
(Replace all values between =...= and fix paths, get more information about flags with `/PathToScript/getAccs -h`, Do NOT replace #FILE#!)

### 4. Add script to crontab
Add crontab via `crontab -e` and add a new line: <br>
`*/15 * * * * =SCRIPT=`<br>
(Releace #SCRIPT# with the script you testet in step 3)
Also make sure that your cron thas the correct PATH variable!
