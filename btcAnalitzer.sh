#!/bin/bash

# iortego42Madrid

declare -A color
color[green]="\e[0;32m\033[1m"
color[end]="\033[0m\e[0m"
color[red]="\e[0;31m\033[1m"
color[blue]="\e[0;34m\033[1m"
color[yellow]="\e[0;33m\033[1m"
color[purple]="\e[0;35m\033[1m"
color[turquoise]="\e[0;36m\033[1m"
color[gray]="\e[0;37m\033[1m"

#============================
#
#   FUNCIONES DE INTERTFAZ
#
#============================

trap ctrl_c INT

function ctrl_c(){
  echo -e "\n${color[red]} [ABORT] Saliendo . . .${color[end]}"
  tput cnorm; exit 1
}

function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function generateFiles(){

    echo '' > $tmp_file

    while [ "$(cat $tmp_file | wc -l)" != "0" ]; do
        curl -s -H "$USER_AGENT" "$url_machines_get_all?api_token=$API_TOKEN" -X GET -L | tr "'" '"' | sed 's/None/\"None\"/g' | sed 's/True/\"True\"/g' | sed 's/False/\"False\"/g' > $tmp_file
    done
}


function help_panel(){
  echo -e "\n${color[purple]}==============================={[PANEL DE AYUDA]}=============================== ${color[end]}"
  for i in {1..80}; do echo -ne "${color[grey]}_"; done
  echo -ne "${color[end]}\n"
  echo -e "\n\t${color[yellow]}[-e]\tModo exploracion"
  echo -e "\t\t${color[turquoise]}unconfirmed_transactions${color[gray]}:\t Listar todas las transaciones no confirmadas"
  echo -e "\t\t${color[turquoise]}inspect${color[gray]}:\t\t\t Inspecionar un hash de transaccion"
  echo -e "\t\t${color[turquoise]}address${color[gray]}:\t\t\t Inspecionar una transferencia de direccion"
  echo -e "\t${color[yellow]}[-n]\tMostrar ultimas "n" transacciones"
  echo -e "\t${color[yellow]}[-h]\tPanel de Ayuda"
  echo -e "\t\t${color[turquoise]}unconfirmed_transactions${color[gray]}:\t Listar todas las transaciones no confirmadas"

  tput cnorm; exit 1
}

#========================
#
#   VARIABLES GLOBALES
#
#========================

unconfirmed_transactions="https://www.blockchain.com/es/btc/unconfirmed-transactions"
inspect_transation_url="https://www.blockchain.com/es/btc/tx"
inspect_address_url="https://www.blockchain.com/btc/address" 

#============================
#
#   FUNCIONES PRINCIPALES
#
#============================

function unconfirmed_transactions(){
  echo "" > ut.tmp
  local hashInfo=0
  local hashUsd=0
  local hashBtc=0
  local hashTime=0
  #hashes=$(curl -s $unconfirmed_transactions | html2text | grep -iA 1 "hash" | grep -ivE "hash|\--|tiempo")
  while [ $(cat ut.tmp | wc -l) -eq 1 ]; do
    curl -s $unconfirmed_transactions | html2text > ut.tmp
  done
 
  local outputs=100
  if [ $1 ] && [ $1 -ne 0 ]; then
    outputs=$1
  fi
  hashes=$(cat ut.tmp | grep -iA 1 "hash" | grep -ivE "hash|\--|tiempo" | head -n $outputs)
  
  echo "Hash_Cantidad_Bitcoin_Tiempo" > ut.table

  for hash in $hashes; do 
    hashInfo=$(cat ut.tmp | grep -A 6 $hash)
    hashUsd=$(echo -ne "$hashInfo" | tail -n 1)
    hashBtc=$(echo -ne "$hashInfo" | tail -n 3 | head -n 1)
    hashTime=$(echo -ne "$hashInfo" | tail -n 5 | head -n 1)
    #echo -e "${hash}_${hashUsd}_${hashBtc}_${hashTime}" >> ut.table
    echo -e "${color[green]}$hash${color[end]}_${color[blue]}${hashUsd}${color[end]}_${color[yellow]}${hashBtc}${color[end]}_${color[gray]}${hashTime}${color[end]}" >> ut.table
  done
  cat ut.table | tr '_' ' ' | awk '{print $2}' | grep -vi "cantidad" | tr -d "Â US$," > money
  
  money=0; cat money | while read $money_line
  do
    ((money+=$money_line))
    echo $money
  done
    
  #echo -ne "${color[red]}"
  #printTable '_' "$(cat ut.table)"
  echo
  rm  ut.* 2>/dev/null
  tput cnorm
}

paramCount=0
numberOutput=0
while getopts "e:n:i:h" arg; do
  case $arg in
    e) exploration_mode=$OPTARG; ((paramCount++));;
    h) help_panel;;
    i) ;;
    n) numberOutput=$OPTARG; ((numberOutput++));;
  esac
done

tput civis

if [ $paramCount -eq 0 ]; then
  help_panel

else
  if [ "$exploration_mode" == "unconfirmed_transactions" ]; then
    unconfirmed_transactions $numberOutput
  fi

fi
