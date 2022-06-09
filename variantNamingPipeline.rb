#!/usr/bin/env ruby
#
# Facilitate variant querying/registering process with ClinGen Allele Registry
#
# Please create an user name and a password on ClinGen Allele Registry (http://reg.clinicalgenome.org/redmine/projects/registry/genboree_registry/landing) before registerying the variants.
# You can either pass in the path of the file with one line in the format of [User Login]:[Password] or you can modify the variable: loginFile on line 29
#
# There will be 3 types of standard output: *_CAid*, *_noCAid*, *_summary*
#   *_CAid* contains original input and a new column CAid. (Does not include the ones that could not be registered/named)
#   *_noCAid* contains the variants which could not be registered/named
#   *_summary*  summary report of the variants
#
# When not ran successfully there will be an *_Error* which contains Error information given by the ClinGen Allele Registry
#
# ruby v1.8.7
# Author: David Chen
# email: dc12@bcm.edu
#

require 'net/http'
require 'digest/sha1'
require 'optparse'
require 'json'
require 'time'
require 'zlib'

# THE LOGIN FILE PATH NEEDS TO BE MODIFIED TO FIT YOUR DIRECTORY PATH
# IT IS EXPECTING A LINE IN THE FILE WITH FORMAT AS  [USER LOGIN]:[PASSWORD]
loginFile="/home/dc12/.AlleleRegistry"

# return response
# throw exceptions in case of errors
def postData(url, data)
  # send request & parse response
  http = Net::HTTP.new(URI(url).host)
  http.read_timeout = 1200 # seconds
  req = Net::HTTP::Post.new("#{url}")
  req.body = data
  res = http.request(req)
  response = res.body
  # check status
  if not res.is_a? Net::HTTPSuccess
    raise "Error for POST requests: #{response}"
  end
  return response
end

# return response
# throw exceptions in case of errors
def putData(url, data, login, password)
  # calculate token & full URL
  identity = Digest::SHA1.hexdigest("#{login}#{password}")
  gbTime = Time.now.to_i.to_s
  token = Digest::SHA1.hexdigest("#{url}#{identity}#{gbTime}")
  request = "#{url}&gbLogin=#{login}&gbTime=#{gbTime}&gbToken=#{token}"
  # send request & parse response
  http = Net::HTTP.new(URI(url).host)
  http.read_timeout = 1200 # seconds
  req = Net::HTTP::Put.new("#{request}")
  req.body = data
  res = http.request(req)
  response = res.body
  # check status
  if not res.is_a? Net::HTTPSuccess
    raise "Error for PUT requests: #{response}"
  end
  return response
end

# Reads and returns either the user name or password depending on the options passed in
def userLogingAndPw(file, options)
  abort("Error: User Login file: #{file} does not exist") unless File.exist?(file)
  data = File.open(file,'r').readline.chomp.split(/:/)
  return data[0] if options==:user
  return data[1]
end

# Helper function to create the required vcf headers
def outputHeader(vcfVersion,genomeVersion,newHeaderColumns="")
  headerFileFormat = "##fileformat=#{vcfVersion}\n"
  headerGrch38 = "##contig=<ID=1,length=248956422,assembly=GRCh38>\n" +
    "##contig=<ID=2,length=242193529,assembly=GRCh38>\n"+
    "##contig=<ID=3,length=198295559,assembly=GRCh38>\n"+
    "##contig=<ID=4,length=190214555,assembly=GRCh38>\n"+
    "##contig=<ID=5,length=181538259,assembly=GRCh38>\n"+
    "##contig=<ID=6,length=170805979,assembly=GRCh38>\n"+
    "##contig=<ID=7,length=159345973,assembly=GRCh38>\n"+
    "##contig=<ID=8,length=145138636,assembly=GRCh38>\n"+
    "##contig=<ID=9,length=138394717,assembly=GRCh38>\n"+
    "##contig=<ID=10,length=133797422,assembly=GRCh38>\n"+
    "##contig=<ID=11,length=135086622,assembly=GRCh38>\n"+
    "##contig=<ID=12,length=133275309,assembly=GRCh38>\n"+
    "##contig=<ID=13,length=114364328,assembly=GRCh38>\n"+
    "##contig=<ID=14,length=107043718,assembly=GRCh38>\n"+
    "##contig=<ID=15,length=101991189,assembly=GRCh38>\n"+
    "##contig=<ID=16,length=90338345,assembly=GRCh38>\n"+
    "##contig=<ID=17,length=83257441,assembly=GRCh38>\n"+
    "##contig=<ID=18,length=80373285,assembly=GRCh38>\n"+
    "##contig=<ID=19,length=58617616,assembly=GRCh38>\n"+
    "##contig=<ID=20,length=64444167,assembly=GRCh38>\n"+
    "##contig=<ID=21,length=46709983,assembly=GRCh38>\n"+
    "##contig=<ID=22,length=50818468,assembly=GRCh38>\n"+
    "##contig=<ID=X,length=156040895,assembly=GRCh38>\n"+
    "##contig=<ID=Y,length=57227415,assembly=GRCh38>\n"+
    "##contig=<ID=M,length=16569,assembly=GRCh38>\n"

  headerGrch37 = "##contig=<ID=1,length=249250621,assembly=gnomAD_GRCh37>\n"+
    "##contig=<ID=2,length=243199373,assembly=GRCh37>\n"+
    "##contig=<ID=3,length=198022430,assembly=GRCh37>\n"+
    "##contig=<ID=4,length=191154276,assembly=GRCh37>\n"+
    "##contig=<ID=5,length=180915260,assembly=GRCh37>\n"+
    "##contig=<ID=6,length=171115067,assembly=GRCh37>\n"+
    "##contig=<ID=7,length=159138663,assembly=GRCh37>\n"+
    "##contig=<ID=8,length=146364022,assembly=GRCh37>\n"+
    "##contig=<ID=9,length=141213431,assembly=GRCh37>\n"+
    "##contig=<ID=10,length=135534747,assembly=GRCh37>\n"+
    "##contig=<ID=11,length=135006516,assembly=GRCh37>\n"+
    "##contig=<ID=12,length=133851895,assembly=GRCh37>\n"+
    "##contig=<ID=13,length=115169878,assembly=GRCh37>\n"+
    "##contig=<ID=14,length=107349540,assembly=GRCh37>\n"+
    "##contig=<ID=15,length=102531392,assembly=GRCh37>\n"+
    "##contig=<ID=16,length=90354753,assembly=GRCh37>\n"+
    "##contig=<ID=17,length=81195210,assembly=GRCh37>\n"+
    "##contig=<ID=18,length=78077248,assembly=GRCh37>\n"+
    "##contig=<ID=19,length=59128983,assembly=GRCh37>\n"+
    "##contig=<ID=20,length=63025520,assembly=GRCh37>\n"+
    "##contig=<ID=21,length=48129895,assembly=GRCh37>\n"+
    "##contig=<ID=22,length=51304566,assembly=GRCh37>\n"+
    "##contig=<ID=X,length=155270560,assembly=GRCh37>\n"+
    "##contig=<ID=Y,length=59373566,assembly=GRCh37>\n"

  headerColumns = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n"
  headerColumns = newHeaderColumns unless newHeaderColumns == ""

  if genomeVersion.match(/grch38|hg38/i)
    return headerFileFormat + headerGrch38 + headerColumns
  elsif genomeVersion.match(/grch37|hg18/i)
    return headerFileFormat + headerGrch37 + headerColumns
  else
    #Making sure the genome version matches with the versions we currently handle
    abort("Error: Genome Version: #{genomeVersion} is not a supported version. Please use one of the supported ones (hg19|grch37 or hg38|grch38).")
  end
end

# Parses the e/sQTL input file to create a VCF for Allele Registry
def convertQtlInputToVcf( options,infile,outfileName,notRegisteredFile)
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Create an intermediate VCF: #{outfileName} from the input: #{infile}"
  #output = File.open( outfile,"w" )
  #output.puts(outputHeader("VCFv4.2",ref))
  if options[:gz]
    inputFile = Zlib::GzipReader.open(infile)
    notRegFile =  Zlib::GzipWriter.open( notRegisteredFile )
  else
    inputFile = File.open(infile)
    notRegFile = File.open( notRegisteredFile,"w" )
  end
  columnNames = []
  metadata = {}
  #skip = []
  origHeader = ""
  origData = ""
  data = ""
  vcfHeader = outputHeader("VCFv4.2",options[:ref])
  lineCount = 1
  fileCount = 1
  tmpFileName = "#{outfileName}_tmp-#{fileCount}"
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Collecting variants for #{tmpFileName}"
  #File.open(infile).each_with_index { |line,index|
  inputFile.each { |line|
    tmp = line.chomp.split("\t")
    varID = ""
    chr = ""
    pos = ""
    ref = ""
    alt = ""
    if options[:gtex_egenes]
      if line.match("gene_name\tgene_chr")
        origHeader = line.chomp
        columnNames = tmp
        notRegFile.write "#{line.chomp}\tErrorComments\n"
        next
      end

      #make sure the required column names are there in the header
      requiredCols = ["variant_id","chr","variant_pos","ref","alt"]
      checkColumnNames(columnNames,requiredCols)

      varID = tmp[columnNames.index("variant_id")]
      chr = tmp[columnNames.index("chr")].split("chr")[1]
      pos = tmp[columnNames.index("variant_pos")]
      ref = tmp[columnNames.index("ref")]
      alt = tmp[columnNames.index("alt")]
    else
      if line.match("variant_id")
        origHeader = line.chomp
        columnNames = tmp
        notRegFile.write "#{line.chomp}\tErrorComments\n"
        next
      end
      #make sure the required column names are there in the header
      requiredCols = ["variant_id"]
      checkColumnNames(columnNames,requiredCols)
      variantId_split= tmp[columnNames.index("variant_id")].split("_")

      varID = tmp[columnNames.index("variant_id")]
      chr = variantId_split[0].split("chr")[1]
      pos = variantId_split[1]
      ref = variantId_split[2]
      alt = variantId_split[3]
    end

    if alt.match(/\*/)
      notRegFile.write "#{line.chomp}\tCurrent version of Allele Registry cannot take * as an alt allele\n"
    elsif alt.match(/,/)
      notRegFile.write "#{line.chomp}\tAllele Registry cannot take more than 1 alt allele, please split this entry into entries with just 1 alt allele\n"
    else
      data = data + "#{chr}\t#{pos}\t.\t#{ref}\t#{alt}\t.\t.\t#{varID}\n"
      origData = origData + line
      if lineCount <= options[:block]
        lineCount = lineCount + 1
      else
        lineCount = 0
        vcfData = vcfHeader + data
        origData = vcfHeader + origData
        callAlleleRegistry(options,vcfData,tmpFileName,origData)
        fileCount = fileCount + 1
        tmpFileName = "#{outfileName}_tmp-#{fileCount}"
        puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Collecting variants for #{tmpFileName}"
        data = ""
        origData = ""
      end

      #output.puts "#{chr}\t#{pos}\t.\t#{ref}\t#{alt}\t.\t.\t#{varID}"
    end
  }
  unless data == ""
    vcfData = vcfHeader + data
    origData = vcfHeader + origData
    callAlleleRegistry(options,vcfData,tmpFileName,origData )
  end
  notRegFile.close
  #output.close
  #metadata[:skip] = skip
  metadata[:origHeader] = origHeader
  metadata[:vcfHeader] = vcfHeader
  return metadata
end

# Parses the input VCF file and creates a new VCF for Allele Registry
def modVcfInputToAlleleReg( options,infile,outfileName,notRegisteredFile)
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Create an intermediate VCF: #{outfileName} from the input: #{infile}"
  createHeader = FALSE
  metadata = {}
  vcfVersion = ""
  headerCols = ""
  origHeader = ""
  vcfHeader = ""
  fileCount = 1
  lineCount = 1
  data = ""
  if options[:gz]
    inputFile = Zlib::GzipReader.open( infile )
    notRegFile = Zlib::GzipWriter.open( notRegisteredFile )
  else
    inputFile = File.open( infile,"r" )
    notRegFile = File.open( notRegisteredFile,"w" )
  end
  tmpFileName = "#{outfileName}_tmp-#{fileCount}"
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Collecting variants for #{tmpFileName}"
  inputFile.each { |line|
    tmp = line.chomp
    if tmp.match(/^##fileformat/)
      vcfVersion = tmp.split(/=/)[1]
      notRegFile.write line
      origHeader = origHeader + line
      next
    elsif tmp.match(/#CHROM/)
      origHeader = origHeader + line
      if tmp.match(/##CHROM/)
        headerCols = tmp.upcase.sub("##CHROM","#CHROM").split(/\t/)
      else
        headerCols = tmp.upcase.split(/\t/)
      end
      notRegFile.write "#{tmp}\tErrorComments\n"
      if vcfVersion == ""
        abort("VCF version could not be found, please include it under the first line eg. ##fileformat=VCFv4.2")
      end
      #checks header column to make sure the required ones are there, otherwise it will exit with error message
      requiredCols = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO".split(/\t/)
      checkColumnNames(headerCols,requiredCols)
      vcfHeader = outputHeader(vcfVersion,options[:ref],headerCols.join("\t")) + "\n"
      createHeader = TRUE
      next
    elsif tmp.match(/^##/)
      origHeader = origHeader + line
      notRegFile.write line
      next
    end

    # Check to make sure vcfHeader is generated otherwise the header column might be missing
    unless createHeader
      abort("Header for the VCF was not created, please check to see if header for file format and columns are listed correctly in the input file.\nThe following column titles are required: #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n")
    end
    altInd = headerCols.index("ALT")
    alt = tmp.split("\t")[altInd]
    if alt.match(/\*/)
      notRegFile.write "#{tmp}\tCurrent version of Allele Registry cannot take * as an alt allele\n"
    elsif alt.match(/,/)
      notRegFile.write "#{tmp}\tAllele Registry cannot take more than 1 alt allele, please split this entry into multiple entries with just 1 alt allele\n"
    else
      data= data+line
      if lineCount <= options[:block]
        lineCount = lineCount + 1
      else
        lineCount = 0
        vcfData = vcfHeader + data
        callAlleleRegistry( options,vcfData,tmpFileName,"" )
        fileCount = fileCount + 1
        tmpFileName = "#{outfileName}_tmp-#{fileCount}"
        puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Collecting variants for #{tmpFileName}"
        data = ""
      end
    end
  }
  unless data == ""
    vcfData = vcfHeader + data
    callAlleleRegistry( options,vcfData,tmpFileName,"" )
  end
  notRegFile.close
  metadata[:origHeader] = origHeader
  metadata[:vcfHeader] = vcfHeader
  return metadata
end

# Helper function to make sure the correct columns are there in the header
def checkColumnNames(header,requiredCols)
  requiredCols.each { |col|
    unless header.include?(col)
      abort("The header column needs to have '#{col}' as a column header")
    end
  }
end

# Makes the request with ClinGen Allele Registry
def callAlleleRegistry(options,data,outfileName,origData)
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Calling ClinGen Allele Registry for data in #{outfileName}"
  # URL to connect to allele registry
  #url = "http://reg.genome.network/alleles?file=vcf&fields=none+@id+externalRecords"
  url = "http://reg.genome.network/alleles?file=vcf&fields=none+@id"

  if options[:naming]
    response = putData( url,data,userLogingAndPw(options[:loginFile],:user),userLogingAndPw(options[:loginFile],:pw))
  else
    response = postData(url, data)
  end
  respJson = JSON.parse(response)
  if respJson.is_a?(Hash)
    errfile = "#{outfileName}_Error.txt"
    File.open(errfile,"w") {|file|
      respJson.each { |key,value|
        file.write "#{key}: #{value}\n"
      }
    }
    outfile = "#{outfileName}_input.txt"
    File.open(outfile,"w") { |file| file.write data}
  else
    if options[:summary]
      sumFile = "#{outfileName}_summary.txt"
      createSummaryReport( respJson,sumFile )
    end

    if options[:gz]
      pipeOutputFile = "#{outfileName}_CAid#{options[:infileExtension]}#{options[:gzFileExtension]}"
      notRegFile = "#{outfileName}_noCAid#{options[:infileExtension]}#{options[:gzFileExtension]}"
    else
      pipeOutputFile = "#{outfileName}_CAid#{options[:infileExtension]}"
      notRegFile = "#{outfileName}_noCAid#{options[:infileExtension]}"
    end
    if options[:gtex]
      outputCAid( options, origData ,respJson,pipeOutputFile,notRegFile )
    else
      outputCAid( options, data ,respJson,pipeOutputFile,notRegFile )
    end

  end
end

# Creates the summary report to show the general results
def createSummaryReport( respJson,outfile )
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Creating summary file: #{outfile}"
  totalVariants = respJson.size
  extRecords = {}
  respJson.each { |entry|
    if entry["@id"] == "_:CA"
      addCount( extRecords,"unregistered",1)
    end
    if entry.key?("externalRecords")
      entry["externalRecords"].each_key { |extKey| addCount( extRecords, extKey,1) }
    end
  }
  unregistered = 0
  unregistered = unregistered + extRecords["unregistered"] if extRecords.key?("unregistered")
  sumOut = File.open(outfile,"w")
  sumOut.puts "Total variants: #{totalVariants}"
  sumOut.puts "Total registered: #{totalVariants-unregistered}"
  sumOut.puts "Total unregistered: #{unregistered}"
  sumOut.puts "Variants seen in other records:"
  extRecords.each_key { |key|
    next if key == "unregistered"
    sumOut.puts "#{key}: #{extRecords[key]}"
  }
  sumOut.close
end

# Creates the CAid file which contains CAid from Allele Registry
def outputCAid( options, data,respJson,outfile,notRegisteredFile)
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Creating CAid file: #{outfile}"
  respCount = 0
  if options[:gz]
    out = Zlib::GzipWriter.open( outfile )
    notRegFile = Zlib::GzipWriter.open( notRegisteredFile )
  else
    out = File.open( outfile, "w" )
    notRegFile = File.open( notRegisteredFile,"w" )
  end
  #puts ""
  #puts data
  data.split("\n").each { |line|
    tmp = line.chomp
    next if tmp.match(/#/)
    #puts respCount
    #puts respJson[respCount]
    caId = respJson[respCount]["@id"]
    if caId == "_:CA"
      notRegFile.write "#{tmp}\t\n"
    else
      out.write "#{tmp}\t#{caId}\n"
    end
    respCount = respCount + 1
  }
  notRegFile.close
  out.close
end

# Clean up intermediate files in tmp directory
def cleanTmpDirFiles(tmpFileRootName)
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Clean up/Initial Clean up to make sure no intermediate files:"
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Removing files resembing #{tmpFileRootName}"
  Dir["#{tmpFileRootName}*"].each  { |file|
    #puts file
    File.delete(file)
  }
  #puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Attempt to remove tmp directory: #{tmpPath}"
  #Dir.delete(tmpPath) if Dir.entries(tmpPath).size == 2
end

def mergeIntermediateWithInput(options, tmpDir, ourFileName)
  if options[:gz]
    caIdOutName = "#{outFileName}_CAid#{options[:infileExtension]}#{options[:gzFileExtension]}"
    noCAidOutName = "#{outFileName}_noCAid#{options[:infileExtension]}#{options[:gzFileExtension]}"
  else
    caIdOutName = "#{outFileName}_CAid#{options[:infileExtension]}"
    noCAidOutName = "#{outFileName}_noCAid#{options[:infileExtension]}"
  end
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Merging *_CAid* intermediate files in: #{tmpDir}"
  caIDs = Dir["#{tmpDir}/*tmp*_CAid*"]

end

def mergeIntermediateVcfFiles(options,tmpDir,outFileName)
  if options[:gz]
    caIdOutName = "#{outFileName}_CAid#{options[:infileExtension]}#{options[:gzFileExtension]}"
    noCAidOutName = "#{outFileName}_noCAid#{options[:infileExtension]}#{options[:gzFileExtension]}"
  else
    caIdOutName = "#{outFileName}_CAid#{options[:infileExtension]}"
    noCAidOutName = "#{outFileName}_noCAid#{options[:infileExtension]}"
  end
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Merging *_CAid* intermediate files in: #{tmpDir}"
  caIDs = Dir["#{tmpDir}/*tmp*_CAid*"]
  #puts "cat #{caIDs.join(" ")} > #{options[:out]}/#{caIdOutName}\n"
  `cat #{caIDs.join(" ")} > #{options[:out]}/#{caIdOutName}`

  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Merging *_noCAid* intermediate files in: #{tmpDir}"
  noCAids = Dir["#{tmpDir}/*tmp*_noCAid*"]
  #puts "cat #{options[:notRegisteredFile]} #{noCAids.join(" ")} > #{options[:out]}/#{noCAidOutName}"
  `cat #{options[:notRegisteredFile]} #{noCAids.join(" ")} > #{options[:out]}/#{noCAidOutName}`

  if options[:summary]
    summaries = "#{tmpDir}/*tmp*summary*"
    mergeIntermediateSummary(options, tmpDir, outFileName, countLinesInFiles(options,noCAids,options[:notRegisteredFile]) )
  end
end

def countLinesInFiles(options, fileArray, singleFile)
  sum = 0
  fileArray.each { |file|
    if options[:gz]
      sum = sum + Zlib::GzipReader.open(file).readlines.size
    else

      sum = sum + File.readlines(file).size
    end
  }
  if options[:gz]
    file = Zlib::GzipReader.open(singleFile)
  else
    file = File.open(singleFile)
  end
  file.each { |line|
    next if line.match(/#/)
    sum = sum + 1
  }
  return sum
end

def mergeIntermediateSummary(options, tmpDir, outFileName, noCAidsCount)
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Merging summary intermediate files in: #{tmpDir}"
  totalCountHash = {}
  Dir["#{tmpDir}/*tmp*summary*"].each { |summary|
    extRecordCheck = FALSE
    File.open(summary,"r").each_line { |line|
      if line.match(/records:/)
        extRecordCheck = TRUE
        next
      end
      if extRecordCheck
        #     puts line
        tmpLine = line.chomp.split(":")
        addCount( totalCountHash,tmpLine[0],tmpLine[1].to_i )
      else
        #puts line
        count = line.chomp.split(":")[1].to_i
        if line.match(/variants/)
          addCount(totalCountHash, :variants,count )
        elsif line.match(/unregistered/)
          addCount(totalCountHash, :unregistered,count )
        else
          addCount(totalCountHash, :registered,count )
        end
      end
    }
  }
  addCount( totalCountHash, :variants,noCAidsCount )
  addCount( totalCountHash, :unregistered,noCAidsCount )

  outfile = "#{options[:out]}/#{outFileName}_summary.txt"
  puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] Creating final summary file: #{outfile}"
  setKeys = [:variants, :registered, :unregistered]
  out = File.open(outfile,"w")
  out.puts "Total variants: #{totalCountHash[:variants]}"
  out.puts "Total registered: #{totalCountHash[:registered]}"
  out.puts "Total unregistered: #{totalCountHash[:unregistered]}"
  out.puts "Variants seen in other records:"
  outKeys = totalCountHash.keys - setKeys
  outKeys.each { |key|
    next if setKeys.include?(key)
    out.puts "#{key}: #{totalCountHash[key]}"
  }
  out.close
end

# Helper function to add the count of a database in for summary report
def addCount(countHash, key, count)
  if countHash.key?(key)
    tmp = countHash[key]
    tmp = tmp + count
    countHash[key] = tmp
  else
    countHash[key] = count
  end
end

options = {}
optparse = OptionParser. new { |opts|
  opts.banner = "Note: An user account is required for variant naming.  Please go to http://reg.clinicalgenome.org/redmine/projects/registry/genboree_registry/landing to create an account.\n\n" +
    "Usage:  ruby #{File.basename(__FILE__)} [options]\n" +
    "\tDefault is set on querying the variants instead of naming the variants.\n\tInput is set on VCF format unless GTEx option is specified."
  opts.on('-n', '--name', "Naming/registering the variants in Allele Registry") { options[:naming] = TRUE}
  opts.on('--gtex_egenes', "Using GTEx s/eQTL egenes files as input (input will be assumed to be a VCF if this is not set)") { options[:gtex_egenes]=TRUE}
  opts.on('--gtex_pairs', "Using GTEx s/eQTL gene/signif pair files as input (input will be assumed to be a VCF if this is not set)") { options[:gtex_pairs]=TRUE}
  opts.on('--gz', "Use this flag to indicate the input is gzipped") { options[:gz] = TRUE}
  opts.on('-r', '--ref reference', "reference genome for the input file [hg19|grch37 or hg38|grch38] (default at hg38)") { |ref| options[:ref] = ref}
  opts.on('-b', '--block blockNumber', "Querying/Naming in blocks in large inputs, Default is at 10000") { |block| options[:block] = block.to_i}
  opts.on('-i', '--input inputPath', "Path to the input file") {|input| options[:input]=input}
  opts.on('-o', '--out outputPath', "Designate output path (default at the current locaiton)") {|out| options[:out]=out}
  opts.on('-w', '--work workingPath', "Designate working directory for the intermediate files (default is set as tmp under outputPath") {|work| options[:work]=work}
  opts.on('-s', '--summary', "Creates the summary report at the end") {options[:summary]=TRUE}
  opts.on('-l', '--login filePath', "Path to the file which contains user login information (one line in [username]:[pw] format)") { |filePath| options[:loginFile] = filePath}
  opts.on('-h', '--help', "Display this screen"){ puts optparse; exit }
}
optparse.parse!

if options[:ref].nil?
  options[:ref] = "hg38"
end

if options[:input].nil?
  puts "Error:"
  puts "An input file is required, it can be specified using [-i|--input] [Path to input]"
  puts ""
  puts optparse
  exit(1)
end

infile = options[:input]
options[:block] = 10000 if options[:block].nil?
outfilePath = Dir.pwd
outfilePath = options[:out] unless options[:out].nil?
options[:out] = Dir.pwd if options[:out].nil?

if options[:loginFile].nil?
  options[:loginFile] = loginFile
end

unless File.exist?(options[:loginFile])
  puts "Error: login file - #{options[:loginFile]} could not be found. Please use make sure the files exists and pass it with -l flag or modify loginFile path in the code"
  puts ""
  puts optparse
  exit(1)
end

#Make sure input file exist
abort("Error: Input file: #{infile} does not exist") unless File.exist?(infile)
#Make sure output path exist
abort("Error: Output path: #{outfilePath} points to a locatioin that does not exist") unless File.directory?(outfilePath)

if options[:work]
  tmpDir = options[:work]
  abort("Error: working directory: #{tmpDir} for intermediate files does not exist.") unless File.directory?(tmpDir)
else
  tmpDir = "#{outfilePath}/tmp"
  Dir.mkdir( tmpDir ) unless File.exist?( tmpDir )
end
if options[:gz]
  options[:gzFileExtension] = File.extname( infile )
  options[:infileExtension] = File.extname( File.basename(infile,File.extname(infile)) )
  fname = File.basename(infile,"#{options[:infileExtension]}#{options[:gzFileExtension]}")
  notRegisteredFile = "#{tmpDir}/#{fname}_noCAid#{options[:infileExtension]}#{options[:gzFileExtension]}"
else
  options[:infileExtension] = File.extname(infile)
  fname = File.basename( infile,File.extname(infile) )
  notRegisteredFile = "#{tmpDir}/#{fname}_noCAid#{options[:infileExtension]}"
end

options[:notRegisteredFile] = notRegisteredFile
tmpDirFname = "#{tmpDir}/#{fname}"
#make sure intermediates files do not exist in tmp dir
cleanTmpDirFiles(tmpDirFname)
vcfFname = "#{tmpDirFname}_CARmod"

if options[:gtex_egenes] || options[:gtex_pairs]
  metadata = convertQtlInputToVcf( options,infile,vcfFname,notRegisteredFile )
else
  metadata = modVcfInputToAlleleReg( options,infile,vcfFname,notRegisteredFile )
end
mergeIntermediateVcfFiles(options,tmpDir,fname)


#remove the intermediate files
cleanTmpDirFiles(tmpDirFname)

puts "[#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}] finish"