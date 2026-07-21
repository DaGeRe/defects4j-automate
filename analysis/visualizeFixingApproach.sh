#!/usr/bin/env bash
#
# visualize-opencode.sh - Visualisiert OpenCode / OpenCodeInterpreter JSONL Ausgaben
# Nutzung: ./visualize-opencode.sh [datei.jsonl] oder cat datei.jsonl | ./visualize-opencode.sh

# Farben definieren
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
RESET='\033[0m'

# Prüfen ob jq installiert ist
if ! command -v jq &> /dev/null; then
    echo "Fehler: 'jq' wird benötigt. Bitte mit 'sudo apt install jq' installieren." >&2
    exit 1
fi

format_output() {
    while IFS= read -r line; do
        [ -z "$line" ] && continue

        # Event-Typ auslesen
        type=$(echo "$line" | jq -r '.type // empty')

        case "$type" in
            "step_start")
                timestamp=$(echo "$line" | jq -r '.timestamp // empty')
                echo -e "\n${BOLD}${MAGENTA}=== Step Start ===${RESET} ${GRAY}(Timestamp: ${timestamp})${RESET}"
                ;;

            "tool_use")
                tool=$(echo "$line" | jq -r '.part.tool // "unbekannt"')
                call_id=$(echo "$line" | jq -r '.part.callID // ""')
                title=$(echo "$line" | jq -r '.part.part.title // .part.title // .part.state.input.command // .part.state.input.filePath // ""')
                status=$(echo "$line" | jq -r '.part.state.status // "executing"')
                
                # Status-Farbe
                if [ "$status" = "completed" ]; then
                    status_color="${GREEN}"
                else
                    status_color="${YELLOW}"
                fi

                echo -e "${BOLD}${CYAN}[TOOL USE]${RESET} ${BOLD}${tool}${RESET} | Status: ${status_color}${status}${RESET}"
                [ -n "$title" ] && echo -e "           ${GRAY}Target/Command:${RESET} ${title}"

                # Details / Input anzeigen
                input_json=$(echo "$line" | jq -r '.part.state.input // empty')
                if [ -n "$input_json" ] && [ "$input_json" != "null" ]; then
                    echo -e "           ${GRAY}Input:${RESET}"
                    echo "$input_json" | jq . 2>/dev/null | sed 's/^/             /'
                fi

                # Tool Output verarbeiten
                output=$(echo "$line" | jq -r '.part.state.output // empty')
                if [ -n "$output" ] && [ "$output" != "null" ]; then
                    echo -e "\n           ${BOLD}${BLUE}--- Output ---${RESET}"
                    
                    # ANSI Escape Codes entfernen und mit Zeilennummern formatieren
                    echo "$output" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | nl -ba -s": " -w4 | sed 's/^/             /'
                    echo -e "           ${BOLD}${BLUE}--------------${RESET}\n"
                fi
                ;;

            "step_finish")
                reason=$(echo "$line" | jq -r '.part.reason // "finished"')
                tokens=$(echo "$line" | jq -r '.part.tokens.total // "0"')
                echo -e "${BOLD}${GREEN}=== Step Finished ===${RESET} ${GRAY}(Reason: ${reason} | Tokens: ${tokens})${RESET}\n"
                echo -e "${GRAY}--------------------------------------------------------------------------------${RESET}"
                ;;

            *)
                # Falls andere/unbekannte JSON-Zeilen vorkommen
                echo -e "${GRAY}[RAW]${RESET} $line"
                ;;
        esac
    done
}

# Eingabe-Verarbeitung (stdin oder Datei)
if [ -p /dev/stdin ] || [ -f "$1" ]; then
    cat "$@" | format_output
else
    echo "Nutzung: $0 <datei.jsonl> oder cat <datei.jsonl> | $0"
    exit 1
fi
