require 'spec_helper'

describe ProxyController do 
  describe "GET #index" do
    context "without params" do
      it "is bad request" do
        get :index
        response.status.should == 400
      end
    end

    context "with query and all required params" do
      before { 
        get :index, "x-lquery" => "integer", "x-facet_def" => "test", "x-nofacets" => 1, :format => :xml
      }

      let(:doc) {
        Nokogiri::XML.parse(response.body)
      }

      it "is valid request" do
        response.status.should == 200
      end

      it "returns 10 pnx documents" do
        doc.xpath("count(//search:DOC)").should == 10
      end

      it "assigns counts and doc indices" do
        doc.xpath("//search:DOCSET/@TOTALHITS").first.content.to_i.should == 15
        doc.xpath("//search:DOCSET/@FIRSTHIT").first.content.to_i.should == 1
        doc.xpath("//search:DOCSET/@LASTHIT").first.content.to_i.should == 10
        doc.xpath("//search:FACET[@NAME='type']/search:FACET_VALUES[@KEY='article']/@VALUE").first.content.to_i.should == 15
        doc.xpath("//search:DOCSET/search:DOC[1]/@ID").first.content.to_i.should == 1
        doc.xpath("//search:DOCSET/search:DOC[7]/@ID").first.content.to_i.should == 7
      end

      it "assigns counts and doc indices for subsequent page" do
        get :index, "x-lquery" => "integer", :startRecord => 11, "x-facet_def" => "test", "x-nofacets" => 1, :format => :xml
        doc = Nokogiri::XML.parse(response.body)
        doc.xpath("//search:DOCSET/@TOTALHITS").first.content.to_i.should == 15
        doc.xpath("//search:DOCSET/@FIRSTHIT").first.content.to_i.should == 11
        doc.xpath("//search:DOCSET/@LASTHIT").first.content.to_i.should == 15
        doc.xpath("//search:FACET[@NAME='type']/search:FACET_VALUES[@KEY='article']/@VALUE").first.content.to_i.should == 15
        doc.xpath("//search:DOCSET/search:DOC[1]/@ID").first.content.to_i.should == 11
        doc.xpath("//search:DOCSET/search:DOC[2]/@ID").first.content.to_i.should == 12
      end

    end

    context "with caching" do
      before { 
        Rails.cache.clear 
      }

      it "only queries solr once on repeated request" do
        RSolr.should_receive(:connect).once.and_call_original
        get :index, "x-lquery" => "integer", "x-facet_def" => "test", "x-nofacets" => 1, :format => :xml
        get :index, "x-lquery" => "integer", "x-facet_def" => "test", "x-nofacets" => 1, :format => :xml
      end

    end


  end
end
