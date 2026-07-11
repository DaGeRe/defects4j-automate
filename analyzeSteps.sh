

for i in 0 1 2 6 7; do
	for project in Lang JacksonDatabind Jsoup; do
		for mode in uninformed semi-informed informed; do
			info_file="iteration-$i/bugs_${project}_${mode}.txt"
			echo -n "$project-$mode "
			count_expected=0
			count_success_no_doc=0
			count_failed_giveup=0
			
			count_success_total=0
			count_failed_total=0
			avg_tokens_success="0.0"
			avg_tokens_failed="0.0"
			for file in iteration-$i/runs_"$project"_"$mode"/fixing_*; do
				bug_id=$(basename "$file" | sed 's/fixing_//; s/\.txt//')
				bug_was_fixed=$(awk -v id="$bug_id" '$1 == id {print $3}' "$info_file")
				# echo -n "$file "
				tool_count=$(grep "^{" "$file" | jq -s 'map(select(.type == "tool_use")) | length')
				text_count=$(grep "^{" "$file" | jq -s 'map(select(.type == "text")) | length')
				tokens_sum=$(grep "^{" "$file" | jq -s 'map(.part.tokens.total // 0) | add')
				# echo "$tool_count $text_count $tokens_sum $bug_was_fixed"
				
				if [ "$bug_was_fixed" -eq 0 ]; then
					((count_success_total++))
					avg_tokens_success=$(echo "scale=2; $avg_tokens_success + ($tokens_sum - $avg_tokens_success) / $count_success_total" | bc)
					if [ "$text_count" -gt 0 ]; then
						((count_expected++))
					else
					  ((count_success_no_doc++))
					fi
				elif [ "$bug_was_fixed" -eq 1 ]; then
					((count_failed_total++))
					avg_tokens_failed=$(echo "scale=2; $avg_tokens_failed + ($tokens_sum - $avg_tokens_failed) / $count_failed_total" | bc)
					if [ "$text_count" -gt 0 ]; then
						((count_failed_giveup++))
					else
						((count_expected++))
					fi
			    fi
			done
			
			echo $count_expected $count_success_no_doc $count_failed_giveup $avg_tokens_success $avg_tokens_failed
		done
	done
done
