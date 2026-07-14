set encoding utf8
set terminal pdfcairo size 10,3

array Projects[3] = ["Lang", "JacksonDatabind", "Jsoup"]

do for [i=1:3] {
    proj = Projects[i]

	set out sprintf("%s.pdf", proj)

	set multiplot layout 1,3

	set xlabel 'Steps'
	set ylabel 'Tokens'
	plot sprintf("%s_uninformed.csv", proj) u ($3+$4):5:(($2 == 1) ? 0x00FF00 : 0xFF0000) with points pt 7 ps 1.5 lc rgb variable title 'Uninformed'

	unset ylabel
	plot sprintf("%s_semi-informed.csv", proj) u ($3+$4):5:(($2 == 1) ? 0x00FF00 : 0xFF0000) with points pt 7 ps 1.5 lc rgb variable title 'semi-ininformed'

	plot sprintf("%s_informed.csv", proj) u ($3+$4):5:(($2 == 1) ? 0x00FF00 : 0xFF0000) with points pt 7 ps 1.5 lc rgb variable title 'informed'

	unset multiplot
	unset output
}
