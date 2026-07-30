set encoding utf8
set terminal pdfcairo size 10,3

array Projects[7] = ["Cli", "Compress", "JacksonCore", "JacksonDatabind", "Jsoup", "Lang", "Time"]

do for [i=1:7] {
    proj = Projects[i]

	set out sprintf("%s.pdf", proj)

	set multiplot layout 1,3

	set xlabel 'Steps'
	set ylabel 'Tokens'
	plot sprintf("results-%s-uninformed.csv", proj) u ($3):4:(($2 == 0) ? 0x00FF00 : 0xFF0000) with points pt 7 ps 1.5 lc rgb variable title 'Uninformed'

	unset ylabel
	plot sprintf("results-%s-semi-informed.csv", proj) u ($3):4:(($2 == 0) ? 0x00FF00 : 0xFF0000) with points pt 7 ps 1.5 lc rgb variable title 'semi-informed'

	plot sprintf("results-%s-informed.csv", proj) u ($3):4:(($2 == 0) ? 0x00FF00 : 0xFF0000) with points pt 7 ps 1.5 lc rgb variable title 'informed'

	unset multiplot
	unset output
}
