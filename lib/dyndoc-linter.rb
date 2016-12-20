# Pour simplifier chercher les tags voisins qui sont ouvrant et fermant et les virer

## First version of dyn-lint
## TODO:
## * detect the position of the error
## * warning when suspecting block ending by ] by accident

module Dyndoc
  module Linter
    def Linter.selected_tags(txt)
      selected_tags=txt.scan(/(?:\{[\#\@](?:[\w\:\|-]*[<>]?[=?!><]?(?:\.\w*)?)\]|\[[\#\@](?:[\w\:\|-]*[<>]?[=?!><]?)\})/).each_with_index.map{|e,i| [i+1,e] }
      ## p selected_tags
      selected_tags
    end

    def Linter.simplify_dyndoc_tags(tags)
      (0..(tags.length-2)).each do |i|
        if (tags[i][1] == "{#"+tags[i+1][1][2..-2]+"]" and tags[i+1][1] == "[#"+tags[i][1][2..-2]+"}") or (tags[i][1][0]=="{" and tags[i+1][1]=="[#}")
          tags.delete_at i+1;tags.delete_at i
          Dyndoc::Linter.simplify_dyndoc_tags(tags)
          break
        end
      end
      return tags
    end

    def Linter.guess_bad_tags(tags)

    end

    def Linter.guess_bad_opentags(txt)
      selected_opentags=txt.scan(/(?:\{[\#\@](?:[\w\:\|-]*[<>]?[=?!><]?(?:\.\w*)?)\})/).each_with_index.map{|e,i| [i+1,e] }
    end

    def Linter.check_content(txt)
      Dyndoc::Linter.simplify_dyndoc_tags(Dyndoc::Linter.selected_tags(txt))
    end

    def Linter.check_file(file_to_lint)
      txt=File.read(file_to_lint)
      Dyndoc::Linter.check_content(txt) + Dyndoc::Linter.guess_bad_opentags(txt)
    end
  end
end
