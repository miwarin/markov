# coding: utf-8

require 'uri'
require 'open-uri'
require 'rexml/document'
require 'pp'


# XML を解析して係り受けごとにまとめる
def syntactic_parse(xml)
  syntactic ||= []
  
  doc = REXML::Document.new(xml)
  doc.elements.each('ResultSet/Result/ChunkList/Chunk') do |chunk|
    chunks = ""
    chunk.elements.each('MorphemList') do |ml|
      ml.elements.each("Morphem/Surface") do |mo|
        chunks << mo.text
      end
    end
    syntactic << chunks
  end
  
  return syntactic
end

def dummy()
  xml = "./hoge.xml"
  text = File.open(xml).read()
  syntactic = syntactic_parse(text)
  return syntactic
end

# 係り受け解析
def syntactic_analysis(text)
#  return dummy()

  apiuri = "http://jlp.yahooapis.jp/DAService/V1/parse"
  appid = "?appid=" + "YOUR APPID"
  sentence = "&sentence=" + URI.encode(text)
  uri = apiuri + appid + sentence
  
  response = open(uri).read()
  syntactic = syntactic_parse(response)
  return syntactic
end


# マルコフ連鎖 学習
def learn(syntacticed)
  statetab ||= {}

  size = syntacticed.size
  0.upto(size - 2) {|index|
    w1 = syntacticed[index]
    w2 = syntacticed[index + 1]
    
    statetab[w1] ||= []
    statetab[w1] << w2
  }
  
  return statetab
end


N_MAX = 10

# マルコフ連鎖 生成
def generate(input, statetab)
  
  output = ""
  
  term = statetab.keys.sample
  output << term
  
  0.upto(N_MAX) {|n|
    if statetab.key?(term)
      term = statetab[term].sample
    else
      term = statetab.keys.sample
    end
    output << term
  }
  
  return output
end

# テキスト読むだけ
#   テキストの途中に \n があると chomp だと削除できないようなので gsub しとく
def read(text)
  File.open(text).read.gsub("\n", "")
end


def main(argv)
  file = argv[0]
  input = read(file)
  syntactic = syntactic_analysis(input)
  statetab = learn(syntactic)
  output = generate(input, statetab)
  
  puts output
end

main(ARGV)
