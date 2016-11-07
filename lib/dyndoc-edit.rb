module Dyndoc
module FileWatcher ## USED by dyn-html

  def FileWatcher.get_dyn_html_info(filename,dyn_file,user)
    content=File.read(filename)
    current_tags=[] #select current tags from doc_tags_info
    doc_tags_info=Dyndoc::Edit.get_doc_tags_info(content,current_tags)
    ##p [:fw_current_tags, current_tags]
    doc_tag=(doc_tags_info.empty? ? "" : "__ALL_DOC_TAG__")
    #p [:dyn_file,dyn_file,$1]
    tmp=dyn_file.split("/")
    user=tmp[2] if tmp[1]=="users"
    ##p [:fw_user,user]
    html_files=Dyndoc::Edit.html_files({doc_tags_info: doc_tags_info , dyn_file: dyn_file },user)

    current_tags=html_files.keys[1..-1] if doc_tag=="__ALL_DOC_TAG__" and current_tags.empty?
    current_doc_tag=(current_tags.empty? ? doc_tag : current_tags[0])
    {html_files: html_files, doc_tag: doc_tag, user: user, current_doc_tag: current_doc_tag, current_tags: current_tags}
  end

end

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

  ## if selected_tag is an Array, allow to get current tags to proces
  def Edit.get_doc_tags_info(content,current_tags=nil)
    doc_tags_info=""
    if content =~ /^\-{3}/
      b=content.split(/^(\-{3,})/,-1)
      if b[0].empty? and b.length>4
        tmp=b[2].strip.split("\n").select{|e2| e2.strip =~/^docs\:/}
        doc_tags_info=tmp[0] || ""
        doc_tags_info=$1.strip if doc_tags_info =~ /^docs\:(.*)/

        tmp=b[2].strip.split("\n").select{|e2| e2.strip =~/^only\:/}
        current_tag_info=tmp[0] || ""
        current_tag_info=$1.strip if current_tag_info =~ /^only\:(.*)/
        p [:only_tag,current_tag_info]
        ## added possibility select current tags only when current_tags is provided as an Array
        if tmp[0] and current_tags and current_tags.is_a? Array
          doc_tags=Edit.get_doc_tags(doc_tags_info)
          current_tag_info.split(",").map{|e| e.strip}.each{|e| current_tags << e if doc_tags.include? e}
          ##p [:only_current_tags,current_tags]
        end

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
