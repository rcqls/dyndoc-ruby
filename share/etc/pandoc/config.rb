{
	"md2s5"			=> ["-t","s5","--webtex","-s","-V","s5-url=#{Dyndoc.cfg_dir[:etc]}/pandoc/extra/s5-ui/default", "--self-contained"],
	"md2revealjs" 	=> ["-t","revealjs","--webtex","-s","-V","theme=sky","-V","revealjs-url=#{Dyndoc.cfg_dir[:etc]}/pandoc/extra/reveal.js-3.0.0", "--self-contained"]
}