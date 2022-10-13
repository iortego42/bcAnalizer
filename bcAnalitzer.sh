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
              echo -e "${table}" | column -s '#' -t | awk '/^\s\s\+/{gsub(" ", "-", $0)}1' | sed  's/--+/  +/'
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

function help_panel(){
  echo -e "\n${color[purple]}==============================={[PANEL DE AYUDA]}=============================== ${color[end]}"
  for i in {1..80}; do echo -ne "${color[grey]}_"; done
  echo -ne "${color[end]}\n"
  echo -e "\n\t${color[yellow]}[-e]\tModo exploracion: Lista todas las ultimas transaciones no confirmadas"
  echo -e "\t${color[yellow]}[-n]\tMostrar ultimas "n" transacciones"
  echo -e "\t${color[yellow]}[-a]\tRecibe una direccion de una transaccion"
  echo -e "\t${color[yellow]}[-i]\tRecibe un Hash de una transaccion"
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
inspect_address_url="https://www.blockchain.com/es/btc/address" 

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
    #hashUsd=$(echo -ne "$hashInfo" | tail -n 1)
    #hashBtc=$(echo -ne "$hashInfo" | tail -n 3 | head -n 1)
    #hashTime=$(echo -ne "$hashInfo" | tail -n 5 | head -n 1)
    #echo -e "${hash}_${hashUsd}_${hashBtc}_${hashTime}" >> ut.table
    echo -e "${hash}_$(echo -n "$hashInfo" | tail -n 1 | tr -d "Â US$.")_$(echo -n "$hashInfo" | tail -n 3 | head -n 1)_$(echo -n "$hashInfo" | tail -n 5 | head -n 1 )" >> ut.table
    #echo -e "${hash}_${hashUsd}_${hashBtc}_${hashTime}" >> ut.table
  done
  money=$(cat ut.table | awk -F '_' '{print $2}' | grep -vi "cantidad" | tr -d "Â US$." | tr ',' '.' | paste -sd+ | bc | tr '.' ',' | numfmt --grouping)
  echo -e "${color[blue]}Cantidad Total_${money}\$${color[end]}" > ut.money
  #echo -e "${color[green]}$hash${color[end]}_${color[blue]}${hashUsd}${color[end]}_${color[yellow]}${hashBtc}${color[end]}_${color[gray]}${hashTime}${color[end]}" >> ut.table
  #cat ut.table | tr '_' ' ' | awk '{${color[green]}${1}${color[end]}_${color[blue]}${2}${color[end]}_${color[yellow]}${3}${color[end]}_${color[gray]}${4}${color[end]}}'
  cat ut.table | tr '_' ' ' | awk -v g=$(echo -ne ${color[green]}) -v e=$(echo -ne ${color[end]}) -v b=$(echo -ne ${color[blue]}) -v y=$(echo -ne ${color[yellow]}) -v x=$(echo -ne ${color[gray]}) '{print g $1 e "_" b $2 e "_" y $3 e "_" x $5 e}' > ut.table 

  printTable '_' "$(cat ut.table)"
  printTable '_' "$(cat ut.money)"
   
  rm ut.* 2>/dev/null
  tput cnorm
}

function inspect(){
  echo "" > it.tmp
  while [ "$(cat it.tmp | wc -l)" == "1" ]
  do
    curl -s "${inspect_transation_url}/$1" | html2text > it.tmp
  done
  
  local hashEntrada=$(cat it.tmp | grep -A 100 "Entradas$" | grep -B 100 "Gastos$")
  local hashSalida=$(cat it.tmp | grep -A 100 "Gastos$" | grep -B 100 "Comprar criptomonedas$")
  local hashEstado=$(cat it.tmp | grep -A 6 "Hash" | grep -A 1 "Estado$" | tail -n 1)

  if [ "$hashEstado" == "No confirmado" ]; then
    hashEstado=$(echo -e "${color[red]}$hashEstado")
  elif [ "$hashEstado" == "Confirmado" ]; then
    hashEstado=$(echo -e "${color[green]}$hashEstado")
  else
    hashEstado=$(echo -e "${color[turquoise]}$hashEstado")
  fi
  
  count=1
  echo -e "${color[green]}Entrada${color[end]}_${color[blue]}Cantidad${color[end]}" > it.entrada
  while read line; do
    if [[ "$line" == "Direcci"* ]]; then
        read var
        echo -ne "${count}: ${color[green]}$var${color[end]}" >> it.entrada
        ((count++));
        read var
        read var
        echo -e "_${color[blue]}$var${color[end]}" >> it.entrada
    fi
  done <<< "$hashEntrada"
 
  count=1
  echo -e "${color[purple]}Salida${color[end]}_${color[blue]}Cantidad${color[end]}" > it.salida
  while read line; do
    if [[ "$line" == "Direcci"* ]]; then
        read var
        echo -ne "${count}: ${color[purple]}$var${color[end]}" >> it.salida
        ((count++));
        read var
        read var
        echo -e "_${color[blue]}$var${color[end]}" >> it.salida
    fi
  done <<< "$hashSalida"

  printTable '_' "$(echo -e "${color[gray]}Estado:_$hashEstado${color[end]}" )"
  printTable '_' "$(cat it.entrada)"
  printTable '_' "$(cat it.salida)"
  rm it.* 2>/dev/null
  tput cnorm
}

function inspect_address(){
  echo "" > ia.tmp

  while [ "$(cat ia.tmp | wc -l)" == "1" ]
  do
    curl -s "${inspect_address_url}/$1" | html2text > ia.tmp
  done
  ultimosHash=$(cat ia.tmp | grep -A 3 "Hash" | grep -v "\--")
  echo -e "${color[yellow]}Transacciones${color[end]}_${color[green]}Total Recibido${color[end]}_${color[blue]}Total Enviado${color[end]}_${color[turquoise]}Saldo actual${color[end]}" > ia.table
  echo -ne "${color[yellow]}$(cat ia.tmp | grep -A 1 "Transac" | head -n 2 | tail -n 1)${color[end]}_" >> ia.table
  echo -ne "${color[green]}$(cat ia.tmp | grep -A 1 "Total recibido" | tail -n 1 | tr '.' ',')${color[end]}_" >> ia.table
  echo -ne "${color[blue]}$(cat ia.tmp | grep -A 1 "Total enviado" | tail -n 1 | tr '.' ',')${color[end]}_" >> ia.table
  echo -ne "${color[turquoise]}$(cat ia.tmp | grep -A 1 "Saldo final" | tail -n 1 | tr '.' ',')${color[end]}" >> ia.table
  

  printTable '_' "$(cat ia.table)"
  echo -e "_${color[red]}ULTIMOS HASHES DE DE ESTA DIRECCION${color[end]}" > ia.thash
  hashes=$(cat ia.tmp | grep -A 1 "Hash" | grep -v "Hash\|\--")
  count=1
  for hash in $hashes; do
    echo -e "${color[turquoise]}  ${count} ${color[end]}_${color[turquoise]}$hash${color[end]}" >> ia.thash
    let count++
  done
  printTable '_' "$(cat ia.thash)"
  rm ia.* 2>/dev/null
  tput cnorm
}

paramCount=0
numberOutput=0
tput civis
while getopts ":n:" num; do
  case "$num" in
    n) numberOutput=$OPTARG;;
    :) help_panel;;
  esac
done
OPTIND=1
while getopts ":i:a:n:eh" arg; do 
  case "$arg" in
    e) unconfirmed_transactions $numberOutput; ((paramCount++));;
    h) help_panel; ((paramCount++));;
    i) inspect $OPTARG; ((paramCount++));;
    a) inspect_address $OPTARG; ((paramCount++));;
    :) help_panel;;
  esac
done
if [ "$paramCount" == "0" ]; then
  help_panel
fi

