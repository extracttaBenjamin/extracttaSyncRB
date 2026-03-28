#!/bin/bash

echo "Check Parameters"
echo "Database Name: ${1:-"(Not informed)"}"
echo "Send the collection name: ${2:-"(Not informed)"}"
echo "Send the product name [default: Todos]: ${3:-"Todos"}"
echo "CSV directory [default: /opt/mongosync]: ${4:-"/opt/mongosync"}"
echo "Run as root [default: false]: ${5:-"false"}"
# echo "Send the environment name [DEV|TST|HLG|QA|PRD]: $6" # not in use yet
logs=()
scriptFile="$($startTime +%Y%m%dT%H%M%S)-csv-collection-report.sh"
logFile="$($startTime +%Y%m%dT%H%M%S)-csv-collection-report.log"
if [[ -z "$1" || -z "$2" ]]; then 
  msg="Namespace to examined was not informed"
else
  msg="Namespace to examined: ${1}.${2}"
fi
logs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"ERROR", c:"namespace Selection", msg: "${msg}"}'

if $3 == ""; then 
  product="Todos"
else 
  product=$3
fi
logs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"product Selection", msg: "${product} was the product selected"}'

if $3 == ""; then 
  csvDir="/opt/mongosync"
else
  csvDir=$3
fi
logs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"csv Path", msg: "${csvDir} was the CSVs path selected"}'

# 3. Lógica para o boolean Run as Root
if [[ -z "$5" || "$5" == "false" ]]; then
    asRoot=false
else
    asRoot=true
fi
logs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"execution Mode", msg: "Database and/or Collection not informed"}'

# environment=$(if $5 == ""; then echo "Todos" else $5 fi) # not in use yet

shopt -s nocaseglob
startTime=$(date +%Y%m%dT%H%M%S.%3N%z)
logs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"script Execution", msg:"Script execution start time"}'
foundLogs=()
notFoundLogs=()
if $asRoot; then
  csvs=$(sudo -u mongosync ls -N -1 "$csvDir/*.csv")
else
  csvs=$(ls -N -1 "$csvDir/*.csv")
fi
count=0
found=0
entries=()
foundSorted=()
notFound=0
notfounds=()
notFoundsorted=()
for csv in ${csvs[@]}; do
  let "count++"
  dbCollProd="$database,$collection,$product"
  dbColl="$database,$collection,Todos"
  if $asRoot; then
    entry=$(sudo grep -E "${dbCollProd}|${dbColl}" "$csv")
  else
    entry=$(grep -E "${dbCollProd}|${dbColl}" "$csv")
  fi
  if [ $? -eq 0 ]; then 
    let "found++"
    entries+="${csv}: ${entry}"
  else
    let "notFound++"
    notfounds+="$csv"
  fi
done
endTime=$(date +%Y%m%dT%H%M%S.%3N%z)
shopt -u nocaseglob

mapfile -f foundSorted < <(printf "%s\n" "${entries[@]}" | sort) 
mapfile -f notFoundSorted < <(printf "%s\n" "${notfounds[@]}" | sort) 

diffTime=$endTime-$startTime
if $asRoot; then
  cat << EOREPORT | sudo tee ${scriptFile}
# Execution Started at "$startTime"
# Execution Ended at "$endTime"
# Execution duration "$endTime +%Y%m%dT%H%M%S.%3N"

# CSV Files Founded
// listar todos os CSVs encontrados, listados em ordem alfabética

if [ ! ${found} -eq 0 ]; then
  localCount=0
  for fs in ${foundSorted}; do
    let "localCount++"
    foundLogs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"entry Founded", msg:"Searched entry ${localCount} - ${fs}"}'
  done
else
  foundLogs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"entry Founded", msg:"No on searched entry founded"}'
fi

if [ ! ${notFound} -eq 0 ]; then
  localCount=0
  for nfs in ${notFoundSorted}; do
    let "localCount++"
    notFoundLogs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"not Founded Entries", msg:"Searched entry not founded: ${localCount} - ${nfs}"}'
  done
else
  notFoundLogs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"not Founded Entries", msg:"No more CSV entries to look for"}'
fi
EOREPORT
else
    cat << EOREPORT | tee ${scriptFile}
# Execution Started at "$startTime"
# Execution Ended at "$endTime"
# Execution duration "$endTime +%Y%m%dT%H%M%S.%3N"

# CSV Files Founded
// listar todos os CSVs encontrados, listados em ordem alfabética

if [ ! ${found} -eq 0 ]; then
  localCount=0
  for fs in ${foundSorted[@]}; do
    let "localCount++"
    foundLogs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"entry Founded", msg:"Searched entry ${localCount} - ${fs}"}'
  done
else
  foundLogs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"entry Founded", msg:"No on searched entry founded"}'
fi

if [ ! ${notFound} -eq 0 ]; then
  localCount=0
  for nfs in ${notFoundSorted[@]}; do
    let "localCount++"
    notFoundLogs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"not Founded Entries", msg:"Searched entry not founded: ${localCount} - ${nfs}"}'
  done
else
  notFoundLogs+='{t:ISODate("$(date +%Y%m%dT%H%M%S.%3N%z)"), s:"INFO", c:"not Founded Entries", msg:"No more CSV entries to look for"}'
fi
logs+=${foundLogs[@]}
logs+=${notFoundSorted[@]}
echo ${logs[@]} >> ${logFile}
EOREPORT
./${scriptFile}