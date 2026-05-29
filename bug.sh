#!/bin/sh

BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
RESET_COLOUR="\033[0m"

[ -f /tmp/bug_todo_temp ] && rm /tmp/bug_todo_temp

get_next_id () {
	echo $(($(head -n 1 "$BUG_PROJECT")+1))
}

unNL () {
	sed 's/\t/\\t/g; s/$/\\/g' | tr "\\n" n
}

reNL () {
	sed 's/\\t/\t/g; s/\\n/\n/g'
}

priorNumToName () {
	sed 's/^1$/URGENT/g; s/^2$/High/g; s/^3$/Medium/g; s/^4$/Low/g; s/^5$/Whenever/g'
}

priorNameToNum () {
	sed 's/^URGENT$/1/g; s/^High$/2/g; s/^Medium$/3/g; s/^Low$/4/g; s/^Whenever$/5/'
}

trim () {
	sed 's/^ //g; s/ $//g'
}

updateCurID () {
	sed "s/^[0-9][0-9]*\$/${1}/g" "$BUG_PROJECT" > /tmp/bugproj
	mv /tmp/bugproj "$BUG_PROJECT"
}

fileToLine () {
	file="$1"
	id="$(grep "^ID:" "$file" | head -n 1 | cut -d ":" -f 2- | trim)"
	prior="$(grep "^Priority:" "$file" | head -n 1 | cut -d ":" -f 2- | trim)"
	state="$(grep "^State:" "$file" | head -n 1 | cut -d ":" -f 2- | trim)"
	subj="$(grep "^Subject:" "$file" | head -n 1 | cut -d ":" -f 2- | trim)"
	desc="$(tail -n +6 "$file" | unNL | trim)"

	printf '%s\n' "${id}	${prior}	${state}	${subj}	${desc}"
}

add () {
	id=$(get_next_id)

	read -p "Enter Priority (1,2,3.. 1=highest): " priority
	priority=$(echo $priority | priorNumToName)
	read -p "Enter State (NS,IP): " state
	read -p "Enter Subject: " subject

	touch /tmp/bug_todo_temp
	echo "ID: ${id}" >> /tmp/bug_todo_temp
	echo "Priority: ${priority}" >> /tmp/bug_todo_temp
	echo "State: ${state}" >> /tmp/bug_todo_temp
	echo "Subject: ${subject}" >> /tmp/bug_todo_temp
	echo "-- Description Below --" >> /tmp/bug_todo_temp
	"${VISUAL:-${EDITOR:-vi}}" /tmp/bug_todo_temp

	fileToLine /tmp/bug_todo_temp >> "$BUG_PROJECT"
	updateCurID "$id"
}

lineToFile () {
	line="$(awk "/^${1}\t/" "$BUG_PROJECT")"
	id="$(printf '%s' "$line" | cut -f 1)"
	prior="$(printf '%s' "$line" | cut -f 2)"
	state="$(printf '%s' "$line" | cut -f 3)"
	subject="$(printf '%s' "$line" | cut -f 4)"
	desc="$(printf '%s' "$line" | cut -f 5)"

	touch /tmp/bug_todo_temp
	echo "ID: ${id}" >> /tmp/bug_todo_temp
	echo "Priority: ${priority}" >> /tmp/bug_todo_temp
	echo "State: ${state}" >> /tmp/bug_todo_temp
	echo "Subject: ${subject}" >> /tmp/bug_todo_temp
	echo "-- Description Below --" >> /tmp/bug_todo_temp
	echo "$desc" | reNL >> /tmp/bug_todo_temp
}

selectEntry () {
	tail -n +2 "$BUG_PROJECT" | cut -f 1,4 | fzf -i | cut -f 1
}

edit () {
	id=$(selectEntry)
	lineToFile $id
	echo A:$id:B
	"${VISUAL:-${EDITOR:-vi}}" /tmp/bug_todo_temp
	updatedLine="$(fileToLine /tmp/bug_todo_temp)"
	sed "/^${id}\t.*/d" "$BUG_PROJECT" > /tmp/bug_temp
	mv /tmp/bug_temp "$BUG_PROJECT"
	printf '%s\n' "$updatedLine" >> "$BUG_PROJECT"
}

view () {
	id=$(selectEntry)
	lineToFile $id
	output="$(cat /tmp/bug_todo_temp | sed "\
	s/^ID:/\\${MAGENTA}\\${BOLD}ID:\\${RESET_COLOUR}/g; \
	s/^Priority:/\\${MAGENTA}\\${BOLD}Priority:\\${RESET_COLOUR}/g; \
	s/^State:/\\${MAGENTA}\\${BOLD}State:\\${RESET_COLOUR}/g; \
	s/^Subject:/\\${MAGENTA}\\${BOLD}Subject:\\${RESET_COLOUR}/g; \
	s/^-- Description Below --/\\${GREEN}\\${BOLD}-- Description Below --\\${RESET_COLOUR}/g")"
	echo "$output"
}

list () {
	output="$(tail -n +2 "$BUG_PROJECT" | cut -f 1-4 | sed "\
	s/\tURGENT\t/\t\\${RED}\\${BOLD}URGENT\\${RESET_COLOUR}\t/g; \
	s/\tHigh\t/\t\\${MAGENTA}\\${BOLD}High\\${RESET_COLOUR}\t/g; \
	s/\tMedium\t/\t\\${CYAN}\\${BOLD}Medium\\${RESET_COLOUR}\t/g; \
	s/\tLow\t/\t\\${GREEN}\\${BOLD}Low\\${RESET_COLOUR}\t/g; \
	s/\tAnytime\t/\t\\${BOLD}Anytime\\${RESET_COLOUR}\t/g; \
	s/\tNS\t/\t\\${BLUE}\\${BOLD}NS\\${RESET_COLOUR}\t/g; \
	s/\tIP\t/\t\\${YELLOW}\\${BOLD}IP\\${RESET_COLOUR}\t/g")"
	echo "$output"
}

list
