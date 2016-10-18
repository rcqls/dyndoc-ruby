module Dyndoc
module Edit

  def Edit.docs_from_doc_tags_info(doc_tags_info)
    docs={}
    unless doc_tags_info.empty?
      doc_tags_info.split(",").each{|e|
        if e.strip =~ /^([^\(]*)(\([^\(\)]*\))?$/
          docs[$1.strip]=($2 || "("+$1.strip+")")[1..-2].strip
        end
      }
    end
    return docs
  end

  def Edit.get_doc_tags_info(content)
    doc_tags_info=""
    if content =~ /^\-{3}/
        b=content.split(/^(\-{3,})/,-1)
        if b[0].empty? and b.length>4
          tmp=b[2].strip.split("\n").select{|e2| e2.strip =~/^docs\:/}
          doc_tags_info=tmp[0] || ""
          doc_tags_info=$1.strip if doc_tags_info =~ /^docs\:(.*)/
        end
    end
    return doc_tags_info
  end

  def Edit.get_docs(doc_tags_info)
    Edit.docs_from_doc_tags_info(doc_tags_info)
  end

  def Edit.get_doc_tags(doc_tags_info)
    Edit.get_docs(doc_tags_info).keys
  end

  def Edit.get_doc_tags_menu(doc_tags_info)
    doc_tags=Edit.get_doc_tags(doc_tags_info)
    return "" if doc_tags.empty?
    doc_tags="<div class=\"item\" data-value=\"\">default</div>"+doc_tags.map{|e| "<div class=\"item\">"+e+"</div>"}.join("")
    ##p [:dropdown,doc_tags]
    doc_tags
  end

  def Edit.html_file(doc,user=nil) #doc={tag: ..., dyn_file: ..., doc_tags_info: ...}
    html_file=File.join(File.dirname(doc[:dyn_file]),File.basename(doc[:dyn_file],".*")+".html")
    docs=Edit.get_docs(doc[:doc_tags_info])
    if !docs.empty? and docs.keys.include? doc[:tag]
      doc_extra=docs[doc[:tag]]
      if doc_extra[0,1]=="_"
        doc_extra +=doc[:tag] if doc_extra.length==1
        html_file=File.join(File.dirname(doc[:dyn_file]),File.basename(doc[:dyn_file],".*")+doc_extra+".html")
      elsif doc_extra[0,1]=="~"
        # from user root
        if user
          html_file=File.join("/users",user,doc_extra[1..-1]+".html")
        end
      elsif doc_extra[0,1]=="/"
        # from global root
        html_file=File.join(doc_extra[1..-1]+".html")
      elsif !doc_extra.empty?
        html_file=File.join(File.dirname(doc[:dyn_file]),doc_extra+".html")
      end
    end
    return html_file
  end

  def Edit.html_files(doc,user=nil) #doc={dyn_file: ..., doc_tags_info: ...}
    html_files={}
    doc_tags=[""]+Edit.get_doc_tags(doc[:doc_tags_info])
    doc2=doc.dup
    doc_tags.each do |tag|
      doc2[:tag]=tag
      html_file=Edit.html_file(doc2,user)
      html_files[tag]=html_file
    end
    return html_files
  end

end
end
